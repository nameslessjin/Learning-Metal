import MetalKit
enum DebugLights {
    static let linePipelineState: MTLRenderPipelineState = {
        let library = Renderer.library
        let vertexFunction = library?.makeFunction(name: "vertex_debug")
        let fragmentFunction = library?.makeFunction(name: "fragment_debug_line")
        let psoDescriptor = MTLRenderPipelineDescriptor()
        psoDescriptor.vertexFunction = vertexFunction
        psoDescriptor.fragmentFunction = fragmentFunction
        psoDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        psoDescriptor.depthAttachmentPixelFormat = .depth32Float
        let pipelineState: MTLRenderPipelineState
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: psoDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }()
    
    static let pointPipelineState: MTLRenderPipelineState = {
        let library = Renderer.library
        let vertexFunction = library?.makeFunction(name: "vertex_debug")
        let fragmentFunction = library?.makeFunction(name: "fragment_debug_point")
        let psoDescriptor = MTLRenderPipelineDescriptor()
        psoDescriptor.vertexFunction = vertexFunction
        psoDescriptor.fragmentFunction = fragmentFunction
        psoDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        psoDescriptor.depthAttachmentPixelFormat = .depth32Float
        let pipelineState: MTLRenderPipelineState
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: psoDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }()
    
    static func debugDrawPoint(encoder: MTLRenderCommandEncoder, uniforms: Uniforms, position: float3, color: float3) {
        var vertices = [position]
        encoder.setVertexBytes(&vertices, length: MemoryLayout<float3>.stride, index: 0)
        var uniforms = uniforms
        uniforms.modelMatrix = .identity
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        var lightColor = color
        encoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
        encoder.setRenderPipelineState(pointPipelineState)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
    }
    
    static func debugDrawDirection(encoder: MTLRenderCommandEncoder, uniforms: Uniforms, direction: float3, color: float3, count: Int) {
        var vertices: [float3] = []
        for i in -count..<count {
            let value = Float(i) * 0.4
            vertices.append(float3(value, 0, value))
            vertices.append(float3(direction.x + value, direction.y, direction.z + value))
        }
        let buffer = Renderer.device.makeBuffer(bytes: &vertices, length: MemoryLayout<float3>.stride * vertices.count, options: [])
        var uniforms = uniforms
        uniforms.modelMatrix = .identity
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        var lightColor = color
        encoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.setRenderPipelineState(linePipelineState)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices.count)
    }
    
    static func debugDrawLine(encoder: MTLRenderCommandEncoder, uniforms: Uniforms, position: float3, direction: float3, color: float3) {
        var vertices: [float3] = []
        vertices.append(position)
        vertices.append(float3(
            position.x + direction.x,
            position.y + direction.y,
            position.z + direction.z
        ))
        let buffer = Renderer.device.makeBuffer(bytes: &vertices, length: MemoryLayout<float3>.stride * vertices.count, options: [])
        var uniforms = uniforms
        uniforms.modelMatrix = .identity
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        var lightColor = color
        encoder.setFragmentBytes(&lightColor, length: MemoryLayout<float3>.stride, index: 1)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        
        // render line
        encoder.setRenderPipelineState(linePipelineState)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices.count)
        
        // render starting point
        encoder.setRenderPipelineState(pointPipelineState)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1)
    }
    
    static func draw(lights: [Light], encoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
        encoder.label = "Debug lights"
        for light in lights {
            switch light.type {
                case Point:
                    debugDrawPoint(encoder: encoder, uniforms: uniforms, position: light.position, color: light.color)
                case Spot:
                    debugDrawPoint(encoder: encoder, uniforms: uniforms, position: light.position, color: light.color)
                    debugDrawLine(encoder: encoder, uniforms: uniforms, position: light.position, direction: light.coneDirection, color: light.color)
                case Sun:
                    debugDrawDirection(encoder: encoder, uniforms: uniforms, direction: light.position, color: [1, 0, 0], count: 5)
                default: break
            }
        }
    }
}
