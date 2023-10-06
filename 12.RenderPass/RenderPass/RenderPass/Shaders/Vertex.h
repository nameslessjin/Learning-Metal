//
//  Vertex.h
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/4/23.
//

#ifndef Vertex_h
#define Vertex_h
#import "Common.h"

struct VertexIn {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
    float3 color [[attribute(Color)]];
    float3 tangent [[attribute(Tangent)]];
    float3 bitangent [[attribute(Bitangent)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float3 color;
    float3 worldPosition;
    float3 worldNormal;
    float3 worldTangent;
    float3 worldBitangent;
};


#endif /* Vertex_h */
