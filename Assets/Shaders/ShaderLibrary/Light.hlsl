#ifndef LIBRARY_LIGHT
#define LIBRARY_LIGHT

struct Light {
    half3 direction;
    half3 color;
    half distanceAttenuation;
    half shadowAttenuation;
};

Light GetMainLight() {
    Light light;
    light.direction = _MainLightPosition.xyz;
    light.distanceAttenuation = unity_LightData.z;
    light.shadowAttenuation = 1.0;
    light.color = _MainLightColor.rgb;

    return light;
}

#endif
