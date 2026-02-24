import SwiftUI
import SpriteKit
import Combine
import UIKit

enum GameSessionState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case respawning
    case levelComplete(level: Int)
}

/// Main game view that hosts the SpriteKit scene
struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GameViewModel()
    @State private var showingPause = false
    @State private var showingLevelComplete = false
    @State private var currentLevel: Int
    
    init(levelNumber: Int) {
        self._currentLevel = State(initialValue: levelNumber)
    }
    
    var body: some View {
        ZStack {
            // SpriteKit scene
            if let scene = viewModel.getScene() {
                SpriteView(scene: scene)
                    .id(ObjectIdentifier(scene))
                    .ignoresSafeArea()
            } else {
                Color.black
            }
            
            if viewModel.sessionState == .loading {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Text("Generating level...")
                        .font(Theme.Typography.hudFont(size: 14))
                        .foregroundColor(.white)
                        .accessibilityIdentifier("game.loading.label")
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(Theme.Colors.surface.opacity(0.9))
                .cornerRadius(14)
            }
            
            // HUD
            VStack {
                // Top HUD
                HStack {
                    Button(action: {
                        viewModel.pauseGameplay()
                        showingPause = true
                    }) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Theme.Colors.surface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.Colors.neonBlue.opacity(0.3), lineWidth: 1))
                    }
                    .accessibilityIdentifier("game.pause.button")
                    .disabled(viewModel.sessionState != .playing)
                    
                    Spacer()
                    
                    // Level Badge
                    VStack(spacing: 2) {
                        Text("LEVEL")
                            .font(Theme.Typography.hudFont(size: 10))
                            .foregroundColor(Theme.Colors.neonBlue)
                        Text("\(currentLevel)")
                            .font(Theme.Typography.titleFont(size: 24))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.surface.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.neonBlue.opacity(0.2), lineWidth: 1))
                    
                    Spacer()
                    
                    // Timer Badge
                    VStack(spacing: 2) {
                        Text("TIME")
                            .font(Theme.Typography.hudFont(size: 10))
                            .foregroundColor(Theme.Colors.neonPurple)
                        Text(viewModel.elapsedTimeString)
                            .font(Theme.Typography.hudFont(size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.surface.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.neonPurple.opacity(0.2), lineWidth: 1))
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                // Rewarded ad buttons (bottom)
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.showRewardedAd(type: RewardedAdType.skipLevel)
                    }) {
                        Label("SKIP", systemImage: "forward.fill")
                            .font(Theme.Typography.hudFont(size: 14))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.surface)
                            .foregroundColor(Theme.Colors.neonBlue)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.sessionState != .playing || !viewModel.isAdReady)
                    
                    Button(action: {
                        viewModel.showRewardedAd(type: RewardedAdType.showPath)
                    }) {
                        Label("HINT", systemImage: "sparkles")
                            .font(Theme.Typography.hudFont(size: 14))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.surface)
                            .foregroundColor(Theme.Colors.neonGreen)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.sessionState != .playing || !viewModel.isAdReady)
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            viewModel.setupScene(for: currentLevel)
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .sheet(isPresented: $showingPause, onDismiss: {
            viewModel.resumeGameplay()
        }) {
            PauseView(
                onResume: {
                    showingPause = false
                    viewModel.resumeGameplay()
                },
                onExitToMenu: {
                    showingPause = false
                    viewModel.stopSession()
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showingLevelComplete) {
            LevelCompleteView(
                levelNumber: currentLevel,
                time: viewModel.elapsedTime,
                onNextLevel: {
                    showingLevelComplete = false
                    if currentLevel < 100 {
                        currentLevel += 1
                        viewModel.setupScene(for: currentLevel)
                    } else {
                        viewModel.stopSession()
                        dismiss()
                    }
                },
                onReturnToMap: {
                    showingLevelComplete = false
                    viewModel.stopSession()
                    dismiss()
                }
            )
        }
        .onChange(of: viewModel.sessionState) { _, state in
            switch state {
            case .paused:
                showingPause = true
            case .levelComplete:
                showingLevelComplete = true
            case .playing, .respawning, .idle, .loading:
                break
            }
        }
        .background(InteractivePopGestureLock())
        .navigationBarBackButtonHidden(true)
    }
}

private struct InteractivePopGestureLock: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GestureLockViewController {
        GestureLockViewController()
    }

    func updateUIViewController(_ uiViewController: GestureLockViewController, context: Context) {
        uiViewController.applyLockIfNeeded()
    }
}

private final class GestureLockViewController: UIViewController {
    private var previousInteractivePopEnabled: Bool?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyLockIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreIfNeeded()
    }

    func applyLockIfNeeded() {
        guard let navigationController else { return }
        guard let gesture = navigationController.interactivePopGestureRecognizer else { return }
        if previousInteractivePopEnabled == nil {
            previousInteractivePopEnabled = gesture.isEnabled
        }
        gesture.isEnabled = false
    }

    private func restoreIfNeeded() {
        guard
            let navigationController,
            let gesture = navigationController.interactivePopGestureRecognizer,
            let previousInteractivePopEnabled
        else {
            return
        }
        gesture.isEnabled = previousInteractivePopEnabled
        self.previousInteractivePopEnabled = nil
    }

    deinit {
        restoreIfNeeded()
    }
}

// MARK: - ViewModel

@MainActor
class GameViewModel: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var elapsedTimeString: String = "00:00"
    @Published var isAdReady: Bool = true // Placeholder
    @Published var gameScene: GameScene?
    @Published private(set) var sessionState: GameSessionState = .idle {
        didSet {
            guard sessionState != oldValue else { return }
            CrashReportingManager.shared.addBreadcrumb(
                category: "game_state",
                message: "Session state changed",
                metadata: [
                    "from": String(describing: oldValue),
                    "to": String(describing: sessionState),
                    "level": "\(currentLevelNumber)"
                ]
            )
        }
    }
    private var timer: Timer?
    private var startTime: Date?
    private var pausedAt: Date?
    private var currentLevelNumber: Int = 1
    private var sceneSetupTask: Task<Void, Never>?
    private var sceneSetupRequestID: UInt64 = 0
    
    func setupScene(for levelNumber: Int) {
        sceneSetupTask?.cancel()
        sceneSetupRequestID &+= 1
        let requestID = sceneSetupRequestID
        sessionState = .loading
        currentLevelNumber = levelNumber
        stopTimer()
        pausedAt = nil
        elapsedTime = 0
        elapsedTimeString = "00:00"
        gameScene = nil
        
        sceneSetupTask = Task { [weak self] in
            guard let self else { return }
            let generated = await Task.detached(priority: .userInitiated) {
                MazeGenerator.generateLevelDataWithDiagnostics(levelNumber: levelNumber)
            }.value
            
            guard !Task.isCancelled else { return }
            guard self.sceneSetupRequestID == requestID else { return }
            self.finishSceneSetup(levelNumber: levelNumber, generated: generated)
        }
    }
    
    func getScene() -> SKScene? {
        return gameScene
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard let start = startTime else { return }
        elapsedTime = Date().timeIntervalSince(start)
        elapsedTimeString = formatTime(elapsedTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func showRewardedAd(type: RewardedAdType) {
        AnalyticsManager.shared.track(.rewardedStarted, properties: [
            "type": type.rawValue
        ])
        // Placeholder: just complete/skip level
        switch type {
        case .skipLevel:
            AnalyticsManager.shared.track(.rewardedRewarded, properties: [
                "type": type.rawValue,
                "reward": "skip_level"
            ])
            handleLevelComplete(level: currentLevelNumber)
        case .showPath:
            // Show path for 3 seconds (placeholder)
            AnalyticsManager.shared.track(.rewardedRewarded, properties: [
                "type": type.rawValue,
                "reward": "show_path_placeholder"
            ])
            print("Show path rewarded ad")
        }
    }
    
    func pauseGameplay() {
        guard sessionState == .playing else { return }
        gameScene?.isPaused = true
        pauseTimer()
        sessionState = .paused
        AnalyticsManager.shared.track(.pause, properties: [
            "level": "\(currentLevelNumber)",
            "elapsed_sec": String(Int(elapsedTime))
        ])
    }
    
    func resumeGameplay() {
        guard sessionState == .paused else { return }
        gameScene?.isPaused = false
        resumeTimerIfNeeded()
        sessionState = .playing
        AnalyticsManager.shared.track(.resume, properties: [
            "level": "\(currentLevelNumber)",
            "elapsed_sec": String(Int(elapsedTime))
        ])
    }
    
    func pauseTimer() {
        guard pausedAt == nil else { return }
        pausedAt = Date()
        stopTimer()
    }
    
    func resumeTimerIfNeeded() {
        guard let pauseStarted = pausedAt else { return }
        if let startTime {
            self.startTime = startTime.addingTimeInterval(Date().timeIntervalSince(pauseStarted))
        }
        pausedAt = nil
        startTimer()
    }
    
    func stopSession() {
        sceneSetupTask?.cancel()
        sceneSetupTask = nil
        gameScene?.isPaused = true
        gameScene = nil
        stopTimer()
        pausedAt = nil
        sessionState = .idle
    }
    
    private func handlePlayerDied() {
        pauseTimer()
        sessionState = .respawning
        AnalyticsManager.shared.track(.playerDeath, properties: [
            "level": "\(currentLevelNumber)",
            "elapsed_sec": String(Int(elapsedTime))
        ])
    }
    
    private func handlePlayerRespawn() {
        if !((gameScene?.isPaused) ?? false) {
            resumeTimerIfNeeded()
            sessionState = .playing
        }
    }
    
    private func handleLevelComplete(level: Int) {
        currentLevelNumber = level
        pauseTimer()
        gameScene?.isPaused = true
        sessionState = .levelComplete(level: level)
        AnalyticsManager.shared.track(.levelComplete, properties: [
            "level": "\(level)",
            "time_sec": String(Int(elapsedTime))
        ])
    }
    
    deinit {
        sceneSetupTask?.cancel()
        timer?.invalidate()
        timer = nil
    }
    
    private func finishSceneSetup(
        levelNumber: Int,
        generated: (levelData: LevelData, diagnostics: MazeGenerator.GenerationDiagnostics)
    ) {
        let levelData = generated.levelData
        
        // Create scene using actual screen size
        let screenSize = UIScreen.main.bounds.size
        let scene = GameScene(size: screenSize)
        scene.scaleMode = .aspectFit
        scene.isUserInteractionEnabled = true
        scene.levelData = levelData
        scene.onPlayerDied = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handlePlayerDied()
            }
        }
        scene.onPlayerRespawn = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handlePlayerRespawn()
            }
        }
        scene.onLevelComplete = { [weak self] level in
            Task { @MainActor [weak self] in
                self?.handleLevelComplete(level: level)
            }
        }
        scene.renderLevel()
        
        self.gameScene = scene
        AnalyticsManager.shared.track(.levelStart, properties: [
            "level": "\(levelNumber)",
            "seed": "\(generated.diagnostics.seed)",
            "generation_attempts": "\(generated.diagnostics.attempts)",
            "generation_fallback": generated.diagnostics.usedFallback ? "1" : "0"
        ])
        
        startTime = Date()
        startTimer()
        HapticManager.shared.prepare()
        sessionState = .playing
    }
}
