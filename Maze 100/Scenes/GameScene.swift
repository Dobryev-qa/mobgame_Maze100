import SpriteKit
import GameplayKit
import SwiftUI

/// Main game scene that renders the maze and handles player movement
class GameScene: SKScene {
    
    // MARK: - Properties
    
    var levelData: LevelData!
    var playerNode: SKSpriteNode!
    var finishNode: SKSpriteNode!
    var gridNodes: [[SKShapeNode?]] = []
    var obstacleNodes: [[SKShapeNode?]] = []
    
    var cellSize: CGFloat = 50.0
    var isMoving: Bool = false
    var moveCompletion: (() -> Void)?
    var onLevelComplete: ((Int) -> Void)?
    var onPlayerDied: (() -> Void)?
    var onPlayerRespawn: (() -> Void)?
    
    private var cameraController: CameraController!
    private var playerTrail: SKEmitterNode?
    private var touchStartPosition: CGPoint?
    private var touchStartViewPosition: CGPoint?
    private var isDead: Bool = false
    private var hasKey: Bool = false
    private var toggledWalls: Set<GridCoordinate> = []
    private var activeBiome: Theme.Biome!
    private var lastRenderedLevel: Int = -1
    
    // Managers
    private let hapticManager = HapticManager.shared
    private let audioManager = AudioManager.shared
    private var fogOfWarManager: FogOfWarManager?
    private var movingSpikeNodes: [MovingSpike] = []
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        // Initialization moved to renderLevel to avoid race conditions
    }
    
    /// Call this after setting levelData to render the level
    func renderLevel() {
        // Initialize core components if not already
        if activeBiome == nil {
            activeBiome = Theme.themeForLevel(levelData.levelNumber)
            backgroundColor = SKColor(activeBiome.background)
        }
        if cameraController == nil {
            cameraController = CameraController(scene: self)
        }
        
        // Reset state for new level (only if it's actually a new level)
        if lastRenderedLevel != levelData.levelNumber {
            isDead = false
            isMoving = false
            hasKey = false
            toggledWalls.removeAll()
            lastRenderedLevel = levelData.levelNumber
        }
        
        fogOfWarManager?.removeFog()
        fogOfWarManager = nil
        scene?.camera = nil
        removeAllChildren()
        movingSpikeNodes.removeAll()
        playerTrail = nil
        cameraController.ensureCameraAttached()
        
        renderGrid()
        renderObstacles()
        renderMovingSpikes()
        renderFinish()
        renderPlayer()
        
        // Setup initial camera - center on the entire grid
        let gridSize = calculateGridSize()
        let gridCenter = CGPoint(x: gridSize.width / 2, y: gridSize.height / 2)
        cameraController.centerOn(position: gridCenter)
        cameraController.zoomToFit(contentSize: gridSize, in: self.size, padding: 0.9)
        
        // Setup fog of war for insane levels (81+)
        if levelData.levelNumber >= 81 {
            fogOfWarManager = FogOfWarManager(scene: self)
            fogOfWarManager?.setVisibleRadius(1) // 3x3
            updateFogOfWarIfNeeded()
        }
    }
    
    // MARK: - Setup
    
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Check collision with moving spikes
        guard !isMoving && !isDead else {
            // Already moving or dead, check for death during movement
            if !isDead { checkMovingSpikeCollisions() }
            return
        }
        
        checkMovingSpikeCollisions()
    }
    
    private func checkMovingSpikeCollisions() {
        guard let playerCoord = coordinateForPosition(playerNode.position) else { return }
        
        for spike in movingSpikeNodes {
            if spike.overlaps(coordinate: playerCoord, cellSize: cellSize) {
                playerDied()
                break
            }
        }
    }
    
    private func calculateGridSize() -> CGSize {
        let width = CGFloat(levelData.gridSize) * cellSize
        let height = CGFloat(levelData.gridSize) * cellSize
        return CGSize(width: width, height: height)
    }
    
    
    // MARK: - Rendering
    
    private func renderGrid() {
        let gridSize = calculateGridSize()
        let gridNode = SKShapeNode(rectOf: gridSize)
        gridNode.strokeColor = SKColor(activeBiome.accent.opacity(0.1))
        gridNode.lineWidth = 1.0
        gridNode.position = CGPoint(x: gridSize.width / 2, y: gridSize.height / 2)
        addChild(gridNode)
        
        // Render individual grid lines
        for i in 0...levelData.gridSize {
            let x = CGFloat(i) * cellSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: gridSize.height))
            line.path = path
            line.strokeColor = SKColor(white: 0.15, alpha: 0.3)
            line.lineWidth = 0.5
            line.position = .zero
            addChild(line)
            
            let y = CGFloat(i) * cellSize
            let hLine = SKShapeNode()
            let hPath = CGMutablePath()
            hPath.move(to: CGPoint(x: 0, y: y))
            hPath.addLine(to: CGPoint(x: gridSize.width, y: y))
            hLine.path = hPath
            hLine.strokeColor = SKColor(white: 0.15, alpha: 0.3)
            hLine.lineWidth = 0.5
            hLine.position = .zero
            addChild(hLine)
        }
    }
    
    private func renderObstacles() {
        obstacleNodes = Array(repeating: Array(repeating: nil, count: levelData.gridSize), count: levelData.gridSize)
        
        for y in 0..<levelData.gridSize {
            for x in 0..<levelData.gridSize {
                let coord = GridCoordinate(x, y)
                if let cell = levelData.cellType(at: coord) {
                    // Only render obstacles that shouldn't be hidden
                    var shouldRender = false
                    switch cell {
                    case .wall, .hole, .spike, .gate, .key, .portal, .pressurePlate:
                        shouldRender = true
                    case .toggleWall:
                        shouldRender = !toggledWalls.contains(coord) // Don't render if toggled "off"
                    default:
                        break
                    }
                    
                    if shouldRender {
                        let pos = positionForCoordinate(coord)
                        let node = SKShapeNode(rectOf: CGSize(width: cellSize * 1.0, height: cellSize * 1.0))
                        
                        // Theme override for walls
                        if cell == .wall || cell == .toggleWall {
                            node.fillColor = SKColor(activeBiome.wall)
                        } else {
                            node.fillColor = SKColor(hex: cell.color) ?? .gray
                        }
                        
                        node.strokeColor = .clear
                        node.position = pos
                        node.name = "cell_\(cell.rawValue)_\(x)_\(y)"
                        node.zPosition = 1
                        addChild(node)
                        obstacleNodes[y][x] = node
                    }
                }
            }
        }
    }
    
    private func renderMovingSpikes() {
        movingSpikeNodes.removeAll()
        for spikeData in levelData.movingSpikes {
            let spike = MovingSpike(data: spikeData, cellSize: cellSize, scene: self)
            addChild(spike)
            movingSpikeNodes.append(spike)
        }
    }
    
    private func renderFinish() {
        let pos = positionForCoordinate(levelData.finishPosition)
        finishNode = SKSpriteNode(color: .white, size: CGSize(width: cellSize * 0.7, height: cellSize * 0.7))
        finishNode.position = pos
        finishNode.name = "finish"
        
        // Add glow effect (placeholder)
        let glow = SKEmitterNode()
        if let particleImage = UIImage.color(.white, size: CGSize(width: 10, height: 10)) {
            glow.particleTexture = SKTexture(image: particleImage)
        }
        glow.particleColor = .white
        glow.particleColorBlendFactor = 1.0
        glow.particleBirthRate = 20
        glow.particleLifetime = 0.3
        glow.particlePositionRange = CGVector(dx: cellSize/2, dy: cellSize/2)
        glow.targetNode = self
        finishNode.addChild(glow)
        
        // Note: For a real particle effect, you'd need a texture. 
        // This is a placeholder using a simple colored sprite
        let particle = SKSpriteNode(color: .white.withAlphaComponent(0.5), size: CGSize(width: 5, height: 5))
        particle.position = .zero
        let emit = SKEmitterNode()
        if let particleImage = UIImage.color(.white, size: CGSize(width: 10, height: 10)) {
            emit.particleTexture = SKTexture(image: particleImage)
        }
        emit.particleColor = .white
        emit.particleColorBlendFactor = 1.0
        emit.particleBirthRate = 20
        emit.particleLifetime = 0.3
        emit.particlePositionRange = CGVector(dx: cellSize/2, dy: cellSize/2)
        emit.targetNode = self
        finishNode.addChild(emit)
        
        addChild(finishNode)
    }
    
    private func renderPlayer() {
        let pos = positionForCoordinate(levelData.startPosition)
        playerNode = SKSpriteNode(color: SKColor(activeBiome.accent), size: CGSize(width: cellSize * 0.7, height: cellSize * 0.7))
        playerNode.position = pos
        playerNode.name = "player"
        
        // Rounded corners for a modern feel
        playerNode.physicsBody = SKPhysicsBody(rectangleOf: playerNode.size)
        playerNode.physicsBody?.isDynamic = false
        
        // Add permanent trail
        let trail = ParticleEffects.createPlayerTrail(color: SKColor(activeBiome.accent))
        trail.targetNode = self
        playerNode.addChild(trail)
        self.playerTrail = trail
        
        addChild(playerNode)
    }
    
    private func positionForCoordinate(_ coord: GridCoordinate) -> CGPoint {
        // Convert grid coordinates to scene coordinates
        // Grid (0,0) is top-left, SpriteKit (0,0) is bottom-left
        // We'll position the grid so that (0,0) is at bottom-left of the grid's frame
        let x = CGFloat(coord.x) * cellSize + cellSize / 2
        let y = CGFloat(coord.y) * cellSize + cellSize / 2
        return CGPoint(x: x, y: y)
    }
    
    private func coordinateForPosition(_ pos: CGPoint) -> GridCoordinate? {
        let gridWidth = CGFloat(levelData.gridSize) * cellSize
        let gridHeight = CGFloat(levelData.gridSize) * cellSize
        let gridOrigin = CGPoint(x: 0, y: 0) // Grid starts at (0,0)
        
        let localX = pos.x - gridOrigin.x
        let localY = pos.y - gridOrigin.y
        
        if localX < 0 || localY < 0 || localX >= gridWidth || localY >= gridHeight {
            return nil
        }
        
        let gridX = Int(floor(localX / cellSize))
        let gridY = Int(floor(localY / cellSize))
        return GridCoordinate(gridX, gridY)
    }
    
    
    // MARK: - Movement
    
    private func calculateSlidePath(from start: GridCoordinate, in direction: Direction) -> (path: [GridCoordinate], final: GridCoordinate, distance: Int) {
        var current = start
        var path: [GridCoordinate] = []
        var distance = 0
        
        while true {
            let next = current.neighbor(in: direction)
            guard levelData.isValidCoordinate(next) else {
                break // Hit boundary
            }
            
            // Check dynamic walkability
            if !isPathWalkable(next) {
                break // Hit wall
            }
            
            // Check if next cell is deadly (hole or spike)
            if levelData.isDeadly(next) {
                // Include this cell in path (player will die upon entering)
                path.append(next)
                distance += 1
                break
            }
            path.append(next)
            distance += 1
            current = next
        }
        
        return (path, current, distance)
    }
    
    private func isPathWalkable(_ coord: GridCoordinate) -> Bool {
        guard let type = levelData.cellType(at: coord) else { return false }
        
        if type == .gate {
            return hasKey // Walkable only if key is collected
        }
        
        if type == .toggleWall {
            return toggledWalls.contains(coord) // Walkable only if toggled off
        }
        
        return type.isWalkable
    }
    
    private func startSliding(in direction: Direction) {
        guard !isMoving else { return }
        
        let startCoord = coordinateForPosition(playerNode.position) ?? levelData.startPosition
        let (path, finalCoord, _) = calculateSlidePath(from: startCoord, in: direction)
        
        guard !path.isEmpty else {
            hapticManager.impact(style: .light)
            audioManager.playSFX("wall_hit")
            cameraController.screenShake(intensity: 2)
            return
        }
        
        // --- Special Cell Interactions ---
        handleSpecialCellInteractions(in: path)
        
        isMoving = true
        
        // Juice: Squish and stretch (elongate in movement direction)
        let stretchX: CGFloat = (direction == .left || direction == .right) ? 1.2 : 0.8
        let stretchY: CGFloat = (direction == .up || direction == .down) ? 1.2 : 0.8
        playerNode.run(SKAction.scaleX(to: stretchX, y: stretchY, duration: 0.1))
        
        // Animate along path
        var actions: [SKAction] = []
        for (index, coord) in path.enumerated() {
            let targetPos = positionForCoordinate(coord)
            let moveTime = TimeInterval(0.08) // Faster, snappier movement
            let move = SKAction.move(to: targetPos, duration: moveTime)
            actions.append(move)
            
            // Track deadly collision
            if index == path.count - 1 && levelData.isDeadly(coord) {
                let die = SKAction.run { [weak self] in
                    self?.playerDied()
                }
                actions.append(die)
            }
        }
        
        let sequence = SKAction.sequence(actions)
        playerNode.run(sequence) { [weak self] in
            guard let self = self else { return }
            self.isMoving = false
            
            // Juice: Return to normal scale with a little bounce
            let bounce = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            self.playerNode.run(bounce)
            
            if !self.levelData.isDeadly(finalCoord) {
                // Juice: Impact sparks and shake
                self.hapticManager.impact(style: .medium)
                self.audioManager.playSFX("wall_hit")
                self.cameraController.screenShake(intensity: 4, duration: 0.15)
                
                let sparks = ParticleEffects.createWallHit(at: self.playerNode.position, color: SKColor(self.activeBiome.accent))
                self.addChild(sparks)
                self.scheduleTemporaryNodeCleanup(sparks, after: 1.0)
                
                self.updateFogOfWarIfNeeded()
                self.checkWinCondition(at: finalCoord)
                
                // --- Final Cell Logic (Portal/Switch) ---
                self.handleFinalCellLogic(at: finalCoord)
            }
        }
    }
    
    private func handleSpecialCellInteractions(in path: [GridCoordinate]) {
        for coord in path {
            let type = levelData.cellType(at: coord)
            
            if type == .key {
                collectKey(at: coord)
            }
        }
    }
    
    private func handleFinalCellLogic(at coord: GridCoordinate) {
        let type = levelData.cellType(at: coord)
        
        if type == .portal {
            teleportFrom(coord)
        } else if type == .pressurePlate {
            toggleLinkedWalls(for: coord)
        }
    }
    
    private func collectKey(at coord: GridCoordinate) {
        guard !hasKey else { return }
        hasKey = true
        hapticManager.notification(type: .success)
        audioManager.playSFX("key_collect")
        
        // Remove key visual
        obstacleNodes[coord.y][coord.x]?.run(SKAction.fadeOut(withDuration: 0.2))
        
        // Remove all gates
        cameraController.screenShake(intensity: 5, duration: 0.3)
        for row in obstacleNodes {
            for node in row {
                if let name = node?.name, name.contains("cell_gate") {
                    node?.run(SKAction.fadeOut(withDuration: 0.5)) {
                        node?.removeFromParent()
                    }
                }
            }
        }
    }
    
    private func teleportFrom(_ coord: GridCoordinate) {
        guard let target = levelData.portalPairs[coord] else { return }
        let targetPos = positionForCoordinate(target)
        
        hapticManager.impact(style: .heavy)
        audioManager.playSFX("portal")
        cameraController.screenShake(intensity: 10, duration: 0.2)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let move = SKAction.move(to: targetPos, duration: 0)
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        
        playerNode.run(SKAction.sequence([fadeOut, move, fadeIn])) { [weak self] in
            self?.cameraController.centerOn(position: targetPos)
            self?.updateFogOfWarIfNeeded()
        }
    }
    
    private func toggleLinkedWalls(for coord: GridCoordinate) {
        guard let targets = levelData.switchTargets[coord] else { return }
        hapticManager.impact(style: .medium)
        
        for t in targets {
            if toggledWalls.contains(t) {
                toggledWalls.remove(t)
                obstacleNodes[t.y][t.x]?.run(SKAction.fadeAlpha(to: 1.0, duration: 0.3))
            } else {
                toggledWalls.insert(t)
                obstacleNodes[t.y][t.x]?.run(SKAction.fadeAlpha(to: 0.1, duration: 0.3))
            }
        }
    }
    
    private func checkWinCondition(at coord: GridCoordinate) {
        if coord == levelData.finishPosition {
            levelComplete()
        }
    }
    
    private func playerDied() {
        guard !isDead else { return }
        isDead = true
        onPlayerDied?()
        
        hapticManager.impact(style: .heavy)
        audioManager.playSFX("death")
        cameraController.screenShake(intensity: 12, duration: 0.4)
        
        isMoving = false
        playerNode.removeAllActions()
        playerTrail?.particleBirthRate = 0 // Stop trail
        
        // Juice: Explosion effect
        let explosion = ParticleEffects.createDeathExplosion(at: playerNode.position, color: SKColor(Theme.Colors.death))
        addChild(explosion)
        scheduleTemporaryNodeCleanup(explosion, after: 1.5)
        
        // Death animation
        let fade = SKAction.fadeOut(withDuration: 0.1)
        let scale = SKAction.scale(to: 2.0, duration: 0.1) // Pop then disappear
        let group = SKAction.group([fade, scale])
        
        playerNode.run(group) { [weak self] in
            guard let self = self else {
                return
            }
            
            // Reset for respawn
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let startPos = self.positionForCoordinate(self.levelData.startPosition)
                self.playerNode.alpha = 1.0
                self.playerNode.setScale(1.0)
                self.playerNode.position = startPos
                self.playerTrail?.particleBirthRate = 80 // Restart trail
                self.isDead = false
                self.cameraController.centerOn(position: startPos)
                self.updateFogOfWarIfNeeded()
                self.onPlayerRespawn?()
            }
        }
    }
    
    private func levelComplete() {
        hapticManager.notification(type: .success)
        audioManager.playSFX("victory")
        cameraController.screenShake(intensity: 5, duration: 0.5)
        
        // Juice: Victory Confetti
        let confetti = ParticleEffects.createVictoryConfetti(size: self.size)
        confetti.position = CGPoint(x: self.size.width / 2, y: self.size.height + 50)
        cameraController.cameraNode?.addChild(confetti) // Attach to camera so it follows view
        scheduleTemporaryNodeCleanup(confetti, after: 3.5)
        
        // Victory animation
        let scale = SKAction.scale(to: 1.5, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let group = SKAction.group([scale, fade])
        playerNode.run(group) { [weak self] in
            let level = self?.levelData.levelNumber ?? 1
            self?.onLevelComplete?(level)
        }
    }
    
    // MARK: - Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStartPosition = touch.location(in: self)
        if let view {
            touchStartViewPosition = touch.location(in: view)
        } else {
            touchStartViewPosition = nil
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, 
              !isMoving,
              !isDead else {
            touchStartPosition = nil
            touchStartViewPosition = nil
            return
        }

        let usingViewCoordinates = (view != nil && touchStartViewPosition != nil)
        let startPos = touchStartViewPosition ?? touchStartPosition ?? touch.location(in: self)
        let endPos: CGPoint
        if let view {
            endPos = touch.location(in: view)
        } else {
            endPos = touch.location(in: self)
        }
        let dx = endPos.x - startPos.x
        let rawDy = endPos.y - startPos.y
        // UIKit view coordinates grow downward, SpriteKit scene coordinates grow upward.
        // Normalize so positive dy always means an "up" swipe for direction mapping below.
        let dy = usingViewCoordinates ? -rawDy : rawDy
        
        touchStartPosition = nil
        touchStartViewPosition = nil
        
        // Threshold in screen points (stable regardless of camera zoom).
        let threshold: CGFloat = 24.0
        
        if abs(dx) > abs(dy) {
            if abs(dx) > threshold {
                let direction: Direction = dx > 0 ? .right : .left
                startSliding(in: direction)
            }
        } else {
            if abs(dy) > threshold {
                let direction: Direction = dy > 0 ? .up : .down
                startSliding(in: direction)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartPosition = nil
        touchStartViewPosition = nil
    }
}

private extension GameScene {
    func scheduleTemporaryNodeCleanup(_ node: SKNode, after delay: TimeInterval) {
        node.run(.sequence([
            .wait(forDuration: delay),
            .removeFromParent()
        ]))
    }
}

// MARK: - Fog of War

extension GameScene {
    private func updateFogOfWarIfNeeded() {
        guard let fog = fogOfWarManager,
              let playerCoord = coordinateForPosition(playerNode.position) else { return }
        fog.updateFog(for: playerCoord, gridSize: levelData.gridSize, cellSize: cellSize)
    }
}
