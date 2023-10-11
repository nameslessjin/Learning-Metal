//
//  LightingRenderPass.swift
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/6/23.
//

import MetalKit

struct LightingRenderPass: RenderPass {
    let label = "Lighting Render Pass"
    var descriptor: MTLRenderPassDescriptor?
    var sunLightPSO: MTLRenderPipelineState
    var pointLightPSO: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    var icosphere = Model(name: "icosphere.obj")
    weak var albedoTexture: MTLTexture?
    weak var normalTexture: MTLTexture?
    weak var positionTexture: MTLTexture?
    weak var stencilTexture: MTLTexture?
    
    init(view: MTKView) {
        sunLightPSO = PipelineStates.createSunLightPSO(colorPixelFormat: view.colorPixelFormat)
        pointLightPSO = PipelineStates.createPointLightPSO(colorPixelFormat: view.colorPixelFormat)
        depthStencilState = Self.buildDepthStencilState()
    }
    
    func resize(view: MTKView, size: CGSize) {}
    
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = false
        let frontFaceStencil = MTLStencilDescriptor()
        frontFaceStencil.stencilCompareFunction = .notEqual
        frontFaceStencil.stencilFailureOperation = .keep
        frontFaceStencil.depthFailureOperation = .keep
        frontFaceStencil.depthStencilPassOperation = .keep
        descriptor.frontFaceStencil = frontFaceStencil
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    
    func draw(commandBuffer: MTLCommandBuffer, scene: GameScene, uniforms: Uniforms, params: Params) {
        
        // set stencilAttachment to load so that the LightingRenderPass can use  the stencil texture for stencil testing
        descriptor?.stencilAttachment.texture = stencilTexture
        descriptor?.depthAttachment.texture = stencilTexture
        descriptor?.stencilAttachment.loadAction = .load
        descriptor?.depthAttachment.loadAction = .dontCare
        
        // accumulate output from all light types when running the lighting pass
        // each type needs a different fragment function so multiple pipeline states
        guard let descriptor = descriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        
        renderEncoder.label = label
        renderEncoder.setDepthStencilState(depthStencilState)
        var uniforms = uniforms
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        
        renderEncoder.setFragmentTexture(albedoTexture, index: BaseColor.index)
        renderEncoder.setFragmentTexture(normalTexture, index: NormalTexture.index)
        renderEncoder.setFragmentTexture(positionTexture, index: PositionTexture.index)
        
        drawSunLight(renderEncoder: renderEncoder, scene: scene, params: params)
        drawPointLight(renderEncoder: renderEncoder, scene: scene, params: params)
        renderEncoder.endEncoding()
    }
    
    func drawSunLight(renderEncoder: MTLRenderCommandEncoder, scene: GameScene, params: Params) {
        renderEncoder.pushDebugGroup("Sun Light")
        renderEncoder.setRenderPipelineState(sunLightPSO)
        
        var params = params
        params.lightCount = UInt32(scene.lighting.sunlights.count)
        renderEncoder.setFragmentBytes(&params, length: MemoryLayout<Params>.stride, index: ParamsBuffer.index)
        renderEncoder.setFragmentBuffer(scene.lighting.sunBuffer, offset: 0, index: LightBuffer.index)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.popDebugGroup()
    }

    func drawPointLight(renderEncoder: MTLRenderCommandEncoder, scene: GameScene, params: Params) {
        renderEncoder.pushDebugGroup("Point lights")
        renderEncoder.setRenderPipelineState(pointLightPSO)
        renderEncoder.setVertexBuffer(scene.lighting.pointBuffer, offset: 0, index: LightBuffer.index)
        renderEncoder.setFragmentBuffer(scene.lighting.pointBuffer, offset: 0, index: LightBuffer.index)
        
        guard let mesh = icosphere.meshes.first,
              let submesh = mesh.submeshes.first else { return }
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: index)
        }
        
        // instancing, drawing the same geometry on GPU
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer,
            indexBufferOffset: submesh.indexBufferOffset,
            instanceCount: scene.lighting.pointLights.count) // GPU will repeat drawing the submesh for instanceCount times
        renderEncoder.popDebugGroup()
        
    }
}
