//
//  Skybox.swift
//  ImageBasedLighting
//
//  Created by JINSEN WU on 12/5/23.
//

import MetalKit

struct Skybox {
    let mesh: MTKMesh
    var skyTexture: MTLTexture?
    let pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState?
    var diffuseTexture: MTLTexture?
    var brdfLut: MTLTexture?
    
    struct SkySettings {
        var turbidity: Float = 0.28
        var sunElevation: Float = 0.6
        var upperAtmosphereScattering: Float = 0.4
        var groundAlbedo: Float = 0.8
    }
    var skySettings = SkySettings()
    
    init(textureName: String?) {
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let cube = MDLMesh(
            boxWithExtent: [1, 1, 1],
            segments: [1, 1, 1],
            inwardNormals: true,
            geometryType: .triangles,
            allocator: allocator
        )
        do {
            mesh = try MTKMesh(mesh: cube, device: Renderer.device)
        } catch {
            fatalError("failed to create skybox mesh")
        }
        
        pipelineState = PipelineStates.createSkyboxPSO(vertexDescriptor: MTKMetalVertexDescriptorFromModelIO(cube.vertexDescriptor))
        depthStencilState = Self.buildDepthStencilState()
        
        if let textureName = textureName {
            do {
                skyTexture = try TextureController.loadCubeTexture(imageName: textureName)
                diffuseTexture = try TextureController.loadCubeTexture(imageName: "irradiance.png")
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            skyTexture = loadGeneratedSkyboxTexture(dimensions: [256, 256])
        }
        
        // brdf lookup texture
        brdfLut = Renderer.buildBRDF()
    }
    
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .lessEqual
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    func render(encoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
        encoder.pushDebugGroup("Skybox")
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState) // for correct depth comparison
        encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        
        // multiple each model's matrix with the view matrix and the projection matrix
        // when we move through the scene it is the skybox is moving
        var uniforms = uniforms
        // we don't want the skybox to move, so we remove the translation, we still want rotation
        uniforms.viewMatrix.columns.3 = [0, 0, 0, 1]
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        
        let submesh = mesh.submeshes[0]
        
        encoder.setFragmentTexture(skyTexture, index: SkyboxTexture.index)
        
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0)
        encoder.popDebugGroup()
    }
    
    func loadGeneratedSkyboxTexture(dimensions: SIMD2<Int32>) -> MTLTexture? {
        var texture: MTLTexture?
        let skyTexture = MDLSkyCubeTexture(
            name: "sky",
            channelEncoding: .float16,
            textureDimensions: dimensions,
            turbidity: skySettings.turbidity,
            sunElevation: skySettings.sunElevation,
            upperAtmosphereScattering: skySettings.upperAtmosphereScattering,
            groundAlbedo: skySettings.groundAlbedo
        )
        do {
            let textureLoader = MTKTextureLoader(device: Renderer.device)
            texture = try textureLoader.newTexture(texture: skyTexture, options: nil)
        } catch {
            print(error.localizedDescription)
        }
        return texture
    }
    
    func update(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentTexture(skyTexture, index: SkyboxTexture.index)
        encoder.setFragmentTexture(diffuseTexture, index: SkyboxDiffuseTexture.index)
        encoder.setFragmentTexture(brdfLut, index: BRDFLutTexture.index)
    }
    
    // create the diffuse irradiance texture
    mutating func loadIrradianceMap() {
        // Model I/O currently doesn't load cube textures from the asset catalog
        guard let skyCube = MDLTexture(cubeWithImagesNamed: ["cube-sky.png"])
        else { return }
        
        // use Model I/O to create the irradiance texture from the source image
        let irradiance =
        MDLTexture.irradianceTextureCube(
            with: skyCube,
            name: nil,
            dimensions: [64, 64],
            roughness: 0.6
        )
        
        let loader = MTKTextureLoader(device: Renderer.device)
        do {
            diffuseTexture = try loader.newTexture(texture: irradiance, options: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

