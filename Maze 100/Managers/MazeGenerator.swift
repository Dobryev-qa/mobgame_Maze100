import Foundation

/// Professional-grade Maze Generator for Maze 100
/// Implements a multi-stage structural algorithm on a fixed grid
nonisolated class MazeGenerator {
    struct GenerationDiagnostics: Sendable {
        let levelNumber: Int
        let seed: UInt64
        let attempts: Int
        let usedFallback: Bool
    }
    
    private static let fixedSize = 15
    private static let maxGenerationAttempts = 300
    
    nonisolated static func generateLevelData(levelNumber: Int) -> LevelData {
        generateLevelDataWithDiagnostics(levelNumber: levelNumber).levelData
    }
    
    nonisolated static func generateLevelDataWithDiagnostics(levelNumber: Int) -> (levelData: LevelData, diagnostics: GenerationDiagnostics) {
        let generator = AdvancedLevelGenerator(
            levelIndex: levelNumber,
            maxAttempts: maxGenerationAttempts
        )
        return generator.generateWithDiagnostics()
    }
}

// MARK: - Advanced Engine

nonisolated private final class AdvancedLevelGenerator {
    private let size = 15
    private let levelIndex: Int
    private let initialSeed: UInt64
    private let maxAttempts: Int
    private var rng: SeededRandomNumberGenerator
    
    init(levelIndex: Int, maxAttempts: Int) {
        self.levelIndex = levelIndex
        self.maxAttempts = maxAttempts
        // Mix level number into seed for diversity
        let seed = UInt64(levelIndex) ^ 0x5EC6E1DE
        self.initialSeed = seed
        self.rng = SeededRandomNumberGenerator(seed: seed)
    }
    
    func generate() -> LevelData {
        generateWithDiagnostics().levelData
    }
    
    func generateWithDiagnostics() -> (levelData: LevelData, diagnostics: MazeGenerator.GenerationDiagnostics) {
        let profile = DifficultyProfile(level: levelIndex)
        
        for attempt in 1...maxAttempts {
            var grid = Array(repeating: Array(repeating: CellType.wall, count: size), count: size)
            
            // Phase 1: Structural Planning (Macro-zones)
            var planner = StructuralPlanner(size: size, rng: rng)
            planner.generateMacroZones(on: &grid)
            self.rng = planner.rng // Update state
            
            // Phase 2: Primary Path Construction
            var constructor = PathConstructor(size: size, difficulty: profile, rng: rng)
            guard let pathData = constructor.buildPrimaryPath(on: &grid) else {
                continue // Retry
            }
            self.rng = constructor.rng
            
            // Phase 3: Add Branches & False Solutions
            ConstraintEngine.addBranches(to: &grid, difficulty: profile, rng: &rng)
            
            // Phase 4: Add Hazards (Holes/Spikes)
            ConstraintEngine.addHazards(to: &grid, protectedPath: Set(pathData.path), difficulty: profile, rng: &rng)
            
            // Phase 5: Place Advanced Elements (Keys, Portals, Moving Spikes)
            let advancedData = placeAdvancedElements(
                grid: &grid,
                path: pathData.path,
                start: pathData.start,
                finish: pathData.finish,
                profile: profile
            )
            
            // Phase 6: Validation (A* Solver)
            let solver = Solver(grid: grid, start: pathData.start, finish: pathData.finish, portals: advancedData.portals)
            guard let turnCount = solver.solveComplexity(), turnCount >= profile.minMoves else {
                continue // Path blocked or too short (too simple)
            }
            
            // Final check: start and finish are correct
            grid[pathData.start.y][pathData.start.x] = .player
            grid[pathData.finish.y][pathData.finish.x] = .finish
            
            let levelData = LevelData(
                levelNumber: levelIndex,
                gridSize: size,
                cells: grid,
                startPosition: pathData.start,
                finishPosition: pathData.finish,
                movingSpikes: advancedData.movingSpikes,
                portalPairs: advancedData.portals,
                switchTargets: advancedData.switchTargets
            )
            .also { _ in
                if attempt > 1 {
                    print("[MazeGenerator] Generated after retries. level=\(levelIndex) seed=\(initialSeed) attempts=\(attempt)")
                }
            }
            return (
                levelData,
                MazeGenerator.GenerationDiagnostics(
                    levelNumber: levelIndex,
                    seed: initialSeed,
                    attempts: attempt,
                    usedFallback: false
                )
            )
        }

        print("[MazeGenerator] Fallback level used. level=\(levelIndex) seed=\(initialSeed) maxAttempts=\(maxAttempts)")
        let fallback = makeFallbackLevel(profile: profile)
        return (
            fallback,
            MazeGenerator.GenerationDiagnostics(
                levelNumber: levelIndex,
                seed: initialSeed,
                attempts: maxAttempts,
                usedFallback: true
            )
        )
    }
    
    private struct AdvancedElements {
        var movingSpikes: [MovingSpikeData] = []
        var portals: [GridCoordinate: GridCoordinate] = [:]
        var switchTargets: [GridCoordinate: [GridCoordinate]] = [:]
    }
    
    private func placeAdvancedElements(
        grid: inout [[CellType]],
        path: [GridCoordinate],
        start: GridCoordinate,
        finish: GridCoordinate,
        profile: DifficultyProfile
    ) -> AdvancedElements {
        var data = AdvancedElements()
        let pathSet = Set(path)
        let reserved = pathSet.union([start, finish])
        
        // 1. Keys & Gates (Level 31+)
        if levelIndex >= 31 {
            // Place one key off-path
            var candidates: [GridCoordinate] = []
            for y in 1..<size-1 {
                for x in 1..<size-1 {
                    let c = GridCoordinate(x, y)
                    if grid[y][x] == .empty && !pathSet.contains(c) {
                        candidates.append(c)
                    }
                }
            }
            if let keyPos = candidates.randomElement(using: &rng) {
                grid[keyPos.y][keyPos.x] = .key
                // Place a gate ON the primary path to force collection
                if path.count > 5 {
                    let gatePos = path[path.count / 2]
                    grid[gatePos.y][gatePos.x] = .gate
                }
            }
        }
        
        // 2. Portals (Level 61+)
        if levelIndex >= 61 {
            var candidates: [GridCoordinate] = []
            for y in 1..<size-1 {
                for x in 1..<size-1 {
                    let coord = GridCoordinate(x, y)
                    if grid[y][x] == .empty && !reserved.contains(coord) {
                        candidates.append(coord)
                    }
                }
            }
            candidates.shuffle(using: &rng)
            if candidates.count >= 2 {
                let p1 = candidates.removeFirst()
                let p2 = candidates.removeFirst()
                grid[p1.y][p1.x] = .portal
                grid[p2.y][p2.x] = .portal
                data.portals[p1] = p2
                data.portals[p2] = p1
            }
        }
        
        // 3. Moving Spikes (Level 51+)
        if levelIndex >= 51 {
            // Simple logic for now: pick random empty spots
            for _ in 0..<levelIndex/20 {
                let y = Int.random(in: 1..<size-1, using: &rng)
                let x = Int.random(in: 1..<size-1, using: &rng)
                if grid[y][x] == .empty && !pathSet.contains(GridCoordinate(x, y)) {
                    let endX = min(size-2, x + 3)
                    data.movingSpikes.append(MovingSpikeData(
                        startPosition: GridCoordinate(x, y),
                        endPosition: GridCoordinate(endX, y),
                        speed: 1.5,
                        pauseDuration: 0.5
                    ))
                }
            }
        }
        
        return data
    }

    private func makeFallbackLevel(profile: DifficultyProfile) -> LevelData {
        var grid = Array(repeating: Array(repeating: CellType.wall, count: size), count: size)
        let start = GridCoordinate(1, 1)
        let finish = GridCoordinate(size - 2, size - 2)

        // Carve an L-shaped deterministic path to guarantee solvability.
        for x in 1..<(size - 1) {
            grid[1][x] = .empty
        }
        for y in 1..<(size - 1) {
            grid[y][size - 2] = .empty
        }

        // Add a few deterministic branches for non-triviality.
        let branchColumns = [3, 6, 9, 11].filter { $0 < size - 2 }
        for x in branchColumns {
            for y in 2..<(min(size - 3, 6)) {
                grid[y][x] = .empty
            }
        }

        // Light hazards away from guaranteed path.
        if levelIndex >= 10 {
            for y in stride(from: 3, to: size - 2, by: 3) {
                for x in stride(from: 2, to: size - 3, by: 4) where grid[y][x] == .empty && !(y == 1 || x == size - 2) {
                    grid[y][x] = .hole
                }
            }
        }

        // Optional key/gate in fallback for higher levels, placed so it remains solvable.
        var portals: [GridCoordinate: GridCoordinate] = [:]
        if levelIndex >= 31 {
            let key = GridCoordinate(3, 3)
            let gate = GridCoordinate(size - 3, 1)
            if grid[key.y][key.x] == .empty { grid[key.y][key.x] = .key }
            if grid[gate.y][gate.x] == .empty { grid[gate.y][gate.x] = .gate }
        }
        if levelIndex >= 61 {
            let p1 = GridCoordinate(2, size - 3)
            let p2 = GridCoordinate(size - 4, 3)
            if grid[p1.y][p1.x] == .empty && grid[p2.y][p2.x] == .empty {
                grid[p1.y][p1.x] = .portal
                grid[p2.y][p2.x] = .portal
                portals[p1] = p2
                portals[p2] = p1
            }
        }

        grid[start.y][start.x] = .player
        grid[finish.y][finish.x] = .finish

        let solver = Solver(grid: grid, start: start, finish: finish, portals: portals)
        if solver.solveComplexity() == nil {
            print("[MazeGenerator] Fallback validation failed unexpectedly. level=\(levelIndex) seed=\(initialSeed)")
        }

        return LevelData(
            levelNumber: levelIndex,
            gridSize: size,
            cells: grid,
            startPosition: start,
            finishPosition: finish,
            movingSpikes: [],
            portalPairs: portals,
            switchTargets: [:]
        )
    }
}

nonisolated private extension LevelData {
    func also(_ block: (LevelData) -> Void) -> LevelData {
        block(self)
        return self
    }
}

// MARK: - Components

nonisolated private struct StructuralPlanner {
    let size: Int
    var rng: SeededRandomNumberGenerator
    
    mutating func generateMacroZones(on grid: inout [[CellType]]) {
        let zoneSize = 3
        for zoneY in stride(from: 0, to: size, by: zoneSize) {
            for zoneX in stride(from: 0, to: size, by: zoneSize) {
                // Determine if this zone is a corridor, an island, or dense
                let type = Double.random(in: 0...1, using: &rng)
                // Lower openness to ensure more walls (stoppers) are preserved
                let openProb = type < 0.3 ? 0.6 : (type < 0.7 ? 0.3 : 0.1)
                
                // Instead of per-cell random, try to carve small chambers
                if type < 0.2 {
                    // Carve a small 2x2 room in this zone
                    let ox = zoneX + Int.random(in: 0...max(0, zoneSize-2), using: &rng)
                    let oy = zoneY + Int.random(in: 0...max(0, zoneSize-2), using: &rng)
                    for ry in oy..<min(oy+2, size-1) {
                        for rx in ox..<min(ox+2, size-1) {
                            if rx > 0 && ry > 0 { grid[ry][rx] = .empty }
                        }
                    }
                } else {
                    // Cell-based logic with lower density
                    for y in zoneY..<min(zoneY + zoneSize, size) {
                        for x in zoneX..<min(zoneX + zoneSize, size) {
                            if x == 0 || x == size-1 || y == 0 || y == size-1 { continue }
                            if Double.random(in: 0...1, using: &rng) < openProb {
                                grid[y][x] = .empty
                            }
                        }
                    }
                }
            }
        }
    }
}

nonisolated private struct PathData {
    let start: GridCoordinate
    let finish: GridCoordinate
    let path: [GridCoordinate]
}

nonisolated private struct PathConstructor {
    let size: Int
    let difficulty: DifficultyProfile
    var rng: SeededRandomNumberGenerator
    
    mutating func buildPrimaryPath(on grid: inout [[CellType]]) -> PathData? {
        // Start and Finish positions (fixed corners for stability)
        let start = GridCoordinate(1, 1)
        let finish = GridCoordinate(size-2, size-2)
        
        var current = start
        var path: [GridCoordinate] = [current]
        grid[start.y][start.x] = .empty
        
        // Strategy: Force a turn by placing a stopper wall
        var attempts = 0
        var lastDir: Direction? = nil
        
        while current != finish && attempts < 150 {
            attempts += 1
            
            // Prefer a direction that leads towards finish but isn't the current one
            var potentialDirs = Direction.allCases.filter { $0 != lastDir }
            potentialDirs.shuffle(using: &rng)
            
            var foundTurn = false
            for dir in potentialDirs {
                let dist = Int.random(in: 2...4, using: &rng)
                let (moved, finalPos, carvedPoints) = tryProject(from: current, in: dir, dist: dist, target: finish, on: &grid)
                
                if moved {
                    current = finalPos
                    path.append(contentsOf: carvedPoints)
                    lastDir = dir
                    foundTurn = true
                    break
                }
            }
            
            if !foundTurn {
                // Desperation move: allow any direction including previous
                let dir = Direction.allCases.randomElement(using: &rng)!
                let (moved, finalPos, carvedPoints) = tryProject(from: current, in: dir, dist: 2, target: finish, on: &grid)
                if moved {
                    current = finalPos
                    path.append(contentsOf: carvedPoints)
                    lastDir = dir
                }
            }
        }
        
        grid[finish.y][finish.x] = .empty
        return (current.distance(to: finish) <= 2) ? PathData(start: start, finish: finish, path: path) : nil
    }
    
    private mutating func tryProject(from pos: GridCoordinate, in dir: Direction, dist: Int, target: GridCoordinate, on grid: inout [[CellType]]) -> (Bool, GridCoordinate, [GridCoordinate]) {
        var points: [GridCoordinate] = []
        
        for i in 1...dist {
            var temp = pos
            for _ in 0..<i { temp = temp.neighbor(in: dir) }
            
            if temp.x <= 0 || temp.x >= size-1 || temp.y <= 0 || temp.y >= size-1 { return (false, pos, []) }
            points.append(temp)
        }
        
        // Stopper logic: Place a wall at dist + 1 if possible
        let stopper = points.last!.neighbor(in: dir)
        if stopper.x > 0 && stopper.x < size-1 && stopper.y > 0 && stopper.y < size-1 {
            if grid[stopper.y][stopper.x] == .empty && stopper != target {
                // Don't block existing paths if they are critical, but for generator it's okay
                grid[stopper.y][stopper.x] = .wall
            }
        }
        
        for p in points {
            grid[p.y][p.x] = .empty
        }
        
        return (true, points.last!, points)
    }
}

nonisolated private struct ConstraintEngine {
    static func addBranches(to grid: inout [[CellType]], difficulty: DifficultyProfile, rng: inout SeededRandomNumberGenerator) {
        let size = grid.count
        let branchCount = 3 + difficulty.level / 10
        
        for _ in 0..<branchCount {
            let ry = Int.random(in: 1..<size-1, using: &rng)
            let rx = Int.random(in: 1..<size-1, using: &rng)
            if grid[ry][rx] == .empty {
                // Carve a false corridor
                let dir = Direction.allCases.randomElement(using: &rng)!
                var cur = GridCoordinate(rx, ry)
                for _ in 0..<3 {
                    let next = cur.neighbor(in: dir)
                    if next.x <= 0 || next.x >= size-1 || next.y <= 0 || next.y >= size-1 { break }
                    grid[next.y][next.x] = .empty
                    cur = next
                }
            }
        }
    }
    
    static func addHazards(to grid: inout [[CellType]], protectedPath: Set<GridCoordinate>, difficulty: DifficultyProfile, rng: inout SeededRandomNumberGenerator) {
        let size = grid.count
        let density = difficulty.hazardDensity
        
        for y in 1..<size-1 {
            for x in 1..<size-1 {
                let c = GridCoordinate(x, y)
                if grid[y][x] == .empty && !protectedPath.contains(c) {
                    if Double.random(in: 0...1, using: &rng) < density {
                        grid[y][x] = .hole
                    }
                }
            }
        }
    }
}

nonisolated private final class Solver {
    private let grid: [[CellType]]
    private let start: GridCoordinate
    private let finish: GridCoordinate
    private let portals: [GridCoordinate: GridCoordinate]
    private let size: Int
    
    init(grid: [[CellType]], start: GridCoordinate, finish: GridCoordinate, portals: [GridCoordinate: GridCoordinate]) {
        self.grid = grid
        self.start = start
        self.finish = finish
        self.portals = portals
        self.size = grid.count
    }
    
    /// Returns the minimal number of MOVES (turns) to solve the maze
    func solveComplexity() -> Int? {
        struct State: Hashable {
            let position: GridCoordinate
            let hasKey: Bool
        }
        
        let startState = State(position: start, hasKey: false)
        var queue: [(State, Int)] = [(startState, 0)]
        var visited = [State: Int]()
        visited[startState] = 0
        
        while !queue.isEmpty {
            let (current, moves) = queue.removeFirst()
            if current.position == finish { return moves }
            
            var actualPosition = current.position
            if grid[current.position.y][current.position.x] == .portal, let dest = portals[current.position] {
                actualPosition = dest
            }
            
            for dir in Direction.allCases {
                let slideResult = slide(from: actualPosition, dir: dir, hasKey: current.hasKey)
                let nextState = State(position: slideResult.position, hasKey: slideResult.hasKey)
                if visited[nextState] == nil || visited[nextState]! > moves + 1 {
                    visited[nextState] = moves + 1
                    queue.append((nextState, moves + 1))
                }
            }
        }
        return nil
    }
    
    func solve() -> [GridCoordinate]? {
        // Keeps compatibility with existing validation if needed, but we prefer complexity score now
        return solveComplexity() != nil ? [] : nil
    }
    
    private func slide(from pos: GridCoordinate, dir: Direction, hasKey initialHasKey: Bool) -> (position: GridCoordinate, hasKey: Bool) {
        var current = pos
        var collectedKeyDuringMove = false
        while true {
            let next = current.neighbor(in: dir)
            
            if next.x < 0 || next.x >= size || next.y < 0 || next.y >= size { break }
            let tile = grid[next.y][next.x]
            if tile == .wall { break }
            if tile == .gate && !initialHasKey { break }
            if tile.isDeadly { return (next, initialHasKey || collectedKeyDuringMove) }
            
            current = next
            if tile == .key {
                // Matches runtime behavior: key affects subsequent moves, not the current path calculation.
                collectedKeyDuringMove = true
            }
            if tile == .finish || tile == .portal { break }
        }
        return (current, initialHasKey || collectedKeyDuringMove)
    }
}

nonisolated private struct DifficultyProfile {
    let level: Int
    // minMoves represents mandatory number of turns
    var minMoves: Int { 4 + level / 15 }
    var hazardDensity: Double { min(0.04 + Double(level) * 0.003, 0.2) }
}

// MARK: - Utilities

nonisolated struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) {
        self.state = seed == 0 ? 0xDEADC0DE : seed
    }
    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }
}
