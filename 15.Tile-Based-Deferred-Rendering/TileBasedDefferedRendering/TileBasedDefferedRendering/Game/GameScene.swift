import MetalKit

struct GameScene {
    static var objectId: UInt32 = 1;
    
    lazy var train: Model = {
        createModel(name: "train.obj")
    }()
    lazy var treefir1: Model = {
        createModel(name: "treefir.obj")
    }()
    lazy var treefir2: Model = {
        createModel(name: "treefir.obj")
    }()
    lazy var treefir3: Model = {
        createModel(name: "treefir.obj")
    }()
    lazy var ground: Model = {
        Model(name: "large_plane.obj", objectId: 0)
    }()
    lazy var sun: Model = {
        Model(name: "sun_sphere.obj")
    }()
    
//    lazy var gizmo: Model = {
//        Model(device: Renderer.device, name: "gizmo.usd")
//    }()

    var models: [Model] = []
    
//    var camera = FPCamera()
    var camera = ArcballCamera()
//    var camera = OrthographicCamera()
//    var camera = PlayerCamera()
    
    var defaultView: Transform {
        Transform(
            position: [3.2 , 3.1, 1.0],
            rotation: [-0.6, 10.7, 0.0]
        )
    }
    
    var lighting = SceneLighting()
    
    var debugMainCamera: ArcballCamera?
    var debugShadowCamera: OrthographicCamera?
    
    var shouldDrawMainCamera = false
    var shouldDrawLightCamera = false
    var shouldDrawBoundingSphere = false
    var isPaused = false
    
    init() {
        
        models = [ground, treefir1, treefir2, treefir3, train]
        treefir1.position = [-1, 0, 2.5]
        treefir2.position = [-3, 0, -2]
        treefir3.position = [ 1.5, 0, -0.5]
        
        camera.transform = defaultView
        camera.far = 20
        // ArcballCaera
        camera.distance = 4.0
        camera.target = [0, 1, 0]
        // digital emily
//        camera.distance = 30
//        camera.rotation = .zero
//        camera.rotation.y = .pi
        
        // OrhographicsCamera
//        camera.position = [0, 2, 0]
//        camera.rotation.x = .pi / 2
    }
    
    func createModel(name: String) -> Model {
        let model = Model(name: name, objectId: Self.objectId)
        Self.objectId += 1
        return model
    }
    
    mutating func update(size: CGSize) {
        camera.update(size: size)
    }
    
    mutating func update(deltaTime: Float) {
        
        let input = InputController.shared
        if input.keysPressed.contains(.one) || input.keysPressed.contains(.two) {
            camera.distance = 4
            if let mainCamera = debugMainCamera {
                camera = mainCamera
                debugMainCamera = nil
                debugShadowCamera = nil
            }
            shouldDrawMainCamera = false
            shouldDrawLightCamera = false
            shouldDrawBoundingSphere = false
            isPaused = false
        }
        if input.keysPressed.contains(.one) {
            camera.transform = Transform()
        }
        if input.keysPressed.contains(.two) {
            camera.transform = defaultView
        }
        if input.keysPressed.contains(.three) {
            shouldDrawMainCamera.toggle()
        }
        if input.keysPressed.contains(.four) {
            shouldDrawLightCamera.toggle()
        }
        if input.keysPressed.contains(.five) {
            shouldDrawBoundingSphere.toggle()
        }
        if !isPaused {
            if shouldDrawMainCamera || shouldDrawLightCamera || shouldDrawBoundingSphere {
                isPaused = true
                debugMainCamera = camera
                debugShadowCamera = OrthographicCamera()
                debugShadowCamera?.viewSize = 16
                debugShadowCamera?.far = 16
                let sun = lighting.lights[0]
                debugShadowCamera?.position = sun.position
                camera.distance = 40
                camera.far = 50
                camera.fov = 120
            }
        }
        input.keysPressed.removeAll()
        camera.update(deltaTime: deltaTime)
        if isPaused {return}
        
        // rotate sun light around the scene
//        let rotationMatrix = float4x4(rotation: [0, deltaTime * 0.4, 0])
//        let position = lighting.lights[0].position
//        lighting.lights[0].position = (rotationMatrix * float4(position.x, position.y, position.z, 1)).xyz
//        sun.position = lighting.lights[0].position
        
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
//        gizmo.position = bottomLeft
//        gizmo.position = (forwardVector - rightVector) * 10

    }
}
