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

struct Rectangle {
    float2 center;
    float2 size;
};

struct Ray {
    float3 origin;
    float3 direction;
};

struct Sphere {
    float3 center;
    float raidus;
};

struct Plane {
    float y;
};

struct Light {
    float3 position;
};

struct Box {
    float3 center;
    float size;
};

struct Camera {
    // look-at, requires forward direction, up direction, left vector
    float3 position;
    Ray ray{float3(0), float3(0)};
    float rayDivergence;
};

float distToSphere(Ray ray, Sphere s) {
    return length(ray.origin - s.center) - s.raidus;
};

float distToPlane(Ray ray, Plane plane) {
    return ray.origin.y - plane.y;
};

float distToBox(Ray r, Box b) {
    // offset the current ray og by the center of the box, offset the resulting distance d by the length of the box edge
    float3 d = abs(r.origin - b.center) - float3(b.size);
    
    // get the distance to the farthest edge by using max, then get the smaller value between 0 and the distance
    // if the ray is inside the box, this value will be negative, so we add the larger length between 0 and d
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float differenceOp(float d0, float d1) {
    // the second shape is subtracted from the first
    // the result of this function is a signed distance to a compound shape boundary
    // it will only be negative when inside the first shape but outside the second
    return max(d0, -d1);
}

float unionOp(float d0, float d1) {
    return min(d0, d1);
}

float distanceToRectangle(float2 point, Rectangle rectangle) {
    
    // offset the current point coors by the given rectangle center
    // calculate the signed distance to each of the two edges
    float2 distances = abs(point - rectangle.center) - rectangle.size / 2;
    
    // if those two distances are positive, calculate the distance to the corner
    // otherwise return the distance to the closer edge
    return
    all(sign(distances) > 0)
    ? length(distances)
    : max(distances.x, distances.y);
}

float distanceToScene(float2 point) {
    // create a rectangle and get the distance
    Rectangle r1 = Rectangle{float2(0.0), float2(0.3)};
    float d2r1 = distanceToRectangle(point, r1);
    
    // create a smaller rectangle and get the distance
    // the area is repeated every 0.1 point, 10th of the size of the scene using a modulo operation
    Rectangle r2 = Rectangle{float2(0.05), float2(0.04)};
    // fmod in metal use trunc instead of floor
    // we need the modulus operator to draw many small rectangles mirrored with a distance of 0.1 from each other
    float2 mod = point - 0.1 * floor(point / 0.1);
    float d2r2 = distanceToRectangle(mod, r2);
    
    // subtract the second repeated rectangle from the first rectangle and return the resulting distance
    float diff = differenceOp(d2r1, d2r2);
    return diff;
}

float getShadow(float2 point, float2 lightPos) {
    
    // get a vector from point to light
    float2 lightDir = normalize(lightPos - point);
    float shadowDistance = 0.75;
    float distAlongRay = 0.0;
    
    // divide the vector into small step
    for (int i = 0; i < 80; ++i) {
        // calculate how far along the ray we are and move along the ray by lerp
        float2 currentPoint = point + lightDir * distAlongRay;
        
        // check how far we are from the surface, test if we hit an object
        float d2scene = distanceToScene(currentPoint);
        if (d2scene <= 0.001) { return 0.0; }
        distAlongRay += d2scene;
        if (distAlongRay > shadowDistance) { break; }
    }
    return 1.0;
}

float distToScene_softshadow(Ray r) {
    
    // create a plane and calculate the distance to it from the current ray
    Plane p = Plane{0.0};
    float d2p = distToPlane(r, p);
    
    // create three spheres, one small one, and two larger ones that are concentric
    Sphere s1 = Sphere{float3(2.0), 2.0};
    Sphere s2 = Sphere{float3(0.0, 4.0, 0.0), 4.0};
    Sphere s3 = Sphere{float3(0.0, 4.0, 0.0), 3.9};
    
    // create a repeated ray that mirros the small sphere located between 0 and 4.0
    Ray repeatRay = r;
    repeatRay.origin = fract(r.origin / 4.0) * 4.0;
    
    // calculate the distance to btween three spheres
    // the small sphere is created repeatedly every 4.0 units in all directions
    float d2s1 = distToSphere(repeatRay, s1);
    float d2s2 = distToSphere(r, s2);
    float d2s3 = distToSphere(r, s3);
    
    // calculate the difference between the two large spheres first, which results in a large hollow sphere
    // then subtract the small one from it, resulting in the large sphere having holes in it
    float dist = differenceOp(d2s2, d2s3);
    dist = differenceOp(dist, d2s1);
    
    // join the result with the plane to complete the scene
    dist = unionOp(d2p, dist);
    
    return dist;
}

float distToScene(Ray r) {
    Plane p{0.0};
    float d2p = distToPlane(r, p);
    
    Sphere s1 = Sphere{float3(0.0, 0.5, 0.0), 8.0};
    Sphere s2 = Sphere{float3(0.0, 0.5, 0.0), 6.0};
    Sphere s3 = Sphere{float3(10., -5., -10.), 15.0};
    
    float d2s1 = distToSphere(r, s1);
    float d2s2 = distToSphere(r, s2);
    float d2s3 = distToSphere(r, s3);
    
    // subtract the second sphere from first sphere, resulting in a hollow sphere
    float dist = differenceOp(d2s1, d2s2);
    // subtract the third sphere from the hollow sphere to make a cross-section
    dist = differenceOp(dist, d2s3);
    
    // add a box and plane
    Box b = Box{float3(1., 1., -4.), 1.};
    float dtb = distToBox(r, b);
    dist = unionOp(dist, dtb);
    dist = unionOp(d2p, dist);
    
    return dist;
}

float3 getNormal(Ray ray) {
    // assume the ray touches the left side of a sphere situated at the origin.
    // the normal vector is (-1, 0, 0) at that contact point away from the sphere.
    // if the ray moves slightly to the right, it is inside the sphere(-0.001).
    // if it moves slightly to the left, it is outside the sphere(0.001).
    // if we subtract left from right we get -0.002, which still points to the left
    // so this is our x-coord of the normal, repeat this for Y and Z
    float2 eps = float2(0.001, 0.0);
    float3 n = float3(
                      distToScene(Ray{ray.origin + eps.xyy, ray.direction})
                      - distToScene(Ray{ray.origin - eps.xyy, ray.direction}),
                      distToScene(Ray{ray.origin + eps.yxy, ray.direction})
                      - distToScene(Ray{ray.origin - eps.yxy, ray.direction}),
                      distToScene(Ray{ray.origin + eps.yyx, ray.direction})
                      - distToScene(Ray{ray.origin - eps.yyx, ray.direction})
                      );
    
    return normalize(n);
}

float lighting(Ray ray, float3 normal, Light light) {
    
    // find the direction to the light ray
    float3 lightRay = normalize(light.position - ray.origin);
    
    // need the angle between normal and light ray
    float diffuse = max(0.0, dot(normal, lightRay));
    
    // need reflection on the surface, depends on the looking direction which is ray.direction
    float3 refectedRay = reflect(ray.direction, normal);
    float specular = max(0.0, dot(refectedRay, lightRay));
    
    specular = pow(specular, 200.0);
    return diffuse + specular;
}

float shadow(Ray ray, Light light, float k) {
    // find the light's direction and length to the intersection point
    float3 lightDir = light.position - ray.origin;
    float lightDist = length(lightDir);
    lightDir = normalize(lightDir);
    
    // white light and eps tells how much wider the beam is
    float l = 1.0;
    float eps = 0.1;
    
    // move ray to light in small steps
    float distAlongRay = eps * 2.0;
    for (int i = 0; i < 100; ++i) {
        Ray lightRay = Ray{ray.origin + lightDir * distAlongRay, lightDir};
        float dist = distToScene(lightRay);
        
        // compute the light, this gives the percentage of beam coveraged
        // invert it so we get the percentages of beam in the light
        // take min value to preserve the darkest shadow
        l = min(l, 1.0 - (eps - dist) / eps);
        
        // k is attenuator
        // moving along the ray and increase the beam width
        distAlongRay += dist * 0.5;
        eps += dist * k;
        
        // if we go along the light ray, pass it and did not intersection with anything
        if (distAlongRay > lightDist) { break; }
    }
    return max(l, 0.0);
}

float ao(float3 pos, float3 n) {
    
    // cone tracing
    // eps is both the cone radius and the distance from the surface
    float eps = 0.01;
    
    // move a way a bit to avoid hitting surfaces we are moving away from
    pos += n * eps * 2.0;
    
    // scene is initially white
    float occlusion = 0.0;
    
    
    for (float i = 1.0; i < 10.0; ++i) {
        // get the scene distance, double the cone radius so we know how much of the cone is occluded
        float d = distToScene(Ray{pos, float3(0)});
        float coneWidth = 2.0 * eps;
        
        // eliminate negative values for the light
        float occlusionAmount = max(coneWidth - d, 0.);
        
        // get the ratio of occlusion scaled by the cone width
        float occlusionFactor = occlusionAmount / coneWidth;
        
        // set a lower impact for more distant occluders
        occlusionFactor *= 1.0 - (i / 10.0);
        
        // preserve the highest occlusion value so far
        occlusion = max(occlusion, occlusionFactor);
        
        // double size/distance, move along the normal by it
        eps *= 2.0;
        pos += n * eps;
    }
    
    // return how much light reaches this point
    return max(0.0, 1.0 - occlusion);
}

Camera setupCam(float3 pos, float3 target, float fov, float2 uv, int x) {
    
    uv *= fov;
    // calculate camera forward
    float3 cw = normalize(target - pos);
    // temporary up vector
    float3 cp = float3(0.0, 1.0, 0.0);
    // left vector
    float3 cu = normalize(cross(cw, cp));
    // correct up vector
    float3 cv = normalize(cross(cu, cw));
    // create a ray at the given og, use left for X, up for Y and forward for Z
    Ray ray = Ray{pos, normalize(uv.x * cu + uv.y * cv + 0.5 * cw)};
    
    // create a camera using the ray, the ray divergence represents the width of the cone
    // x is the number of pixels inside fov (if view is 60 wide, contains 60 pxiels, each pixel is 1 degree)
    Camera cam = Camera{pos, ray, fov / float(x)};
    
    return cam;
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
  float4 color = float4(0.9, 0.9, 0.8, 1.0);

  // Edit start
    // hard shadow
//    float d2scene = distanceToScene(uv);
//    bool inside = d2scene < 0.0;
//    color = inside ? float4(0.8, 0.5, 0.5, 1.0) : float4(0.9, 0.9, 0.8, 1.0);
//
//    // animated light position
//    float2 lightPos = 2.8 * float2(sin(time), cos(time));
//    float dist2light = length(lightPos - uv); // distance from any point to light
//    color *= max(0.3, 2.0 - dist2light);
//    
//    float shadow = getShadow(uv, lightPos);
//    color *= 2;
//    color *= shadow * .5 + .5;
    
    
//    // Soft shadow
//    color = 0;
//    uv.y = -uv.y;
//    
//    // create a ray to travel with inside the scene
//    Ray ray = Ray{float3(0., 4., -12.), normalize(float3(uv, 1.))};
//    
//    bool hit = false;
//    
//    // divde the ray into small steps
//    for(int i = 0; i < 200; ++i) {
//        
//        // calculate the new distance to the scene
//        float dist = distToScene(ray);
//        
//        // if hit an object, break out of the loop
//        if (dist < 0.001) {
////            color = 1.0;
//            hit = true;
//            break;
//        }
//        
//        // move along the ray by the distance to the scene to find the point in space we are sampling at
//        ray.origin += ray.direction * dist;
//    }
//    
//    float3 col = 1.0;
//    
//    if (!hit) {
//        // background color
//        col = float3(0.5, 0.5, 0.8);
//    } else {
//        // get the normal so that we can calculate the color
//        float3 n = getNormal(ray);
//        Light light = Light{float3(sin(time) * 10.0, 5.0, cos(time) * 10.0)};
//        
//        float l = lighting(ray, n, light);
//        float s = shadow(ray, light, 0.3);
//        
//        soft shadow
//        col = col * l * s;
//    }
//    
//    // add another fixed light source in front of the scene
//    Light light2 = Light{ float3(0.0, 5.0, -15.0)};
//    float3 lightRay = normalize(light2.position - ray.origin);
//    float fl = max(0.0, dot(getNormal(ray), lightRay) / 2.0);
//    
//    col = col + fl;
//    color = float4(col, 1.0);

    // ao
    color = 0;
    uv.y = -uv.y;
    
    // create a ray to travel with inside the scene
    float3 camPos = float3(sin(time) * 10., 3., cos(time) * 10.);
    Camera cam = setupCam(camPos, float3(0), 1.25, uv, width);
    Ray ray = cam.ray;
    
    bool hit = false;
    
    // divde the ray into small steps
    for(int i = 0; i < 200; ++i) {
        
        // calculate the new distance to the scene
        float dist = distToScene(ray);
        
        // if hit an object, break out of the loop
        if (dist < 0.001) {
            hit = true;
            break;
        }
        
        // move along the ray by the distance to the scene to find the point in space we are sampling at
        ray.origin += ray.direction * dist;
    }
    
    float3 col = 1.0;
    
    if (!hit) {
        // background color
        col = float3(0.5, 0.5, 0.8);
    } else {
        // get the normal so that we can calculate the color
        float3 n = getNormal(ray);

        float o = ao(ray.origin, n);
        col = col * o;
        
    }
    
    color = float4(col, 1.0);
    
    
  // Edit end
  output.write(color, gid);
}
