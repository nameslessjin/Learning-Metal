//
//  Lighting.h
//  Lighting
//
//  Created by JINSEN WU on 9/30/23.
//

#ifndef Lighting_h
#define Lighting_h

#import "Common.h"

float3 phongLighting
(
 float3 normal,
 float3 position,
 constant Params &params,
 constant Light *lights,
 Material material
 );

float calculateShadow(
                      float4 shadowPosition,
                      depth2d<float> shadowTexture);

float3 calculateSun(
                    Light light,
                    float3 normal,
                    Params params,
                    Material material);

float3 calculatePoint(
                      Light light,
                      float3 position,
                      float3 normal,
                      Material material);

float3 calculateSpot(
                     Light light,
                     float3 position,
                     float3 normal,
                     Material material);

#endif /* Lighting_h */
