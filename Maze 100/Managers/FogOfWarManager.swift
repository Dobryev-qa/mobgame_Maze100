import SpriteKit

/// Manages fog of war visibility for the game
class FogOfWarManager {
    
    private weak var scene: SKScene?
    private var fogNode: SKSpriteNode?
    private var visibleRadius: Int = 1 // 3x3 means radius 1 from center
    private var lastRenderKey: RenderKey?
    
    private struct RenderKey: Equatable {
        let playerCoord: GridCoordinate
        let gridSize: Int
        let cellSize: CGFloat
        let visibleRadius: Int
    }
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    /// Set the visible radius (1 = 3x3, 2 = 5x5, etc.)
    func setVisibleRadius(_ radius: Int) {
        self.visibleRadius = radius
        lastRenderKey = nil
    }
    
    /// Update fog of war based on player position
    func updateFog(for playerCoord: GridCoordinate, gridSize: Int, cellSize: CGFloat) {
        guard let scene = scene else { return }
        
        let renderKey = RenderKey(
            playerCoord: playerCoord,
            gridSize: gridSize,
            cellSize: cellSize,
            visibleRadius: visibleRadius
        )
        guard lastRenderKey != renderKey else { return }
        lastRenderKey = renderKey
        
        // Create a texture that masks the visible area
        let textureSize = CGSize(width: CGFloat(gridSize) * cellSize, height: CGFloat(gridSize) * cellSize)
        UIGraphicsBeginImageContextWithOptions(textureSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }
        
        // Fill entire area with dark overlay
        UIColor(white: 0.0, alpha: 0.85).setFill()
        context.fill(CGRect(origin: .zero, size: textureSize))
        
        // Cut out visible area (3x3 around player)
        let visibleRect = CGRect(
            x: CGFloat(playerCoord.x - visibleRadius) * cellSize,
            y: CGFloat(playerCoord.y - visibleRadius) * cellSize,
            width: CGFloat(visibleRadius * 2 + 1) * cellSize,
            height: CGFloat(visibleRadius * 2 + 1) * cellSize
        )
        context.setBlendMode(.clear)
        context.fill(visibleRect)
        
        // Create texture from image
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return
        }
        let texture = SKTexture(image: image)
        UIGraphicsEndImageContext()
        
        if let fogNode {
            fogNode.texture = texture
            fogNode.size = textureSize
            fogNode.position = CGPoint(x: textureSize.width / 2, y: textureSize.height / 2)
        } else {
            // Create sprite node once and update texture afterwards to reduce node churn.
            let fog = SKSpriteNode(texture: texture)
            fog.position = CGPoint(x: textureSize.width / 2, y: textureSize.height / 2)
            fog.zPosition = 100 // Above everything
            scene.addChild(fog)
            self.fogNode = fog
        }
    }
    
    /// Remove fog of war (when level ends or feature disabled)
    func removeFog() {
        fogNode?.removeFromParent()
        fogNode = nil
        lastRenderKey = nil
    }
}
