
#include <metal_stdlib>
using namespace metal;

struct PassthroughVertex {
    float x;
    float y;
    float z;
    float u;
    float v;
};

struct PassthroughVertexOut {
    float4 position [[position]];
    float2 textureCoordinates;
};

vertex PassthroughVertexOut vertex_passthrough(
    device const PassthroughVertex *vertices [[buffer(0)]],
    uint id [[vertex_id]]
) {
    PassthroughVertex in = vertices[id];
    PassthroughVertexOut out;
    out.position = float4(in.x, in.y, in.z, 1.0);
    out.textureCoordinates = float2(in.u, in.v);
    return out;
}

fragment float4 fragment_passthrough(
    PassthroughVertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]],
    sampler sam [[sampler(0)]]
) {
    return tex.sample(sam, in.textureCoordinates);
}