Shader "Custom/Planet Surface"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Noise2D ("Noise 2D", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0
        _TessellationEdgeLength ("Tessellation Edge Length", Range(2, 50)) = 15
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
            float2 uv_Noise2D;
            float3 normal;
        };

        sampler2D _Noise2D;
        float4 _Color;
        float _Smoothness;
        float _Metallic;
        float _TessellationEdgeLength;

        float4 Tessellation (VertexData v0, VertexData v1, VertexData v2) {
            return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _TessellationEdgeLength, 0);
        }

        void VertexProgram (inout VertexData v) {
            v.vertex.xyz = normalize(v.vertex.xyz);
            v.normal = v.vertex.xyz;
        }

        void SurfaceProgram (Input IN, inout SurfaceOutputStandard o) {
            o.Albedo = tex2D(_Noise2D, IN.uv_Noise2D).r * _Color.rgb;
            o.Smoothness = _Smoothness;
            o.Metallic = _Metallic;
        }

        ENDCG
    }
}
