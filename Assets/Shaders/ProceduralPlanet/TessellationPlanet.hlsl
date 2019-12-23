#ifndef PROCEDURAL_PLANET_TESSELLATION_PLANET_INCLUDED
#define PROCEDURAL_PLANET_TESSELLATION_PLANET_INCLUDED

Varyings Vertex(Attributes input) {
    input.positionOS.xyz = normalize(input.positionOS.xyz);
    return VertexProgram(input);
}

#endif
