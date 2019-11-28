#if !defined(STANDARD_LIGHTING_INCLUDED)
#define STANDARD_LIGHTING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

float _Smoothness;
float _Metallic;
float4 _ColorTint;
float3 _Emission;

struct ColorInput {
    float3 worldPos;
    float3 worldNormal;
    UNITY_SHADOW_COORDS(a)
};

UnityLight CreateLight (ColorInput i) {
    UnityLight light;

    light.dir = _WorldSpaceLightPos0.xyz;
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
	light.color = _LightColor0.rgb * attenuation;

    return light;
}

UnityIndirect CreateIndirectLight (ColorInput i, float3 viewDir) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
		indirectLight.diffuse = max(0, ShadeSH9(float4(i.worldNormal, 1)));

		float3 reflectionDir = reflect(-viewDir, i.worldNormal);
		float4 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectionDir);
		indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);
	#endif

	return indirectLight;
}

float3 GetEmission() {
    #if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
		return _Emission;
	#else
		return 0;
	#endif
}

float4 GetColor(ColorInput i) {
    float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
    float3 worldRefl = reflect(-worldViewDir, i.worldNormal);
    half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
    half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

    float3 specularTint;
    float oneMinusReflectivity;
    float3 albedo = DiffuseAndSpecularFromMetallic(_ColorTint.rgb, _Metallic, specularTint, oneMinusReflectivity);

    half4 color = UNITY_BRDF_PBS(albedo, specularTint, oneMinusReflectivity, _Smoothness, i.worldNormal, worldViewDir, CreateLight(i), CreateIndirectLight(i, worldViewDir));
    color.rgb += GetEmission();
    color.a = _ColorTint.a;
    return color;
}

#endif
