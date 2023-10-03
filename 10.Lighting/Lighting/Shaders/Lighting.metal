//
//  Lighting.metal
//  Lighting
//
//  Created by JINSEN WU on 9/30/23.
//

#include <metal_stdlib>
using namespace metal;
#import "Lighting.h"

float3 phongLighting
(
 float3 normal,
 float3 position,
 constant Params &params,
 constant Light *lights,
 float3 baseColor
 ) {
    float3 diffuseColor = 0;
    float3 ambientColor = 0;
    float3 specularColor = 0;
    float materialShininess = 32;
    float3 materialSpecularColor = float3(1, 1, 1);
    
    for (uint i = 0; i < params.lightCount; ++i) {
        Light light = lights[i];
        switch (light.type) {
            case Sun: {
                float3 lightDirection = normalize(-light.position); // sun light is direct light in direction 0 - light in regular sense
                float diffuseIntensity = saturate(-dot(lightDirection, normal)); // the light direction is opposite from intersection point, saturate to 0 and 1 campling
                diffuseColor += light.color * baseColor * diffuseIntensity;
                
                if (diffuseIntensity > 0) {
                    float3 reflection = reflect(lightDirection, normal);
                    float3 viewDirection = normalize(params.cameraPosition);
                    float specularIntensity = pow(saturate(dot(reflection, viewDirection)), materialShininess);
                    specularColor += light.specularColor * materialSpecularColor * specularIntensity;
                }
                break;
            }
            case Point: {
                float d = distance(light.position, position);
                float3 lightDirection = normalize(light.position - position);
                float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
                float diffuseIntensity = saturate(dot(lightDirection, normal));
                float3 color = light.color * baseColor * diffuseIntensity;
                color *= attenuation;
                diffuseColor += color;
                break;
            }
            case Spot: {
                float d = distance(light.position, position);
                float3 lightDirection = normalize(light.position - position);
                
                // calculate the cos between the ray and the direction of the spot light is point
                float3 coneDirection = normalize(light.coneDirection);
                float spotResult = dot(lightDirection, -coneDirection);
                
                // if it is outside the cone angle, ignore the ray
                if (spotResult > cos(light.coneAngle)) {
                    float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
                    attenuation *= pow(spotResult, light.coneAttenuation);
                    float diffuseIntensity = saturate(dot(lightDirection, normal));
                    float3 color = light.color * baseColor * diffuseIntensity;
                    color *= attenuation;
                    diffuseColor += color;
                }
                break;
            }
            case Ambient: {
                ambientColor += light.color;
                break;
            }
            case unused: {
                break;
            }
        }
    }
    
    return diffuseColor + ambientColor + specularColor;
}
