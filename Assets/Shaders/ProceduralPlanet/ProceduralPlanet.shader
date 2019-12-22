Shader "Custom/Procedural Planet" {
    Properties {
        _Metallic ("Metallic", Range(0, 1)) = 0.5
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [MainColor] _BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}

        [HideInInspector] _Gradients2D ("Gradients", 2D) = "white" {}
        [HideInInspector] _Permutation2D ("Permutation", 2D) = "white" {}
        _Strength ("Strength", Float) = 1
        _Frequency ("Frequency", Float) = 1
        _Lacunarity ("Lacunarity", Float) = 2
        _Persistence ("Persistence", Float) = 0.5
        _Octaves ("Octaves", Int) = 8

        _TessellationEdgeLength ("Tessellation Edge Length", Range(2, 50)) = 15
    }

    SubShader {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "LightWeightPipeline"
        }

        Pass {
            Name "ForwardLit"
            Tags {
                "LightMode" = "LightWeightForward"
            }

            Blend Off
            ZWrite On

            HLSLPROGRAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            // #pragma hull HullProgram
            // #pragma domain DomainProgram

            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/LitForwardPass.hlsl"
            // #include "LitPass.hlsl"

            ENDHLSL
        }

        Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/Shaders/ShadowCasterPass.hlsl"

            ENDHLSL
        }

        Pass {
            Name "DepthOnly"
            Tags {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            ENDHLSL
        }
    }
}
