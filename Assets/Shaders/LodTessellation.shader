Shader "Custom/LOD Tessellation Shader"
{
    Properties
    {
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0
        _ColorTint ("Tint", Color) = (1.0, 1.0, 1.0, 1.0)

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

            CGPROGRAM

            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram

            #include "UnityCG.cginc"
            #include "Tessellation.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "Noise.cginc"

            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            struct VertexData {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
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
                float h : TEXCOORD7;
            };
            
            float4 _ColorTint;
            float _TessellationEdgeLength;

            VertexData VertexProgram (VertexData v) {
                return v;
            }

            TessellationFactors PatchConstantFunction (InputPatch<VertexData, 3> patch) {
	            float4 p0 = patch[0].vertex;
	            float4 p1 = patch[1].vertex;
	            float4 p2 = patch[2].vertex;

	            TessellationFactors f;
                // float3 tessellation = UnityEdgeLengthBasedTessCull(p0, p1, p2, _TessellationEdgeLength, 128.0);
                float3 tessellation = UnityEdgeLengthBasedTess(p0, p1, p2, _TessellationEdgeLength);
	            f.edge[0] = tessellation[0];
	            f.edge[1] = tessellation[1];
	            f.edge[2] = tessellation[2];
		        f.inside = (tessellation[0] + tessellation[1] + tessellation[2]) / 3.0;
	            return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("fractional_odd")]
            [UNITY_patchconstantfunc("PatchConstantFunction")]
            VertexData HullProgram (InputPatch<VertexData, 3> patch, uint id : SV_OutputControlPointID) {
	            return patch[id];
            }

            [UNITY_domain("tri")]
            Interpolators DomainProgram (TessellationFactors factors, OutputPatch<VertexData, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
                #define DOMAIN_PROGRAM_INTERPOLATE(fieldName) \
		            patch[0].fieldName * barycentricCoordinates.x + \
		            patch[1].fieldName * barycentricCoordinates.y + \
		            patch[2].fieldName * barycentricCoordinates.z;

                VertexData v;
                v.vertex = DOMAIN_PROGRAM_INTERPOLATE(vertex);
                v.tangent = DOMAIN_PROGRAM_INTERPOLATE(tangent);
                v.normal = DOMAIN_PROGRAM_INTERPOLATE(normal);
                v.texcoord = DOMAIN_PROGRAM_INTERPOLATE(texcoord);

                float h = distance(normalize(patch[0].vertex.xyz), normalize(patch[1].vertex.xyz)) / factors.inside / 8;

                Interpolators o;
                o.vertex = normalize(v.vertex.xyz);
                v.vertex = float4(o.vertex.xyz * noise(o.vertex.xyz).w, v.vertex.w);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = v.normal;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.tangent = v.tangent;
                o.worldTangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.h = h;
                TRANSFER_SHADOW(o)
                return o;
            }
            
            fixed4 FragmentProgram (Interpolators i): SV_Target {
                // float h = distance(i.worldPos, _WorldSpaceCameraPos);
                float3 gradient = finiteDifferenceGradient(i.vertex, i.h).xyz;
                // float3 gradient = noise(i.vertex).xyz;
                float3 adjustedNormal = normalize(i.vertex - gradient);
                float3 worldNormal = UnityObjectToWorldNormal(adjustedNormal);
                
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

        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram

            #include "UnityCG.cginc"
            #include "Tessellation.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "Noise.cginc"

            #pragma multi_compile_shadowcaster
            
            struct VertexData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };
            
            struct Interpolators {
                float4 pos : SV_POSITION;
            };
            
            float4 _ColorTint;
            float _TessellationEdgeLength;

            VertexData VertexProgram (VertexData v) {
                return v;
            }

            TessellationFactors PatchConstantFunction (InputPatch<VertexData, 3> patch) {
	            float4 p0 = patch[0].vertex;
	            float4 p1 = patch[1].vertex;
	            float4 p2 = patch[2].vertex;

	            TessellationFactors f;
                // float3 tessellation = UnityEdgeLengthBasedTessCull(p0, p1, p2, _TessellationEdgeLength, 128.0);
                float3 tessellation = UnityEdgeLengthBasedTess(p0, p1, p2, _TessellationEdgeLength);
	            f.edge[0] = tessellation[0];
	            f.edge[1] = tessellation[1];
	            f.edge[2] = tessellation[2];
		        f.inside = (tessellation[0] + tessellation[1] + tessellation[2]) / 3.0;
	            return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("fractional_odd")]
            [UNITY_patchconstantfunc("PatchConstantFunction")]
            VertexData HullProgram (InputPatch<VertexData, 3> patch, uint id : SV_OutputControlPointID) {
	            return patch[id];
            }

            [UNITY_domain("tri")]
            Interpolators DomainProgram (TessellationFactors factors, OutputPatch<VertexData, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
                #define DOMAIN_PROGRAM_INTERPOLATE(fieldName) \
		            patch[0].fieldName * barycentricCoordinates.x + \
		            patch[1].fieldName * barycentricCoordinates.y + \
		            patch[2].fieldName * barycentricCoordinates.z;

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
