//
//  Shaders.metal
//  Textures
//
//  Created by JINSEN WU on 9/29/23.
//

#include <metal_stdlib>
using namespace metal;
#import "Common.h"

struct VertexIn {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute((UV))]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float2 uv;
};

vertex VertexOut vertex_main(const VertexIn in [[stage_in]], constant Uniforms &uniforms [[buffer(UniformsBuffer)]]) {
    float4 position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * in.position;
    float3 normal = in.normal;
    VertexOut out {
        .position = position,
        .normal = normal,
        .uv = in.uv
    };
    return out;
}

fragment float4 fragment_main(constant Params &params [[buffer(ParamsBuffer)]], VertexOut in [[stage_in]], texture2d<float> baseColorTexture [[texture(BaseColor)]]) {
    constexpr sampler textureSampler(mip_filter::linear, address::repeat, max_anisotropy(8));
    float3 baseColor = baseColorTexture.sample(textureSampler, in.uv * params.tiling).rgb;
    return float4(baseColor, 1);
}
