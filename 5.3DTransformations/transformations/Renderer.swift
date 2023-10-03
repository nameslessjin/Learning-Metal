//
//  Renderer.swift
//  transformations
//
//  Created by JINSEN WU on 9/26/23.
//

import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!
    
    lazy var triangle: Triangle = {
        Triangle(device: Renderer.device)
    }()
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        // create the shader function library
        let library = device.makeDefaultLibrary()
        Renderer.library = library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        // create the pipeline state
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        super.init()
        metalView.clearColor = MTLClearColor(
            red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0
        )
        metalView.delegate = self
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {}
    
    func draw(in view: MTKView) {
        guard
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {return}
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(triangle.vertexBuffer, offset: 0, index: 0)
        
        // draw the untransformed triangle in light gray
        var color: simd_float4 = [0.8, 0.8, 0.8, 1]
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        var translation = matrix_float4x4()
        translation.columns.0 = [1, 0, 0, 0]
        translation.columns.1 = [0, 1, 0, 0]
        translation.columns.2 = [0, 0, 1, 0]
        translation.columns.3 = [0, 0, 0, 1]
        var matrix = translation
        renderEncoder.setVertexBytes(&matrix, length: MemoryLayout<matrix_float4x4>.stride, index: 11)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle, indexCount: triangle.indices.count, indexType: .uint16, indexBuffer: triangle.indexBuffer, indexBufferOffset: 0
        )
        
        // draw the new triangle in red
        color = [1, 0, 0, 1]
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        translation.columns.3.x = triangle.vertices[6]
        translation.columns.3.y = triangle.vertices[7]
        translation.columns.3.z = triangle.vertices[8]
        let scaleX: Float = 1.2
        let scaleY: Float = 0.5
        let scaleMatrix = float4x4(
            [scaleX, 0, 0, 0],
            [0, scaleY, 0, 0],
            [0,     0,  1, 0],
            [0,     0,  0, 1]
        )
        let angle = Float.pi / 2.0
        let rotationMatrix = float4x4(
            [cos(angle), -sin(angle), 0, 0],
            [sin(angle), cos(angle),  0, 0],
            [0,             0,        1, 0],
            [0,             0,        0, 1]
        )
        matrix = rotationMatrix * translation.inverse
        renderEncoder.setVertexBytes(&matrix, length: MemoryLayout<matrix_float4x4>.stride, index: 11)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: triangle.indices.count, indexType: .uint16, indexBuffer: triangle.indexBuffer, indexBufferOffset: 0)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {return}
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
