import MetalPerformanceShaders




// create a metal device, command queue, command buffer
guard let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue()
else { fatalError() }

let size = 4
let count = size * size

func createMPSMatrix(withRepeatingValue: Float) -> MPSMatrix {
    // retrieve the optimal number of bytes between one row and the next
    // simd use column major, MPSMatrix uses row major
    let rowBytes = MPSMatrixDescriptor.rowBytes(
        forColumns: size,
        dataType: .float32)
    
    // create a new array and populate it
    let array = [Float](
        repeating: withRepeatingValue, count: count
    )
    
    // create a buffer with array data
    guard let buffer = device.makeBuffer(
        bytes: array,
        length: size * rowBytes,
        options: []
    )
    else { fatalError() }
    
    // create a matrix descriptor then create the MPS matrix using the descriptor
    let matrixDescriptor = MPSMatrixDescriptor(
        rows: size,
        columns: size,
        rowBytes: rowBytes,
        dataType: .float32
    )
    return MPSMatrix(buffer: buffer, descriptor: matrixDescriptor)
}

let A = createMPSMatrix(withRepeatingValue: 3)
let B = createMPSMatrix(withRepeatingValue: 2)
let C = createMPSMatrix(withRepeatingValue: 1)

// create a MPS matrix multiplication kernel
let multiplicationKernel = MPSMatrixMultiplication(
    device: device,
    transposeLeft: false,
    transposeRight: false,
    resultRows: size,
    resultColumns: size,
    interiorColumns: size,
    alpha: 1.0,
    beta: 0.0
    )

guard let commandBuffer = commandQueue.makeCommandBuffer()
else { fatalError() }

// multiply A and B and place the result in C
multiplicationKernel.encode(
    commandBuffer: commandBuffer,
    leftMatrix: A,
    rightMatrix: B,
    resultMatrix: C)

commandBuffer.commit()
commandBuffer.waitUntilCompleted()

// read the result back from matrix C into a buffer typed to float
let contents = C.data.contents()
let pointer = contents.bindMemory(to: Float.self, capacity: count)
// create an array filled with the values from the buffer
(0..<count).map {
    pointer.advanced(by: $0).pointee
}
