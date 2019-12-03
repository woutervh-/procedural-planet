Shader "Custom/LOD Tessellation Shader"
{
    Properties
    {
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0
        _ColorTint ("Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        _Emission ("Emission", Color) = (0.0, 0.0, 0.0)

        _Gradients2D ("Gradients", 2D) = "white" {}
        _Permutation2D ("Permutation", 2D) = "white" {}
        _Strength ("Strength", Float) = 1
        _Frequency ("Frequency", Float) = 1
        _Lacunarity ("Lacunarity", Float) = 2
        _Persistence ("Persistence", Float) = 0.5
        _Octaves ("Octaves", Int) = 8

        _TessellationEdgeLength ("Tessellation Edge Length", Range(2, 50)) = 15
    }

    SubShader
    {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            Blend One Zero
			ZWrite On

            CGPROGRAM

            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            #define FORWARD_BASE_PASS

            #include "LodTessellation.cginc"

            ENDCG
        }

        Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

            Blend One One
			ZWrite Off

			CGPROGRAM

            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram
            #pragma multi_compile_fwdadd_fullshadows nolightmap nodirlightmap nodynlightmap novertexlight

            #include "LodTessellation.cginc"

            ENDCG
		}

        Pass {
            Tags {
                "LightMode" = "Deferred"
            }

            CGPROGRAM

            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram

            #define DEFERRED_PASS
            #include "LodTessellation.cginc"

            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram

            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"
            #include "Tessellation.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "Noise.cginc"
            
            struct VertexData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct Interpolators {
                float4 pos : SV_POSITION;
            };
            
            VertexData VertexProgram (VertexData v) {
                return v;
            }

            #define TESSELLATION_VERTEX_DATA VertexData
            #include "NoiseTessellation.cginc"

            [UNITY_domain("tri")]
            Interpolators DomainProgram (TessellationFactors factors, OutputPatch<VertexData, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
                VertexData v;
                v.vertex = DOMAIN_PROGRAM_INTERPOLATE(vertex);
                v.normal = DOMAIN_PROGRAM_INTERPOLATE(normal);

                float3 vertex = normalize(v.vertex.xyz);
                Interpolators o;
                v.vertex = float4(vertex * noise(vertex).w, v.vertex.w);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
            
            fixed4 FragmentProgram (Interpolators i): SV_Target {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }
}
