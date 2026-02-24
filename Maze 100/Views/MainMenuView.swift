import SwiftUI
import Combine

/// Main menu with level selection
struct MainMenuView: View {
    @StateObject private var viewModel = MainMenuViewModel()
    @State private var showingSettings = false
    @State private var selectedLevel: LevelSelection? = nil
    
    private struct LevelSelection: Identifiable, Hashable {
        let level: Int
        var id: Int { level }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background.ignoresSafeArea()
                
                // Animated Background Elements (Optional for future)
                Circle()
                    .fill(Theme.Colors.neonPurple.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Theme.Colors.neonBlue.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: 150, y: 200)
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("MAZE 100")
                            .font(Theme.Typography.titleFont(size: 48))
                            .foregroundColor(.white)
                            .shadow(color: Theme.Colors.neonBlue.opacity(0.5), radius: 10)
                        
                        Text("PRO EDITION")
                            .font(Theme.Typography.hudFont(size: 14))
                            .foregroundColor(Theme.Colors.neonBlue)
                            .kerning(4)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                    
                    // Level Map Path
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(1...100, id: \.self) { level in
                                let unlocked = viewModel.isLevelUnlocked(level)
                                let completed = viewModel.isLevelCompleted(level)
                                
                                // Zig-zag Offset
                                let xOffset: CGFloat = CGFloat(sin(Double(level) * 0.8) * 60)
                                
                                Button(action: {
                                    if unlocked {
                                        selectedLevel = LevelSelection(level: level)
                                    }
                                }) {
                                    LevelNode(level: level, isUnlocked: unlocked, isCompleted: completed)
                                }
                                .accessibilityIdentifier("main.level.\(level)")
                                .buttonStyle(ScaleButtonStyle())
                                .offset(x: xOffset)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                
                                // Connection line (if not last)
                                if level < 100 {
                                    PathLineView(level: level)
                                        .offset(x: calculateLineOffset(for: level))
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
                
                // Bottom Bar / Settings
                VStack {
                    Spacer()
                    GlassButton("Settings", icon: "gearshape.fill") {
                        showingSettings = true
                    }
                    .accessibilityIdentifier("main.settings.button")
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(item: $selectedLevel) { selection in
                GameView(levelNumber: selection.level)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                viewModel.refresh()
                HapticManager.shared.prepare()
            }
        }
    }
    
    private func calculateLineOffset(for level: Int) -> CGFloat {
        let currentX = sin(Double(level) * 0.8) * 60
        let nextX = sin(Double(level + 1) * 0.8) * 60
        return CGFloat((currentX + nextX) / 2)
    }
}

// MARK: - Connector Line
struct PathLineView: View {
    let level: Int
    
    var body: some View {
        let x1 = sin(Double(level) * 0.8) * 60
        let x2 = sin(Double(level + 1) * 0.8) * 60
        
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Theme.Colors.neonBlue.opacity(0.3), Theme.Colors.neonPurple.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: 80)
            .rotationEffect(.init(degrees: atan2(x2 - x1, 80) * 180 / .pi))
            .offset(y: -40) // Position between nodes
    }
}

// MARK: - ViewModel

class MainMenuViewModel: ObservableObject {
    @Published var progress: LevelProgress = LevelProgress()
    
    init() {
        refresh()
    }
    
    func refresh() {
        progress.load()
    }
    
    func isLevelUnlocked(_ level: Int) -> Bool {
        return progress.isLevelUnlocked(level)
    }
    
    func isLevelCompleted(_ level: Int) -> Bool {
        return progress.isLevelCompleted(level)
    }
    
    func bestTime(for level: Int) -> TimeInterval? {
        return progress.bestTime(for: level)
    }
}
