//
//  ParticlesRenderPass.swift
//  Particles
//
//  Created by JINSEN WU on 10/11/23.
//

import MetalKit

struct ParticlesRenderPass: RenderPass {
    var label: String = "Particle Effects"
    var descriptor: MTLRenderPassDescriptor?
    var size: CGSize = .zero
    let computePSO: MTLComputePipelineState
    let renderPSO: MTLRenderPipelineState
    let blendingPSO: MTLRenderPipelineState
    
    init(view: MTKView) {
        computePSO = PipelineStates.createComputePSO(function: "computeParticles")
        renderPSO = PipelineStates.createParticleRenderPSO(pixelFormat: view.colorPixelFormat)
        blendingPSO = PipelineStates.createParticleRenderPSO(pixelFormat: view.colorPixelFormat, enableBlending: true)
    }
    
    mutating func resize(view: MTKView, size: CGSize) {
        self.size = size
    }
    
    func update(commandBuffer: MTLCommandBuffer, scene: GameScene) {
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        computeEncoder.label = label
        computeEncoder.setComputePipelineState(computePSO)
        
        let threadsPerGroup = MTLSize(width: computePSO.threadExecutionWidth, height: 1, depth: 1)
        
        for emitter in scene.particleEffects {
            emitter.emit()
            if emitter.currentParticles <= 0 { continue }
            
            let threadsPerGrid = MTLSize(width: emitter.particleCount, height: 1, depth: 1)
            computeEncoder.setBuffer(emitter.particleBuffer, offset: 0, index: 0)
            computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        }
        computeEncoder.endEncoding()
        
    }
    
    func render(commandBuffer: MTLCommandBuffer, scene: GameScene) {
        guard let descriptor = descriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }
        
        renderEncoder.label = label
        var size: float2 = [Float(size.width), Float(size.height)]
        renderEncoder.setVertexBytes(&size, length: MemoryLayout<float2>.stride, index: 0) // drawable size for shader
        
        for emitter in scene.particleEffects {
            if emitter.currentParticles <= 0 { continue }
            
            // set pipepline state based on blending
            renderEncoder.setRenderPipelineState(emitter.blending ? blendingPSO : renderPSO)
            
            renderEncoder.setVertexBuffer(emitter.particleBuffer, offset: 0, index: 1)
            renderEncoder.setVertexBytes(&emitter.position, length: MemoryLayout<float2>.stride, index: 2)
            renderEncoder.setFragmentTexture(emitter.particleTexture, index: 0)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: emitter.currentParticles)
        }
        renderEncoder.endEncoding()
    }
    
    func draw(commandBuffer: MTLCommandBuffer, scene: GameScene, uniforms: Uniforms, params: Params) {
        update(commandBuffer: commandBuffer, scene: scene)
        render(commandBuffer: commandBuffer, scene: scene)
    }
}
