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
 float3 baseColor
 );

#endif /* Lighting_h */
