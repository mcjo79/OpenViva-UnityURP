Shader "URP/Surface/TexReceiveCutout2S" {
    Properties {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0,2)) = 1.0
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _PhotoDataColor ("Photo Data Color", Color) = (0,0,0,1)
        _Metallic ("Metallic", 2D ) = "black" {}
        _Normal ("Normal", 2D ) = "bump" {}
    }

    SubShader {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Pass {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float clipPosW : TEXCOORD1;
            };

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.clipPosW = ComputeClipSpacePosition(OUT.positionCS).w;
                return OUT;
            }

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            uniform float _Smoothness;
            uniform float _Cutoff;
            uniform float4 _PhotoDataColor;
			uniform float4 _MainTex_ST;
            uniform float4 _Metallic_ST;
            uniform float4 _Normal_ST;
            



            half4 frag(Varyings IN) : SV_Target {
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); // Corrected texture sampling
                color.a = color.a > _Cutoff ? 1 : 0;
                clip(color.a - 0.5);
                return color;
            }

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Transparent"
}
