//
//  Common.h
//  Space
//
//  Created by JINSEN WU on 9/27/23.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef struct {
  matrix_float4x4 modelMatrix;
  matrix_float4x4 viewMatrix;
  matrix_float4x4 projectionMatrix;
} Uniforms;





#endif /* Common_h */
