Shader "Custom/Planet"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
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

            struct VertexData {
    	        float4 vertex : POSITION;
            };

            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            struct FragmentOutput {
    		    float4 color : SV_Target;
            };

            float4 _Color;
            float _TessellationEdgeLength;

            VertexData VertexProgram (VertexData v) {
    	        return v;
            }

            TessellationFactors PatchConstantFunction (InputPatch<VertexData, 3> patch) {
	            float4 p0 = mul(unity_ObjectToWorld, patch[0].vertex).xyzw;
	            float4 p1 = mul(unity_ObjectToWorld, patch[1].vertex).xyzw;
	            float4 p2 = mul(unity_ObjectToWorld, patch[2].vertex).xyzw;

	            TessellationFactors f;
                float3 tessellation = UnityEdgeLengthBasedTessCull(p0, p1, p2, _TessellationEdgeLength, 0.0);
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

        		float3 vertex = DOMAIN_PROGRAM_INTERPOLATE(vertex);
                vertex = normalize(vertex);

                Interpolators i;
        		i.vertex = UnityObjectToClipPos(float4(vertex.xyz, 1.0));
                i.worldPos = mul(unity_ObjectToWorld, vertex).xyz;
        		return i;
            }

            FragmentOutput FragmentProgram (Interpolators i) {
                FragmentOutput o;
                o.color = _Color;
                return o;
            }
        
            ENDCG
        }
    }
}
