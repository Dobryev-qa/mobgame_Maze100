import Foundation

/// Types of cells in the maze grid
nonisolated enum CellType: String, Codable, CaseIterable, Sendable {
    case empty      // Walkable empty cell
    case wall       // Solid wall
    case player     // Player starting position
    case finish     // Goal/finish cell
    case hole       // Deadly hole - instant death
    case spike      // Deadly spike - instant death
    case movingSpike // Moving spike (special handling)
    case key        // Pickable key
    case gate       // Locked wall (removed by key)
    case portal     // Teleportation portal
    case pressurePlate // Toggle switch
    case toggleWall  // Wall that can be toggled off

    var isWalkable: Bool {
        switch self {
        case .empty, .player, .finish, .key, .portal, .pressurePlate:
            return true
        case .wall, .hole, .spike, .movingSpike, .gate, .toggleWall:
            return false
        }
    }

    var isDeadly: Bool {
        switch self {
        case .hole, .spike, .movingSpike:
            return true
        default:
            return false
        }
    }

    var color: String {
        switch self {
        case .empty: return "#2C2C2E"
        case .wall: return "#1C1C1E"
        case .player: return "#007AFF"
        case .finish: return "#FFFFFF"
        case .hole: return "#000000"
        case .spike, .movingSpike: return "#FF3B30"
        case .key: return "#FFD700" // Gold
        case .gate: return "#4A4A4A" // Dark gate
        case .portal: return "#BC00FF" // Purple
        case .pressurePlate: return "#39FF14" // Neon Green
        case .toggleWall: return "#5856D6" // Indigo
        }
    }
}
