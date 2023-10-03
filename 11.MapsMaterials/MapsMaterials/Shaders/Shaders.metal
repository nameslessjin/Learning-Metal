//
//  Shaders.metal
//  Lighting
//
//  Created by JINSEN WU on 9/29/23.
//

#include <metal_stdlib>
using namespace metal;
#import "Common.h"
#import "Lighting.h"


struct VertexIn {
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
    float3 color [[attribute(Color)]];
    float3 tangent [[attribute((Tangent))]];
    float3 bitangent [[attribute((Bitangent))]];
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

vertex VertexOut vertex_main(const VertexIn in [[stage_in]], constant Uniforms &uniforms [[buffer(UniformsBuffer)]]) {
    float4 position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * in.position;
    VertexOut out {
        .position = position,
        .uv = in.uv,
        .color = in.color,
        .worldPosition = (uniforms.modelMatrix * in.position).xyz,
        .worldNormal = uniforms.normalMatrix * in.normal,
        .worldTangent = uniforms.normalMatrix * in.tangent,
        .worldBitangent = uniforms.normalMatrix * in.bitangent
    };
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], constant Params &params [[buffer(ParamsBuffer)]], texture2d<float> baseColorTexture [[texture(BaseColor)]], constant Light *lights [[buffer(LightBuffer)]], texture2d<float> normalTexture [[texture(NormalTexture)]], constant Material &_material [[buffer(MaterialBuffer)]]) {
    
    Material material = _material;
    
    constexpr sampler textureSampler(filter::linear, address::repeat, mip_filter::linear, max_anisotropy(8));
    
    if (!is_null_texture(baseColorTexture)) {
        material.baseColor = baseColorTexture.sample(textureSampler, in.uv * params.tiling).rgb;
    }
    
    float3 normal;
    if (is_null_texture(normalTexture)) normal = in.worldNormal;
    else {
        normal = normalTexture.sample(textureSampler, in.uv * params.tiling).rgb;
        normal = normal * 2 - 1;
        normal = float3x3(in.worldTangent, in.worldBitangent, in.worldNormal) * normal;
    }
    normal = normalize(normal);
    
    
    float3 color = phongLighting(normal, in.worldPosition, params, lights, material);
    return float4(color, 1);
}
