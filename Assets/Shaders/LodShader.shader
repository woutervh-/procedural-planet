Shader "Custom/LOD Shader"
{
    Properties
    {
        _Gradients2D ("Gradients", 2D) = "white" {}
        _Permutation2D ("Permutation", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0
        _ColorTint ("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        CGPROGRAM

        #pragma surface SurfaceProgram Standard addshadow fullforwardshadows vertex:VertexProgram nolightmap
        #pragma target 3.0

        #include "UnityCG.cginc"

        struct VertexData {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Input {
            float3 Pos;
            float4 Tangent;
        };

        sampler2D _Gradients2D;
        sampler2D _Permutation2D;
        float _Smoothness;
        float _Metallic;
        float4 _ColorTint;

        float3 fade(float3 t) {
            return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
        }

        float3 fadeDerivative(float3 t) {
            return 30.0 * t * t * (t * (t - 2.0) + 1.0);
        }

        float3 gradient(float t) {
            return tex2Dlod(_Gradients2D, float4(t, 0, 0, 0)).xyz * 2.0 - 1.0;
        }

        float4 perlin(float3 p) {
            float3 ip = fmod(floor(p), 256.0) / 256.0;
            float3 fp = p - floor(p);
            float3 u = fade(fp);
            float3 du = fadeDerivative(fp);
            float4 permutation = tex2Dlod(_Permutation2D, float4(ip.xy, 0, 0));
            float aa = permutation.x + ip.z;
            float ab = permutation.y + ip.z;
            float ba = permutation.z + ip.z;
            float bb = permutation.w + ip.z;

            float3 g000 = gradient(aa);
            float3 g100 = gradient(ba);
            float3 g010 = gradient(ab);
            float3 g110 = gradient(bb);
            float3 g001 = gradient(aa + 1.0 / 256.0);
            float3 g101 = gradient(ba + 1.0 / 256.0);
            float3 g011 = gradient(ab + 1.0 / 256.0);
            float3 g111 = gradient(bb + 1.0 / 256.0);

            float v000 = dot(g000, fp + float3(0, 0, 0));
            float v100 = dot(g100, fp + float3(-1, 0, 0));
            float v010 = dot(g010, fp + float3(0, -1, 0));
            float v110 = dot(g110, fp + float3(-1, -1, 0));
            float v001 = dot(g001, fp + float3(0, 0, -1));
            float v101 = dot(g101, fp + float3(-1, 0, -1));
            float v011 = dot(g011, fp + float3(0, -1, -1));
            float v111 = dot(g111, fp + float3(-1, -1, -1));

            float a = v000;
            float b = v100 - v000;
            float c = v010 - v000;
            float d = v001 - v000;
            float e = v110 - v010 - v100 + v000;
            float f = v101 - v001 - v100 + v000;
            float g = v011 - v001 - v010 + v000;
            float h = v111 - v011 - v101 + v001 - v110 + v010 + v100 - v000;

            float3 da = g000;
            float3 db = g100 - g000;
            float3 dc = g010 - g000;
            float3 dd = g001 - g000;
            float3 de = g110 - g010 - g100 + g000;
            float3 df = g101 - g001 - g100 + g000;
            float3 dg = g011 - g001 - g010 + g000;
            float3 dh = g111 - g011 - g101 + g001 - g110 + g010 + g100 - g000;

            float v = a + b * u.x + (c + e * u.x) * u.y + (d + f * u.x + (g + h * u.x) * u.y) * u.z;
            float3 dv = da + db * u.x + (dc + de * u.x) * u.y + (dd + df * u.x + (dg + dh * u.x) * u.y) * u.z;
            dv.x += du.x * (b + e * u.y + (f + h * u.y) * u.z);
            dv.y += du.y * (c + e * u.x + (g + h * u.x) * u.z);
            dv.z += du.z * (d + f * u.x + (g + h * u.x) * u.y);

            return float4(dv / 2, (v + 1) / 2);
        }

        float4 noise(float3 p, float frequency) {
            float4 perlinSample = perlin(p * frequency);
            perlinSample.xyz *= frequency;
            return perlinSample;
        }

        float4 myNoise(float3 p) {
            float4 sum = float4(0, 0, 0, 0);
            sum += noise(p, 1.0);
            // sum += noise(p, 2) / 2;
            // sum += noise(p, 4) / 4;
            // sum *= 2.0;
            // sum.w += 3;
            return sum;
        }

        void VertexProgram (inout VertexData v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            v.normal = normalize(mul(unity_ObjectToWorld, v.vertex));
            o.Pos = normalize(mul(unity_ObjectToWorld, v.vertex)).xyz;
            o.Tangent = v.tangent;
        }

        float3 GetNormal(float3 N, float3 P) {
            float3 gradient = myNoise(P).xyz;

            float e = 1;
            int o = 8;
            float F = myNoise(float3(P.x, P.y, P.z)).w;
            float Fx = myNoise(float3(P.x + e, P.y, P.z)).w;
            float Fy = myNoise(float3(P.x, P.y + e, P.z)).w;
            float Fz = myNoise(float3(P.x, P.y, P.z + e)).w;

            float3 dF = float3((Fx - F) / e, (Fy - F) / e, (Fz - F) / e);

            return normalize(N - gradient);
            // return normalize(N - dF);
        }

        void SurfaceProgram (Input IN, inout SurfaceOutputStandard o) {
            float3 n = GetNormal(normalize(o.Normal), IN.Pos);
            float3 binormal = cross(normalize(o.Normal), IN.Tangent) * (IN.Tangent.w * unity_WorldTransformParams.w);
            float3 normalW = (IN.Tangent * n.x) + (binormal * n.y) + (n * n.z);
            o.Normal = UnityObjectToWorldNormal(normalW);

            o.Albedo = _ColorTint;
            // o.Albedo = float4(normal, 1);
            // o.Emission = float4(normal, 1);
            // o.Normal = normal;
            o.Smoothness = _Smoothness;
            o.Metallic = _Metallic;
        }

        ENDCG
    }

    Fallback "Diffuse"
}
