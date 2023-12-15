//
//  ICB.metal
//  GPUDriven
//
//  Created by JINSEN WU on 12/15/23.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct ICBContainer {
    command_buffer icb [[id(0)]];
};

struct Model {
    constant float *vertexBuffer;
    constant float *uvBuffer;
    constant uint *indexBuffer;
    constant float *materialBuffer;
};


kernel void encodeCommands(
                           uint modelIndex [[thread_position_in_grid]], // dispatch a thread for each model, modelIndex gives the thread ppsotion, is the index into the arrays of models and model params
                           device ICBContainer *icbContainer [[buffer(ICBBuffer)]],
                           constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
                           constant Model *models [[buffer(ModelsBuffer)]],
                           constant ModelParams *modelParams [[buffer(ModelParamsBuffer)]],
                           // formulate draw call arguments using the submesh data.  Retrieve these arguments from drawArgumentsBuffer
                           constant MTLDrawIndexedPrimitivesIndirectArguments *drawArgumentsBuffer [[buffer(DrawArgumentsBuffer)]])
{
    // retrieve model and draw arguments
    Model model = models[modelIndex];
    MTLDrawIndexedPrimitivesIndirectArguments drawArguments = drawArgumentsBuffer[modelIndex];
    
    // use modelIndex to point to the appropriate command.  When we set up the indirect command buffer on swift, we indicate how many
    // commands it should expect
    render_command cmd(icbContainer->icb, modelIndex);
    
    cmd.set_vertex_buffer(&uniforms, UniformsBuffer);
    cmd.set_vertex_buffer(model.vertexBuffer, VertexBuffer);
    cmd.set_vertex_buffer(model.uvBuffer, UVBuffer);
    cmd.set_vertex_buffer(modelParams, ModelParamsBuffer);
    cmd.set_fragment_buffer(modelParams, ModelParamsBuffer);
    cmd.set_fragment_buffer(model.materialBuffer, MaterialBuffer);
    
    cmd.draw_indexed_primitives(
        primitive_type::triangle,
        drawArguments.indexCount,
        model.indexBuffer + drawArguments.indexStart,
        drawArguments.instanceCount,
        drawArguments.baseVertex,
        drawArguments.baseInstance);
}
