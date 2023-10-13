//
//  Flocking.metal
//  Flocking
//
//  Created by JINSEN WU on 10/13/23.
//

#include <metal_stdlib>
using namespace metal;

struct Boid {
    float2 position;
    float2 velocity;
};

// cohesion
constant float average = 100; // represents a smalelr group of the swarm that stays cohesive
constant float attenuation = 0.1; // a toning down factor that let you relax the cohesion rule
constant float cohesionWeight = 2.0; // the contribution made to the final cumulative behavior

// separation
constant float limit = 20; // a value that represents the proximity threshold that triggers the repulsion force
constant float separationWeight = 1.0; // the contribution made by the separation rule to the final cumulative behavior

// alignment
constant float neighbors = 8; // represents the size of the local group that determines the "desired velocity"
constant float alignmentWeight = 3.0; // the contribution made by the alignment rule to the final cumulative behavior

// escaping
constant float escapingWeight = 0.01;
constant float predatorWeight = 10.0;

// dampening
constant float dampeningWeight = 1.0f;

kernel void clearScreen(
                        texture2d<half, access::write> output [[texture((0))]],
                        uint2 id [[thread_position_in_grid]]
                        )
{
    output.write(half4(0.0, 0.0, 0.0, 1.0), id);
}

float2 cohesion(
                uint index,
                device Boid* boids,
                uint particleCount
                )
{
    // current boid
    Boid thisBoid = boids[index];
    float2 position = float2(0);
    
    // loop through all of the boids in the swarm and accumulate each boids' position
    for (uint i = 0; i < particleCount; ++i) {
        Boid boid = boids[i];
        if (i != index) {
            position += boid.position;
        }
    }
    
    // get the average position for the entire swaem
    position /= (particleCount - 1);
    
    // calculate another averaged position based on the current boid position
    // average preserves average locality
    position = (position - thisBoid.position) / average;
    return position;
}

float2 separation(
                  uint index,
                  device Boid* boids,
                  uint particleCount
                  )
{
    Boid thisBoid = boids[index];
    float2 position = float2(0);
    
    // if a boid other than the isolated one, check the distance between the current and isolated boids
    // if the distance is smaller than the threshold, update the position to keep the isolated
    // boid within a safe distance
    for (uint i = 0; i < particleCount; ++i) {
        Boid boid = boids[i];
        if (i != index) {
            if (abs(distance(boid.position, thisBoid.position)) < limit) {
                position = position - (boid.position - thisBoid.position);
            }
        }
    }
    return position;
}

float2 alignment(
                 uint index,
                 device Boid* boids,
                 uint particleCount
                 )
{
    Boid thisBoid = boids[index];
    float2 velocity = float2(0);
    
    // accumulate teach boid's velocity
    for (uint i = 0; i < particleCount; ++i) {
        Boid boid = boids[i];
        if (i != index) {
            velocity += boid.velocity;
        }
    }
    
    velocity /= (particleCount - 1);
    
    // calculate averaged velocity based on the current boid velocity and the size of the local group
    // neighbors, which preserves locality
    velocity = (velocity - thisBoid.velocity) / neighbors;
    return velocity;
}

float2 escaping(Boid predator, Boid boid) {
    // averaged position of the neighboring boids relative to the predator position
    // the final result is adjusted and negated because the escaping direction if the opposite
    // of where the predator is located
    return -predatorWeight * (predator.position - boid.position) / average;
}

float2 dampening(Boid boid) {
    float2 velocity = float2(0);
    
    // check if the velocity is larger than the separation threshold, if it does, attenuate the velocity
    // in the same direction
    if (abs(boid.velocity.x) > limit) {
        velocity.x += boid.velocity.x / abs(boid.velocity.x) * attenuation;
    }
    if (abs(boid.velocity.y) > limit) {
        velocity.y += boid.velocity.y / abs(boid.velocity.y) * attenuation;
    }
    return velocity;
}

kernel void boids(
                  texture2d<half, access::write> output [[texture(0)]],
                  device Boid *boids [[buffer(0)]],
                  constant uint& particleCount [[buffer(1)]],
                  uint id [[thread_position_in_grid]]
                  )
{
    Boid predator = boids[0]; // label the first boid as the predator
    Boid boid;
    if (id != 0) boid = boids[id];

    float2 position = boid.position;
    float2 velocity = boid.velocity;
    
    // check collision with the edges of the screen and update velocity
    if (position.x < 0 || position.x > output.get_width()) {
        velocity.x *= -1;
    }
    if (position.y < 0 || position.y > output.get_height()) {
        velocity.y *= -1;
    }
    
    // determine the cohesion vector for the current boid and then attenuate its force
    float2 cohesionVector = cohesion(id, boids, particleCount) * attenuation;
    float2 separationVector = separation(id, boids, particleCount) * attenuation;
    float2 alignmentVector = alignment(id, boids, particleCount) * attenuation;
    float2 escapingVector = escaping(predator, boid) * attenuation;
    float2 dampeningVector = dampening(boid) * attenuation;
    
    velocity += cohesionVector * cohesionWeight 
            + separationVector * separationWeight
            + alignmentVector * alignmentWeight
            + escapingVector * escapingWeight
            + dampeningVector * dampeningWeight;
    
    position += velocity;
    boid.position = position;
    boid.velocity = velocity;
    boids[id] = boid;
    
    // check collision with the edges of the screen and update velocity for predator
    if (predator.position.x < 0 || predator.position.x > output.get_width()) {
        predator.velocity.x *= -1;
    }
    if (predator.position.y < 0 || predator.position.y > output.get_height()) {
        predator.velocity.y *= -1;
    }
    predator.position += predator.velocity / 2;
    boids[0] = predator;
    
    uint2 location = uint2(position);
    half4 color = half4(1.0);
    if (id == 0) { // predator color and location
        color = half4(1.0, 0.0, 0.0, 1.0);
        location = uint2(predator.position);
    }
    output.write(color, location);
    
    // modifies the neighboring pixels around all sides of the boid which
    // causes the boid to appear larger
    output.write(color, location + uint2(-1, 1));
    output.write(color, location + uint2( 0, 1));
    output.write(color, location + uint2( 1, 1));
    output.write(color, location + uint2(-1, 0));
    output.write(color, location + uint2( 1, 0));
    output.write(color, location + uint2(-1, -1));
    output.write(color, location + uint2( 0, -1));
    output.write(color, location + uint2( 1, -1));
}

