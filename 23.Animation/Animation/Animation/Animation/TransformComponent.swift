//
//  TransformComponent.swift
//  Animation
//
//  Created by JINSEN WU on 12/7/23.
//

import ModelIO

struct TransformComponent {
    // hold all transform matrices for each frame
    let keyTransforms: [float4x4]
    let duration: Float
    var currentTransform: float4x4 = .identity
    
    // receives an TransformComponenet from either an asset or a mesh
    init(transform: MDLTransformComponent, object: MDLObject, startTime: TimeInterval, endTime: TimeInterval)
    {
        duration = Float(endTime - startTime)
        let timeStride = stride(from: startTime, to: endTime, by: 1 / TimeInterval(GameController.fps))
        
        // create all transform matrices for every frame
        keyTransforms = Array(timeStride).map {
            time in MDLTransform.globalTransform(with: object, atTime: time)
        }
    }
    
    mutating func getCurrentTransform(at time: Float) {
        guard duration > 0 else {
            currentTransform = .identity
            return
        }
        
        // retrive the matrix at a particular frame
        let frame = Int(fmod(time, duration) * Float(GameController.fps))
        if frame < keyTransforms.count {
            currentTransform = keyTransforms[frame]
        } else {
            currentTransform = keyTransforms.last ?? .identity
        }
    }
}
