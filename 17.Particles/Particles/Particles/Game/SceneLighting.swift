import MetalKit

struct SceneLighting {
    
    static func buildDefaultLight() -> Light {
        var light = Light()
        light.position = [0, 0, 0]
        light.color = float3(repeating: 1.0)
        light.specularColor = float3(repeating: 0.6)
        light.attenuation = [1, 0, 0]
        light.type = Sun
        return light
    }
    
    let sunlight: Light = {
        var light = Self.buildDefaultLight()
        light.position = [3, 3, -2]
        light.color = float3(repeating: 0.8)
        return light
    }()
    
    let backLight: Light = {
        var light = Self.buildDefaultLight()
        light.position = [0, 3, 2]
        light.color = float3(repeating: 1.0)
        return light
    }()
    
    let leftFillLight: Light = {
        var light = Self.buildDefaultLight()
        light.position = [3, -2, 0]
        light.color = float3(repeating: 0.3)
        return light
    }();
    
    let rightFillLight: Light = {
        var light = Self.buildDefaultLight()
        light.position = [-2, -1, 1]
        light.color = float3(repeating: 0.1)
        return light
    }()
    
    var lights: [Light] = []
    var lightsBuffer: MTLBuffer
    
    init() {
        lights = [sunlight, backLight, leftFillLight, rightFillLight]
        lightsBuffer = Self.createBuffer(lights: lights)
    }
    
    static func createBuffer(lights: [Light]) -> MTLBuffer {
        var lights = lights
        return Renderer.device.makeBuffer(bytes: &lights, length: MemoryLayout<Light>.stride * lights.count, options: [])!
    }
    
}
