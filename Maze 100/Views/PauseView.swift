import SwiftUI
import Combine

/// Pause menu
struct PauseView: View {
    @Environment(\.dismiss) private var dismiss
    let onResume: (() -> Void)?
    let onExitToMenu: (() -> Void)?
    
    init(onResume: (() -> Void)? = nil, onExitToMenu: (() -> Void)? = nil) {
        self.onResume = onResume
        self.onExitToMenu = onExitToMenu
    }
    
    var body: some View {
        ZStack {
            // Background Blur / Dim
            Theme.Colors.background.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Title
                VStack(spacing: 8) {
                    Text("PAUSED")
                        .font(Theme.Typography.titleFont(size: 48))
                        .foregroundColor(.white)
                        .shadow(color: Theme.Colors.neonBlue.opacity(0.5), radius: 10)
                    
                    Rectangle()
                        .fill(Theme.Colors.neonBlue)
                        .frame(width: 100, height: 2)
                }
                
                // Info Card
                VStack(spacing: 15) {
                    HStack {
                        Text("STATUS")
                            .font(Theme.Typography.hudFont(size: 14))
                            .foregroundColor(Theme.Colors.textSecondary)
                        Spacer()
                        Text("IN PROGRESS")
                            .font(Theme.Typography.hudFont(size: 14))
                            .foregroundColor(Theme.Colors.neonGreen)
                    }
                }
                .padding()
                .background(Theme.Colors.surface)
                .cornerRadius(16)
                .frame(maxWidth: 280)
                
                // Actions
                VStack(spacing: 15) {
                    GlassButton("Resume", icon: "play.fill") {
                        if let onResume {
                            onResume()
                        } else {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("pause.resume.button")
                    
                    Button(action: {
                        if let onExitToMenu {
                            onExitToMenu()
                        } else {
                            dismiss()
                        }
                    }) {
                        Text("Exit to Menu")
                            .font(Theme.Typography.bodyFont(size: 16))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                    .accessibilityIdentifier("pause.exit.button")
                    .padding(.top, 10)
                }
            }
            .padding(30)
        }
    }
}
