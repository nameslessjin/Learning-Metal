import MetalKit

struct GameScene {
    lazy var sphere: Model = {
        Model(device: Renderer.device, name: "sphere.obj")
    }()
    
    lazy var gizmo: Model = {
        Model(device: Renderer.device, name: "gizmo.usd")
    }()
    var models: [Model] = []
    
//    var camera = FPCamera()
    var camera = ArcballCamera()
//    var camera = OrthographicCamera()
//    var camera = PlayerCamera()
    
    var defaultView: Transform {
        Transform(
            position: [-1.18, 1.57, -1.28],
            rotation: [-0.73, 13.3, 0.0]
        )
    }
    
    let lighting = SceneLighting()
    
    init() {
        
        models = [sphere, gizmo]
        camera.transform = defaultView
        
        // ArcballCaera
        camera.distance = length(camera.position)
//        camera.target = [0, 1.2, 0]
        
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
        
        let heightNear = 2 * tan(camera.fov / 2) * camera.near
        let widthNear = heightNear * camera.aspect
        let cameraNear = camera.position + forwardVector * camera.near
        let cameraUp = float3(0, 1, 0)
        let bottomLeft = cameraNear - (cameraUp * (heightNear / 2)) - (rightVector * (widthNear / 2))
        gizmo.position = bottomLeft
        gizmo.position = (forwardVector - rightVector) * 10
    }
}
