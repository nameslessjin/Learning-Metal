//
//  Shaders.metal
//  Pipeline
//
//  Created by JINSEN WU on 9/25/23.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    float4 position [[attribute(0)]];
};

// the vertices are indexed in the vertex buffer.  The vertex shader gets the current vertex index via stage_in
vertex float4 vertex_main(const VertexIn vertexIn [[stage_in]])
{
    return vertexIn.position;
}

fragment float4 fragment_main()
{
    return float4(1, 0, 0, 1);
}
