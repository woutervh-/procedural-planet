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

        #include "UnityCG.cginc"
        #include "Tessellation.cginc"

        struct VertexData {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Input {
<<<<<<< HEAD
            float4 vertex;
=======
            float3 position;
            float4 tangent;
>>>>>>> 1f2b9244962db90be21d0ea67e07a39ca8c886a7
            INTERNAL_DATA
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

            return float4(dv, v);
        }

        float4 noise(float3 p, float frequency) {
            float4 noise = perlin(p * frequency);
            noise.xyz *= frequency;
            return noise;
        }

        float4 myNoise(float3 p) {
            float4 sum = float4(0, 0, 0, 0);
            sum += noise(p, 1);
            // sum += noise(p, 2) / 2;
            // sum += noise(p, 4) / 4;
            sum /= 2;
            sum.w += 1.5;
            return sum;
        }

        void VertexProgram (inout VertexData v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.tangent = v.tangent;
            o.position = UnityObjectToWorldNormal(normalize(v.vertex));

            float height = myNoise(o.position).w;
            // v.vertex = float4(height * o.position, 1);
        }

        void SurfaceProgram (Input IN, inout SurfaceOutputStandard o) {
            float3 unitSphere = normalize(IN.position);
            float3 gradient = myNoise(unitSphere).xyz;
            float3 normal = normalize(unitSphere - gradient);
            float3 binormal = cross(unitSphere, IN.tangent.xyz) * (IN.tangent.w * unity_WorldTransformParams.w);
            float3 worldNormal = (IN.tangent.xyz * normal.x) + (binormal * normal.y) + (normal * normal.z);

            // float3 worldNormal = WorldNormalVector(IN, o.Normal);

            o.Albedo = _ColorTint;
            o.Normal = worldNormal;
            o.Smoothness = _Smoothness;
            o.Metallic = _Metallic;
        }

        ENDCG
    }
}
