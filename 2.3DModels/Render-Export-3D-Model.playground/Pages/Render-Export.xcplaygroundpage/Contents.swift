import PlaygroundSupport
import MetalKit

guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("GPU is not supported")
}

let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: device)
view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)
view.isPaused = true
view.enableSetNeedsDisplay = false

// the allocator manages the memory for the mesh data
let allocator = MTKMeshBufferAllocator(device: device)

// model I/O creates a sphere with the specified size and returns an MDLMesh with all the vertex info in data buffers
let mdlMesh = MDLMesh(coneWithExtent: [1, 1, 1], segments: [10, 10], inwardNormals: false, cap: true, geometryType: .triangles, allocator: allocator)

// convert Model I/O mesh to a MetalKit mesh
let mesh = try MTKMesh(mesh: mdlMesh, device: device)


// begin export code
// the top level of a scene in Model I/O, we build a complete scene hieararchy
// by adding child objects such as meshes, cameras and lights
let asset = MDLAsset()
asset.add(mdlMesh)
let fileExtension = "obj"
guard MDLAsset.canExportFileExtension(fileExtension)
else { fatalError("Can't export a .\(fileExtension) format")}

do
{
    let url = playgroundSharedDataDirectory
        .appendingPathComponent("primitive.\(fileExtension)")
    try asset.export(to: url)
}
catch
{
    fatalError("Error \(error.localizedDescription)")
}
// end export code

guard let commandQueue = device.makeCommandQueue() else {
    fatalError("Could not create a command queue")
}


let shader = """
#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    // the position is anput attribute with location/index 0
    float4 position [[attribute(0)]];
};

vertex float4 vertex_main(const VertexIn vertex_in[[stage_in]])
{
    return vertex_in.position;
}

fragment float4 fragment_main()
{
    return float4(1, 0, 0, 1);
}
"""

// setup shader
let library = try device.makeLibrary(source: shader, options: nil)
let vertexFunction = library.makeFunction(name: "vertex_main")
let fragmentFunction = library.makeFunction(name: "fragment_main")


// create pipeline state
let pipelineDescriptor = MTLRenderPipelineDescriptor()
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm // 32 bits
pipelineDescriptor.vertexFunction = vertexFunction
pipelineDescriptor.fragmentFunction = fragmentFunction
pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)


// create command buffer to stores all the commands for GPU to run
// get a reference to the view's render pass descriptor.  It holds data for the render destinations, aka attachments
// use the render pass descriptor to create the render command encoder
// From the command buffer, we get a command encoder using the render pass descriptor
guard let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
else { fatalError() }

// gives render encoder the pipeline state
renderEncoder.setRenderPipelineState(pipelineState)

// give vertex buffer to render encoder
renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)

// we only have one submesh in the mesh right now
guard let submesh = mesh.submeshes.first else { fatalError() }

renderEncoder.setTriangleFillMode(.lines)

// instruct the GPU to render a vertex buffer consisting of triangles with the vertices placed in the correct
// order by the submesh idnex information, it does not do actual render until the GPU has received all the
// command buffer's commands
renderEncoder.drawIndexedPrimitives(
    type: .triangle,
    indexCount: submesh.indexCount,
    indexType: submesh.indexType,
    indexBuffer: submesh.indexBuffer.buffer,
    indexBufferOffset: 0
)

// send commands to the render command encoder
// render encoder are draw calls and end the render pass
renderEncoder.endEncoding()
// the MTKView is backed by a Core Animation CAMetalLayer and the layer owns a drawable texture which Metal can
// read and write to
guard let drawable = view.currentDrawable else { fatalError() }
// ask the command buffer to present the MTKView's drawble and commit to the GPU
commandBuffer.present(drawable)
commandBuffer.commit()

PlaygroundPage.current.liveView = view



