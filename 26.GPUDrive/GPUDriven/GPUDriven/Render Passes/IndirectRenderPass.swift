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

struct IndirectRenderPass: RenderPass {
  var label = "Indirect Command Encoding"
  var descriptor: MTLRenderPassDescriptor?
  let depthStencilState: MTLDepthStencilState?
  let pipelineState: MTLRenderPipelineState
    
    var uniformsBuffer: MTLBuffer!
    var modelParamsBuffer: MTLBuffer!
    var icb: MTLIndirectCommandBuffer! // this buffer hold the render command list
    
    let icbPipelineState: MTLComputePipelineState
    let icbComputeFunction: MTLFunction
    
    var icbBuffer: MTLBuffer!
    var modelsBuffer: MTLBuffer!
    
    var drawArgumentsBuffer: MTLBuffer!
    

  init() {
    pipelineState = PipelineStates.createIndirectPSO()
    depthStencilState = Self.buildDepthStencilState()
      
      icbComputeFunction = Renderer.library.makeFunction(name: "encodeCommands")!
      icbPipelineState = PipelineStates.createComputePSO(function: "encodeCommands")
  }

  mutating func resize(view: MTKView, size: CGSize) {
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
      updateUniforms(scene: scene, uniforms: uniforms)
      
      guard
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()
      else { return }
      encodeDraw(encoder: computeEncoder)
      useResources(encoder: computeEncoder, models: scene.models)
      dispatchThreads(encoder: computeEncoder, drawCount: scene.models.count)
      computeEncoder.endEncoding()
      
      
    guard let descriptor = descriptor,
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
      return
    }
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)

      // useResources(encoder: renderEncoder, models: scene.models)
      renderEncoder.executeCommandsInBuffer(icb, range: 0..<scene.models.count)
    renderEncoder.endEncoding()
  }
    
    func dispatchThreads(encoder: MTLComputeCommandEncoder, drawCount: Int) {
        // set up threads and dispatch them off to the GPU
        let threadExecutionWidth = icbPipelineState.threadExecutionWidth
        let threads = MTLSize(width: drawCount, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
        encoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
    }
    
    func encodeDraw(encoder: MTLComputeCommandEncoder) {
        // set all buffer in one go
        // these below are argument buffers so we don't need to loop through models and set each vertex buffer individually
        encoder.setComputePipelineState(icbPipelineState)
        encoder.setBuffer(icbBuffer, offset: 0,  index: ICBBuffer.index)
        encoder.setBuffer(uniformsBuffer, offset: 0, index: UniformsBuffer.index)
        encoder.setBuffer(modelsBuffer, offset: 0, index: ModelsBuffer.index)
        encoder.setBuffer(modelParamsBuffer, offset: 0, index: ModelParamsBuffer.index)
        encoder.setBuffer(drawArgumentsBuffer, offset: 0, index: DrawArgumentsBuffer.index)
    }
    
    mutating func initializeUniforms(_ models: [Model]) {
        let bufferLength = MemoryLayout<Uniforms>.stride
        uniformsBuffer = Renderer.device.makeBuffer(length: bufferLength, options: [])
        uniformsBuffer.label = "Uniforms"
        
        //
        var modelParams: [ModelParams] = models.map {
            model in
            var modelParams = ModelParams()
            modelParams.modelMatrix = model.transform.modelMatrix
            modelParams.normalMatrix = modelParams.modelMatrix.upperLeft
            modelParams.tiling = model.tiling
            return modelParams
        }
        
        modelParamsBuffer = Renderer.device.makeBuffer(bytes: &modelParams, length: MemoryLayout<ModelParams>.stride * models.count, options: [])
        
        modelParamsBuffer.label = "Model Transforms Array"
    }
    
    func updateUniforms(scene: GameScene, uniforms: Uniforms) {
        var uniforms = uniforms
        uniformsBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
    }

    mutating func initialize(models: [Model]) {
        initializeUniforms(models)
        initializeICBCommands(models)
        initializeModels(models)
        initializeDrawArguments(models: models)
    }
    
    mutating func initializeICBCommands(_ models: [Model]) {
        
        // specify the GPU should expect an indexed draw call
        let icbDescriptor = MTLIndirectCommandBufferDescriptor()
        icbDescriptor.commandTypes = [.drawIndexed]
        icbDescriptor.inheritBuffers = false
        icbDescriptor.maxVertexBufferBindCount = 25
        icbDescriptor.maxFragmentBufferBindCount = 25
        // if we require a different pipeline for different submeshes, set this to false to add setting
        // the render pipeline state to the list of indirect encoder commands
        icbDescriptor.inheritPipelineState = true
        
        guard let icb = Renderer.device.makeIndirectCommandBuffer(descriptor: icbDescriptor, maxCommandCount: models.count, options: [])
        else { fatalError("Failed to create ICB") }
        self.icb = icb
        
        // use the model index to keep track of the command list, set all the necessary data for each draw call
        // we can move this part to GPU to make it set up the command list parallelly
//        for (modelIndex, model) in models.enumerated() {
//            let mesh = model.meshes[0]
//            let submesh = mesh.submeshes[0]
//            let icbCommand = icb.indirectRenderCommandAt(modelIndex)
//            icbCommand.setVertexBuffer(uniformsBuffer, offset: 0, at: UniformsBuffer.index)
//            icbCommand.setVertexBuffer(modelParamsBuffer, offset: 0, at: ModelParamsBuffer.index)
//            icbCommand.setFragmentBuffer(modelParamsBuffer, offset: 0, at: ModelParamsBuffer.index)
//            icbCommand.setVertexBuffer(mesh.vertexBuffers[VertexBuffer.index], offset: 0, at: VertexBuffer.index)
//            icbCommand.setVertexBuffer(mesh.vertexBuffers[UVBuffer.index], offset: 0, at: UVBuffer.index)
//            icbCommand.setFragmentBuffer(submesh.argumentBuffer!, offset: 0, at: MaterialBuffer.index)
//            icbCommand.drawIndexedPrimitives(.triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer, indexBufferOffset: submesh.indexBufferOffset, instanceCount: 1, baseVertex: 0, baseInstance: modelIndex)
//        }
        
        
        // create an argument encoder to match the compute function parameter
        let icbEncoder = icbComputeFunction.makeArgumentEncoder(bufferIndex: ICBBuffer.index)
        // assign an argument buffer that will contain the command list to the encoder
        icbBuffer = Renderer.device.makeBuffer(length: icbEncoder.encodedLength, options: [])
        // set the indirect command buffer in the argument buffer
        icbEncoder.setArgumentBuffer(icbBuffer, offset: 0)
        icbEncoder.setIndirectCommandBuffer(icb, index: 0)
        
    }
    
    mutating func initializeModels(_ models: [Model]) {
        
        // create an argument buffer encoder, we stored encodeCommands in icbComputeFUnction so that the encoder
        // can reference the function arguments and see how many space the argument buffer will need
        let encoder = icbComputeFunction.makeArgumentEncoder(bufferIndex: ModelsBuffer.index)
        // argument buffer using the length provided by encodeCommands and multiply by model count
        modelsBuffer = Renderer.device.makeBuffer(length: encoder.encodedLength * models.count, options: [])
        
        for (index, model) in models.enumerated() {
            let mesh = model.meshes[0]
            let submesh = mesh.submeshes[0]
            encoder.setArgumentBuffer(modelsBuffer, startOffset: 0, arrayElement: index)
            encoder.setBuffer(mesh.vertexBuffers[VertexBuffer.index], offset: 0, index: 0)
            encoder.setBuffer(mesh.vertexBuffers[UVBuffer.index], offset: 0, index: 1)
            encoder.setBuffer(submesh.indexBuffer, offset: submesh.indexBufferOffset, index: 2)
            encoder.setBuffer(submesh.argumentBuffer!, offset: 0, index: 3)
        }
    }
    
    mutating func initializeDrawArguments(models: [Model]) {
        // set up draw argument buffer with appropriate length
        let drawLength = models.count * MemoryLayout<MTLDrawIndexedPrimitivesIndirectArguments>.stride
        drawArgumentsBuffer = Renderer.device.makeBuffer(length: drawLength, options: [])
        drawArgumentsBuffer.label = "Draw Arguments"
        var drawPointer = drawArgumentsBuffer.contents().bindMemory(to: MTLDrawIndexedPrimitivesIndirectArguments.self, capacity: models.count)
        
        // iterate through the models adding a draw argument into the buffer for each model
        // each property in drawArgument corresponds to a parameter in the final draw call
        for (modelIndex, model) in models.enumerated() {
            let mesh = model.meshes[0]
            let submesh = mesh.submeshes[0]
            var drawArgument = MTLDrawIndexedPrimitivesIndirectArguments()
            drawArgument.indexCount = UInt32(submesh.indexCount)
            drawArgument.indexStart = UInt32(submesh.indexBufferOffset)
            drawArgument.instanceCount = 1
            drawArgument.baseVertex = 0
            drawArgument.baseInstance = UInt32(modelIndex)
            drawPointer.pointee = drawArgument
            drawPointer = drawPointer.advanced(by: 1)
        }
    }
    
    func useResources(encoder: MTLComputeCommandEncoder, models: [Model]) {
        encoder.pushDebugGroup("Using resources")
        encoder.useResource(uniformsBuffer, usage: .read)
        encoder.useResource(modelParamsBuffer, usage: .read)
        
        if let heap = TextureController.heap {
            encoder.useHeap(heap)
        }
        
        // when we use a resource, it is available to the GPU as indrect resource ready for the GPU to access
        for model in models {
            let mesh = model.meshes[0]
            let submesh = mesh.submeshes[0]
            encoder.useResource(mesh.vertexBuffers[VertexBuffer.index], usage: .read)
            encoder.useResource(mesh.vertexBuffers[UVBuffer.index], usage: .read)
            encoder.useResource(submesh.indexBuffer, usage: .read)
            encoder.useResource(submesh.argumentBuffer!, usage: .read)
        }
        encoder.popDebugGroup()
        
        // this is where the encodeCommands will write the coomands
        encoder.useResource(icb, usage: .write)
    }
}
