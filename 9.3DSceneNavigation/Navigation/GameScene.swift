import MetalKit

struct GameScene {
    lazy var house: Model = {
        Model(name: "lowpoly-house.obj")
    }()
    
    lazy var ground: Model = {
        var ground = Model(name: "plane.obj")
        ground.tiling = 16
        ground.scale = 40
        return ground
    }()
    lazy var models: [Model] = [ground, house]
    
//    var camera = FPCamera()
//    var camera = ArcballCamera()
//    var camera = OrthographicCamera()
    var camera = PlayerCamera()
    
    init() {
        camera.position = [0, 1.5, -5]
        
        // ArcballCaera
//        camera.distance = length(camera.position)
//        camera.target = [0, 1.2, 0]
        
        // OrhographicsCamera
//        camera.position = [0, 2, 0]
//        camera.rotation.x = .pi / 2
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        ground.scale = 40
        camera.update(deltaTime: deltaTime)
    }
}
