#if !defined(LOD_TESSELLATION_INCLUDED)
#define LOD_TESSELLATION_INCLUDED

#include "UnityCG.cginc"
#include "Tessellation.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "Noise.cginc"
#include "StandardLighting.cginc"

struct VertexData {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
};

struct Interpolators {
    float4 pos : SV_POSITION;
    float3 worldPos : TEXCOORD0;
    half3 normal : TEXCOORD1;
    half3 worldNormal : TEXCOORD2;
    float4 tangent : TEXCOORD3;
    float4 worldTangent : TEXCOORD4;
    float3 vertex : TEXCOORD5;
    UNITY_SHADOW_COORDS(6)
};

VertexData VertexProgram (VertexData v) {
    return v;
}

#define TESSELLATION_VERTEX_DATA VertexData
#include "NoiseTessellation.cginc"

[UNITY_domain("tri")]
Interpolators DomainProgram (TessellationFactors factors, OutputPatch<VertexData, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
    VertexData v;
    v.vertex = DOMAIN_PROGRAM_INTERPOLATE(vertex);
    v.tangent = DOMAIN_PROGRAM_INTERPOLATE(tangent);
    v.normal = DOMAIN_PROGRAM_INTERPOLATE(normal);
    v.texcoord = DOMAIN_PROGRAM_INTERPOLATE(texcoord);

    Interpolators o;
    UNITY_INITIALIZE_OUTPUT(Interpolators, o);
    o.vertex = normalize(v.vertex.xyz);
    v.vertex = float4(o.vertex.xyz * noise(o.vertex.xyz).w, v.vertex.w);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normal = v.normal;
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.tangent = v.tangent;
    o.worldTangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    UNITY_TRANSFER_SHADOW(o, v.uv1)

    return o;
}

ColorOutput FragmentProgram (Interpolators i) {
    float3 gradient = noise(i.vertex).xyz;
    float3 adjustedNormal = normalize(i.vertex - gradient);
    float3 worldNormal = UnityObjectToWorldNormal(adjustedNormal);

    ColorInput colorInput;
    colorInput.worldPos = i.worldPos;
    colorInput.worldNormal = worldNormal;
    colorInput._ShadowCoord = i._ShadowCoord;

    return GetColor(colorInput);
}

#endif
