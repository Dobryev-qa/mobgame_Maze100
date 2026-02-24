import Foundation
import UIKit

/// Manages haptic feedback for the game
class HapticManager {
    static let shared = HapticManager()
    private var lifecycleObservers: [NSObjectProtocol] = []
    
    private init() {
        observeAppLifecycle()
    }
    
    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private var notificationGenerator: UINotificationFeedbackGenerator?
    
    /// Prepare haptic generators (call on app launch)
    func prepare() {
        if impactGenerators.isEmpty {
            impactGenerators = [
                .light: UIImpactFeedbackGenerator(style: .light),
                .medium: UIImpactFeedbackGenerator(style: .medium),
                .heavy: UIImpactFeedbackGenerator(style: .heavy)
            ]
            notificationGenerator = UINotificationFeedbackGenerator()
        }
        
        impactGenerators.values.forEach { $0.prepare() }
        notificationGenerator?.prepare()
    }
    
    /// Trigger impact haptic
    /// - Parameter style: The impact style (light, medium, heavy)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        DispatchQueue.main.async {
            self.impactGenerators[style]?.impactOccurred()
        }
    }
    
    /// Trigger notification haptic (success, warning, error)
    /// - Parameter type: The notification type
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        DispatchQueue.main.async {
            self.notificationGenerator?.notificationOccurred(type)
        }
    }
    
    private func observeAppLifecycle() {
        let center = NotificationCenter.default
        lifecycleObservers.append(
            center.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.prepare()
            }
        )
    }
}
