#ifndef PROCEDURAL_PLANET_LIT_PASS_INCLUDED
#define PROCEDURAL_PLANET_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
// #include "../ShaderLibrary/Surface.hlsl"
// #include "../ShaderLibrary/BRDF.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float _Metallic;
    float _Smoothness;
CBUFFER_END

struct Attributes {
	float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
};

struct Varyings {
    float4 positionCS : SV_POSITION;
    float3 positionWS : VAR_POSITION;
    float3 normalWS : VAR_NORMAL;
    half3 vertexSH : TEXCOORD1;
    float3 viewDirWS : TEXCOORD4;
    half4 fogFactorAndVertexLight : TEXCOORD6;
};

Varyings LitPassVertex(Attributes input) {
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    Varyings output;
    output.positionCS = vertexInput.positionCS;
    output.positionWS = vertexInput.positionWS;
    output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    half fogFactor = ComputeFogFactor(output.positionCS.z);
    half3 vertexLight = VertexLighting(output.positionWS, normalInput.normalWS);
    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
    return output;
}

float4 LitPassFragment(Varyings input) : SV_TARGET {
    InputData inputData;
    inputData.positionWS = input.positionWS;
    inputData.normalWS = input.normalWS;
    inputData.viewDirectionWS = SafeNormalize(input.viewDirWS);
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SampleSHPixel(input.vertexSH, inputData.normalWS);

    SurfaceData surfaceData;
    surfaceData.albedo = _BaseColor.rgb;
    surfaceData.specular = _Metallic.rrr;
    surfaceData.metallic = _Metallic;
    surfaceData.smoothness = _Smoothness;
    surfaceData.normalTS = half3(0, 0, 0);
    surfaceData.emission = half3(0, 0, 0);
    surfaceData.occlusion = 1.0;
    surfaceData.alpha = _BaseColor.a;

    half4 color = LightweightFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);

    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}

#endif
