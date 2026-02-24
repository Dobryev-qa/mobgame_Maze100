import SwiftUI
import Combine
import StoreKit

/// Settings screen
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("SETTINGS")
                        .font(Theme.Typography.titleFont(size: 32))
                        .foregroundColor(.white)
                        .accessibilityIdentifier("settings.title")
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Audio Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("AUDIO")
                                .font(Theme.Typography.hudFont(size: 14))
                                .foregroundColor(Theme.Colors.neonBlue)
                                .padding(.leading, 10)
                            
                            HStack {
                                Label("Sound Effects", systemImage: viewModel.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .font(Theme.Typography.bodyFont())
                                Spacer()
                                Toggle("", isOn: $viewModel.isSoundEnabled)
                                    .tint(Theme.Colors.neonBlue)
                                    .labelsHidden()
                            }
                            .padding()
                            .background(Theme.Colors.surface)
                            .cornerRadius(12)
                        }
                        
                        // Store Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("STORE")
                                .font(Theme.Typography.hudFont(size: 14))
                                .foregroundColor(Theme.Colors.neonGreen)
                                .padding(.leading, 10)
                            
                            VStack(spacing: 1) {
                                Button(action: {
                                    Task { await viewModel.removeAds() }
                                }) {
                                    HStack {
                                        Label("Remove Ads", systemImage: "speaker.slash.fill")
                                            .font(Theme.Typography.bodyFont())
                                        Spacer()
                                        if viewModel.isAdFree {
                                            Text("PURCHASED")
                                                .font(Theme.Typography.hudFont(size: 10))
                                                .foregroundColor(Theme.Colors.neonGreen)
                                        } else if viewModel.isStoreLoading {
                                            Text("LOADING...")
                                                .font(Theme.Typography.hudFont(size: 10))
                                                .foregroundColor(Theme.Colors.textMuted)
                                        } else {
                                            Text(viewModel.removeAdsPriceText)
                                                .font(Theme.Typography.bodyFont())
                                                .foregroundColor(Theme.Colors.textSecondary)
                                        }
                                    }
                                    .padding()
                                    .background(Theme.Colors.surface)
                                }
                                .disabled(viewModel.isAdFree || viewModel.isStoreBusy)
                                
                                Button(action: {
                                    Task { await viewModel.restorePurchases() }
                                }) {
                                    HStack {
                                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                                            .font(Theme.Typography.bodyFont())
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Theme.Colors.surface)
                                }
                                .disabled(viewModel.isStoreBusy)
                            }
                            .cornerRadius(12)
                            
                            if let storeStatusMessage = viewModel.storeStatusMessage {
                                Text(storeStatusMessage)
                                    .font(Theme.Typography.hudFont(size: 11))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .padding(.horizontal, 8)
                            }
                        }
                        
                        // Progress Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("PROGRESS")
                                .font(Theme.Typography.hudFont(size: 14))
                                .foregroundColor(Theme.Colors.neonPurple)
                                .padding(.leading, 10)
                            
                            Button(action: {
                                viewModel.resetProgress()
                            }) {
                                HStack {
                                    Label("Reset All Progress", systemImage: "trash.fill")
                                        .font(Theme.Typography.bodyFont())
                                    Spacer()
                                }
                                .foregroundColor(Theme.Colors.death)
                                .padding()
                                .background(Theme.Colors.surface)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("INFO")
                                .font(Theme.Typography.hudFont(size: 14))
                                .foregroundColor(Theme.Colors.textMuted)
                                .padding(.leading, 10)
                            
                            VStack(spacing: 1) {
                                InfoRow(title: "Version", value: viewModel.appVersionText)
                                InfoRow(title: "Studio", value: "Antigravity Labs")
                            }
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                GlassButton("Done") {
                    dismiss()
                }
                .accessibilityIdentifier("settings.done.button")
                .padding(.bottom, 20)
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Typography.bodyFont())
            Spacer()
            Text(value)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding()
        .background(Theme.Colors.surface)
    }
}

// MARK: - ViewModel

@MainActor
class SettingsViewModel: ObservableObject {
    private var isBootstrappingAudioState = true
    
    @Published var isSoundEnabled: Bool = true {
        didSet {
            guard !isBootstrappingAudioState, isSoundEnabled != oldValue else { return }
            AudioManager.shared.setMuted(!isSoundEnabled)
        }
    }
    
    @Published var isAdFree: Bool = false
    @Published var isStoreLoading: Bool = false
    @Published var isStoreBusy: Bool = false
    @Published var removeAdsPriceText: String = "$1.99"
    @Published var storeStatusMessage: String?
    @Published var appVersionText: String = "1.0.0"
    
    private let storeManager = StoreManager.shared
    private var progress: LevelProgress = LevelProgress()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        progress.load()
        isBootstrappingAudioState = true
        isSoundEnabled = !AudioManager.shared.checkMute()
        isBootstrappingAudioState = false
        
        storeManager.$purchasedProductIDs
            .map { $0.contains(StoreManager.adFreeProductID) }
            .assign(to: &$isAdFree)
        
        storeManager.$isLoadingProducts
            .assign(to: &$isStoreLoading)
        
        storeManager.$availableProducts
            .map { products in
                products.first(where: { $0.id == StoreManager.adFreeProductID })?.displayPrice ?? "$1.99"
            }
            .assign(to: &$removeAdsPriceText)
        
        storeManager.$lastStoreErrorMessage
            .assign(to: &$storeStatusMessage)
        
        appVersionText = Self.makeAppVersionText()
        
        Task { [weak self] in
            guard let self else { return }
            await self.storeManager.loadProducts()
        }
    }
    
    func resetProgress() {
        progress.resetProgress()
        AnalyticsManager.shared.track(.progressReset)
    }
    
    func removeAds() async {
        guard !isStoreBusy else { return }
        isStoreBusy = true
        defer { isStoreBusy = false }
        storeStatusMessage = nil
        do {
            try await storeManager.purchase(StoreManager.adFreeProductID)
            if isAdFree {
                storeStatusMessage = "Purchase restored/confirmed."
            }
        } catch {
            storeStatusMessage = error.localizedDescription
            print("Purchase failed: \(error)")
        }
    }
    
    func restorePurchases() async {
        guard !isStoreBusy else { return }
        isStoreBusy = true
        defer { isStoreBusy = false }
        storeStatusMessage = nil
        do {
            try await storeManager.restorePurchases()
            storeStatusMessage = isAdFree ? "Purchases restored." : "No purchases to restore."
        } catch {
            storeStatusMessage = error.localizedDescription
            print("Restore failed: \(error)")
        }
    }
    
    private static func makeAppVersionText(bundle: Bundle = .main) -> String {
        let version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
        let build = (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
        return "\(version) (\(build))"
    }
}
