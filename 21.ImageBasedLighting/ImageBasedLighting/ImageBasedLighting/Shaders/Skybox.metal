//
//  Skybox.metal
//  ImageBasedLighting
//
//  Created by JINSEN WU on 12/5/23.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn {
    float4 position [[attribute(Position)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 textureCoordinates;
};

vertex VertexOut vertex_skybox(
                               const VertexIn in [[stage_in]],
                               constant Uniforms &uniforms [[buffer(UniformsBuffer)]])
{
    VertexOut out;
    float4x4 vp = uniforms.projectionMatrix * uniforms.viewMatrix;
    out.position = (vp * in.position).xyww; // use xyww instead of xyzw to place the sky as far away as possible at the edge of NDC
    // during clips space to NDC, all coords are divided by w, so the z will be 1 which will ensure that the skybox renders behind everything else within the scene
    out.textureCoordinates = in.position.xyz;
    return out;
}

fragment half4 fragment_skybox(
                               VertexOut in [[stage_in]],
                               texturecube<half> cubeTexture [[texture(SkyboxTexture)]])
{
    constexpr sampler default_sampler(filter::linear);
    half4 color = cubeTexture.sample(default_sampler, in.textureCoordinates);
    return color;
}

