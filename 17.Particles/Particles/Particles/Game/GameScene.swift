import MetalKit

struct GameScene {
    var models: [Model] = []
    var camera = ArcballCamera()
    var lighting = SceneLighting()
    var particleEffects: [Emitter] = []
    
    mutating func update(size: CGSize) {
        let snow = ParticleEffects.createSnow(size: size)
        snow.position = [0, Float(size.height) + 100]
        
        let fire = ParticleEffects.createFire(size: size)
        fire.position = [0, 0]
        particleEffects = [snow, fire]
    }
    
    mutating func update(deltaTime: Float) {
        
    }
}
