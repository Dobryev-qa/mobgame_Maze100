import Foundation

/// Tracks player progress across all levels
nonisolated struct LevelProgress: Codable {
    var currentLevel: Int = 1
    var unlockedLevels: Int = 1 // Highest unlocked level (1-100)
    var isSoundEnabled: Bool = true
    var completedLevels: Set<Int> = [] // Set of completed level numbers
    var levelTimes: [Int: TimeInterval] = [:] // Level number -> best time

    static let storageKey = "levelProgress"

    /// Save progress to UserDefaults
    mutating func save() {
        save(to: .standard)
    }
    
    mutating func save(to defaults: UserDefaults, key: String = Self.storageKey) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            defaults.set(data, forKey: key)
        } catch {
            print("Failed to save level progress: \(error)")
        }
    }

    /// Load progress from UserDefaults
    mutating func load() {
        load(from: .standard)
    }
    
    mutating func load(from defaults: UserDefaults, key: String = Self.storageKey) {
        guard let data = defaults.data(forKey: key) else { return }
        let decoder = JSONDecoder()
        do {
            self = try decoder.decode(LevelProgress.self, from: data)
        } catch {
            print("Failed to load level progress: \(error)")
        }
    }

    /// Unlock a level (if it's the next one or within range)
    mutating func unlockLevel(_ level: Int) {
        if level > unlockedLevels && level <= 100 {
            unlockedLevels = level
            save()
        }
    }

    /// Mark a level as completed
    mutating func completeLevel(_ level: Int, time: TimeInterval? = nil) {
        completedLevels.insert(level)
        if let time = time {
            // Save best time
            if let existing = levelTimes[level] {
                levelTimes[level] = min(existing, time)
            } else {
                levelTimes[level] = time
            }
        }
        save()
    }

    /// Check if a level is unlocked
    func isLevelUnlocked(_ level: Int) -> Bool {
        return level <= unlockedLevels
    }

    /// Check if a level is completed
    func isLevelCompleted(_ level: Int) -> Bool {
        return completedLevels.contains(level)
    }

    /// Get best time for a level
    func bestTime(for level: Int) -> TimeInterval? {
        return levelTimes[level]
    }

    /// Reset all progress (for testing)
    mutating func resetProgress() {
        currentLevel = 1
        unlockedLevels = 1
        completedLevels.removeAll()
        levelTimes.removeAll()
        save()
    }
}
