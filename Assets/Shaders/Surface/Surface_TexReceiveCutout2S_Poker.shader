Shader "Surface/TexReceiveCutout2S_Poker_front_URP" {
    Properties {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0,1)) = 1.0
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _Red ("Red", Range(0,1)) = 0.0
        _Highlighted ("Highlighted", Range(0,1)) = 0.0
    }

    SubShader {
        Tags {
            "RenderType"="TransparentCutout"
                "Queue" = "Transparent"
        }

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile_local_fragment _ _SHADOWS_SOFT
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.uv = IN.uv;
                OUT.positionCS = TransformObjectToHClip(IN.vertex.xyz);
                return OUT;
            }

			
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            half _Smoothness;
            half _Red;
            half _Highlighted;
            half _Cutoff;

            struct SurfaceData {
                half3 Albedo;
                half Metallic;
                half3 Emission;
                half Smoothness;
                half Alpha;
            };

            void surf(Varyings IN, out SurfaceData surface) {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                surface.Albedo = c.rgb;
                surface.Metallic = 0;
                surface.Emission = half3(0, 0, 0);
                surface.Smoothness = _Smoothness;
                surface.Alpha = c.a;
                
                half withinRed = 1.-step(0.6338, IN.uv.x)*step(IN.uv.y, 0.5);
                surface.Albedo *= half3(min(1.,_Red+withinRed), withinRed, withinRed);

                half s = sin(_Time.y*2.)*0.25+0.25;
                surface.Emission = half3(s, s, s)*_Highlighted; 
            }

            half4 frag(Varyings IN) : SV_Target {
                SurfaceData surface;
                surf(IN, surface);

                half4 color = half4(surface.Albedo, surface.Alpha);
                clip(surface.Alpha - _Cutoff);
                return color;
            }
            ENDHLSL
        }
    }

}
