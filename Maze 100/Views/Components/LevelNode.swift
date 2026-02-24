import SwiftUI

struct LevelNode: View {
    let level: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Glow effect for unlocked levels
            if isUnlocked {
                Circle()
                    .fill(Theme.Colors.neonBlue.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .blur(radius: 15)
                    .scaleEffect(isPulsing ? 1.2 : 0.8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    }
            }
            
            // Outer Ring
            Circle()
                .stroke(
                    isUnlocked ? Theme.Gradients.primary : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 3
                )
                .frame(width: 65, height: 65)
                .background(
                    Circle()
                        .fill(Theme.Colors.surface)
                )
            
            // Content
            VStack(spacing: 0) {
                Text("\(level)")
                    .font(Theme.Typography.titleFont(size: 24))
                    .foregroundColor(isUnlocked ? .white : .gray)
                
                if isCompleted {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.victory)
                }
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}
