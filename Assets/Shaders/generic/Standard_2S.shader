Shader "Surface/TexReceiveCast2S_Opaque" {
    Properties {
        _FrontTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _BackTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Normal("Normal", 2D) = "bump" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Smoothness ("Smooth", Range(0,1)) = 0.0
        _Glossiness ("Glossiness", Range(0, 1)) = 0.5
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"



            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float facing : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            uniform sampler2D _FrontTex;
            uniform sampler2D _BackTex;
            uniform sampler2D _Normal;
            uniform float _Metallic;
            uniform float _Smoothness;
            uniform float _Glossiness;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.worldPos = TransformObjectToWorld(v.vertex).xyz;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                // Calcul de la direction de la vue dans l'espace du monde
                float3 viewDirWorldSpace = normalize(_WorldSpaceCameraPos - o.worldPos);
                o.facing = dot(viewDirWorldSpace, o.worldNormal) > 0 ? 1.0 : -1.0;
                return o;
            }

            half4 frag (v2f i) : SV_Target {
                half3 albedoFront = tex2D(_FrontTex, i.uv).rgb;
                half3 albedoBack = tex2D(_BackTex, i.uv).rgb;
                half3 albedo = lerp(albedoBack, albedoFront, step(0.0, i.facing));

                // Utilisation de la normal map fournie
                half3 normal = UnpackNormal(tex2D(_Normal, i.uv));
                // Ajustement de la direction de la normale en fonction de la face visible
                normal = faceforward(normal, normalize(_WorldSpaceCameraPos - i.worldPos), normal);

                // Calcul de l'éclairage spéculaire
                half3 lightDir = normalize(_MainLightPosition.xyz - i.worldPos);
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 reflectDir = reflect(-lightDir, normal);
                half roughness = 1.0 - _Smoothness;
                half spec = pow(max(dot(viewDir, reflectDir), 0.0), roughness * 128.0); // La valeur 128.0 peut être ajustée

                // Moduler le spéculaire et l'albedo par le paramètre de métallicité
                half3 specularColor = _MainLightColor.rgb * spec;
                half3 finalColor = lerp(albedo, specularColor, _Metallic);


                return half4(finalColor, 1.0);
            }

            ENDHLSL
        }
    }
}
