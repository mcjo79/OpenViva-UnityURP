Shader "Surface/Stocking" {
    Properties {
        _OutlineColor ("Outline color", Color) = (1, 1, 1, 1)
        _OutSizeMin ("Outline Size Min", Range(0, 0.003)) = 0.001
        _OutSizeMax ("Outline Size Max", Range(0, 0.003)) = 0.001
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Bumpmap", 2D) = "bump" {}
        _SkinColor ("Skin Color", Color) = (0.26, 0.19, 0.16, 0)
        _RimMin ("Rim Min", Range(0, 1.0)) = 0
        _RimMax ("Rim Max", Range(0, 16.0)) = 0
    }

    SubShader {
        Tags {
            "Queue"="AlphaTest"
            "RenderType"="TransparentCutout"
            "IgnoreProjector"="True"
            "PhotoData"="Opaque"
        }

        LOD 100
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
                float3 viewDir : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_BumpMap);

            half3 _SkinColor;
            half _RimMin;
            half _RimMax;


            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionCS = CustomObjectToClipPos(IN.positionOS);
                OUT.uv_MainTex = IN.uv_MainTex;
                OUT.viewDir = CustomWorldSpaceViewDir(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex);
                clip(c.a - 0.5);

                half3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv_MainTex));
                half rim = saturate((dot(normalize(IN.viewDir), normal) - _RimMin) * _RimMax);
                half3 albedo = lerp(c.rgb, _SkinColor, rim * rim);

                return half4(albedo, 1.0);
            }

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
