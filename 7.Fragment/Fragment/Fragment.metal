//
//  Fragment.metal
//  Fragment
//
//  Created by JINSEN WU on 9/27/23.
//

#include <metal_stdlib>
using namespace metal;
#import "Common.h"
#import "ShaderDefs.h"


fragment float4 fragment_main(VertexOut in [[stage_in]], constant Params &params [[buffer(ParamsBuffer)]]) {
    
    float4 sky = float4(0.34, 0.9, 1.0, 1.0);
    float4 earth = float4(0.29, 0.58, 0.2, 1.0);
    float intensity = in.normal.y * 0.5 + 0.5;
    
    return mix(earth, sky, intensity);
}
