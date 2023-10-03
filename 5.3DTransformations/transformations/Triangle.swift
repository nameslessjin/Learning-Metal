import MetalKit

struct Triangle {
    var vertices: [Float] = [
        -0.7, 0.8, 0,
        -0.7, -0.5, 0,
         0.4, 0.1, 0
    ]
    
    var indices: [UInt16] = [
        0, 1, 2
    ]
    
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    
    init(device: MTLDevice) {
        guard let vertexBuffer = device.makeBuffer(
            bytes: &vertices,
            length: MemoryLayout<Float>.stride * vertices.count,
            options: []) else {
            fatalError("Unable to create quad vertex buffer")
        }
        self.vertexBuffer = vertexBuffer
        guard let indexBuffer = device.makeBuffer(
            bytes: &indices,
            length: MemoryLayout<UInt16>.stride * indices.count,
            options: []) else {
            fatalError("Unable to create quad vertex buffer")
        }
        
        self.indexBuffer = indexBuffer
    }
}
