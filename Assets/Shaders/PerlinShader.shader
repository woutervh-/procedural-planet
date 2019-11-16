// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Perlin Shader"
{
    Properties
    {
        _Gradients2D ("Gradients", 2D) = "white" {}
        _Permutation2D ("Permutation", 2D) = "white" {}
        _EdgeLength ("Tessellation Edge Length", Range(2, 50)) = 15
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0
        _Strength ("Strength", Range(0, 1)) = 0.5
        _Frequency ("Frequency", Range(0, 8)) = 2
        _Center ("Center", Vector) = (0, 0, 0)
        _Lacunarity ("Lacunarity", Float) = 2.3
        _Gain ("Gain", Float) = 0.4
        _Octaves ("Octaves", Range(0, 24)) = 12
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        CGPROGRAM

        #pragma surface SurfaceProgram Standard addshadow fullforwardshadows vertex:VertexProgram tessellate:Tessellation nolightmap

        #include "UnityCG.cginc"
        #include "Tessellation.cginc"

        struct VertexData {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Input {
            float4 vertex;
            float3 normal;
        };

        sampler2D _Gradients2D;
        sampler2D _Permutation2D;
        float _Strength;
        float _Frequency;
        float3 _Center;
        float _EdgeLength;
        float _Smoothness;
        float _Metallic;
        float _Lacunarity;
        float _Gain;
        int _Octaves;

        float3 fade(float3 t) {
            return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
        }

        float3 fadeDerivative(float3 t) {
            return 30.0 * t * t * (1.0 + t * (t - 2.0));
        }

        float3 gradient(float t) {
            return tex2Dlod(_Gradients2D, float4(t, 0, 0, 0)).rgb * 2.0 - 1.0;
        }

        float4 perlin(float3 p) {
            float3 ip = fmod(floor(p), 256.0) / 256.0;
            float3 fp = p - floor(p);
            float3 u = fade(fp);
            float3 du = fadeDerivative(fp);

            float4 permutation = tex2Dlod(_Permutation2D, float4(ip.xy, 0, 0));
            float aa = permutation.r + ip.z;
            float ab = permutation.g + ip.z;
            float ba = permutation.b + ip.z;
            float bb = permutation.a + ip.z;

            float3 c000 = gradient(aa);
            float3 c100 = gradient(ba);
            float3 c010 = gradient(ab);
            float3 c110 = gradient(bb);
            float3 c001 = gradient(aa + 1.0 / 256.0);
            float3 c101 = gradient(ba + 1.0 / 256.0);
            float3 c011 = gradient(ab + 1.0 / 256.0);
            float3 c111 = gradient(bb + 1.0 / 256.0);

            float3 p000 = fp + float3(0, 0, 0);
            float3 p100 = fp + float3(-1, 0, 0);
            float3 p010 = fp + float3(0, -1, 0);
            float3 p110 = fp + float3(-1, -1, 0);
            float3 p001 = fp + float3(0, 0, -1);
            float3 p101 = fp + float3(-1, 0, -1);
            float3 p011 = fp + float3(0, -1, -1);
            float3 p111 = fp + float3(-1, -1, -1);

            float a = dot(c000, p000);
            float b = dot(c100, p100);
            float c = dot(c010, p010);
            float d = dot(c110, p110);
            float e = dot(c001, p001);
            float f = dot(c101, p101);
            float g = dot(c011, p011);
            float h = dot(c111, p111);

            float k0 = a;
            float k1 = (b - a);
            float k2 = (c - a);
            float k3 = (e - a);
            float k4 = (a + d - b - c);
            float k5 = (a + f - b - e);
            float k6 = (a + g - c - e);
            float k7 = (b + c + e + h - a - d - f - g);

            float v = k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.x * u.z + k6 * u.y * u.z + k7 * u.x * u.y * u.z;
            float3 dv = du * float3(
                k1 + k4 * u.y + k5 * u.z + k7 * u.y * u.z,
                k2 + k4 * u.x + k6 * u.z + k7 * u.y * u.z,
                k3 + k5 * u.x + k6 * u.y + k7 * u.y * u.z
            );

            return float4(dv, v);
        }

        float4 noise(float3 p, float3 center, float frequency, float strength) {
            float4 sum = float4(0, 0, 0, 0);
            for (int i=0; i<_Octaves; i++) {
                float4 value = perlin(center + p * frequency);
                sum += strength * float4(value.xyz * frequency, value.w);
                strength *= _Gain;
                frequency *= _Lacunarity;
            }
            return sum;
        }

        float4 Tessellation (VertexData v0, VertexData v1, VertexData v2) {
            float maxStrength = _Strength * (pow(_Gain, _Octaves) - 1.0) / (_Gain - 1.0);
            float maxStrengthScaled = mul(float4(maxStrength, 0, 0, 1), unity_ObjectToWorld);
            return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, maxStrengthScaled.x);
        }

        void VertexProgram (inout VertexData v) {
            v.vertex.xyz = normalize(v.vertex.xyz);
            float3 tangent = v.tangent.xyz;
            float3 binormal = cross(v.normal, tangent) * (v.tangent.w * unity_WorldTransformParams.w);
            float4 value = noise(v.vertex.xyz, _Center, _Frequency, _Strength); // Get noise derivative in xyz and noise value in w.
            tangent += v.normal * (dot(tangent, value.xyz) - value.w); // Offset tangent by noise delta in the tangent's direction.
            binormal += v.normal * (dot(binormal, value.xyz) - value.w); // Offset binormal by noise delta in the binormal's direction.
            v.vertex.xyz += v.normal * value.w;
            v.normal = normalize(cross(tangent, binormal));
        }

        void SurfaceProgram (Input IN, inout SurfaceOutputStandard o) {
            // o.Emission = float4(o.Normal, 1);
            o.Albedo = float4(1, 1, 1, 1);
            o.Smoothness = _Smoothness;
            o.Metallic = _Metallic;
        }

        ENDCG
    }
}
