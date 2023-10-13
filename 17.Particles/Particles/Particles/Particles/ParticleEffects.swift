//
//  ParticleEffects.swift
//  Particles
//
//  Created by JINSEN WU on 10/11/23.
//

import CoreGraphics

struct ParticleDescriptor {
    var position: float2 = [0, 0]
    // close range specify a starting position also randomness within limits
    // if we have position [10, 0] and a positionXrange of 0...180 then each particle will be within 10 to 190
    var positionXRange: ClosedRange<Float> = 0...0
    var positionYRange: ClosedRange<Float> = 0...0
    var direction: Float = 0
    var directionRange: ClosedRange<Float> = 0...0
    var speed: Float = 0
    var speedRange: ClosedRange<Float> = 0...0
    var pointSize: Float = 80
    var pointSizeRange: ClosedRange<Float> = 0...0
    // if we have startScale to 1 and endScale to 0 then the particle will get smaller over its lifespan
    var startScale: Float = 0
    var startScaleRange: ClosedRange<Float> = 1...1
    var endScale: Float = 0
    var endScaleRange: ClosedRange<Float>?
    var life: Float = 0
    var lifeRange: ClosedRange<Float> = 1...1
    var color: float4 = [0, 0, 0, 1]
}

enum ParticleEffects {
    static func createFire(size: CGSize) -> Emitter {
        var descriptor = ParticleDescriptor()
        descriptor.position.x = Float(size.width) / 2 - 90
        descriptor.positionXRange = 0...180
        descriptor.direction = Float.pi / 2
        descriptor.directionRange = -0.3...0.3
        descriptor.speed = 3
        descriptor.pointSize = 80
        descriptor.startScale = 0
        descriptor.startScaleRange = 0.5...1.0
        descriptor.endScaleRange = 0...0
        descriptor.life = 180
        descriptor.lifeRange = -50...70
        descriptor.color = float4(1.0, 0.392, 0.1, 0.5)
        return Emitter(descriptor, texture: "fire", particleCount: 1200, birthRate: 5, birthDelay: 0, blending: true)
    }
    
    static func createSnow(size: CGSize) -> Emitter {
        
        // particle will appear at the top of the screen in random positions
        var descriptor = ParticleDescriptor()
        descriptor.positionXRange = 0...Float(size.width)
        descriptor.direction = -.pi / 2
        descriptor.speedRange = 4...8
        descriptor.pointSizeRange = 80 * 0.5...80
        descriptor.startScale = 0
        descriptor.startScaleRange = 0.2...1.0
        
        descriptor.life = 500 // set life span to 500 frames
        descriptor.color = [1, 1, 1, 1]
        
        return Emitter(
            descriptor,
            texture: "snowflake",
            particleCount: 800,
            
            // how fast the particles emit
            // eomit one every 20 frames until there are 100 snowflakes in total
            birthRate: 2,
            birthDelay: 20
        )
    }
    
}
