//
//  Pipelines.swift
//  Flocking
//
//  Created by JINSEN WU on 10/13/23.
//

import MetalKit

enum PipelineStates {
    static func createComputePSO(function: String) -> MTLComputePipelineState {
        guard let kernel = Renderer.library.makeFunction(name: function)
        else { fatalError("Unable to create \(function) PSO") }
        
        let pipelineState: MTLComputePipelineState
        do {
            pipelineState = try Renderer.device.makeComputePipelineState(function: kernel)
        } catch {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
}
