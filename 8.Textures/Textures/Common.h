//
//  Common.h
//  Textures
//
//  Created by JINSEN WU on 9/29/23.
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
    uint tiling;
} Params;

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2
} Attributes;

typedef enum {
    VertexBuffer = 0,
    UVBuffer = 1,
    UniformsBuffer = 11,
    ParamsBuffer = 12
} BufferIndices;

typedef enum {
    BaseColor = 0
} TextureIndices;



#endif /* Common_h */
