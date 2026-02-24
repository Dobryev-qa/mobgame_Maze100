import Foundation
import AVFoundation
import UIKit

/// Manages sound effects and background music for Maze 100
class AudioManager: NSObject {
    static let shared = AudioManager()
    
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    private var bgmPlayer: AVAudioPlayer?
    private var lifecycleObservers: [NSObjectProtocol] = []
    
    private var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "isMuted") }
        set { UserDefaults.standard.set(newValue, forKey: "isMuted") }
    }
    
    override private init() {
        super.init()
        setupAudioSession()
        observeAppLifecycle()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    /// Play a sound effect by name
    func playSFX(_ name: String) {
        guard !isMuted else { return }
        
        // In a real app, you would load the audio file from the bundle.
        // This implementation provides the infrastructure for it.
        if let player = sfxPlayers[name] {
            player.play()
        } else if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                sfxPlayers[name] = player
            } catch {
                print("Could not play SFX: \(name) - \(error)")
            }
        }
    }
    
    /// Start background music
    func startBGM(_ name: String) {
        guard !isMuted else { return }
        
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            do {
                bgmPlayer = try AVAudioPlayer(contentsOf: url)
                bgmPlayer?.numberOfLoops = -1 // Loop infinitely
                bgmPlayer?.volume = 0.4
                bgmPlayer?.prepareToPlay()
                bgmPlayer?.play()
            } catch {
                print("Could not play BGM: \(name) - \(error)")
            }
        }
    }
    
    /// Stop background music
    func stopBGM() {
        bgmPlayer?.stop()
    }
    
    /// Toggle mute state
    func toggleMute() {
        setMuted(!isMuted)
    }
    
    /// Set mute state explicitly (idempotent).
    func setMuted(_ muted: Bool) {
        guard isMuted != muted else { return }
        isMuted = muted
        if isMuted {
            stopBGM()
        }
    }
    
    func checkMute() -> Bool {
        return isMuted
    }
    
    private func observeAppLifecycle() {
        let center = NotificationCenter.default
        
        lifecycleObservers.append(
            center.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.setupAudioSession()
            }
        )
        
        lifecycleObservers.append(
            center.addObserver(
                forName: UIApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.stopBGM()
            }
        )
    }
}
