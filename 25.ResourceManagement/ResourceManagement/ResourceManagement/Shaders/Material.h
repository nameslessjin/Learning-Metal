//
//  Material.h
//  ResourceManagement
//
//  Created by JINSEN WU on 12/12/23.
//

#ifndef Material_h
#define Material_h

struct ShaderMaterial {
    texture2d<float> baseColorTexture [[id(BaseColor)]];
    texture2d<float> normalTexture [[id(NormalTexture)]];
    texture2d<float> roughnessTexture [[id(RoughnessTexture)]];
    texture2d<float> metallicTexture [[id(MetallicTexture)]];
    texture2d<float> aoTexture [[id(AOTexture)]];
    texture2d<float> opacityTexture [[id(OpacityTexture)]];
    Material material [[id(OpacityTexture + 1)]];
};


#endif /* Material_h */
