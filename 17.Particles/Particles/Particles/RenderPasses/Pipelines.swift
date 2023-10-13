import MetalKit

enum PipelineStates {
    static func createPSO(descriptor: MTLRenderPipelineDescriptor) -> MTLRenderPipelineState {
        let pipelineState: MTLRenderPipelineState
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
    
    static func createForwardPSO(colorPixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
        let vertexFunction = Renderer.library?.makeFunction(name: "vertex_main")
        let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_PBR")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
        return createPSO(descriptor: pipelineDescriptor)
    }

    static func createParticleRenderPSO(pixelFormat: MTLPixelFormat, enableBlending: Bool = false) -> MTLRenderPipelineState {
        let vertexFunction = Renderer.library.makeFunction(name: "vertex_particle")
        let fragmentFunction = Renderer.library.makeFunction(name: "fragment_particle")
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.depthAttachmentPixelFormat = .depth32Float
        if enableBlending {
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = .add
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        }
        return Self.createPSO(descriptor: descriptor)
    }
    
    static func createComputePSO(function: String) -> MTLComputePipelineState {
     
        // create a compute pipeline state from the kernel
        guard let kernel = Renderer.library.makeFunction(name: function)
        else { fatalError("Unable to create \(function) PSO") }
        let pipelineState: MTLComputePipelineState
        
        do {
            pipelineState = try Renderer.device.makeComputePipelineState(function: kernel)
        } catch { fatalError(error.localizedDescription) }
        return pipelineState
    }
}

