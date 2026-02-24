import SpriteKit

/// Library of particle effects for Maze 100
struct ParticleEffects {
    
    /// Create a spark effect for wall impacts
    static func createWallHit(at position: CGPoint, color: SKColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark") // Fallback to circle if missing
        emitter.particleBirthRate = 500
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.4
        emitter.particlePositionRange = CGVector(dx: 5, dy: 5)
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.5
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.position = position
        emitter.targetNode = nil // Should be added to scene
        return emitter
    }
    
    /// Create a trail effect for the player
    static func createPlayerTrail(color: SKColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 80
        emitter.particleLifetime = 0.4
        emitter.particlePositionRange = CGVector(dx: 10, dy: 10)
        emitter.particleSpeed = 0
        emitter.particleAlpha = 0.5
        emitter.particleAlphaSpeed = -1.5
        emitter.particleScale = 0.1
        emitter.particleScaleSpeed = -0.2
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        return emitter
    }
    
    /// Create a death explosion effect
    static func createDeathExplosion(at position: CGPoint, color: SKColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 2000
        emitter.numParticlesToEmit = 100
        emitter.particleLifetime = 0.8
        emitter.particlePositionRange = CGVector(dx: 10, dy: 10)
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 100
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.2
        emitter.particleScale = 0.2
        emitter.particleScaleSpeed = -0.3
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.position = position
        return emitter
    }
    
    /// Create victory confetti effect
    static func createVictoryConfetti(size: CGSize) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 500
        emitter.particleLifetime = 2.5
        emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
        emitter.particleSpeed = 200
        emitter.emissionAngle = -.pi / 2
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.4
        emitter.particleScale = 0.1
        emitter.particleScaleRange = 0.2
        emitter.particleColor = .white
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor.red, SKColor.yellow, SKColor.blue, SKColor.green, SKColor.cyan, SKColor.magenta],
            times: [0, 0.2, 0.4, 0.6, 0.8, 1.0]
        )
        return emitter
    }
}
