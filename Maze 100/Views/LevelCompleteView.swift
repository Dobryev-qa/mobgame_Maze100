import SwiftUI
import Combine

/// Victory screen shown when player completes a level
struct LevelCompleteView: View {
    let levelNumber: Int
    let time: TimeInterval
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LevelCompleteViewModel()
    let onNextLevel: (() -> Void)?
    let onReturnToMap: (() -> Void)?
    
    init(
        levelNumber: Int,
        time: TimeInterval,
        onNextLevel: (() -> Void)? = nil,
        onReturnToMap: (() -> Void)? = nil
    ) {
        self.levelNumber = levelNumber
        self.time = time
        self.onNextLevel = onNextLevel
        self.onReturnToMap = onReturnToMap
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background.ignoresSafeArea()
            
            // Celebration Glow
            Circle()
                .fill(Theme.Colors.victory.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
            
            VStack(spacing: 35) {
                // Celebration Title
                VStack(spacing: 5) {
                    Text("VICTORY")
                        .font(Theme.Typography.titleFont(size: 48))
                        .foregroundColor(.white)
                        .shadow(color: Theme.Colors.victory.opacity(0.5), radius: 15)
                    
                    Text("LEVEL \(levelNumber) SECURED")
                        .font(Theme.Typography.hudFont(size: 14))
                        .foregroundColor(Theme.Colors.victory)
                        .kerning(3)
                }
                
                // Stats Card
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("COMPLETION TIME")
                            .font(Theme.Typography.hudFont(size: 12))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text(viewModel.formattedTime)
                            .font(Theme.Typography.titleFont(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    // Stars
                    HStack(spacing: 15) {
                        ForEach(0..<3) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.victory)
                                .shadow(color: Theme.Colors.victory.opacity(0.4), radius: 8)
                        }
                    }
                }
                .padding(30)
                .background(Theme.Colors.surface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.Colors.victory.opacity(0.2), lineWidth: 1))
                
                // Actions
                VStack(spacing: 15) {
                    GlassButton("Next Level", icon: "chevron.right") {
                        if let onNextLevel {
                            onNextLevel()
                        } else {
                            dismiss()
                        }
                    }
                    
                    Button(action: {
                        if let onReturnToMap {
                            onReturnToMap()
                        } else {
                            dismiss()
                        }
                    }) {
                        Text("Return to Map")
                            .font(Theme.Typography.bodyFont(size: 16))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(30)
        }
        .onAppear {
            viewModel.setup(time: time, level: levelNumber)
        }
    }
}

// MARK: - ViewModel

class LevelCompleteViewModel: ObservableObject {
    @Published var formattedTime: String = "00:00"
    @Published var isAdReady: Bool = true
    
    private var level: Int = 0
    private var time: TimeInterval = 0
    
    func setup(time: TimeInterval, level: Int) {
        self.time = time
        self.level = level
        formattedTime = formatTime(time)
        
        // Save progress
        var progress = LevelProgress()
        progress.load()
        progress.completeLevel(level, time: time)
        if level < 100 {
            progress.unlockLevel(level + 1)
        }
        progress.save()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    func showRewardedAd(type: RewardedAdType) {
        // Placeholder
        print("Rewarded ad: \(type)")
    }
}
