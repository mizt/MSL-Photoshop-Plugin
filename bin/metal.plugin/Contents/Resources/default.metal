#include <metal_stdlib>
using namespace metal;

kernel void processimage(
    texture2d<float,access::sample> src[[texture(0)]],
    texture2d<float,access::write> dst[[texture(1)]],
    constant float2 &resolution[[buffer(0)]],
    uint2 gid[[thread_position_in_grid]]) {
    
    float2 uv = (float2(gid)+float2(0.5))/resolution;
    
    constexpr sampler _sampler(filter::linear, coord::normalized);
    dst.write(src.sample(_sampler,uv),gid);
}
