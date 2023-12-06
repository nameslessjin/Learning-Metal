/// Copyright (c) 2022 Razeware LLC
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

struct WaterRenderPass: RenderPass {
  let label = "Water Render Pass"
  var descriptor: MTLRenderPassDescriptor?
  var pipelineState: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?
  weak var shadowTexture: MTLTexture?
    
    var reflectionTexture: MTLTexture?
    var refractionTexture: MTLTexture?
    var depthTexture: MTLTexture?

  init() {
    pipelineState = PipelineStates.createForwardPSO()
    depthStencilState = Self.buildDepthStencilState()
      descriptor = MTLRenderPassDescriptor()
      
      
  }

  mutating func resize(view: MTKView, size: CGSize) {
      // reflection and refraction don't need sharp images so we can create textures at half of the size
      let size = CGSize(width: size.width / 2, height: size.height / 2)
      reflectionTexture = Self.makeTexture(size: size, pixelFormat: view.colorPixelFormat, label: "Reflection Texture")
      refractionTexture = Self.makeTexture(size: size, pixelFormat: view.colorPixelFormat, label: "Refraction Texture")
      depthTexture = Self.makeTexture(size: size, pixelFormat: .depth32Float, label: "Reflection Depth Texture")
  }

  func render(
    renderEncoder: MTLRenderCommandEncoder,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setFragmentBuffer(
      scene.lighting.lightsBuffer,
      offset: 0,
      index: LightBuffer.index)
    renderEncoder.setFragmentTexture(shadowTexture, index: ShadowTexture.index)

    scene.skybox?.update(renderEncoder: renderEncoder)

    var params = params
    params.transparency = false
    for model in scene.models {
      model.render(
        encoder: renderEncoder,
        uniforms: uniforms,
        params: params)
    }
    scene.terrain?.render(
      encoder: renderEncoder,
      uniforms: uniforms,
      params: params)

    scene.skybox?.render(
      renderEncoder: renderEncoder,
      uniforms: uniforms)
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
      let attachment = descriptor?.colorAttachments[0]
      attachment?.texture = reflectionTexture // render color to reflection
      attachment?.storeAction = .store
      let depthAttachment = descriptor?.depthAttachment
      depthAttachment?.texture = depthTexture // render depth to depth
      depthAttachment?.storeAction = .store
      
      // pass on the render target textures to water for texturing the water plane
      guard let water = scene.water else { return }
      water.reflectionTexture = reflectionTexture
      water.refractionTexture = refractionTexture
      water.refractionDepthTexture = depthTexture
      
    guard let descriptor = descriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
      return
    }
    renderEncoder.label = label

      // camera position for reflection render, position the camera below the surface of the water
      var reflectionCamera = scene.camera
      reflectionCamera.rotation.x *= -1
      let position = (scene.camera.position.y - water.position.y) * 2
      reflectionCamera.position.y -= position
      
      var uniforms = uniforms
      uniforms.viewMatrix = reflectionCamera.viewMatrix
      
      // create a clip plane at the level of the water, xyz are directional vectors
      // w is the level of the water
      var clipPlane = float4(0, 1, 0, -water.position.y)
      uniforms.clipPlane = clipPlane
      
    render(
      renderEncoder: renderEncoder,
      scene: scene,
      uniforms: uniforms,
      params: params)
    renderEncoder.endEncoding()
      
      // set the refraction texture as the render target
      descriptor.colorAttachments[0].texture = refractionTexture
      guard let refractEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
      refractEncoder.label = "Refraction"
      uniforms.viewMatrix = scene.camera.viewMatrix
      // direction + level of the water
      // we only need to preserve the part of the scene below the clipping plane
      clipPlane = float4(0, -1, 0, -water.position.y)
      uniforms.clipPlane = clipPlane
      render(renderEncoder: refractEncoder, scene: scene, uniforms: uniforms, params: params)
      refractEncoder.endEncoding()
  }
}
