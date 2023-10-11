//
//  GBufferRenderPass.swift
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/6/23.
//

import MetalKit

struct GBufferRenderPass: RenderPass {
    let label = "G-buffer Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    var pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    
    weak var shadowTexture: MTLTexture?
    var albedoTexture: MTLTexture?
    var normalTexture: MTLTexture?
    var positionTexture: MTLTexture?
    var depthTexture: MTLTexture?
    
    init(view: MTKView) {
        pipelineState = PipelineStates.createGBufferPSO(colorPixelFormat: view.colorPixelFormat)
        depthStencilState = Self.buildDepthStencilState()
        descriptor = MTLRenderPassDescriptor() // create a new one instead of using default
    }
    
    mutating func resize(view: MTKView, size: CGSize) {
        albedoTexture = Self.makeTexture(size: size, pixelFormat: .bgra8Unorm, label: "Albedo Texture")
        // store position and normal values in higher precision
        normalTexture = Self.makeTexture(size: size, pixelFormat: .rgba16Float, label: "Normal Texture")
        positionTexture = Self.makeTexture(size: size, pixelFormat: .rgba16Float, label: "Position Texture")
        depthTexture = Self.makeTexture(size: size, pixelFormat: .depth32Float_stencil8, label: "Depth Texture")
    }
    
    func draw(commandBuffer: MTLCommandBuffer, scene: GameScene, uniforms: Uniforms, params: Params) {
        
        let textures = [
            albedoTexture,
            normalTexture,
            positionTexture
        ]
        // iterate through the textures, add them to render pass
        for (index, texture) in textures.enumerated() {
            let attachment = descriptor?.colorAttachments[RenderTargetAlbedo.index + index]
            attachment?.texture = texture
            attachment?.loadAction = .clear // when we add the color attachment, we can set the clear color
            attachment?.storeAction = .store // ensure the color textures don't clear before the next render pass
            attachment?.clearColor = MTLClearColor(red: 0.73, green: 0.92, blue: 1, alpha: 1) // blue sky
        }
        descriptor?.depthAttachment.texture = depthTexture
        descriptor?.depthAttachment.storeAction = .dontCare
        descriptor?.stencilAttachment.texture = depthTexture
        descriptor?.stencilAttachment.storeAction = .store
        
        guard let descriptor = descriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        renderEncoder.label = label
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // in the initial pass, we only store the albedo and mark fragments as shadowed or not, need to the light
        // since we already processed the shadow matrices in the shadow render pass
        // renderEncoder.setFragmentBuffer(scene.lighting.lightsBuffer, offset: 0, index: LightBuffer.index)
        renderEncoder.setFragmentTexture(shadowTexture, index: ShadowTexture.index)
        
        for model in scene.models {
            model.render(encoder: renderEncoder, uniforms: uniforms, params: params)
        }
        renderEncoder.endEncoding()
    }
    
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        let frontFaceStencil = MTLStencilDescriptor()
        frontFaceStencil.stencilCompareFunction = .always
        frontFaceStencil.stencilFailureOperation = .keep
        frontFaceStencil.depthFailureOperation = .keep
        frontFaceStencil.depthStencilPassOperation = .incrementClamp
        descriptor.frontFaceStencil = frontFaceStencil
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
}
