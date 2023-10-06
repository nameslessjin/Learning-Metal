//
//  ObjectId.metal
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/5/23.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct FragmentOut {
    uint objectId [[color(0)]]; // color attachment 0 contains the object ID texture
};


fragment FragmentOut fragment_objectId(constant Params &params [[buffer(ParamsBuffer)]]) {
    FragmentOut out {
        .objectId = params.objectId
    };
    
    return out;
}

