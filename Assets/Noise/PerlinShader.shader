Shader "Custom/Perlin Shader"
{
    Properties
    {
        _Gradients2D ("Gradients", 2D) = "white" {}
        _Permutation2D ("Permutation", 2D) = "white" {}
        _Frequency ("Frequency", Range(0, 255)) = 15
        _Center ("Center", Vector) = (0, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        CGPROGRAM

        #pragma surface SurfaceProgram Standard addshadow fullforwardshadows vertex:VertexProgram nolightmap

        #include "UnityCG.cginc"

        struct VertexData {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Input {
            float4 vertex : SV_POSITION;
            float2 uv_Permutation2D;
            float2 uv_Gradients2D;
            float3 normal;
        };

        sampler2D _Gradients2D;
        sampler2D _Permutation2D;
        float _Frequency;
        float3 _Center;

        float3 fade(float3 t) {
            return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
        }

        float3 gradient(float t) {
            return tex2D(_Gradients2D, float4(t, 0, 0, 0)).rgb * 2.0 - 1.0;
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

        void VertexProgram (inout VertexData v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.vertex = v.vertex;
        }

        void SurfaceProgram (Input IN, inout SurfaceOutputStandard o) {
            float v1 = 1 - abs(perlin(_Center + IN.vertex.xyz * _Frequency));
            // float v2 = perlin(_Center + IN.vertex.xyz * _Frequency * 2) / 2;
            // float v = v1 + v2;
            float v = v1;
            o.Albedo = float4(v, v, v, 1);
            o.Smoothness = 0;
            o.Metallic = 0;
        }

        ENDCG
    }
}
