//
//  Shaders.metal
//  Lighting
//
//  Created by JINSEN WU on 9/29/23.
//

#include <metal_stdlib>
using namespace metal;
#import "Lighting.h"


struct VertexIn {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
    float3 color [[attribute(Color)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float3 color;
    float3 worldPosition;
    float3 worldNormal;
};

vertex VertexOut vertex_main(const VertexIn in [[stage_in]], constant Uniforms &uniforms [[buffer(UniformsBuffer)]]) {
    float4 position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * in.position;
    VertexOut out {
        .position = position,
        .uv = in.uv,
        .color = in.color,
        .worldPosition = (uniforms.modelMatrix * in.position).xyz,
        .worldNormal = uniforms.normalMatrix * in.normal
    };
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant Params &params [[buffer(ParamsBuffer)]], texture2d<float> baseColorTexture [[texture(BaseColor)]], constant Light *lights [[buffer(LightBuffer)]]) {
    constexpr sampler textureSampler(filter::linear, address::repeat, mip_filter::linear, max_anisotropy(8));
    
    float3 baseColor;
    if (is_null_texture(baseColorTexture)) {
        baseColor = in.color;
    } else {
        baseColor = baseColorTexture.sample(textureSampler, in.uv * params.tiling).rgb;
    }
    
    float3 normalDirection = normalize(in.worldNormal);
    float3 color = phongLighting(normalDirection, in.worldPosition, params, lights, baseColor);
    return float4(color, 1);
}

