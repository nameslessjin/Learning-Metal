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

class Water: Transformable {
  let mesh: MTKMesh
  var transform = Transform()
  let pipelineState: MTLRenderPipelineState
    
    weak var reflectionTexture: MTLTexture?
    weak var refractionTexture: MTLTexture?
    weak var refractionDepthTexture: MTLTexture?
    
    var waterMovementTexture: MTLTexture?
    var timer: Float = 0

  init() {
    let allocator =
      MTKMeshBufferAllocator(device: Renderer.device)
    let plane = MDLMesh(
      planeWithExtent: [100, 0.2, 100],
      segments: [1, 1],
      geometryType: .triangles,
      allocator: allocator)
    do {
      mesh = try MTKMesh(
        mesh: plane, device: Renderer.device)
    } catch {
      fatalError("failed to create water plane")
    }
    pipelineState = PipelineStates.createWaterPSO(
      vertexDescriptor: MTKMetalVertexDescriptorFromModelIO(
        mesh.vertexDescriptor))
      
      waterMovementTexture = try? TextureController.loadTexture(filename: "normal-water")
  }

  func render(
    encoder: MTLRenderCommandEncoder,
    uniforms: Uniforms,
    params: Params
  ) {
    encoder.pushDebugGroup("Water")
    encoder.setRenderPipelineState(pipelineState)
    encoder.setVertexBuffer(
      mesh.vertexBuffers[0].buffer,
      offset: 0,
      index: 0)
    var uniforms = uniforms
    uniforms.modelMatrix = transform.modelMatrix
    encoder.setVertexBytes(
      &uniforms,
      length: MemoryLayout<Uniforms>.stride,
      index: UniformsBuffer.index)

    var params = params
    encoder.setVertexBytes(
      &params,
      length: MemoryLayout<Params>.stride,
      index: ParamsBuffer.index)

    let submesh = mesh.submeshes[0]
      
      encoder.setFragmentTexture(reflectionTexture, index: 0)
      encoder.setFragmentTexture(refractionTexture, index: 1)
      encoder.setFragmentTexture(waterMovementTexture, index: 2)
      var timer = timer
      encoder.setFragmentBytes(&timer, length: MemoryLayout<Float>.size, index: 3)
      encoder.setFragmentTexture(refractionDepthTexture, index: 3)
      
    encoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: submesh.indexCount,
      indexType: submesh.indexType,
      indexBuffer: submesh.indexBuffer.buffer,
      indexBufferOffset: 0)

    encoder.popDebugGroup()
  }
    
    func update(deltaTime: Float) {
        let sensitivity: Float = 0.005
        timer += deltaTime * sensitivity
    }
}
