import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var options: Options
    
    var forwardRenderPass: ForwardRenderPass
    var objectIdRenderPass: ObjectIdRenderPass
    var shadowRenderPass: ShadowRenderPass
    
    var uniforms = Uniforms()
    var params = Params()
    var shadowCamera = OrthographicCamera()

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
        self.options = options
        
        forwardRenderPass = ForwardRenderPass(view: metalView)
        objectIdRenderPass = ObjectIdRenderPass()
        shadowRenderPass = ShadowRenderPass()

        super.init()
        
        metalView.clearColor = MTLClearColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
    }
}

extension Renderer {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        forwardRenderPass.resize(view: view, size: size)
        objectIdRenderPass.resize(view: view, size: size)
        shadowRenderPass.resize(view: view, size: size)
    }
    
    func updateUniforms(scene: GameScene) {
        uniforms.viewMatrix = scene.camera.viewMatrix
        uniforms.projectionMatrix = scene.camera.projectionMatrix
        params.lightCount = UInt32(scene.lighting.lights.count)
        params.cameraPosition = scene.camera.position // this is already in world space

        let sun = scene.lighting.lights[0]
        shadowCamera = OrthographicCamera.createShadowCamera(using: scene.camera, lightPosition: sun.position)
        uniforms.shadowProjectionMatrix = shadowCamera.projectionMatrix;
        uniforms.shadowViewMatrix = float4x4(eye: shadowCamera.position, center: shadowCamera.center, up: [0, 1, 0])
    }
    
    func draw(scene: GameScene, in view: MTKView) {
        guard
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        updateUniforms(scene: scene)
        
        objectIdRenderPass.draw(commandBuffer: commandBuffer, scene: scene, uniforms: uniforms, params: params)
        shadowRenderPass.draw(commandBuffer: commandBuffer, scene: scene, uniforms: uniforms, params: params)
        
        forwardRenderPass.descriptor = descriptor
        forwardRenderPass.idTexture = objectIdRenderPass.idTexture // pass ID texture to the main render pass
        forwardRenderPass.shadowTexture = shadowRenderPass.shadowTexture // pass shadow texture to the main render pass
        forwardRenderPass.draw(commandBuffer: commandBuffer, scene: scene, uniforms: uniforms, params: params)

        
        // DebugLights.draw(lights: scene.lighting.lights, encoder: renderEncoder, uniforms: uniforms)
        
        guard let drawble = view.currentDrawable else {
            return
        }
        
        commandBuffer.present(drawble)
        commandBuffer.commit()
    }
}
