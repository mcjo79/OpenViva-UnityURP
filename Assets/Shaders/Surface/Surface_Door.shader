Shader "Surface/Surface_Door" {
    Properties {
        _MainTex ("Base", 2D) = "white" {}
        _Normal ("Normal", 2D ) = "bump" {}
        _RoughnessAndMask ("Roughness and Mask (RG)", 2D ) = "black" {}
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
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_RoughnessAndMask);
            TEXTURE2D(_Normal);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_RoughnessAndMask);
            SAMPLER(sampler_Normal);

            uniform half3 _Color;

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv_MainTex = IN.uv_MainTex;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
                half2 data = SAMPLE_TEXTURE2D(_RoughnessAndMask, sampler_RoughnessAndMask, IN.uv_MainTex).rg;

                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex).rgb;
                half smoothness = data.r; 
                half3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, IN.uv_MainTex));

                return half4(albedo * saturate(data.ggg + _Color), smoothness);
            }

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
