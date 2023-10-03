import MetalKit
class Model: Transformable {
    let mesh: MTKMesh
    let name: String
    var transform = Transform()
    
    init(device: MTLDevice, name: String) {
        guard let assetURL = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(
            url: assetURL,
            vertexDescriptor: .defaultLayout,
            bufferAllocator: allocator
        )
        if let mdlMesh = asset.childObjects(of: MDLMesh.self).first as? MDLMesh {
            do {
                mesh = try MTKMesh(mesh: mdlMesh, device: device)
            } catch {
                fatalError("Failed to load mesh")
            }
        } else {
            fatalError("No mesh available")
        }
        self.name = name
    }
}

// Rendering
extension Model {
    func render(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(
            mesh.vertexBuffers[0].buffer,
            offset: 0,
            index: 0)
        
        for submesh in mesh.submeshes {
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: submesh.indexCount,
                indexType: submesh.indexType,
                indexBuffer: submesh.indexBuffer.buffer,
                indexBufferOffset: submesh.indexBuffer.offset
            )
        }
    }
}
