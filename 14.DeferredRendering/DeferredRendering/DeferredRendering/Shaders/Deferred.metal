//
//  Deferred.metal
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/6/23.
//

#include <metal_stdlib>
using namespace metal;


#import "Vertex.h"
#import "Lighting.h"
#import "Common.h"

struct GBufferOut {
    float4 albedo [[color(RenderTargetAlbedo)]];
    float4 normal [[color(RenderTargetNormal)]];
    float4 position [[color(RenderTargetPosition)]];
};

constant float3 vertices[6] = {
    float3(-1,  1, 0),       // triangle 1
    float3( 1, -1, 0),
    float3(-1, -1, 0),
    float3(-1,  1, 0),       // triangle 2
    float3( 1,  1, 0),
    float3( 1, -1, 0)
};

struct PointLightIn {
    float4 position [[attribute(Position)]]; // only use the vertex descriptor's position attribute
};

struct PointLightOut {
    float4 position [[position]]; // send this to rasterizer
    uint instanceId [[flat]]; // send this to rasterizer as well but we don't wanto rasterizer interpolation
};

vertex VertexOut vertex_quad(uint vertexID [[vertex_id]]) {
    VertexOut out {
        .position = float4(vertices[vertexID], 1)
    };
    return out;
}

fragment float4 fragment_deferredSun(
                                     VertexOut in [[stage_in]],
                                     constant Params &params [[buffer(ParamsBuffer)]],
                                     constant Light *lights [[buffer(LightBuffer)]],
                                     texture2d<float> albedoTexture [[texture(BaseColor)]],
                                     texture2d<float> normalTexture [[texture(NormalTexture)]],
                                     texture2d<float> positionTexture [[texture(PositionTexture)]])
{
    // the quad is the same size as the screen, in.position matches the screen position, we can use it as coords
    uint2 coord = uint2(in.position.xy);
    float4 albedo = albedoTexture.read(coord);
    float3 normal = normalTexture.read(coord).xyz;
    float3 position = positionTexture.read(coord).xyz;
    
    Material material {
        .baseColor = albedo.xyz,
        .specularColor = float3(0),
        .shininess = 500
    };
    float3 color = phongLighting(normal, position, params, lights, material);
    color *= albedo.a; // this is the shadow where is stored in alpha
    return float4(color, 1);
}

fragment GBufferOut fragment_gBuffer(
                                 VertexOut in [[stage_in]],
                                 depth2d<float> shadowTexture [[texture(ShadowTexture)]],
                                 constant Material &material [[buffer(MaterialBuffer)]])
{
    GBufferOut out;
    // set the albedo texture to the material base color
    out.albedo = float4(material.baseColor, 1.0);
    // calculate whether the fragment is in shadow
    out.albedo.a = calculateShadow(in.shadowPosition, shadowTexture);
    // write normal and position to texture
    out.normal = float4(normalize(in.worldNormal), 1.0);
    out.position = float4(in.worldPosition, 1.0);
    
    return out;
}


vertex PointLightOut vertex_pointLight(
                                       PointLightIn in [[stage_in]],
                                       constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                                       constant Light *lights [[buffer(LightBuffer)]],
                                       uint instanceId [[instance_id]]) // detect the current instance
{
    float4 lightPosition = float4(lights[instanceId].position, 0); // index lights with instanceId
    float4 position = uniforms.projectionMatrix * uniforms.viewMatrix * (in.position + lightPosition); // just translation to lightPosition
    PointLightOut out {
        .position = position,
        .instanceId = instanceId
    };
    return out;
}

fragment float4 fragment_pointLight(
                                    PointLightOut in [[stage_in]],
                                    texture2d<float> normalTexture [[texture(NormalTexture)]],
                                    texture2d<float> positionTexture [[texture(PositionTexture)]],
                                    constant Light *lights [[buffer(LightBuffer)]])
{
    Light light = lights[in.instanceId];
    uint2 coords = uint2(in.position.xy);
    float3 normal = normalTexture.read(coords).xyz;
    float3 position = positionTexture.read(coords).xyz;
    
    Material material {
        .baseColor = 1
    };
    
    float3 lighting = calculatePoint(light, position, normal, material);
    lighting *= 0.5; // reduce the intensity as blending will make the lights brighter
    return float4(lighting, 1);
}
