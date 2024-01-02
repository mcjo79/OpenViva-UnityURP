Shader "URP/Surface/Surface_TexReceiveCutout" {
    Properties {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0,1)) = 1.0
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _PhotoDataColor ("Photo Data Color", Color) = (0,0,0,1)
        _Metallic ("Metallic", 2D ) = "black" {}
        _Normal ("Normal", 2D ) = "bump" {}
        _Color ("Color", Color) = (1,1,1)
    }

    SubShader {
        Tags {
            "RenderType"="Transparent"
            "Queue"="AlphaTest"
            "PhotoData"="Opaque"
        }

        LOD 200

        Pass {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../Custom.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv_MainTex : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_Metallic);
            TEXTURE2D(_Normal);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_Metallic);
            SAMPLER(sampler_Normal);

            half _Smoothness;
            half3 _Color;
            half _Cutoff;

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionCS = CustomObjectToClipPos(IN.positionOS);
                OUT.uv_MainTex = IN.uv_MainTex;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex);
                half2 data = SAMPLE_TEXTURE2D(_Metallic, sampler_Metallic, IN.uv_MainTex).ra;
                half3 albedo = c.rgb * _Color;
                half alpha = c.a;
                half metallic = data.r;
                half smoothness = data.g * _Smoothness;

                clip(alpha - _Cutoff); // Alpha cutoff

                half3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, IN.uv_MainTex));

                return half4(albedo, alpha);
            }

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
