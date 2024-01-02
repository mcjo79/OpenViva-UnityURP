Shader "Surface/Surface_LOD_Card" {
    Properties{
        _MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
        _Scale("Scale", Range(10,200)) = 10
        _Cutoff("Alpha cutoff", Range(0,1)) = 0.5
    }

        SubShader{
            Tags {
                "RenderType" = "Transparent"
                "Queue" = "Transparent"
                "PhotoData" = "Opaque"
            }

            LOD 200
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

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
                };

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                uniform float _Scale;

                Varyings vert(Attributes IN) {
                    Varyings OUT;

                    float3 scaledPosition = IN.positionOS.xyz * _Scale;
                    OUT.positionCS = TransformWorldToHClip(TransformObjectToWorld(scaledPosition));
                    OUT.uv = IN.uv;

                    return OUT;
                }

                half4 frag(Varyings IN) : SV_Target {
                    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                    // Vous pouvez ajouter d'autres traitements ici si nécessaire
                    return col;
                }

                ENDHLSL
            }
        }

            FallBack "Universal Render Pipeline/Transparent"
}