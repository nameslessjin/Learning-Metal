///// Copyright (c) 2023 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

#include <metal_stdlib>
using namespace metal;

struct Sphere {
    float3 center;
    float radius;
    Sphere(float3 c, float r) {
        center = c;
        radius = r;
    }
};

struct Ray {
    float3 origin;
    float3 direction;
    Ray(float3 o, float3 d) {
        origin = o;
        direction = d;
    }
};

// for ground
struct Plane {
    float y;
    Plane(float y) {
        this->y = y;
    }
};

// for ground
float distanceToPlane(Ray ray, Plane plane) {
    return ray.origin.y - plane.y;
}

float distanceToSphere(Ray r, Sphere s) {
    return length(r.origin - s.center) - s.radius;
};

float distanceToScene(Ray r, Sphere s, float range) {
    Ray repeatRay = r; // make a local copy of ray
    // by using fmod, we effectively repeat the space throughout the entire screen
    // this creates an infinite number of spheres, each with its own ray
    repeatRay.origin = fmod(r.origin, range);
    return distanceToSphere(repeatRay, s);
}

float distanceToScene(Ray r, Plane p) {
    return distanceToPlane(r, p);
}

float randomNoise(float2 p) {
    // the values used here are all prime numbers because they are guaranteed not to return the same fractional part
    return fract(6791.0 * sin(47.0 * p.x + 9973.0 * p.y));
}

float smoothNoise(float2 p) {
    // store the coords of pixels
    float2 north = float2(p.x, p.y + 1.0);
    float2 east = float2(p.x + 1.0, p.y);
    float2 south = float2(p.x, p.y - 1.0);
    float2 west = float2(p.x - 1.0, p.y);
    float2 center = float2(p.x, p.y);
    
    // calculate value noise for each coords and divide it by its convolution weight
    // add each of these values to the total noise value sum
    float sum = 0.0;
    sum += randomNoise(north) / 8.0;
    sum += randomNoise(east) / 8.0;
    sum += randomNoise(south) / 8.0;
    sum += randomNoise(west) / 8.0;
    sum += randomNoise(center) / 2.0;
    
    return sum;
}

float interpolatedNoise(float2 p) {
    
    // sample the value noise in each of the four corners of the tile
    float q11 = smoothNoise(float2(floor(p.x), floor(p.y)));
    float q12 = smoothNoise(float2(floor(p.x), ceil(p.y)));
    float q21 = smoothNoise(float2(ceil(p.x), floor(p.y)));
    float q22 = smoothNoise(float2(ceil(p.x), ceil(p.y)));
    
    // use smoothstep for cubic interpolation, mix the corner colors to get the R and P colors
    float2 ss = smoothstep(0.0, 1.0, fract(p));
    float r1 = mix(q11, q21, ss.x);
    float r2 = mix(q12, q22, ss.x);
    return mix(r1, r2, ss.y);
}

float fbm(float2 uv, float steps) {
    float sum = 0;
    float amplitude = 0.8;
    
    // at each step, compute the value noise attenuated by amplitude and add it to the sum
    // update both the location and amplitude values
    for (int i = 0; i < steps; ++i) {
        sum += interpolatedNoise(uv) * amplitude;
        uv += uv * 1.2;
        amplitude *= 0.4;
    }
    return sum;
}

kernel void compute(
  texture2d<float, access::write> output [[texture(0)]],
  constant float &time [[buffer(0)]],
  uint2 gid [[thread_position_in_grid]])
{
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  float4 color = float4(0.41, 0.61, 0.86, 1.0);

  // Edit start
//    color = 0.0;
//    Sphere s = Sphere(float3(1.0), 0.5);
//    // X and Y move the sphere in a circular pattern while Z moves it more into the screen
//    float3 cameraPosition = float3(1000.0 + sin(time) + 1.0, 1000.0 + cos(time) + 1.0, time);
//    Ray ray = Ray(cameraPosition, normalize(float3(uv, 1.0)));
//    
//    // loop enough times to get acceptable precision
//    for (int i = 0; i < 100; i++) {
//        float distance = distanceToScene(ray, s, 2.0);
//        if (distance < 0.001) {
//            color = float4(1.0);
//            break;
//        }
//        ray.origin += ray.direction * distance;
//    }
//    // multiply the color with the ray's current position, which is offset by 1000 to match its initial origin
//    // divide by 10.0 to scale down the result, use abs to guard against negative values
//    float3 positionToCamera = ray.origin - cameraPosition;
//    color *= float4(abs(positionToCamera / 10.0), 1.0);
    
    float tiles = 4.0;
    float2 noise = uv;
    noise.x += time * 0.1; // add time to x attenuated by 0.1 for animation
    noise *= tiles;
    float3 clouds = float3(fbm(noise, tiles));
    color = float4(clouds, 1);

    // set the colors for land and sky
    float3 land = float3(0.3, 0.2, 0.2);
    float3 sky = float3(0.4, 0.6, 0.8);
    clouds *= sky * 3.0; // add sky color to the noise for a bluish effect
    
    // reverse y since image is upside down
    uv.y = -uv.y;
    Ray ray = Ray(float3(0.0, 4.0, -12.0), normalize(float3(uv, 1.0)));
    Plane plane = Plane(0.0);
    
    // apply the ray matching algorithm 
    for (int i = 0; i < 100; ++i) {
        float distance = distanceToScene(ray, plane);
        if (distance < 0.001) {
            clouds = land;
            break;
        }
        ray.origin += ray.direction * distance;
    }
    color = float4(clouds, 1);
    
  // Edit end

  output.write(color, gid);
}
