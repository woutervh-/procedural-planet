#ifndef PROCEDURAL_PLANET_TESSELLATION_PLANET_FRAGMENT_INCLUDED
#define PROCEDURAL_PLANET_TESSELLATION_PLANET_FRAGMENT_INCLUDED

#include "Noise.hlsl"

half4 Fragment(Varyings input) : SV_Target {
    float3 pointOnUnitSphere = normalize(TransformWorldToObjectDir(input.normalWS));
    // float4 noiseSample = noise(pointOnUnitSphere);
    #ifdef UNITY_REVERSED_Z
        float h = 1.0 - input.positionCS.z;
    #else
        float h = input.positionCS.z;
    #endif
    h /= 8.0;
    h *= h;
    float3 adjustedNormal = normalize(pointOnUnitSphere - finiteDifferenceGradient(pointOnUnitSphere, h));
    input.normalWS = TransformObjectToWorldNormal(adjustedNormal);
    return FragmentProgram(input);
}

#endif
