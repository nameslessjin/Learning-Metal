import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var options: Options
    
    var pipelineState: MTLRenderPipelineState!
    let depthStencilState: MTLDepthStencilState?
    
    var timer: Float = 0
    var uniforms = Uniforms()
    var params = Params()
    
    lazy var house: Model = {
        Model(name: "lowpoly-house.obj")
    }()
    
    lazy var ground: Model = {
        var ground = Model(name: "plane.obj")
        ground.tiling = 16
        return ground
    }()

    init(metalView: MTKView, options: Options) {
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
        Self.library = library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        // create the pipeline state
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        do {
            pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        self.options = options
        depthStencilState = Renderer.buildDepthStencilState()
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
    }
    
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width) / Float(size.height)
        let projectionMatrix = float4x4(
            projectionFov: Float(70).degreesToRadians, near: 0.1, far: 100, aspect: aspect
        )
        uniforms.projectionMatrix = projectionMatrix
        
        params.width = UInt32(size.width)
        params.height = UInt32(size.height)
    }
    
    func draw(in view: MTKView) {
        guard
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        timer += 0.005
        uniforms.viewMatrix = float4x4(translation: [0, 1.5, -5]).inverse
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        house.rotation.y = sin(timer)
        house.render(encoder: renderEncoder, uniforms: uniforms, params: params)
        
        ground.scale = 40
        ground.rotation.y = sin(timer)
        ground.render(encoder: renderEncoder, uniforms: uniforms, params: params)
        
        renderEncoder.endEncoding()
        guard let drawble = view.currentDrawable else {
            return
        }
        
        commandBuffer.present(drawble)
        commandBuffer.commit()
    }
}
