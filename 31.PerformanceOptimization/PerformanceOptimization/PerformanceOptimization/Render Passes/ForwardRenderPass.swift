///// Copyright (c) 2023 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MetalKit

struct ForwardRenderPass: RenderPass {
  let label = "Forward Render Pass"
  var descriptor: MTLRenderPassDescriptor?

  var pipelineState: MTLRenderPipelineState
  var transparentPSO: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?

  weak var shadowTexture: MTLTexture?

  init() {
    pipelineState = PipelineStates.createForwardPSO()
    transparentPSO = PipelineStates.createForwardTransparentPSO()
    depthStencilState = Self.buildDepthStencilState()
  }

  mutating func resize(view: MTKView, size: CGSize) {
  }

  func renderTransparentMesh(
    encoder: MTLRenderCommandEncoder,
    scene: GameScene,
    uniformsBuffer: MTLBuffer,
    params: Params
  ) {
    var params = params
    // transparent mesh
    encoder.pushDebugGroup("Transparency")
    let models = scene.models.filter {
      $0.hasTransparency
    }
    params.transparency = true
    if params.alphaBlending {
      encoder.setRenderPipelineState(transparentPSO)
    }
    encoder.setCullMode(.none)
    for model in models {
      model.render(
        encoder: encoder,
        uniformsBuffer: uniformsBuffer,
        params: params,
        renderState: .mainPass)
    }
    encoder.popDebugGroup()

  }
  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniformsBuffer: MTLBuffer,
    params: Params
  ) {
    descriptor?.colorAttachments[0].storeAction = .store
    descriptor?.depthAttachment.storeAction = .store
    guard let descriptor = descriptor,
    let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
      return
    }
    if let heap = TextureController.heap {
      renderEncoder.useHeap(heap, stages: .fragment)
    }
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)

    var lights = scene.lighting.lights
    renderEncoder.setFragmentBytes(
      &lights,
      length: MemoryLayout<Light>.stride * lights.count,
      index: LightBuffer.index)

    renderEncoder.setFragmentTexture(shadowTexture, index: ShadowTexture.index)

    scene.skybox?.update(encoder: renderEncoder)

    if Renderer.cullFaces {
      renderEncoder.setCullMode(.back)
    }

    var params = params
    params.transparency = false
    params.alphaTesting = true

    for model in scene.models {
      model.render(
        encoder: renderEncoder,
        uniformsBuffer: uniformsBuffer,
        params: params,
        renderState: .mainPass)
    }

    renderTransparentMesh(
      encoder: renderEncoder,
      scene: scene,
      uniformsBuffer: uniformsBuffer,
      params: params)
    renderEncoder.endEncoding()
  }
}
