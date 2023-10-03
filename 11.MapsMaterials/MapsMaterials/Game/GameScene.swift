import MetalKit

struct GameScene {
    lazy var cottage: Model = {
        Model(device: Renderer.device, name: "helmet.obj")
    }()

    var models: [Model] = []
    
//    var camera = FPCamera()
    var camera = ArcballCamera()
//    var camera = OrthographicCamera()
//    var camera = PlayerCamera()
    
    var defaultView: Transform {
        Transform(
            position: [4.6 , 2.3, -3.84],
            rotation: [-0.05, 11.7, 0.0]
        )
    }
    
    let lighting = SceneLighting()
    
    init() {
        
        models = [cottage]
        camera.transform = defaultView
        
        // ArcballCaera
        camera.distance = 3.5
        camera.target = .zero
        
        // OrhographicsCamera
//        camera.position = [0, 2, 0]
//        camera.rotation.x = .pi / 2
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        
        let input = InputController.shared
        if input.keysPressed.contains(.one) {
            camera.transform = Transform()
        }
        if input.keysPressed.contains(.two) {
            camera.transform = defaultView
        }
        camera.update(deltaTime: deltaTime)
        calculateGizmo()
    }
    
    mutating func calculateGizmo() {
        var forwardVector: float3 {
            let lookat = float4x4(eye: camera.position, center: .zero, up: [0, 1, 0])
            return [lookat.columns.0.z, lookat.columns.1.z, lookat.columns.2.z]
        }
        var rightVector: float3 {
            let lookat = float4x4(eye: camera.position, center: .zero, up: [0, 1, 0])
            return [lookat.columns.0.x, lookat.columns.1.x, lookat.columns.2.x]
        }
        
//        let heightNear = 2 * tan(camera.fov / 2) * camera.near
//        let widthNear = heightNear * camera.aspect
//        let cameraNear = camera.position + forwardVector * camera.near
//        let cameraUp = float3(0, 1, 0)
//        let bottomLeft = cameraNear - (cameraUp * (heightNear / 2)) - (rightVector * (widthNear / 2))

    }
}
