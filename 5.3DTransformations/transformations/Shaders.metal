//
//  Shaders.metal
//  transformations
//
//  Created by JINSEN WU on 9/26/23.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main (VertexIn in [[stage_in]], constant float4x4 &matrix [[buffer(11)]]) {
    float4 translation = matrix * float4(in.position.xyz, 1);
    VertexOut out {
        .position = translation
    };
    return out;
}

fragment float4 fragment_main (constant float4 &color [[buffer(0)]]) {
    return color;
}
