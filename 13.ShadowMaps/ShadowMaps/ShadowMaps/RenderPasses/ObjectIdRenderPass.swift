import MetalKit

struct ObjectIdRenderPass: RenderPass {
    let label = "Object ID Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    var pipelineState: MTLRenderPipelineState
    var idTexture: MTLTexture?
    var depthTexture: MTLTexture?
    var depthStencilState: MTLDepthStencilState?
    
    mutating func resize(view: MTKView, size: CGSize) {
        idTexture = Self.makeTexture(size: size, pixelFormat: .r32Uint, label: "ID Texture")
        // the pixel format must match the  render pipeline state depth texture format
        depthTexture = Self.makeTexture(size: size, pixelFormat: .depth32Float, label: "ID Depth Texture")
    }
    
    func draw(commandBuffer: MTLCommandBuffer, scene: GameScene, uniforms: Uniforms, params: Params) {
        guard let descriptor = descriptor else {return}
        descriptor.colorAttachments[0].texture = idTexture
        
        // Whenever we are not rendering an object, the pixels will be random, so need to clear the texture before
        // we render to know exactly what object ID is in the area
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store // only set to store if you need the attachment texture donw the line
        descriptor.depthAttachment.texture = depthTexture
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        renderEncoder.label = label
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        for model in scene.models {
            renderEncoder.pushDebugGroup(model.name)
            model.render(encoder: renderEncoder, uniforms: uniforms, params: params)
            renderEncoder.popDebugGroup()
        }
        renderEncoder.endEncoding()
    }
    
    init() {
        pipelineState = PipelineStates.createObjectIdPSO()
        descriptor = MTLRenderPassDescriptor()
        depthStencilState = Self.buildDepthStencilState()
        
    }
    
}
