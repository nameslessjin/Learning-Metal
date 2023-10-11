//
//  ConvertMesh.metal
//  Metal-Rendering
//
//  Created by JINSEN WU on 10/10/23.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

// a kernel function cannot return value
kernel void convert_mesh(
                         device VertexLayout *vertices [[buffer(VertexBuffer)]],
                         uint id [[thread_position_in_grid]], /* identify thread id using thread_position_in_grid */
                         device atomic_int &vertexTotal [[buffer(1)]]
                         )
{
    // we use one thread per grid
    vertices[id].position.z = -vertices[id].position.z;
    atomic_fetch_add_explicit(&vertexTotal, 1, memory_order_relaxed);
}
