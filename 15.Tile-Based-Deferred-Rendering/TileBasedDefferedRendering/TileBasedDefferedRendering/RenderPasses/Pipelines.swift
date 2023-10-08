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
        let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_main")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
        return createPSO(descriptor: pipelineDescriptor)
    }

    static func createObjectIdPSO() -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        let vertexFunction = Renderer.library?.makeFunction(name: "vertex_main")
        let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_objectId")
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .r32Uint
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
        return Self.createPSO(descriptor: pipelineDescriptor)
    }
    
    static func createShadowPSO() -> MTLRenderPipelineState {
        let vertexFunction = Renderer.library?.makeFunction(name: "vertex_depth")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .invalid // only interested in depth info
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor = .defaultLayout
        return createPSO(descriptor: pipelineDescriptor)
    }
    
    static func createGBufferPSO(colorPixelFormat: MTLPixelFormat, tiled: Bool = false) -> MTLRenderPipelineState {
        let vertexFunction = Renderer.library?.makeFunction(name: "vertex_main")
        let fragmentFunction = Renderer.library?.makeFunction(name: "fragment_gBuffer")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .invalid
        if tiled {
            pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        }
        pipelineDescriptor.setColorAttachmentPixelFormats()

        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
        pipelineDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8

        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
        return createPSO(descriptor: pipelineDescriptor)
    }
    
    static func createSunLightPSO(colorPixelFormat: MTLPixelFormat, tiled: Bool = false) -> MTLRenderPipelineState {
        let vertexFunction = Renderer.library?.makeFunction(name: "vertex_quad")
        let fragment = tiled ? "fragment_tiled_deferredSun" : "fragment_deferredSun"
        let fragmentFunction = Renderer.library?.makeFunction(name: fragment)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        if tiled {
            pipelineDescriptor.setColorAttachmentPixelFormats()
        }

        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
        pipelineDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8

        return createPSO(descriptor: pipelineDescriptor)
    }
    
    static func createPointLightPSO(colorPixelFormat: MTLPixelFormat, tiled: Bool = false) -> MTLRenderPipelineState {
        let vertexFunction = Renderer.library?.makeFunction(name: "vertex_pointLight")
        let fragment = tiled ? "fragment_tiled_pointLight" : "fragment_pointLight"
        let fragmentFunction = Renderer.library?.makeFunction(name: fragment)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        if tiled {
            pipelineDescriptor.setColorAttachmentPixelFormats()
        }

        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
        pipelineDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8

        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
        
        let attachment = pipelineDescriptor.colorAttachments[0]
        attachment?.isBlendingEnabled = true
        attachment?.rgbBlendOperation = .add
        attachment?.alphaBlendOperation = .add
        attachment?.sourceRGBBlendFactor = .one
        attachment?.sourceAlphaBlendFactor = .one
        attachment?.destinationRGBBlendFactor = .one // this makes icospheres be blended with the color already drawn in the background quad
        attachment?.destinationAlphaBlendFactor = .zero
        attachment?.sourceRGBBlendFactor = .one
        attachment?.sourceAlphaBlendFactor = .one
        
        return createPSO(descriptor: pipelineDescriptor)
    }
}

extension MTLRenderPipelineDescriptor {
    func setColorAttachmentPixelFormats() {
        colorAttachments[RenderTargetAlbedo.index].pixelFormat = .bgra8Unorm
        colorAttachments[RenderTargetNormal.index].pixelFormat = .rgba16Float
        colorAttachments[RenderTargetPosition.index].pixelFormat = .rgba16Float
    }
}
