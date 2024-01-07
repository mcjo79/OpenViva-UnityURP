Shader "Effects/Fuse" {
    Properties {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Fuse ("Fuse", Range(0,1)) = 1.0
        _FuseGlowLength ("Fuse Glow Length", Range(1,16)) = 1.0
        _FuseGlow ("FuseGlow", Range(0,1)) = 1.0
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="AlphaTest" }

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            // ... Déclarations et fonction vert

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct v2f {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            uniform half _Fuse;
            uniform half _FuseGlowLength;
            uniform half _FuseGlow;

            v2f vert(appdata v) {
                v2f o;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = TransformObjectToHClip(v.vertex.xyz); // Transforme la position du sommet de l'espace objet à l'espace clip
                o.uv = v.uv; // Passe la coordonnée UV à la structure de sortie
                return o;
            }

           half4 frag(v2f i) : SV_Target {
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)
                // Échantillonnage de la texture principale
                half3 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;

                // Calcul de l'émission basée sur la position UV et les propriétés du shader
                half emissionStrength = saturate(1.0 - (_Fuse - i.uv.x) * _FuseGlowLength) * 2.0 * _FuseGlow;
                half3 emissionColor = emissionStrength * half3(1.0, 0.6, 0.3); // Couleur d'émission personnalisée
               

                // Clip basé sur la position UV pour la mèche
                clip(_Fuse - i.uv.x);

                // Combinaison de l'albedo et de l'émission
                half3 finalColor = mainTexColor + emissionColor;

                return half4(finalColor, 1.0); // Retourne la couleur finale avec une opacité complète
            }
            ENDHLSL
        }
    }
}
