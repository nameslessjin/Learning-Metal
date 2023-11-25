//
//  Emitter.swift
//  Flocking
//
//  Created by JINSEN WU on 10/13/23.
//

import MetalKit

struct Particle {
    var position: float2
    var velocity: float2
}

struct Emitter {
    var particleBuffer: MTLBuffer
    
    init(particleCount: Int, size: CGSize) {
        let bufferSize = MemoryLayout<Particle>.stride * particleCount
        particleBuffer = Renderer.device.makeBuffer(length: bufferSize)!
        var pointer = particleBuffer.contents().bindMemory(to: Particle.self, capacity: particleCount)
        
        for _ in 0..<particleCount {
            let width = random(Int(size.width) / 2) + Float(size.width) / Float(4)
            let height = random(Int(size.height) / 2) + Float(size.height) / Float(4)
            let position = float2(width, height)
            pointer.pointee.position = position
            
            // random direction and spped that ranges between -5 and 5
            let velocity: float2 = [
                Float.random(in: -5...5),
                Float.random(in: -5...5)
            ]
            pointer.pointee.velocity = velocity
            pointer = pointer.advanced(by: 1)
        }
    }
    
    func random(_ max: Int) -> Float {
        guard max > 0 else { return 0 }
        return Float.random(in: 0..<Float(max))
    }
}
