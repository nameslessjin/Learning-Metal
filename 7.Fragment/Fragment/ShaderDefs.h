//
//  ShaderDefs.h
//  Fragment
//
//  Created by JINSEN WU on 9/29/23.
//

#ifndef ShaderDefs_h
#define ShaderDefs_h


#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]]; // special attribute qualifier that represents the clip-space position of the vertex
    float3 normal;
};

#endif /* ShaderDefs_h */
