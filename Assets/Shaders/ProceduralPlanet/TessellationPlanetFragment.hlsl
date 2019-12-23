#ifndef PROCEDURAL_PLANET_TESSELLATION_PLANET_FRAGMENT_INCLUDED
#define PROCEDURAL_PLANET_TESSELLATION_PLANET_FRAGMENT_INCLUDED

#include "Noise.hlsl"

half4 Fragment(Varyings input) : SV_Target {
    float3 pointOnUnitSphere = normalize(TransformWorldToObjectDir(input.normalWS));
    float4 noiseSample = noise(pointOnUnitSphere);
    float3 adjustedNormal = normalize(pointOnUnitSphere - noiseSample.xyz);
    input.normalWS = TransformObjectToWorldNormal(adjustedNormal);
    return FragmentProgram(input);
}

#endif
