#if !defined(NOISE_TESSELLATION_INCLUDED)
#define NOISE_TESSELLATION_INCLUDED

#define DOMAIN_PROGRAM_INTERPOLATE(fieldName) \
    patch[0].fieldName * barycentricCoordinates.x + \
    patch[1].fieldName * barycentricCoordinates.y + \
    patch[2].fieldName * barycentricCoordinates.z;

float _TessellationEdgeLength;

struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

TessellationFactors PatchConstantFunction (InputPatch<TESSELLATION_VERTEX_DATA, 3> patch) {
    float4 p0 = patch[0].vertex;
    float4 p1 = patch[1].vertex;
    float4 p2 = patch[2].vertex;

    TessellationFactors f;
    // float3 tessellation = UnityEdgeLengthBasedTessCull(p0, p1, p2, _TessellationEdgeLength, 128.0);
    float3 tessellation = UnityEdgeLengthBasedTess(p0, p1, p2, _TessellationEdgeLength);
    f.edge[0] = tessellation[0];
    f.edge[1] = tessellation[1];
    f.edge[2] = tessellation[2];
    f.inside = (tessellation[0] + tessellation[1] + tessellation[2]) / 3.0;
    return f;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("PatchConstantFunction")]
TESSELLATION_VERTEX_DATA HullProgram (InputPatch<TESSELLATION_VERTEX_DATA, 3> patch, uint id : SV_OutputControlPointID) {
    return patch[id];
}

#endif
