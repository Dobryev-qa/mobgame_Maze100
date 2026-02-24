import Foundation

/// Legacy callback adapter kept for compatibility; delegates to StoreManager.
@MainActor
final class IAPManager {
    static let shared = IAPManager()
    private init() {}
    
    private let removeAdsProductID = StoreManager.adFreeProductID
    
    /// Check if ads have been removed via purchase
    func areAdsRemoved() -> Bool {
        StoreManager.shared.isAdFree
    }
    
    /// Purchase "Remove Ads" product
    func purchaseRemoveAds(completion: @escaping (Bool, String?) -> Void) {
        Task { @MainActor in
            do {
                try await StoreManager.shared.purchase(removeAdsProductID)
                completion(true, nil)
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }
    
    /// Restore purchases (for non-consumables)
    func restorePurchases(completion: @escaping (Bool, [String]?) -> Void) {
        Task { @MainActor in
            do {
                try await StoreManager.shared.restorePurchases()
                let ids = StoreManager.shared.isAdFree ? [self.removeAdsProductID] : []
                completion(!ids.isEmpty, ids.isEmpty ? nil : ids)
            } catch {
                completion(false, nil)
            }
        }
    }
}
