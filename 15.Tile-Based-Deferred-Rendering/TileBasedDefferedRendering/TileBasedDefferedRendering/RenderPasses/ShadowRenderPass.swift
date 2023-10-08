//
//  ShadowRenderPass.swift
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/5/23.
//

import MetalKit

struct ShadowRenderPass: RenderPass {
    let label: String = "Shadow Render Pass"
    var descriptor: MTLRenderPassDescriptor? = MTLRenderPassDescriptor()
    var depthStencilState: MTLDepthStencilState? = Self.buildDepthStencilState()
    var pipelineState: MTLRenderPipelineState
    var shadowTexture: MTLTexture?
    
    mutating func resize(view: MTKView, size: CGSize) {
        // shadow maps are usually square to match the light's cuboid orthographic camera so no need to resize
    }
    
    init () {
        // initialize the pipeline state, builds the depth texture with the required pixel format
        // shadow maps are usually square to match the light's cuboid orthographic camera so no need to resize
        pipelineState = PipelineStates.createShadowPSO()
        shadowTexture = Self.makeTexture(size: CGSize(width: 2048, height: 2048), pixelFormat: .depth32Float, label: "Shadow Depth Texture")
    }
    
    func draw(commandBuffer: MTLCommandBuffer, scene: GameScene, uniforms: Uniforms, params: Params) {
        guard let descriptor = descriptor else { return }
        
        // the GPU will clear the texture on loading it and store it so that the following render pass can use it
        descriptor.depthAttachment.texture = shadowTexture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        renderEncoder.label = "Shadow Encoder"
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        for model in scene.models {
            renderEncoder.pushDebugGroup(model.name)
            model.render(encoder: renderEncoder, uniforms: uniforms, params: params)
            renderEncoder.popDebugGroup()
        }
        
        renderEncoder.endEncoding()
    }
}
