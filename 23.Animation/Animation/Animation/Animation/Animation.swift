//
//  Animation.swift
//  Animation
//
//  Created by JINSEN WU on 12/7/23.
//

// Value is generic
// holds animation key value and time
struct Keyframe<Value> {
    var time: Float = 0
    var value: Value
}

// holds an array of keyframe
struct Animation {
    var translations: [Keyframe<float3>] = []
    var repeatAnimation = true
    var rotations: [Keyframe<simd_quatf>] = []
    
    func getTranslation(at time: Float) -> float3? {
        // ensure that there are translation keys in the array
        guard let lastKeyframe = translations.last else {
            return nil
        }
        
        // if the first keyframe occurs on or after the give time,
        // return the first key value, the first frame should be at keyframe 0
        var currentTime = time
        if let first = translations.first,
           first.time >= currentTime {
            return first.value
        }
        
        // if the time given is greater than the last keyframe, check repeat animation
        // if not return the last keyframe value
        if currentTime >= lastKeyframe.time,
           !repeatAnimation {
            return lastKeyframe.value
        }
        
        // use modulo to get the current time within the clip
        currentTime = fmod(currentTime, lastKeyframe.time)
        // create a new array containing the previous and next keys for all keyframes
        // except the first one
        let keyFramePairs = translations.indices.dropFirst().map {
            (previous: translations[$0 - 1], next: translations[$0])
        }
        
        // find the first tuple of previous and next keyframes where the current time
        // is less than the next keyframe time.  The current time will be beteen the previous and next keyframe times
        guard let (previousKey, nextKey) = (keyFramePairs.first {
            currentTime < $0.next.time
        })
        else { return nil }
        
        // the get interpolated value between 0 and 1 between the previous and next keyframe
        let interpolant =
        (currentTime - previousKey.time) /
        (nextKey.time - previousKey.time)
        
        // use simd_mix to interpolate between the two keyframes
        return simd_mix(previousKey.value, nextKey.value, float3(repeating: interpolant))
    }
    
    func getRotation(at time: Float) -> simd_quatf? {
        guard let lastKeyframe = rotations.last else {
            return nil
        }
        
        var currentTime = time
        if let first = rotations.first,
           first.time >= currentTime {
            return first.value
        }
        
        if currentTime >= lastKeyframe.time,
           !repeatAnimation {
            return lastKeyframe.value
        }
        
        currentTime = fmod(currentTime, lastKeyframe.time)
        let keyFramePairs = rotations.indices.dropFirst().map {
            (previous: rotations[$0 - 1], next: rotations[$0])
        }
        guard let (previousKey, nextKey) = (keyFramePairs.first {
            currentTime < $0.next.time
        })
        else { return nil }
        let interpolant =
        (currentTime - previousKey.time) /
        (nextKey.time - previousKey.time)
        
        return simd_slerp(previousKey.value, nextKey.value, interpolant)
    }
}

