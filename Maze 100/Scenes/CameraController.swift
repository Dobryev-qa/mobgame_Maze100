import SpriteKit

/// Manages camera behavior for the game scene
class CameraController {
    weak var cameraNode: SKCameraNode?
    weak var scene: SKScene?
    private var targetPosition: CGPoint = .zero
    private var isFollowing: Bool = false
    
    init(scene: SKScene) {
        self.scene = scene
        setupCamera()
    }
    
    /// Re-create and attach camera if it was removed during scene rebuild.
    func ensureCameraAttached() {
        if cameraNode?.parent == nil || scene?.camera == nil {
            setupCamera()
        }
    }
    
    private func setupCamera() {
        guard let scene = scene else { return }
        if let existing = cameraNode, existing.parent != nil {
            scene.camera = existing
            return
        }
        let camera = SKCameraNode()
        scene.addChild(camera)
        scene.camera = camera
        self.cameraNode = camera
    }
    
    /// Center camera on a specific position
    func centerOn(position: CGPoint, zoomScale: CGFloat = 1.0) {
        targetPosition = position
        cameraNode?.position = position
        cameraNode?.setScale(zoomScale)
    }
    
    /// Enable smooth following of a target node
    func startFollowing(target: SKNode, zoomScale: CGFloat? = nil) {
        isFollowing = true
        // Could add constraints here for smooth following
    }
    
    /// Stop following the target
    func stopFollowing() {
        isFollowing = false
    }
    
    /// Update camera position (call in scene's update loop)
    func update(deltaTime: TimeInterval) {
        guard let _ = cameraNode else { return }
        // Future: Add smooth interpolation for following targets
    }
    
    /// Trigger a screen shake effect
    func screenShake(intensity: CGFloat = 5, duration: TimeInterval = 0.2) {
        guard let cameraNode = cameraNode else { return }
        
        let originalPosition = cameraNode.position
        var actions: [SKAction] = []
        
        let numberOfShakes = Int(duration / 0.05)
        for _ in 0..<numberOfShakes {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            let move = SKAction.move(to: CGPoint(x: originalPosition.x + dx, y: originalPosition.y + dy), duration: 0.05)
            actions.append(move)
        }
        
        actions.append(SKAction.move(to: originalPosition, duration: 0.05))
        cameraNode.run(SKAction.sequence(actions))
    }
    
    /// Smoothly adjust the zoom scale
    func smoothSetScale(_ scale: CGFloat, duration: TimeInterval = 0.3) {
        cameraNode?.run(SKAction.scale(to: scale, duration: duration))
    }
    
    /// Adjust zoom to fit a specific content size within the scene bounds
    func zoomToFit(contentSize: CGSize, in sceneSize: CGSize, padding: CGFloat = 0.9) {
        let scaleX = sceneSize.width / contentSize.width
        let scaleY = sceneSize.height / contentSize.height
        let scale = min(scaleX, scaleY) * padding
        smoothSetScale(1.0 / scale)
    }
}
