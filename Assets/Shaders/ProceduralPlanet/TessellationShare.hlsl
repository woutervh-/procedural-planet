#ifndef PROCEDURAL_PLANET_TESSELLATION_SHARE_INCLUDED
#define PROCEDURAL_PLANET_TESSELLATION_SHARE_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"

float _TessellationFactor;
float _TessellationFactorTriangleSize;

#define DOMAIN_PROGRAM_INTERPOLATE(fieldName) \
    input[0].fieldName * baryCoords.x + \
    input[1].fieldName * baryCoords.y + \
    input[2].fieldName * baryCoords.z;

struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

Attributes TessellationVertex(Attributes input) {
    return input;
}

TessellationFactors HullConstant(InputPatch<Attributes, 3> input) {
    float3 p0 = input[0].positionOS.xyz;
    float3 p1 = input[1].positionOS.xyz;
    float3 p2 = input[2].positionOS.xyz;

    float3 edgeTessFactors = GetScreenSpaceTessFactor(p0, p1, p2, GetWorldToHClipMatrix(), _ScreenParams, _TessellationFactorTriangleSize);
    edgeTessFactors *= _TessellationFactor;
    edgeTessFactors = max(edgeTessFactors, float3(1, 1, 1));

    float4 tessFactors = CalcTriTessFactorsFromEdgeTessFactors(edgeTessFactors);

    TessellationFactors output;
    output.edge[0] = tessFactors[0];
    output.edge[1] = tessFactors[1];
    output.edge[2] = tessFactors[2];
    output.inside = tessFactors[3];

    return output;
}

[maxtessfactor(64.0)]
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
    #ifdef TESSELLATION_INTERPOLATE_TANGENT
        attributes.tangentOS = DOMAIN_PROGRAM_INTERPOLATE(tangentOS);
    #endif
    attributes.texcoord = DOMAIN_PROGRAM_INTERPOLATE(texcoord);
    #ifdef TESSELLATION_INTERPOLATE_LIGHTMAP_UV
        attributes.lightmapUV = DOMAIN_PROGRAM_INTERPOLATE(lightmapUV);
    #endif

    return Vertex(attributes);
}

#endif
