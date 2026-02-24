import Foundation
import Testing
@testable import Maze_100

struct Maze_100Tests {
    
    private struct LevelSnapshot: Equatable {
        let levelNumber: Int
        let gridSize: Int
        let cells: [[CellType]]
        let start: GridCoordinate
        let finish: GridCoordinate
        let movingSpikes: [MovingSpikeData]
        let portalPairs: [String]
        let switchTargets: [String]
        
        init(_ data: LevelData) {
            levelNumber = data.levelNumber
            gridSize = data.gridSize
            cells = data.cells
            start = data.startPosition
            finish = data.finishPosition
            movingSpikes = data.movingSpikes.sorted {
                if $0.startPosition != $1.startPosition {
                    return ($0.startPosition.y, $0.startPosition.x) < ($1.startPosition.y, $1.startPosition.x)
                }
                return ($0.endPosition.y, $0.endPosition.x) < ($1.endPosition.y, $1.endPosition.x)
            }
            portalPairs = data.portalPairs
                .map { key, value in "\(key.x),\(key.y)->\(value.x),\(value.y)" }
                .sorted()
            switchTargets = data.switchTargets
                .map { key, values in
                    let targets = values
                        .map { "\($0.x),\($0.y)" }
                        .sorted()
                        .joined(separator: "|")
                    return "\(key.x),\(key.y):\(targets)"
                }
                .sorted()
        }
    }

    @Test func levelProgressTracksUnlocksAndBestTime() async throws {
        var progress = LevelProgress()
        
        progress.unlockLevel(2)
        progress.unlockLevel(1) // should not regress
        progress.completeLevel(1, time: 25)
        progress.completeLevel(1, time: 30) // worse time should be ignored
        progress.completeLevel(1, time: 22) // better time should replace
        
        #expect(progress.unlockedLevels == 2)
        #expect(progress.isLevelUnlocked(2))
        #expect(!progress.isLevelUnlocked(3))
        #expect(progress.isLevelCompleted(1))
        #expect(progress.bestTime(for: 1) == 22)
    }
    
    @Test func levelProgressPersistsInIsolatedUserDefaultsSuite() async throws {
        let suiteName = "Maze100Tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        
        var saved = LevelProgress()
        saved.currentLevel = 7
        saved.unlockedLevels = 9
        saved.isSoundEnabled = false
        saved.completeLevel(3, time: 18)
        saved.save(to: defaults)
        
        var loaded = LevelProgress()
        loaded.load(from: defaults)
        
        #expect(loaded.currentLevel == 7)
        #expect(loaded.unlockedLevels == 9)
        #expect(loaded.isSoundEnabled == false)
        #expect(loaded.isLevelCompleted(3))
        #expect(loaded.bestTime(for: 3) == 18)
        
        defaults.removePersistentDomain(forName: suiteName)
    }
    
    @Test func mazeGeneratorSmokeAndInvariantsForLevels1To100() async throws {
        for level in 1...100 {
            let data = MazeGenerator.generateLevelData(levelNumber: level)
            
            #expect(data.levelNumber == level)
            #expect(data.gridSize == 15)
            #expect(data.cells.count == data.gridSize)
            #expect(data.cells.allSatisfy { $0.count == data.gridSize })
            #expect(data.isValidCoordinate(data.startPosition))
            #expect(data.isValidCoordinate(data.finishPosition))
            #expect(data.cellType(at: data.startPosition) == .player)
            #expect(data.cellType(at: data.finishPosition) == .finish)
            
            for (from, to) in data.portalPairs {
                #expect(data.isValidCoordinate(from))
                #expect(data.isValidCoordinate(to))
                #expect(data.portalPairs[to] == from)
                #expect(data.cellType(at: from) == .portal)
                #expect(data.cellType(at: to) == .portal)
            }
            
            for spike in data.movingSpikes {
                #expect(data.isValidCoordinate(spike.startPosition))
                #expect(data.isValidCoordinate(spike.endPosition))
                #expect(spike.speed > 0)
                #expect(spike.pauseDuration >= 0)
            }
        }
    }
    
    @Test func mazeGeneratorIsDeterministicForSameLevelSeed() async throws {
        let level = 73
        let first = MazeGenerator.generateLevelData(levelNumber: level)
        let second = MazeGenerator.generateLevelData(levelNumber: level)

        #expect(LevelSnapshot(first) == LevelSnapshot(second))
    }
    
    @Test func mazeGeneratorPortalEndpointsNeverOverlapStartOrFinish() async throws {
        for level in 61...100 {
            let data = MazeGenerator.generateLevelData(levelNumber: level)
            for coord in data.portalPairs.keys {
                #expect(coord != data.startPosition)
                #expect(coord != data.finishPosition)
            }
        }
    }
    
    @Test func mazeGeneratorBatchDiagnosticsRemainWithinBudgetForLevels1To100() async throws {
        var fallbackCount = 0
        var totalAttempts = 0
        var maxAttempts = 0
        
        for level in 1...100 {
            let result = MazeGenerator.generateLevelDataWithDiagnostics(levelNumber: level)
            let diagnostics = result.diagnostics
            
            totalAttempts += diagnostics.attempts
            maxAttempts = max(maxAttempts, diagnostics.attempts)
            if diagnostics.usedFallback {
                fallbackCount += 1
            }
            
            #expect(diagnostics.levelNumber == level)
            #expect(diagnostics.attempts >= 1)
            #expect(diagnostics.attempts <= 300)
        }
        
        let averageAttempts = Double(totalAttempts) / 100.0
        print("[MazeGeneratorTests] levels=100 avgAttempts=\(averageAttempts) maxAttempts=\(maxAttempts) fallbackCount=\(fallbackCount)")
        
        #expect(fallbackCount == 0)
        #expect(averageAttempts < 80.0)
    }
}
