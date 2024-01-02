Shader "URP/Surface/Surface_HouseWallWear" {
    Properties {
        _MainTex ("Base", 2D) = "white" {}
        _Normal ("Normal", 2D ) = "bump" {}
        _MainTex2 ("Wear Base", 2D) = "white" {}
        _RoughnessAndMask ("Roughness and Mask (RG)", 2D ) = "black" {}
        _Normal2 ("Normal", 2D ) = "bump" {}
        _MaskSize("Mask Size", Range(0.2,4.0)) = 2
        _ShadowWidth("Shadow width", Range(0.0,0.004)) = 0.001
        _ShadowStrength("Shadow Strength", Range(0.0,1)) = 0.5
        _Color ("Color", Color) = (0.6,0.5,1.0,1)
        _PhotoDataColor ("Photo Data Color", Color) = (0,0,0,1)
    }

    SubShader {
        Tags {
            "RenderType"="Opaque"
            "PhotoData"="Opaque"
        }

        LOD 200

        Pass {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv_MainTex : TEXCOORD0;
                half vertColor : COLOR;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                half vertColor : COLOR;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_RoughnessAndMask);
            TEXTURE2D(_Normal);
            TEXTURE2D(_Normal2);
            TEXTURE2D(_MainTex2);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_RoughnessAndMask);
            SAMPLER(sampler_Normal);
            SAMPLER(sampler_Normal2);
            SAMPLER(sampler_MainTex2);

            uniform half3 _Color;
            uniform half _MaskSize;
            uniform half _ShadowWidth;
            uniform half _ShadowStrength;

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv_MainTex = IN.uv_MainTex;
                OUT.vertColor = IN.vertColor;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
                half data1 = SAMPLE_TEXTURE2D(_RoughnessAndMask, sampler_RoughnessAndMask, IN.uv_MainTex*_MaskSize).g;
                half data2 = SAMPLE_TEXTURE2D(_RoughnessAndMask, sampler_RoughnessAndMask, IN.uv_MainTex*_MaskSize+_ShadowWidth).g;
                half mask = smoothstep( 0., IN.vertColor, data1 );
                half mask2 = smoothstep( 0., IN.vertColor, data2 );
                half maskShadow = saturate( mask2-mask );

                half3 albedo1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex).rgb;
                half3 albedo2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, IN.uv_MainTex).rgb;
                half3 normal1 = UnpackNormal(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, IN.uv_MainTex));
                half3 normal2 = UnpackNormal(SAMPLE_TEXTURE2D(_Normal2, sampler_Normal2, IN.uv_MainTex));

                half3 finalAlbedo = albedo1 * _Color * mask + albedo2 * (1.0 - mask) - maskShadow * _ShadowStrength;
                half finalSmoothness = SAMPLE_TEXTURE2D(_RoughnessAndMask, sampler_RoughnessAndMask, IN.uv_MainTex).r * mask;
                half3 finalNormal = normal1 * mask + normal2 * (1.0 - mask);

                return half4(finalAlbedo, finalSmoothness);
            }

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
