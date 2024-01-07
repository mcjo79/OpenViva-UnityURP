Shader "Custom/Grass" {
    Properties{
        _Color("Color", Color) = (1,1,1,1)
        _Blend("Texture Blend", Range(0,1)) = 0.0
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _MainTex2("Albedo 2 (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
    }
    
    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="AlphaTest" }

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

            // ... Déclarations et fonction vert

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct v2f {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform half3 _Color;
            uniform half _Blend;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_MainTex2);
            SAMPLER(sampler_MainTex2);

            uniform half _Glossiness;
            uniform half _Metallic;
            

            v2f vert(appdata v) {
                v2f o;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = TransformObjectToHClip(v.vertex.xyz); // Transforme la position du sommet de l'espace objet à l'espace clip
                o.uv = v.uv; // Passe la coordonnée UV à la structure de sortie
                o.worldPos = TransformObjectToWorld(v.vertex).xyz;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);

                return o;
            }

           half4 frag(v2f i) : SV_Target {
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)
                // Échantillonnage de la texture principale
                half3 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;
                half3 mainTexColor2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv).rgb;
                half3 c = lerp(mainTexColor, mainTexColor2, _Blend) * _Color;


                //application smothness

                half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 lightDir = normalize(_MainLightPosition.xyz - i.worldPos);
                half3 reflectDir = reflect(-lightDir, i.worldNormal);
                half spec = pow(max(dot(viewDir, reflectDir), 0.0), _Glossiness * 128.0);
                half3 specularColor = spec * _MainLightColor.rgb;

                c += specularColor; // Ajoute la couleur spéculaire à 'c'

                //application metallic

                half3 finalColor;

                // Calculez d'abord la couleur diffuse
                half3 diffuseColor = c * (1.0 - _Metallic);

                // Ajoutez la couleur spéculaire modulée par la métallicité
                half3 metallicSpecular = specularColor * _Metallic;
                finalColor = diffuseColor + metallicSpecular;
                
                return float4(finalColor, 1.0); // Retourne la couleur finale avec une opacité complète
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}