import Foundation

nonisolated enum Direction: String, CaseIterable, Codable, Sendable {
    case up, down, left, right
    
    func opposite() -> Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

/// Represents a position in the grid
nonisolated struct GridCoordinate: Hashable, Codable, Sendable {
    let x: Int
    let y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    /// Returns neighboring coordinates (up, down, left, right)
    var neighbors: [GridCoordinate] {
        [
            GridCoordinate(x - 1, y), // left
            GridCoordinate(x + 1, y), // right
            GridCoordinate(x, y - 1), // down
            GridCoordinate(x, y + 1)  // up
        ]
    }

    /// Distance to another coordinate (Manhattan distance)
    func distance(to other: GridCoordinate) -> Int {
        return abs(x - other.x) + abs(y - other.y)
    }
    
    /// Returns the neighbor in the given direction
    func neighbor(in direction: Direction) -> GridCoordinate {
        switch direction {
        case .up: return GridCoordinate(x, y + 1)
        case .down: return GridCoordinate(x, y - 1)
        case .left: return GridCoordinate(x - 1, y)
        case .right: return GridCoordinate(x + 1, y)
        }
    }
}
