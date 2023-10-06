//
//  DebugModel.swift
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/5/23.
//

import MetalKit

enum DebugModel {
    static let modelPipelineState: MTLRenderPipelineState = {
        let library = Renderer.library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_debug_line")
        let psoDescriptor = MTLRenderPipelineDescriptor()
        psoDescriptor.vertexFunction = vertexFunction
        psoDescriptor.fragmentFunction = fragmentFunction
        psoDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        psoDescriptor.depthAttachmentPixelFormat = .depth32Float
        psoDescriptor.vertexDescriptor = .defaultLayout
        
        let pipelineState: MTLRenderPipelineState
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: psoDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        return pipelineState
    }()
    
    static func debugDrawModel(renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms, model: Model, color: float3) {
        var uniforms = uniforms
        uniforms.modelMatrix = model.transform.modelMatrix
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        var lightColor = color
        renderEncoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
        renderEncoder.setRenderPipelineState(modelPipelineState)
        
        for mesh in model.meshes {
            for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: index)
            }
            
            for submesh in mesh.submeshes {
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer, indexBufferOffset: submesh.indexBufferOffset)
            }
        }
    }
}


