//
//  Common.h
//  Lighting
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
    matrix_float3x3 normalMatrix; // normal matrix in world space
    matrix_float4x4 shadowProjectionMatrix;
    matrix_float4x4 shadowViewMatrix;
} Uniforms;

typedef struct {
    uint width;
    uint height;
    uint tiling;
    uint lightCount;
    vector_float3 cameraPosition;
    uint objectId;
    uint touchX;
    uint touchY;
} Params;

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2,
    Color = 3,
    Tangent = 4,
    Bitangent = 5
} Attributes;

typedef enum {
    VertexBuffer = 0,
    UVBuffer = 1,
    ColorBuffer = 2,
    TangentBuffer = 3,
    BitangentBuffer = 4,
    UniformsBuffer = 11,
    ParamsBuffer = 12,
    LightBuffer = 13,
    MaterialBuffer = 14
} BufferIndices;

typedef enum {
    BaseColor = 0,
    NormalTexture = 1,
    RoughnessTexture = 2,
    MetallicTexture = 3,
    AOTexture = 4,
    ShadowTexture = 5,
    PositionTexture = 6,
    IDTexure = 11,
} TextureIndices;

typedef enum {
    unused = 0,
    Sun = 1,
    Spot = 2,
    Point = 3,
    Ambient = 4
} LightType;

typedef struct {
    LightType type;
    vector_float3 position;
    vector_float3 color;
    vector_float3 specularColor;
    vector_float3 attenuation;
    vector_float3 coneDirection;
    float radius;
    float coneAngle;
    float coneAttenuation;
} Light;

typedef struct {
    vector_float3 baseColor;
    vector_float3 specularColor;
    float roughness;
    float metallic;
    float ambientOcclusion;
    float shininess;
} Material;

typedef enum {
    RenderTargetAlbedo = 1,
    RenderTargetNormal = 2,
    RenderTargetPosition = 3
} RenderTargetIndices;

#endif /* Common_h */
