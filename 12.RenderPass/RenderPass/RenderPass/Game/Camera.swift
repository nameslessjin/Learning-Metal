import CoreGraphics

protocol Camera: Transformable {
    var projectionMatrix: float4x4 {get}
    var viewMatrix: float4x4 {get}
    mutating func update(size:CGSize)
    mutating func update(deltaTime: Float)
}

struct FPCamera: Camera {
    var transform = Transform()
    
    var aspect: Float = 1.0
    var fov = Float(70).degreesToRadians
    var near: Float = 0.1
    var far: Float = 100
    var projectionMatrix: float4x4 {
        float4x4(
            projectionFov: fov, near: near, far: far, aspect: aspect
        )
    }
    
    mutating func update(size: CGSize) {
        aspect = Float(size.width / size.height)
    }
    
    var viewMatrix: float4x4 {
        (float4x4(translation: position) * float4x4(rotation: rotation)).inverse
    }
    
    mutating func update(deltaTime: Float) {
        let transform = updateInput(deltaTime: deltaTime)
        rotation += transform.rotation
        position += transform.position
    }
}

extension FPCamera: Movement {}


struct ArcballCamera: Camera {
    var transform = Transform()
    
    var aspect: Float = 1.0
    var fov = Float(70).degreesToRadians
    var near: Float = 0.1
    var far: Float = 100
    let minDistance: Float = 0.0
    let maxDistance: Float = 50
    var target: float3 = [0, 0, 0]
    var distance: Float = 2.5
    
    var projectionMatrix: float4x4 {
        float4x4(
            projectionFov: fov, near: near, far: far, aspect: aspect
        )
    }
    
    mutating func update(size: CGSize) {
        aspect = Float(size.width / size.height)
    }
    
    var viewMatrix: float4x4 {
        let matrix: float4x4
        
        // if the position is the same as the target, we rotate the camera to look around the scene at the target position
        // otherwise, we rotate the camera with the lookAt matrix
        if target == position {
            matrix = (float4x4(translation: target) * float4x4(rotationYXZ: rotation)).inverse
        } else {
            matrix = float4x4(eye: position, center: target, up: [0, 1, 0])
        }
        return matrix
    }
    
    mutating func update(deltaTime: Float) {
        
        let input = InputController.shared
        
        // zoom
        let scrollSensitivity = Settings.mouseScrollSensitivity
        distance -= (input.mouseScroll.x + input.mouseScroll.y) * scrollSensitivity
        distance = min(maxDistance, distance)
        distance = max(minDistance, distance)
        input.mouseScroll = .zero
        
        // drag
        if input.leftMouseDown {
            let sensitivity = Settings.mousePanSensitivity
            rotation.x += input.mouseDelta.y * sensitivity
            rotation.y += input.mouseDelta.x * sensitivity
            rotation.x = max(-.pi / 2, min(rotation.x, .pi / 2))
            input.mouseDelta = .zero
        }
        
        // rotate the distance vector and add the target position to the new vector, take drag and zoom into effect
        let rotateMatrix = float4x4(rotationYXZ: [-rotation.x, rotation.y, 0])
        let distanceVector = float4(0, 0, -distance, 0)
        let rotatedVector = rotateMatrix * distanceVector
        position = target + rotatedVector.xyz
        
    }
}

struct OrthographicCamera: Camera, Movement {
    var transform = Transform()
    var aspect: CGFloat = 1
    var viewSize: CGFloat = 10 // the unit size of the scene
    var near: Float = 0.1
    var far: Float = 100
    
    var viewMatrix: float4x4 {
        (float4x4(translation: position) * float4x4(rotation: rotation)).inverse
    }
    
    var projectionMatrix: float4x4 {
        let rect = CGRect(
            x: -viewSize * aspect * 0.5,
            y: viewSize * 0.5,
            width: viewSize * aspect,
            height: viewSize)
        return float4x4(orthographic: rect, near: near, far: far)
    }
    
    mutating func update(size: CGSize) {
        aspect = size.width / size.height
    }
    
    mutating func update(deltaTime: Float) {
        let transform = updateInput(deltaTime: deltaTime)
        position += transform.position
        let input = InputController.shared
        
        // use scroll to change the view size
        let zoom = input.mouseScroll.x + input.mouseScroll.y
        viewSize -= CGFloat(zoom)
        input.mouseScroll = .zero
    }
}

struct PlayerCamera: Camera {
    var transform = Transform()
    
    var aspect: Float = 1.0
    var fov = Float(70).degreesToRadians
    var near: Float = 0.1
    var far: Float = 100
    var projectionMatrix: float4x4 {
        float4x4(
            projectionFov: fov, near: near, far: far, aspect: aspect
        )
    }
    
    mutating func update(size: CGSize) {
        aspect = Float(size.width / size.height)
    }
    
    var viewMatrix: float4x4 {
        let rotateMatrix = float4x4(rotationYXZ: [-rotation.x, rotation.y, 0])
        return (float4x4(translation: position) * rotateMatrix).inverse
    }
    
    mutating func update(deltaTime: Float) {
        let transform = updateInput(deltaTime: deltaTime)
        rotation += transform.rotation
        position += transform.position
        
        let input = InputController.shared
        // drag
        if input.leftMouseDown {
            let sensitivity = Settings.mousePanSensitivity
            rotation.x += input.mouseDelta.y * sensitivity
            rotation.y += input.mouseDelta.x * sensitivity
            rotation.x = max(-.pi / 2, min(rotation.x, .pi / 2))
            input.mouseDelta = .zero
        }
    }
}

extension PlayerCamera: Movement {}
