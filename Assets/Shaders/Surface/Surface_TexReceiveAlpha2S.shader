Shader "Surface/TexReceiveTransparentInterior" {
    Properties {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0,2)) = 1.0
        _PhotoDataColor ("Photo Data Color", Color) = (0,0,0,1)
        _Metallic ("Metallic", 2D ) = "black" {}
    }

    SubShader {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "PhotoData"="Opaque"
        }

        ZWrite Off
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha

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
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_Metallic);

            half _Smoothness;

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionCS = CustomObjectToClipPos(IN.positionOS);
                OUT.uv_MainTex = IN.uv_MainTex;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex);
                half2 data = SAMPLE_TEXTURE2D(_Metallic, sampler_Metallic, IN.uv_MainTex).ra;
                half3 albedo = c.rgb;
                half alpha = c.a;
                half metallic = data.r;
                half smoothness = data.g * _Smoothness;

                return half4(albedo, alpha);
            }

            ENDHLSL
        }

        // Additional Passes if needed...
    }

    FallBack "Universal Render Pipeline/Transparent"
}
