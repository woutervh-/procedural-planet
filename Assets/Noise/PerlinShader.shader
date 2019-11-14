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

        float3 gradient(float t) {
            return tex2Dlod(_Gradients2D, float4(t, 0, 0, 0)).rgb * 2.0 - 1.0;
        }

        float perlin(float3 p) {
            float3 ip = fmod(floor(p), 256.0) / 256.0;
            float3 fp = p - floor(p);
            float3 u = fade(fp);

            float4 permutation = tex2Dlod(_Permutation2D, float4(ip.xy, 0, 0));
            float aa = permutation.r + ip.z;
            float ab = permutation.g + ip.z;
            float ba = permutation.b + ip.z;
            float bb = permutation.a + ip.z;

            float x1, x2, y1, y2;
            x1 = lerp(dot(gradient(aa), fp + float3(0, 0, 0)), dot(gradient(ba), fp + float3(-1, 0, 0)), u.x);
            x2 = lerp(dot(gradient(ab), fp + float3(0, -1, 0)), dot(gradient(bb), fp + float3(-1, -1, 0)), u.x);
            y1 = lerp(x1, x2, u.y);
            x1 = lerp(dot(gradient(aa + 1.0 / 256.0), fp + float3(0, 0, -1)), dot(gradient(ba + 1.0 / 256.0), fp + float3(-1, 0, -1)), u.x);
            x2 = lerp(dot(gradient(ab + 1.0 / 256.0), fp + float3(0, -1, -1)), dot(gradient(bb + 1.0 / 256.0), fp + float3(-1, -1, -1)), u.x);
            y2 = lerp(x1, x2, u.y);
            return (lerp(y1, y2, u.z) + 1.0) / 2.0;
        }

        float4 Tessellation (VertexData v0, VertexData v1, VertexData v2) {
            return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _EdgeLength, 0);
        }

        void VertexProgram (inout VertexData v) {
            v.vertex.xyz = normalize(v.vertex.xyz) / 2;

            float3 binormal = cross(v.normal, v.tangent.xyz) * (v.tangent.w * unity_WorldTransformParams.w);
            float s11 = perlin(_Center + (v.vertex - 0.001 * v.tangent.xyz) * _Frequency);
            float s12 = perlin(_Center + (v.vertex + 0.001 * v.tangent.xyz) * _Frequency);
            float s21 = perlin(_Center + (v.vertex - 0.001 * binormal) * _Frequency);
            float s22 = perlin(_Center + (v.vertex + 0.001 * binormal) * _Frequency);
            float3 n1 = (s12 - s11) / 2.0 * _Strength * v.normal + 0.001 * v.tangent.xyz;
            float3 n2 = (s22 - s21) / 2.0 * _Strength * v.normal + 0.001 * binormal;

            v.vertex.xyz += v.normal * _Strength * perlin(_Center + v.vertex.xyz * _Frequency);
            v.normal = normalize(cross(n2, n1));
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
