import SpriteKit

/// Represents a moving spike that patrols between two points
class MovingSpike: SKNode {
    
    let startPosition: GridCoordinate
    let endPosition: GridCoordinate
    let patrolDuration: CGFloat
    let pauseDuration: TimeInterval
    let cellSize: CGFloat
    
    private var spriteNode: SKSpriteNode!
    private var currentTarget: GridCoordinate
    private var isPatrolMoving: Bool = false
    private var isPatrolPaused: Bool = false
    
    var onCollision: (() -> Void)?
    
    init(data: MovingSpikeData, cellSize: CGFloat, scene: SKScene) {
        self.startPosition = data.startPosition
        self.endPosition = data.endPosition
        self.patrolDuration = data.speed
        self.pauseDuration = data.pauseDuration
        self.cellSize = cellSize
        self.currentTarget = data.endPosition
        
        super.init()
        
        // Create sprite
        spriteNode = SKSpriteNode(color: SKColor(hex: "#FF3B30") ?? .red, size: CGSize(width: cellSize * 0.7, height: cellSize * 0.7))
        addChild(spriteNode)
        
        // Position at start
        let startPos = positionForCoordinate(data.startPosition, cellSize: cellSize)
        position = startPos
        
        // Start patrol
        startPatrol(in: scene)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func positionForCoordinate(_ coord: GridCoordinate, cellSize: CGFloat) -> CGPoint {
        let x = CGFloat(coord.x) * cellSize + cellSize / 2
        let y = CGFloat(coord.y) * cellSize + cellSize / 2
        return CGPoint(x: x, y: y)
    }
    
    private func startPatrol(in scene: SKScene) {
        // Move to end, pause, move to start, pause, repeat
        let endPos = positionForCoordinate(endPosition, cellSize: cellSize)
        let startPos = positionForCoordinate(startPosition, cellSize: cellSize)
        
        let moveToEnd = SKAction.move(to: endPos, duration: patrolDuration)
        let pauseAtEnd = SKAction.wait(forDuration: pauseDuration)
        let moveToStart = SKAction.move(to: startPos, duration: patrolDuration)
        let pauseAtStart = SKAction.wait(forDuration: pauseDuration)
        
        let sequence = SKAction.sequence([moveToEnd, pauseAtEnd, moveToStart, pauseAtStart])
        let repeatForever = SKAction.repeatForever(sequence)
        
        run(repeatForever)
    }
    
    /// Check if the spike's current position overlaps with a given coordinate
    func overlaps(coordinate: GridCoordinate, cellSize: CGFloat) -> Bool {
        let spikeCoord = coordinateForPosition(position, cellSize: cellSize)
        return spikeCoord == coordinate
    }
    
    private func coordinateForPosition(_ pos: CGPoint, cellSize: CGFloat) -> GridCoordinate {
        let x = Int(pos.x / cellSize)
        let y = Int(pos.y / cellSize)
        return GridCoordinate(x, y)
    }
}
