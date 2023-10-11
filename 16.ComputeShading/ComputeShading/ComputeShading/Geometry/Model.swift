import MetalKit

class Model: Transformable {
    var transform = Transform()
    let meshes: [Mesh]
    let name: String
    var tiling: UInt32 = 1
    let objectId: UInt32
    
    init(name: String, objectId: UInt32 = 0) {
        guard let assetURL = Bundle.main.url(
            forResource: name,
            withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        self.objectId = objectId
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let meshDescriptor = MDLVertexDescriptor.defaultLayout
        let asset = MDLAsset(
            url: assetURL,
            vertexDescriptor: meshDescriptor,
            bufferAllocator: allocator
        )
        asset.loadTextures()
//        let (mdlMeshes, mtkMeshes) = try! MTKMesh.newMeshes(asset: asset, device: device)
        // loading MDLMesh first and changing them before initializing the MTKMesh.
        // This code generateds and loads the vertex tangent and bitangent values.
        var mtkMeshes: [MTKMesh] = []
        let mdlMeshes = asset.childObjects(of: MDLMesh.self) as? [MDLMesh] ?? [] 
        _ = mdlMeshes.map {
            mdlMesh in mdlMesh.addTangentBasis(
                forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                tangentAttributeNamed: MDLVertexAttributeTangent,
                bitangentAttributeNamed: MDLVertexAttributeBitangent)
            mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Renderer.device))
        }
        meshes = zip(mdlMeshes, mtkMeshes).map {
            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
        }
        self.name = name
    }
}

// Rendering
extension Model {
    func render (
        encoder: MTLRenderCommandEncoder,
        uniforms vertex: Uniforms,
        params fragment: Params
    ) {
        encoder.pushDebugGroup(name)
        var uniforms = vertex
        uniforms.modelMatrix = transform.modelMatrix
        uniforms.normalMatrix = uniforms.modelMatrix.upperLeft.inverse.transpose
        
        var params = fragment
        params.tiling = tiling
        params.objectId = objectId
        
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        encoder.setFragmentBytes(&params, length: MemoryLayout<Params>.stride, index: ParamsBuffer.index)
        
        for mesh in meshes {
            for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                encoder.setVertexBuffer(
                    vertexBuffer,
                    offset: 0,
                    index: index)
            }
            
            for submesh in mesh.submeshes {
                // set the fragment texture here
                encoder.setFragmentTexture(submesh.textures.baseColor, index: BaseColor.index)
                encoder.setFragmentTexture(submesh.textures.normal, index: NormalTexture.index)
                encoder.setFragmentTexture(submesh.textures.roughness, index: RoughnessTexture.index)
                encoder.setFragmentTexture(submesh.textures.metallic, index: MetallicTexture.index)
                encoder.setFragmentTexture(submesh.textures.ambientOcclusion, index: AOTexture.index)
                
                var material = submesh.material
                encoder.setFragmentBytes(&material, length: MemoryLayout<Material>.stride, index: MaterialBuffer.index)
                
                encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer, indexBufferOffset: submesh.indexBufferOffset)
            }
        }
        encoder.popDebugGroup()
    }
    
    func convertMesh() {
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let pipelineState: MTLComputePipelineState // requires fewer state changes on the GPU so no need a descriptor
        do {
            guard let kernelFunction = Renderer.library.makeFunction(name: "convert_mesh") else {
                fatalError("Failed to create kernel function")
            }
            
            pipelineState = try Renderer.device.makeComputePipelineState(function: kernelFunction)
        } catch { fatalError(error.localizedDescription) }
        computeEncoder.setComputePipelineState(pipelineState)
        
        // create a buffer to hold the total number of vertices
        let totalBuffer = Renderer.device.makeBuffer(length: MemoryLayout<Int>.stride, options: [])
        let vertexTotal = totalBuffer?.contents().bindMemory(to: Int.self, capacity: 1)
        vertexTotal?.pointee = 0
        computeEncoder.setBuffer(totalBuffer, offset: 0, index: 1)
        
        for mesh in meshes {
            let vertexBuffer = mesh.vertexBuffers[VertexBuffer.index]
            computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
            let vertexCount = vertexBuffer.length / MemoryLayout<VertexLayout>.stride
            
            // the model vertices are a one-dimensional array, we only set up width
            let threadsPerGroup = MTLSize(width: pipelineState.threadExecutionWidth, height: 1, depth: 1)
            let threadsPerGrid = MTLSize(width: vertexCount, height: 1, depth: 1)
            computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
            computeEncoder.endEncoding()
        }
        
        // the command buffer can execute a closure after its GPU operations have finished
        commandBuffer.addCompletedHandler{ _ in
                print("GPU conversion time:", CFAbsoluteTimeGetCurrent() - startTime)
            print("Total Vertices:", vertexTotal?.pointee ?? -1)
        }
        commandBuffer.commit()
        
    }
}
