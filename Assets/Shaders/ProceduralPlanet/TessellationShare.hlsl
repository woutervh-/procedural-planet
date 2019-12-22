#ifndef PROCEDURAL_PLANET_TESSELLATION_SHARE_INCLUDED
#define PROCEDURAL_PLANET_TESSELLATION_SHARE_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"

#define DOMAIN_PROGRAM_INTERPOLATE(fieldName) \
    input[0].fieldName * baryCoords.x + \
    input[1].fieldName * baryCoords.y + \
    input[2].fieldName * baryCoords.z;

struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

TessellationFactors HullConstant(InputPatch<Attributes, 3> input) {
    float4 p0 = input[0].positionOS;
    float4 p1 = input[1].positionOS;
    float4 p2 = input[2].positionOS;

    // Choose something from: https://github.com/Unity-Technologies/ScriptableRenderPipeline/blob/dc09aba6a4cbd997f11e32a51881bf91d1b55b5e/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HullConstant")]
[outputcontrolpoints(3)]
Attributes Hull(InputPatch<Attributes, 3> input, uint id : SV_OutputControlPointID) {
    return input[id];
}

[domain("tri")]
Varyings Domain(TessellationFactors tessFactors, const OutputPatch<Attributes, 3> input, float3 baryCoords : SV_DomainLocation) {
    Attributes attributes;
    attributes.positionOS = DOMAIN_PROGRAM_INTERPOLATE(positionOS);
    attributes.normalOS = DOMAIN_PROGRAM_INTERPOLATE(normalOS);
    attributes.tangentOS = DOMAIN_PROGRAM_INTERPOLATE(tangentOS);
    attributes.texcoord = DOMAIN_PROGRAM_INTERPOLATE(texcoord);
    attributes.lightmapUV = DOMAIN_PROGRAM_INTERPOLATE(lightmapUV);

    return VertexProgram(attributes);
}

#endif
