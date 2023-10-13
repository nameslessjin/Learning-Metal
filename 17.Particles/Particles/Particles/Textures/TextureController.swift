//
//  TextureController.swift
//  Particles
//
//  Created by JINSEN WU on 10/11/23.
//

import MetalKit

enum TextureController {
    static var textures: [String: MTLTexture] = [:]
    
    static func texture(filename: String) -> MTLTexture? {
        if let texture = textures[filename] { return texture }
        let texture = try? loadTexture(filename: filename)
        if texture != nil { textures[filename] = texture }
        return texture
    }
    
    // load textuer from filename
    static func loadTexture(filename: String) throws -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        
        if let texture = try? textureLoader.newTexture(
            name: filename,
            scaleFactor: 1.0,
            bundle: Bundle.main,
            options: nil
        ) {
            print("loaded texture: \(filename)")
            return texture
        }
        
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .SRGB: false,
            .generateMipmaps: NSNumber(value: true)
        ]
        let fileExtension = URL(fileURLWithPath: filename).pathExtension.isEmpty ? "png" : nil
        
        guard let url = Bundle.main.url(
            forResource: filename, withExtension: fileExtension
        ) else {
            print("Failed to load \(filename)")
            return nil
        }
        let texture = try textureLoader.newTexture(URL: url, options: textureLoaderOptions)
        print("loaded texture: \(url.lastPathComponent)")
        return texture
    }
    
    // load from USDZ file
    static func loadTexture(texture: MDLTexture) throws -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .SRGB: false,
            .generateMipmaps: NSNumber(booleanLiteral: true)
        ]
        let texture = try? textureLoader.newTexture(texture: texture, options: textureLoaderOptions)
        print("loaded texture from MDLTexture")
        if texture != nil {
            let filename = UUID().uuidString
            textures[filename] = texture
        }
        return texture
    }
}
