//
//  FlockingPass.swift
//  Flocking
//
//  Created by JINSEN WU on 10/13/23.
//

import MetalKit

struct FlockingPass {
    var particleCount = 100
    let clearScreenPSO = PipelineStates.createComputePSO(function: "clearScreen")
    let boidsPSO = PipelineStates.createComputePSO(function: "boids")
    var emitter: Emitter?
    
    mutating func resize(view: MTKView, size: CGSize) {
        emitter = Emitter(particleCount: particleCount, size: size)
    }
    
    func clearScreen(commandEncoder: MTLComputeCommandEncoder, texture: MTLTexture) {
        commandEncoder.setComputePipelineState(clearScreenPSO)
        commandEncoder.setTexture(texture, index: 0)
        
        let width = clearScreenPSO.threadExecutionWidth
        let height = clearScreenPSO.maxTotalThreadsPerThreadgroup / width
        var threadsPerGroup = MTLSize(width: width, height: height, depth: 1)
        var threadsPerGrid = MTLSize(width: texture.width, height: texture.height, depth: 1)
        
        #if os(iOS)
        if Renderer.device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        } else {
            let width = (Float(texture.width) / Float(width)).rounded(.up)
            let height = (Float(texture.height) / Float(width)).round(.up)
            let groupdsPerGrid = MTLSize(width: Int(width), height: Int(height), depth: 1)
            commandEncoder.dispatchThreadgroups(groupdsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        }
        #elseif os(macOS)
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        #endif
    }
    
    mutating func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
              let texture = view.currentDrawable?.texture,
              let emitter = emitter
        else { return }
        
        clearScreen(commandEncoder: commandEncoder, texture: texture)
        
        // render boids
        commandEncoder.setComputePipelineState(boidsPSO)
        let threadsPerGrid = MTLSize(width: particleCount, height: 1, depth: 1)
        let threadsPerGroup = MTLSize(width: 1, height: 1, depth: 1)
        commandEncoder.setBuffer(emitter.particleBuffer, offset: 0, index: 0)
        commandEncoder.setBytes(&particleCount, length: MemoryLayout<Int>.stride, index: 1)
        
        #if os(iOS)
        if Renderer.device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        } else {
            let threads = min(boidsPSO.threadExecutionWidth, particleCount)
            let threadsPerThreadgroup = MTLSize(width: threads, height: 1, depth: 1)
            let groups = particleCount / threads + 1
            let groupsPerGrid = MTLSize(width: groups, height: 1, depth: 1)
            commandEncoder.dispatchThreadgroups(groupdsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }
        #elseif os(macOS)
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        #endif
        
        commandEncoder.endEncoding()
    }
}
