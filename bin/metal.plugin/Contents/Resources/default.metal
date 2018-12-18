#include <metal_stdlib>
using namespace metal;

kernel void processimage(
    texture2d<float,access::read> src[[texture(0)]],
    texture2d<float,access::write> dst[[texture(1)]],
    uint2 gid[[thread_position_in_grid]]) {
        
    float r = src.read(gid).r;
    dst.write(float4(r,r,r,1.0),gid);

}