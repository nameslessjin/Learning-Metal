//
//  Lighting.metal
//  Lighting
//
//  Created by JINSEN WU on 9/30/23.
//

#include <metal_stdlib>
using namespace metal;
#import "Lighting.h"

float3 calculateSun(
                    Light light,
                    float3 normal,
                    Params params,
                    Material material)
{
    float3 diffuseColor = 0;
    float3 specularColor = 0;
    float3 lightDirection = normalize(-light.position); // sun light is direct light in direction 0 - light in regular sense
    float diffuseIntensity = saturate(-dot(lightDirection, normal)); // the light direction is opposite from intersection point, saturate to 0 and 1 campling
    diffuseColor += light.color * material.baseColor * diffuseIntensity;
    
    if (diffuseIntensity > 0) {
        float3 reflection = reflect(lightDirection, normal);
        float3 viewDirection = normalize(params.cameraPosition);
        float specularIntensity = pow(saturate(dot(reflection, viewDirection)), material.shininess);
        specularColor += light.specularColor * material.specularColor * specularIntensity;
    }
    return diffuseColor + specularColor;
}

float3 calculatePoint(
                      Light light,
                      float3 position,
                      float3 normal,
                      Material material)
{
    float d = distance(light.position, position);
    float3 lightDirection = normalize(light.position - position);
    float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
    float diffuseIntensity = saturate(dot(lightDirection, normal));
    float3 color = light.color * material.baseColor * diffuseIntensity;
    color *= attenuation;
    return color;
}

float3 calculateSpot(
                     Light light,
                     float3 position,
                     float3 normal,
                     Material material)
{
    float d = distance(light.position, position);
    float3 lightDirection = normalize(light.position - position);
    
    // calculate the cos between the ray and the direction of the spot light is point
    float3 coneDirection = normalize(light.coneDirection);
    float spotResult = dot(lightDirection, - coneDirection);
    float3 color = 0;
    
    // if it is outside the cone angle, ignore the ray
    if (spotResult > cos(light.coneAngle)) {
        float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
        attenuation *= pow(spotResult, light.coneAttenuation);
        float diffuseIntensity = saturate(dot(lightDirection, normal));
        color = light.color * material.baseColor * diffuseIntensity;
        color *= attenuation;
    }
    return color;
}

float3 phongLighting
(
 float3 normal,
 float3 position,
 constant Params &params,
 constant Light *lights,
 Material material
 ) {
    float3 ambientColor = 0;
    float3 accumulatedLighting = 0;
    
    for (uint i = 0; i < params.lightCount; ++i) {
        Light light = lights[i];
        switch (light.type) {
            case Sun: {
                accumulatedLighting += calculateSun(light, normal, params, material);
                break;
            }
            case Point: {
                accumulatedLighting += calculatePoint(light, position, normal, material);
                break;
            }
            case Spot: {
                accumulatedLighting += calculateSpot(light, position, normal, material);
                break;
            }
            case Ambient: {
                ambientColor += material.baseColor * light.color;
                break;
            }
            case unused: {
                break;
            }
        }
    }
    
    return accumulatedLighting + ambientColor;
}

float calculateShadow(
                      float4 shadowPosition,
                      depth2d<float> shadowTexture)
{
    // vertex pos from the light.  The GPU performed a perspective divide before writing the fragment to the shadow texure
    // here we matches the same perspective division so that we can cmpare the current sample's depth value to the one in the shadow texture
    float3 position = shadowPosition.xyz / shadowPosition.w;
    // determine the shadow position to serve as a screen space pixel locator on the shadow texture
    // rescale the coords from [-1, 1] to [0, 1] to match the uv space, reverse Y since is it upside down
    float2 xy = position.xy;
    xy = xy * 0.5 + 0.5;
    xy.y = 1 - xy.y;
    constexpr sampler s(coord::normalized, filter::nearest, address::clamp_to_edge, compare_func::less);
    float shadow_sample = shadowTexture.sample(s, xy);
    // darken the diffuse color for pixels with a depth greather than the shadow value
    // if shadowPos.z is 0.5 and shadow sample is 0.2 then from the sun, the current fragment shadowPosition.z is further away than the stored fragment
    // since the sun can't see the fragment, it is blocked, it is in shadow
    return (position.z > shadow_sample + 0.001) ? 0.5 : 1;
}

