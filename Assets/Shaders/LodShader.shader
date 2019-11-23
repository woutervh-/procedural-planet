Shader "Custom/LOD Shader"
{
    Properties
    {
        _Gradients2D ("Gradients", 2D) = "white" {}
        _Permutation2D ("Permutation", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0
        _ColorTint ("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _Strength ("Strength", Float) = 1
        _Frequency ("Frequency", Float) = 1
        _Lacunarity ("Lacunarity", Float) = 2
        _Persistence ("Persistence", Float) = 0.5
        _Octaves ("Octaves", Int) = 8
    }

    SubShader
    {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #include "AutoLight.cginc"

            #include "Noise.cginc"

            struct VertexData {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };
            
            struct Interpolators {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                half3 normal : TEXCOORD1;
                half3 worldNormal : TEXCOORD2;
                float4 tangent : TEXCOORD3;
                float4 worldTangent : TEXCOORD4;
                float3 vertex : TEXCOORD5;
                SHADOW_COORDS(6)
            };
            
            float _Smoothness;
            float _Metallic;
            float4 _ColorTint;
            
            Interpolators VertexProgram (VertexData v) {
                Interpolators o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = v.normal;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.tangent = v.tangent;
                o.worldTangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.vertex = normalize(v.vertex.xyz);
                TRANSFER_SHADOW(o)
                return o;
            }
            
            fixed4 FragmentProgram (Interpolators i): SV_Target {
                float gradientBias = 0.5;
                float3 gradient = noise(i.vertex).xyz;
                float3 adjustedNormal = normalize(i.vertex - gradient);
                float3 blendedNormal = adjustedNormal * gradientBias + i.normal * (1 - gradientBias);
                float3 worldNormal = UnityObjectToWorldNormal(blendedNormal);
                
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                fixed3 diffuse = nl * _LightColor0.rgb;
                fixed3 ambient = ShadeSH9(half4(worldNormal, 1));
                fixed shadow = SHADOW_ATTENUATION(i);
                fixed3 lighting = diffuse * shadow + ambient;

                fixed4 color = _ColorTint;
                color.rgb *= lighting;

                return color;

                // o.Normal = normal;
                // o.Albedo = _ColorTint;
                // o.Smoothness = _Smoothness;
                // o.Metallic = _Metallic;
            }

            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
