//
//  FireworksEmitter.swift
//  Particles
//
//  Created by JINSEN WU on 10/11/23.
//

import MetalKit

struct FireworksEmitter {
    let particleBuffer: MTLBuffer
    
    init(particleCount: Int, size: CGSize, life: Float) {
        let bufferSize = MemoryLayout<Particle>.stride * particleCount
        particleBuffer = Renderer.device.makeBuffer(length: bufferSize)!
        
        let width = Float(size.width)
        let height = Float(size.height)
        let position = float2(Float.random(in: 0...width), Float.random(in: 0...height))
        let color = float4(Float.random(in: 0...life) / life, Float.random(in: 0...life) / life, Float.random(in: 0...life) / life, 1)
        
        var pointer = particleBuffer.contents().bindMemory(to: Particle.self, capacity: particleCount)
        for _ in 0..<particleCount {
            let direction = 2 * Float.pi * Float.random(in: 0...width) / width
            let speed = 3 * Float.random(in: 0...width) / width
            pointer.pointee.position = position
            pointer.pointee.direction = direction
            pointer.pointee.speed = speed
            pointer.pointee.color = color
            pointer.pointee.life = life
            pointer = pointer.advanced(by: 1)
        }
        
        
    }
}
