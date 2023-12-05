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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable identifier_name

struct ForwardRenderPass: RenderPass {
  let label = "Forward Render Pass"
  var descriptor: MTLRenderPassDescriptor?

  var pipelineState: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?
    
    var transparentPSO: MTLRenderPipelineState
    
    var pipelineState_MSAA: MTLRenderPipelineState
    var transparentPSO_MSAA: MTLRenderPipelineState
    
  weak var shadowTexture: MTLTexture?

  init() {
    pipelineState = PipelineStates.createForwardPSO()
    depthStencilState = Self.buildDepthStencilState()
      transparentPSO = PipelineStates.createForwardTransparentPSO()
      
      pipelineState_MSAA = PipelineStates.createForwardPSO_MSAA()
      transparentPSO_MSAA = PipelineStates.createForwardTransparentPSO_MSAA()
  }

  mutating func resize(view: MTKView, size: CGSize) {
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
      let pipelineState = params.antialiasing ? pipelineState_MSAA : pipelineState
      let transparentPSO = params.antialiasing ? transparentPSO_MSAA : transparentPSO
      
    guard let descriptor = descriptor,
    let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
      return
    }
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setFragmentBuffer(
      scene.lighting.lightsBuffer,
      offset: 0,
      index: LightBuffer.index)
    renderEncoder.setFragmentTexture(shadowTexture, index: ShadowTexture.index)
      
      // set up area for scissor testing
      if params.scissorTesting {
          let marginWidth = Int(params.width) / 4
          let marginHeight = Int(params.height) / 4
          let width = Int(params.width) / 2
          let height = Int(params.height) / 2
          let rect = MTLScissorRect(x: marginWidth, y: marginHeight, width: width, height: height)
          renderEncoder.setScissorRect(rect)
      }
      
      // for none transparency submeshes
      var params = params
      params.transparency = false
    for model in scene.models {
      model.render(
        encoder: renderEncoder,
        uniforms: uniforms,
        params: params)
    }
      
      // transparent mesh
      renderEncoder.pushDebugGroup("Transparency")
      // find only the models that have a transparent submesh
      let models = scene.models.filter {
          $0.hasTransparency
      }
      params.transparency = true
      if params.alphaBlending {
          renderEncoder.setRenderPipelineState(transparentPSO)
      }
      for model in models {
          model.render(encoder: renderEncoder, uniforms: uniforms, params: params)
      }
      renderEncoder.popDebugGroup()
    renderEncoder.endEncoding()
  }
}
