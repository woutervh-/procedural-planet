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

struct ColorOutput {
    #if defined(DEFERRED_PASS)
        float4 gBuffer0 : SV_Target0;
        float4 gBuffer1 : SV_Target1;
        float4 gBuffer2 : SV_Target2;
        float4 gBuffer3 : SV_Target3;

        #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
            float4 gBuffer4 : SV_Target4;
        #endif
    #else
        float4 color : SV_Target;
    #endif
};

UnityLight CreateLight (ColorInput i) {
    UnityLight light;

    #if defined(DEFERRED_PASS)
        light.dir = float3(0, 1, 0);
        light.color = 0;
    #else
        #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
    		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
    	#else
		    light.dir = _WorldSpaceLightPos0.xyz;
	    #endif

        UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
	    light.color = _LightColor0.rgb * attenuation;
    #endif

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

ColorOutput GetColor(ColorInput i) {
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

    ColorOutput output;
    #if defined(DEFERRED_PASS)
        output.gBuffer0.rgb = albedo;
        output.gBuffer0.a = _ColorTint.a;
        output.gBuffer1.rgb = specularTint;
        output.gBuffer1.a = _Smoothness;
        output.gBuffer2 = float4(i.worldNormal * 0.5 + 0.5, 1);
        output.gBuffer3 = color;
    #else
        output.color = color;
    #endif

    return output;
}

#endif
