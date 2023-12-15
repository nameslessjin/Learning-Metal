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

struct ForwardRenderPass: RenderPass {
  let label = "Forward Render Pass"
  var descriptor: MTLRenderPassDescriptor?
  let pipelineState: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState?

  init() {
    pipelineState = PipelineStates.createForwardPSO()
    depthStencilState = Self.buildDepthStencilState()
  }

  mutating func resize(view: MTKView, size: CGSize) {
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
    guard let descriptor = descriptor,
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
      return
    }
    var uniforms = uniforms
    var params = params

    if let heap = TextureController.heap {
        renderEncoder.useHeap(heap, stages: .fragment)
    }
    renderEncoder.label = label

    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)

    for model in scene.models {
      renderEncoder.pushDebugGroup(model.name)
      params.tiling = model.tiling
      renderEncoder.setFragmentBytes(
        &params,
        length: MemoryLayout<Params>.stride,
        index: ParamsBuffer.index)

      let mesh = model.meshes[0]
      uniforms.modelMatrix = model.transform.modelMatrix
      uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
      renderEncoder.setVertexBytes(
        &uniforms,
        length: MemoryLayout<Uniforms>.stride,
        index: UniformsBuffer.index)
      for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
        renderEncoder.setVertexBuffer(
          vertexBuffer,
          offset: 0,
          index: index)
      }
      let submesh = mesh.submeshes[0]
      renderEncoder.setFragmentBuffer(
        submesh.argumentBuffer,
        offset: 0,
        index: MaterialBuffer.index)
      if let argumentBuffer = submesh.argumentBuffer {
          renderEncoder.useResource(argumentBuffer, usage: .read, stages: .fragment)
      }

      renderEncoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: submesh.indexCount,
        indexType: submesh.indexType,
        indexBuffer: submesh.indexBuffer,
        indexBufferOffset: submesh.indexBufferOffset
      )
      renderEncoder.popDebugGroup()
    }
    renderEncoder.endEncoding()
  }
}
