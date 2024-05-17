
#include <metal_stdlib>
using namespace metal;

// MARK: - Passthrough

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

// MARK: - Terrain

struct BlockVertex {
    float x;
    float y;
    float z;
    float u;
    float v;
    float r;
    float g;
    float b;
    float a;
};

struct BlockVertexOut {
    float4 position [[position]];
    float2 textureCoordinates;
};

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
};

vertex BlockVertexOut vertex_terrain(
    device const BlockVertex *vertices [[buffer(0)]],
    uint id [[vertex_id]],
    constant Uniforms &uniforms [[buffer(1)]]
) {
    BlockVertex in = vertices[id];
    BlockVertexOut out;
    out.position = uniforms.modelViewProjectionMatrix * float4(in.x, in.y, in.z, 1.0);
    out.textureCoordinates = float2(in.u, in.v);
    return out;
}

fragment float4 fragment_terrain(
    BlockVertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]],
    sampler sam [[sampler(0)]]
) {
    return tex.sample(sam, in.textureCoordinates);
}
