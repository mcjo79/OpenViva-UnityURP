Shader "Surface/Surface_PBR_Pastry" {
    Properties {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Metallic ("Metallic", 2D ) = "black" {}
        _FillingColor ("Filling Color", Color) = (1,0,0,0)
        _Normal ("Normal", 2D ) = "bump" {}
        _PhotoDataColor ("Photo Data Color", Color) = (0,0,0,1)
    }

    SubShader {
        Tags {
            "RenderType"="Opaque"
            "PhotoData"="Opaque"
        }

        LOD 200
        Cull Off

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

            half4 _FillingColor;

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionCS = CustomObjectToClipPos(IN.positionOS.xyz);
                OUT.uv_MainTex = IN.uv_MainTex;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex);
                half2 data = SAMPLE_TEXTURE2D(_Metallic, sampler_Metallic, IN.uv_MainTex).ra;
                half3 albedo = lerp(_FillingColor.rgb * lerp(1.0, c.r, _FillingColor.a), c.rgb, c.a);
                half metallic = data.r;
                half smoothness = lerp(0.25, data.g, _FillingColor.a);
                half3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, IN.uv_MainTex));

                return half4(albedo, 1.0);
            }

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
