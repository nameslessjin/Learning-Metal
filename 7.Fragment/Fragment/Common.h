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

typedef struct {
    uint width;
    uint height;
} Params;

typedef enum {
    VertexBuffer = 0,
    UniformBuffer = 11,
    ParamsBuffer = 12
} BufferIndices;

typedef enum {
    Position = 0,
    Normal = 1
} Attributes;



#endif /* Common_h */
