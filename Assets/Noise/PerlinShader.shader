Shader "Custom/Perlin Shader"
{
    Properties
    {
        _Gradients2D ("Gradients", 2D) = "white" {}
        _Permutation2D ("Permutation", 2D) = "white" {}
        _Strength ("Strength", Range(0, 1)) = 0.5
        _Frequency ("Frequency", Range(0, 255)) = 15
        _Center ("Center", Vector) = (0, 0, 0)
        _EdgeLength ("Tessellation Edge Length", Range(2, 50)) = 15
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0
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

            float k0 = b - a;
            float k1 = c - a;
            float k2 = e - a;
            float k3 = a + d - b - c;
            float k4 = a + f - b - e;
            float k5 = a + g - c - e;
            float k6 = b + c + e + h - a - d - f - g;

            float v = a + u.x * k0 + u.y * k1 + u.z * k2 + u.x * u.y * k3 + u.x * u.z * k4 + u.y * u.z * k5 + u.x * u.y * u.z * k6;
            float3 dv = du * float3(
                k0 + u.y * k3 + u.z * k4 + u.y * u.z * k6,
                k1 + u.x * k3 + u.z * k5 + u.x * u.z * k6,
                k2 + u.x * k4 + u.y * k5 + u.x * u.y * k6
            );

            return float4(dv, v);
        }

        float4 Tessellation (VertexData v0, VertexData v1, VertexData v2) {
            return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, _Strength);
        }

        void VertexProgram (inout VertexData v) {
            float3 tangent = v.tangent.xyz;
            float3 binormal = cross(v.normal, tangent) * (v.tangent.w * unity_WorldTransformParams.w);
            float4 noise = _Strength * perlin(_Center + v.vertex.xyz * _Frequency); // Get noise derivative in xyz and noise value in w.
            tangent += v.normal * (dot(tangent, noise.xyz) - noise.w); // Offset tangent by noise delta in the tangent's direction.
            binormal += v.normal * (dot(binormal, noise.xyz) - noise.w); // Offset binormal by noise delta in the binormal's direction.
            v.vertex.xyz += v.normal * noise.w;
            v.normal = normalize(cross(binormal, tangent));
        }

        void SurfaceProgram (Input IN, inout SurfaceOutputStandard o) {
            // float v1 = 1 - abs(perlin(_Center + IN.vertex.xyz * _Frequency));
            // float v2 = perlin(_Center + IN.vertex.xyz * _Frequency * 2) / 2;
            // float v = v1 + v2;
            // float v = v1;
            o.Albedo = float4(1, 1, 1, 1);
            o.Smoothness = _Smoothness;
            o.Metallic = _Metallic;
        }

        ENDCG
    }
}
