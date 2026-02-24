import Foundation
import UIKit

/// Mock-ready manager for advertisements in Maze 100
@MainActor
final class AdManager: NSObject {
    static let shared = AdManager()
    
    /// Called to check if rewarded ad can be shown
    func isRewardedAdReady() -> Bool {
        // In a real implementation, you would check AdMob/AppLovin SDK state
        return true 
    }
    
    /// Show an interstitial ad (typically between levels)
    func showInterstitial(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard !StoreManager.shared.isAdFree else {
            completion()
            return
        }
        
        print("AdManager: Showing Interstitial Ad...")
        // Simulate ad delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion()
        }
    }
    
    /// Show a rewarded ad (for hints or skips)
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        if StoreManager.shared.isAdFree {
            completion(true)
            return
        }
        
        print("AdManager: Showing Rewarded Ad...")
        // Simulate ad delay and success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(true)
        }
    }
}
