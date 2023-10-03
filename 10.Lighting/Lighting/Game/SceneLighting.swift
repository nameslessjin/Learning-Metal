struct SceneLighting {
    
    var lights: [Light] = []
    
    let sunlight: Light = {
        var light = Self.buildDefaultLight()
        light.position = [1, 2, -2]
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
    
    static func buildDefaultLight() -> Light {
        var light = Light()
        light.position = [0, 0, 0]
        light.color = [1, 1, 1]
        light.specularColor = [0.6, 0.6, 0.6]
        light.attenuation = [1, 0, 0]
        light.type = Sun
        return light
    }
    
    init() {
        lights.append(sunlight)
        lights.append(ambientLight)
        lights.append(redLight)
        lights.append(spotLight)
    }
}
