import Foundation
import StoreKit
import Combine

/// High-fidelity StoreKit 2 manager for Maze 100
@MainActor
final class StoreManager: ObservableObject {
    enum StoreError: LocalizedError {
        case productNotFound(String)
        case purchasePending
        case purchaseCancelled
        case verificationFailed
        case unknownPurchaseResult
        
        var errorDescription: String? {
            switch self {
            case .productNotFound(let id):
                return "Product not found: \(id)"
            case .purchasePending:
                return "Purchase is pending approval."
            case .purchaseCancelled:
                return "Purchase was cancelled."
            case .verificationFailed:
                return "Transaction verification failed."
            case .unknownPurchaseResult:
                return "Unknown purchase result."
            }
        }
    }
    
    static let shared = StoreManager()
    
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var isLoadingProducts: Bool = false
    @Published private(set) var lastStoreErrorMessage: String?
    
    static let adFreeProductID = "com.maze100.removeads"
    static let proPackProductID = "com.maze100.propack"
    
    private let mockPurchasedProductsKey = "storeManager.mockPurchasedProductIDs"
    private let supportedProductIDs = [adFreeProductID, proPackProductID]
    private var productsByID: [String: Product] = [:]
    private var transactionUpdatesTask: Task<Void, Never>?
    private let processInfo = ProcessInfo.processInfo
    
    var isAdFree: Bool {
        purchasedProductIDs.contains(Self.adFreeProductID)
    }
    
    private var allowsMockStoreFallback: Bool {
        #if DEBUG
        // Can be disabled for stricter local testing if needed.
        return !processInfo.arguments.contains("--disable-store-mock-fallback")
        #else
        return false
        #endif
    }
    
    private init() {
        loadMockPurchases()
        startTransactionUpdatesListener()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionUpdatesTask?.cancel()
    }
    
    /// Update the list of products already owned by the user
    func updatePurchasedProducts() async {
        var refreshedIDs = loadMockPurchasedIDs()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if transaction.revocationDate == nil {
                refreshedIDs.insert(transaction.productID)
            } else {
                refreshedIDs.remove(transaction.productID)
            }
        }
        
        purchasedProductIDs = refreshedIDs
        persistMockPurchases()
    }
    
    /// Load product metadata from the App Store (or StoreKit configuration in debug).
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        
        do {
            let products = try await Product.products(for: supportedProductIDs)
            availableProducts = products.sorted { $0.id < $1.id }
            productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            lastStoreErrorMessage = nil
        } catch {
            lastStoreErrorMessage = error.localizedDescription
            CrashReportingManager.shared.record(
                error: error,
                severity: .warning,
                context: "StoreManager.loadProducts"
            )
            print("StoreManager: Failed loading products - \(error)")
        }
    }
    
    /// Purchase a product. Falls back to mock purchase when no StoreKit product metadata is available.
    func purchase(_ productID: String) async throws {
        AnalyticsManager.shared.track(.purchaseStarted, properties: [
            "product_id": productID
        ])
        if productsByID[productID] == nil {
            await loadProducts()
        }
        
        guard let product = productsByID[productID] else {
            if allowsMockStoreFallback {
                // Keep local dev flow operational without a StoreKit config.
                print("StoreManager: Product metadata unavailable for \(productID), using mock purchase fallback.")
                CrashReportingManager.shared.addBreadcrumb(
                    category: "store",
                    message: "Mock purchase fallback used",
                    metadata: ["product_id": productID]
                )
                try await Task.sleep(for: .seconds(1))
                purchasedProductIDs.insert(productID)
                persistMockPurchases()
                AnalyticsManager.shared.track(.purchaseSuccess, properties: [
                    "product_id": productID,
                    "mode": "mock_fallback"
                ])
                return
            }
            
            let error = StoreError.productNotFound(productID)
            AnalyticsManager.shared.track(.purchaseFail, properties: [
                "product_id": productID,
                "error": "product_metadata_unavailable"
            ])
            CrashReportingManager.shared.record(
                error: error,
                severity: .warning,
                context: "StoreManager.purchase",
                metadata: ["product_id": productID]
            )
            throw error
        }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                applyPurchased(transaction: transaction)
                await transaction.finish()
                AnalyticsManager.shared.track(.purchaseSuccess, properties: [
                    "product_id": productID
                ])
            case .pending:
                AnalyticsManager.shared.track(.purchasePending, properties: [
                    "product_id": productID
                ])
                throw StoreError.purchasePending
            case .userCancelled:
                AnalyticsManager.shared.track(.purchaseCancelled, properties: [
                    "product_id": productID
                ])
                throw StoreError.purchaseCancelled
            @unknown default:
                AnalyticsManager.shared.track(.purchaseFail, properties: [
                    "product_id": productID,
                    "error": "unknown_purchase_result"
                ])
                throw StoreError.unknownPurchaseResult
            }
        } catch {
            if !(error is StoreError) {
                AnalyticsManager.shared.track(.purchaseFail, properties: [
                    "product_id": productID,
                    "error": String(describing: error)
                ])
            }
            CrashReportingManager.shared.record(
                error: error,
                context: "StoreManager.purchase",
                metadata: ["product_id": productID]
            )
            throw error
        }
    }
    
    /// Restore previously purchased products
    func restorePurchases() async throws {
        AnalyticsManager.shared.track(.restoreStarted)
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            AnalyticsManager.shared.track(.restoreSuccess, properties: [
                "purchased_count": "\(purchasedProductIDs.count)"
            ])
        } catch {
            AnalyticsManager.shared.track(.restoreFail, properties: [
                "error": String(describing: error)
            ])
            CrashReportingManager.shared.record(
                error: error,
                context: "StoreManager.restorePurchases"
            )
            throw error
        }
    }
    
    func isProductPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    private func loadMockPurchases() {
        guard allowsMockStoreFallback else { return }
        purchasedProductIDs.formUnion(loadMockPurchasedIDs())
    }
    
    private func persistMockPurchases() {
        guard allowsMockStoreFallback else { return }
        UserDefaults.standard.set(Array(purchasedProductIDs).sorted(), forKey: mockPurchasedProductsKey)
    }
    
    private func loadMockPurchasedIDs() -> Set<String> {
        guard allowsMockStoreFallback else { return [] }
        guard let ids = UserDefaults.standard.array(forKey: mockPurchasedProductsKey) as? [String] else {
            return []
        }
        return Set(ids)
    }
    
    private func startTransactionUpdatesListener() {
        transactionUpdatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                do {
                    let transaction = try self.verified(result)
                    self.applyPurchased(transaction: transaction)
                    await transaction.finish()
                } catch {
                    self.lastStoreErrorMessage = error.localizedDescription
                    CrashReportingManager.shared.record(
                        error: error,
                        context: "StoreManager.transactionUpdates"
                    )
                    print("StoreManager: Transaction update verification failed - \(error)")
                }
            }
        }
    }
    
    private func applyPurchased(transaction: Transaction) {
        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
        } else {
            purchasedProductIDs.remove(transaction.productID)
        }
        persistMockPurchases()
    }
    
    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signed):
            return signed
        case .unverified:
            throw StoreError.verificationFailed
        }
    }
}
