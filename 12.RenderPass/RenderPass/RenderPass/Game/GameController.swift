import MetalKit

class GameController: NSObject {
    var scene: GameScene
    var renderer: Renderer
    var options = Options()
    var fps: Double = 0
    var detalTime: Double = 0
    var lastTime: Double = CFAbsoluteTimeGetCurrent()
    
    init(metalView: MTKView, options: Options) {
        renderer = Renderer(metalView: metalView, options: options)
        scene = GameScene()
        super.init()
        self.options = options
        metalView.delegate = self
        fps = Double(metalView.preferredFramesPerSecond)
        mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
    }
}

extension GameController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        scene.update(size: size)
        renderer.mtkView(view, drawableSizeWillChange: size)
    }
    
    func draw(in view: MTKView) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = (currentTime - lastTime)
        lastTime = currentTime
        scene.update(deltaTime: Float(deltaTime))
        renderer.draw(scene: scene, in: view)
    }
}
