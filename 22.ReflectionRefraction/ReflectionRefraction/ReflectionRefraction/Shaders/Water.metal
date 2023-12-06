//
//  Water.metal
//  ReflectionRefraction
//
//  Created by JINSEN WU on 12/6/23.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn {
    float4 position [[attribute((Position))]];
    float2 uv [[attribute((UV))]];
};

struct VertexOut {
    float4 position [[position]];
    float4 worldPosition;
    float2 uv;
};

vertex VertexOut vertex_water(
                              const VertexIn in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(UniformsBuffer)]])
{
    float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    VertexOut out {
        .position = mvp * in.position,
        .uv = in.uv,
        .worldPosition = uniforms.modelMatrix * in.position
    };
    return out;
}

fragment float4 fragment_water(
                               VertexOut in [[stage_in]],
                               constant Params &params [[buffer(ParamsBuffer)]],
                               texture2d<float> reflectionTexture [[texture(0)]],
                               texture2d<float> refractionTexture [[texture(1)]],
                               texture2d<float> normalTexture [[texture(2)]],
                               constant float& timer [[buffer(3)]],
                               depth2d<float> depthMap [[texture(3)]]
                               )
{
    constexpr sampler s(filter::linear, address::repeat);
    
    // texture is only half-size when we build it
    float width = float(reflectionTexture.get_width() * 2.0);
    float height = float(reflectionTexture.get_height() * 2.0);
    float x = in.position.x / width;
    float y = in.position.y / height;
    
    // the reflection coords will use an inverted y because the reflected images is a mirror of the scene
    float2 reflectionCoords = float2(x, 1 - y);
    float2 refractionCoords = float2(x, y);
    // get texture coords and multiple them by a tiling value.  For 2.0 we get ample ripples
    // for 16, we get small ripples
    float2 uv = in.uv * 2.0;
    
    // add smoothness to depth, convert non-linear depth to a linear value
    float far = 100; // the camera's far plane
    float near = 0.1; // the camera's near plane
    float proj33 = far / (far - near);
    float proj43 = proj33 * -near;
    float depth = depthMap.sample(s, refractionCoords);
    float floorDistance = proj43 / (depth - proj33);
    depth = in.position.z;
    float waterDistance = proj43 / (depth - proj33);
    depth = floorDistance - waterDistance;
    
    // Ripple effects
    float waveStrength = 0.1; // attenuator value of the waves
    // calculate ripples by distoring the texture coordinates with timer
    float2 rippleX = float2(uv.x + timer, uv.y);
    float2 rippleY = float2(-uv.x, uv.y) + timer;
    // only grab R and G because they are U and V coordinates that determine the horizontal plane
    // where the ripples will be
    float2 ripple =
        ((normalTexture.sample(s, rippleX).rg * 2.0 - 1.0)
         + (normalTexture.sample(s, rippleY).rg * 2.0 - 1.0))
    * waveStrength;
    
    
    reflectionCoords += ripple;
    // clamp to elimiate anomalies around the margins of the screen
    reflectionCoords = clamp(reflectionCoords, 0.001, 0.999);
    
    refractionCoords += ripple;
    refractionCoords = clamp(refractionCoords, 0.001, 0.999);
    
    float3 viewVector = normalize(params.cameraPosition - in.worldPosition.xyz);
    float mixRatio = dot(viewVector, float3(0, 1, 0));

    float4 color = mix(
                       reflectionTexture.sample(s, reflectionCoords),
                       refractionTexture.sample(s, refractionCoords),
                       mixRatio);
    float4 bluishColor = float4(0.0, 0.3, 0.5, 1.0);
    color = mix(color, bluishColor, 0.3);
    color.a = clamp(depth * 0.75, 0.0, 1.0);
    return color;
}
