Shader "Surface/GenericURP" {
    Properties {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }

    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        LOD 200

        Pass {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv_MainTex : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            uniform half _Glossiness;
            uniform half _Metallic;

            Varyings vert(Attributes IN) {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv_MainTex = IN.uv_MainTex;
                return OUT;
            }

            struct SurfaceData {
                half3 Albedo;
                half Metallic;
                half Smoothness;
                half Alpha;
            };

            void InitializeOutputData(inout SurfaceData surfaceData) {
                surfaceData.Albedo = 0;
                surfaceData.Metallic = 0;
                surfaceData.Smoothness = 0;
                surfaceData.Alpha = 1;
            }

            void surf(Varyings IN, out SurfaceData surfaceData) {
                InitializeOutputData(surfaceData);
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex);
                surfaceData.Albedo = c.rgb;
                surfaceData.Metallic = _Metallic;
                surfaceData.Smoothness = _Glossiness;
                surfaceData.Alpha = c.a;
            }

            half4 frag(Varyings IN) : SV_Target {
                SurfaceData surfaceData;
                surf(IN, surfaceData);

                half3 finalColor = surfaceData.Albedo;
                // Vous pouvez ajouter ici des calculs d'éclairage et d'autres effets
                return half4(finalColor, surfaceData.Alpha);
            }

            ENDHLSL
        }
    }

    Fallback "Universal Render Pipeline/Lit"
}