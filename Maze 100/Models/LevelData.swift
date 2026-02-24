import Foundation

/// Represents a moving spike's patrol pattern
nonisolated struct MovingSpikeData: Codable, Hashable, Sendable {
    let startPosition: GridCoordinate
    let endPosition: GridCoordinate
    let speed: TimeInterval // Time to move from start to end
    let pauseDuration: TimeInterval // Pause at each endpoint

    init(startPosition: GridCoordinate, endPosition: GridCoordinate, speed: TimeInterval = 1.0, pauseDuration: TimeInterval = 0.5) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.speed = speed
        self.pauseDuration = pauseDuration
    }
}

/// Complete level configuration
nonisolated struct LevelData: Codable, Sendable {
    let levelNumber: Int
    let gridSize: Int // Grid is gridSize x gridSize
    let cells: [[CellType]] // 2D array [row][col], row 0 is top
    let startPosition: GridCoordinate
    let finishPosition: GridCoordinate
    let movingSpikes: [MovingSpikeData]
    let portalPairs: [GridCoordinate: GridCoordinate]
    let switchTargets: [GridCoordinate: [GridCoordinate]]

    init(
        levelNumber: Int,
        gridSize: Int,
        cells: [[CellType]],
        startPosition: GridCoordinate,
        finishPosition: GridCoordinate,
        movingSpikes: [MovingSpikeData] = [],
        portalPairs: [GridCoordinate: GridCoordinate] = [:],
        switchTargets: [GridCoordinate: [GridCoordinate]] = [:]
    ) {
        self.levelNumber = levelNumber
        self.gridSize = gridSize
        self.cells = cells
        self.startPosition = startPosition
        self.finishPosition = finishPosition
        self.movingSpikes = movingSpikes
        self.portalPairs = portalPairs
        self.switchTargets = switchTargets
    }
    func cellType(at coordinate: GridCoordinate) -> CellType? {
        guard isValidCoordinate(coordinate) else { return nil }
        return cells[coordinate.y][coordinate.x]
    }

    /// Check if coordinate is within grid bounds
    func isValidCoordinate(_ coordinate: GridCoordinate) -> Bool {
        return coordinate.x >= 0 && coordinate.x < gridSize &&
               coordinate.y >= 0 && coordinate.y < gridSize
    }

    /// Check if coordinate is walkable (not wall, hole, spike, moving spike)
    func isWalkable(_ coordinate: GridCoordinate) -> Bool {
        guard let cell = cellType(at: coordinate) else { return false }
        return cell.isWalkable
    }

    /// Check if coordinate is deadly
    func isDeadly(_ coordinate: GridCoordinate) -> Bool {
        guard let cell = cellType(at: coordinate) else { return false }
        return cell.isDeadly
    }
}
