//
//  Renderer.swift
//  Particles
//
//  Created by JINSEN WU on 10/11/23.
//

import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var options: Options
    
    var uniforms = Uniforms()
    var params = Params()
    
    var forwardRenderPass: ForwardRenderPass

    var particlesRenderPass: ParticlesRenderPass
    
    init(metalView: MTKView, options: Options) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else { fatalError("GPU not available") }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        // create shader functions
        let library = device.makeDefaultLibrary()
        Self.library = library
        self.options = options
        forwardRenderPass = ForwardRenderPass(view: metalView)

        particlesRenderPass = ParticlesRenderPass(view: metalView)
        
        super.init()
        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.3, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        metalView.framebufferOnly = false /* determine that the drawable texture is not only used for rendering */
    }
}

extension Renderer {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        forwardRenderPass.resize(view: view, size: size)
        particlesRenderPass.resize(view: view, size: size)
    }
    
    func updateUniforms(scene: GameScene) {
        uniforms.viewMatrix = scene.camera.viewMatrix
        uniforms.projectionMatrix = scene.camera.projectionMatrix
        params.lightCount = UInt32(scene.lighting.lights.count)
        params.cameraPosition = scene.camera.position
    }
    
    func draw(scene: GameScene, in view: MTKView) {
        guard
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor else { return }
        
        updateUniforms(scene: scene)
        
        forwardRenderPass.descriptor = descriptor
        forwardRenderPass.draw(commandBuffer: commandBuffer, scene: scene, uniforms: uniforms, params: params)
        
        // Render particles with compute shaders

        
        // Render particles with compute, vertex and fragment shaders
        particlesRenderPass.descriptor = descriptor
        particlesRenderPass.draw(commandBuffer: commandBuffer, scene: scene, uniforms: uniforms, params: params)
        
        guard let drawable = view.currentDrawable else { return }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
