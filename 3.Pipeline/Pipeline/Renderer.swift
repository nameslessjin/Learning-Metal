//
//  Renderer.swift
//  Pipeline
//
//  Created by JINSEN WU on 9/25/23.
//

import MetalKit

class Renderer: NSObject
{
    // ! means implicitly unwrapped optional
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var mesh: MTKMesh!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    
    init(metalView: MTKView)
    {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else { fatalError("GPU not available") }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        // create the mesh
        let allocator = MTKMeshBufferAllocator(device: device)
        let size: Float = 0.8
        let mdlMesh = MDLMesh(
            boxWithExtent: [size, size, size],
            segments: [1, 1, 1],
            inwardNormals: false,
            geometryType: .triangles,
            allocator: allocator
        )
        
        do 
        {
            mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } 
        catch let error
        {
            print(error.localizedDescription)
        }
        
        vertexBuffer = mesh.vertexBuffers[0].buffer
        
        // craete the shader function library
        let library = device.makeDefaultLibrary()
        Renderer.library = library
        let vertexFunction = library?.makeFunction(name: "vertex_main") // ? is for optional chaining
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        // create the pipeline state object
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
        do
        {
            pipelineState =
            try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch let error { fatalError(error.localizedDescription) }
        
        
        
        super.init()
        
        metalView.clearColor = MTLClearColor(
            red: 1.0,
            green: 1.0,
            blue: 0.8,
            alpha: 1.0
        )
        
        // set Renderer as the delegate for metalView
        // so that the view will call the MTKViewDelegate drawing methods
        metalView.delegate = self
    }
    


}

extension Renderer: MTKViewDelegate
{
    // necessary func for MTKViewDelegate
    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ){
        
    }
    
    // necessary func for MTKViewDelegate
    func draw(in view: MTKView)
    {
        guard
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        // drawing code
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        for submesh in mesh.submeshes
        {
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: submesh.indexCount,
                indexType: submesh.indexType,
                indexBuffer: submesh.indexBuffer.buffer,
                indexBufferOffset: submesh.indexBuffer.offset
            )
        }
        
        renderEncoder.endEncoding() // after adding the GPU commands to a command encoder, we end its encoding
        guard let drawable = view.currentDrawable else { return }
        commandBuffer.present(drawable) // present the view's drawable texture to the GPU
        commandBuffer.commit() // commit the command buffer, send the encoded commands to the GPU for execution
    }
}
