#ifndef PROCEDURAL_PLANET_TESSELLATION_PLANET_VERTEX_INCLUDED
#define PROCEDURAL_PLANET_TESSELLATION_PLANET_VERTEX_INCLUDED

#include "Noise.hlsl"

Varyings Vertex(Attributes input) {
    float3 pointOnUnitSphere = normalize(input.positionOS.xyz);
    float4 noiseSample = noise(pointOnUnitSphere);
    input.positionOS.xyz = pointOnUnitSphere * noiseSample.w;
    input.normalOS = pointOnUnitSphere;
    return VertexProgram(input);
}

#endif
