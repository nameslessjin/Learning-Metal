//
//  Fireworks.metal
//  Particles
//
//  Created by JINSEN WU on 10/11/23.
//

#include <metal_stdlib>
using namespace metal;
#import "Common.h"

kernel void clearScreen(
                        texture2d<half, access::write> output [[texture(0)]], /* specify need for write access */
                        uint2 id [[thread_position_in_grid]]) /* thread id, in this case is thread per pixel*/
{
    output.write(half4(0.0, 0.0, 0.0, 1.0), id);
}

kernel void fireworks(
                      texture2d<half, access::write> output [[texture((0))]],
                      device Particle *particles [[buffer(0)]],
                      uint id [[thread_position_in_grid]] // 1d index for particle
                      )
{
    // compute velocity
    float xVelocity = particles[id].speed * cos(particles[id].direction);
    float yVelocity = particles[id].speed * sin(particles[id].direction) + 3.0;
    
    // update position
    particles[id].position.x += xVelocity;
    particles[id].position.y += yVelocity;
    
    // compute color based on life
    particles[id].life -= 1.0f;
    half4 color;
    color = half4(particles[id].color) * particles[id].life / 255.0;
    color.a = 1.0;
    
    // update color at the curernt position as well as its neighboring particles
    // to create the look and feel of a thicker particle
    uint2 position = uint2(particles[id].position);
    output.write(color, position);
    output.write(color, position + uint2(0, 1));
    output.write(color, position - uint2(0, 1));
    output.write(color, position + uint2(1, 0));
    output.write(color, position - uint2(1, 0));
    
}

