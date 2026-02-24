import SwiftUI

/// Death screen shown when player dies
struct GameOverView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background Blur / Dim
            Theme.Colors.background.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Icon Glow
                ZStack {
                    Circle()
                        .fill(Theme.Colors.death.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .blur(radius: 30)
                    
                    Image(systemName: "bolt.shred.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Theme.Colors.death)
                        .shadow(color: Theme.Colors.death.opacity(0.5), radius: 15)
                }
                
                // Title
                VStack(spacing: 8) {
                    Text("SYSTEM FAILURE")
                        .font(Theme.Typography.titleFont(size: 32))
                        .foregroundColor(.white)
                    
                    Text("PLAYER DISCONNECTED")
                        .font(Theme.Typography.hudFont(size: 14))
                        .foregroundColor(Theme.Colors.death)
                        .kerning(2)
                }
                
                // Actions
                VStack(spacing: 15) {
                    GlassButton("Reboot System", icon: "arrow.clockwise") {
                        dismiss()
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Abort to Menu")
                            .font(Theme.Typography.bodyFont(size: 16))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(30)
        }
    }
}
