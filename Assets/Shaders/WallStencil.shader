Shader "Surface/WallStencil" {

     Properties {
         _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
         _Smoothness ("Smoothness", Range(0,1)) = 1.0
         _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
         _AlphaMult ("Alpha Multiply", Range(0,1)) = 1.0
     }

     SubShader {
        
        Tags {
             "RenderType"="Transparent"
             "Queue"="AlphaTest"
             "PhotoData"="Opaque"
        }

        LOD 200
		Blend One OneMinusDstAlpha 
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma Standard fullforwardshadows
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            uniform half _Smoothness;
            uniform half _Cutoff;
            uniform half _AlphaMult;
            

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            v2f vert(appdata v) {
            

                v2f o;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.worldPos = TransformObjectToWorld(v.vertex).xyz;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }
            
            half4 frag(v2f i) : SV_Target {
            
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)

                // Échantillonnage de la texture principale
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgba;

                // Appliquer le seuil de coupure alpha
                if (c.a < _Cutoff) {
                    discard; // Élimine les fragments ne répondant pas au seuil de coupure
                }

                // Appliquer la multiplication alpha
                c.a *= _AlphaMult;

                // Calcul de la direction de la vue
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Calcul de la direction de la lumière (ici, en utilisant la lumière principale)
                half3 lightDir = normalize(_MainLightPosition.xyz - i.worldPos);

                // Calcul du vecteur de réflexion basé sur la direction de la lumière et la normale de surface
                half3 reflectDir = reflect(-lightDir, i.worldNormal);

                // Calcul de la composante spéculaire
                half specAngle = max(dot(reflectDir, viewDir), 0.0);
                half specIntensity = pow(specAngle, _Smoothness * 128.0); // La valeur 128.0 peut être ajustée

                // Ajout de la composante spéculaire à la couleur
                half3 specularColor = specIntensity * _MainLightColor.rgb;
                c.rgb += specularColor;

                return half4(c.rgb, c.a);
            }
            ENDHLSL
        }
     }

 }