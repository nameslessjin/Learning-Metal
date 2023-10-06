struct SceneLighting {
    
    static func buildDefaultLight() -> Light {
        var light = Light()
        light.position = [0, 0, 0]
        light.color = [1, 1, 1]
        light.specularColor = [0.6, 0.6, 0.6]
        light.attenuation = [1, 0, 0]
        light.type = Sun
        return light
    }
    
    let sunlight: Light = {
        var light = Self.buildDefaultLight()
        light.position = [3, 3, -2]
        return light
    }()
    
    let fillLight: Light = {
        var light = Self.buildDefaultLight()
        light.position = [-5, 1, 3]
        light.color = float3(repeating: 0.5)
        return light
    }()
    
    let ambientLight: Light = {
        var light = Self.buildDefaultLight()
        light.color = [0.05, 0.2, 0]
        light.type = Ambient
        return light
    }()
    
    let redLight: Light = {
        var light = Self.buildDefaultLight()
        light.type = Point
        light.position = [-0.8, 0.76, -0.18]
        light.color = [1, 0, 0]
        light.attenuation = [0.5, 2, 1]
        return light
    }()
    
    lazy var spotLight: Light = {
        var light = Self.buildDefaultLight()
        light.type = Spot
        light.position = [-0.64, 0.64, -1.07]
        light.color = [1, 0, 1]
        light.attenuation = [1, 0.5, 0]
        light.coneAngle = Float(40).degreesToRadians
        light.coneDirection = [0.5, -0.7, 1]
        light.coneAttenuation = 8
        return light;
    }()
    
    
    let emilyLight1: Light = {
        var light = Self.buildDefaultLight()
        light.position = [0, 10, 20]
        return light
    }()
    let emilyLight2: Light = {
        var light = Self.buildDefaultLight()
        light.position = [0, -5, 20]
        return light
    }()

    let emilyLight3: Light = {
        var light = Self.buildDefaultLight()
        light.position = [20, 10, 0]
        return light
    }()
    
    let emilyLight4: Light = {
        var light = Self.buildDefaultLight()
        light.position = [-20, 10, 0]
        return light
    }()
    
    var lights: [Light] = []
    
    init() {
        lights.append(sunlight)
        lights.append(fillLight)
//        lights.append(ambientLight)
//        lights.append(redLight)
//        lights.append(spotLight)
//        lights.append(emilyLight1)
//        lights.append(emilyLight2)
//        lights.append(emilyLight3)
//        lights.append(emilyLight4)
    }
}
