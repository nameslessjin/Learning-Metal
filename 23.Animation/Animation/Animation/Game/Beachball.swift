//
//  Beachball.swift
//  Animation
//
//  Created by JINSEN WU on 12/6/23.
//

struct Beachball {
    var ball: Model
    var currentTime: Float = 0
    var ballVelocity: Float = 0
    
    
    init(model: Model) {
        self.ball = model
        ball.position = [0, 3, 0]
    }
    
    mutating func update(deltaTime: Float) {
        currentTime += deltaTime
        
        var animation = Animation()
        animation.translations = ballTranslations
        ball.position = animation.getTranslation(at: currentTime) ?? [0, 0, 0]
        ball.position.y += ball.size.y / 2
        
        animation.rotations = ballRotations
        ball.quaternion = animation.getRotation(at: currentTime) ?? simd_quatf()
    }
}

