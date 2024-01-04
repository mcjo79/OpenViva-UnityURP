
Shader "Anime/AnimeHead"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_ToonProximityAmbience ("Toon Proximity Ambience",Color) = (1.,1.,1.)
		_OutlineColor ("Outline color",Color) = (1.,1.,1.)
		_OutSizeMin ("Outline Size Min",Range(0.,0.003)) = 0.001
		_OutSizeMax ("Outline Size Max",Range(0.,0.003)) = 0.001
		_PhotoDataColor ("Photo Data Color",Color) = (0.,1.,0.,1.)
		_Dirt ("Dirt",Range(0.,1)) = 0
	}

	SubShader
	{
		LOD 100

		Tags {
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}

		Pass
		{
			Tags { "LightMode"="UniversalForward" }
			Cull Front

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Custom.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform float3 _OutlineColor;
			uniform float _OutSizeMin;
			uniform float _OutSizeMax;
			uniform float3 _ToonProximityAmbience;
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				// Transforme la normale de l'espace objet à l'espace monde
				float3 worldNorm = TransformObjectToWorldNormal(v.normal); // Utilisez cette fonction pour la transformation
				// Transforme la position de l'espace objet à l'espace monde
				float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
				// Calcule la distance entre la caméra et le point sur la surface
				float dist = distance(_WorldSpaceCameraPos.xyz, worldPos);
				// Calcule l'échelle du contour en fonction de la distance
				float outlineScale = max(_OutSizeMin, min(_OutSizeMax, dist));
				// Applique l'échelle du contour à la position du vertex
				o.vertex = TransformObjectToHClip(v.vertex + float4(worldNorm * outlineScale, 0.0));
				o.uv = v.uv;
				return o;
			}
			

			float4 frag(v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)
				// Renvoie la couleur du contour
				return float4(_OutlineColor, 1.0);
			}
			ENDHLSL
		}
		
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Custom.hlsl" // Si nécessaire
			#include "AnimeShading.hlsl"
			#include "GradualDirt.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				half4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half3 worldNorm : TEXCOORD1;
				half3 worldPos : TEXCOORD2;
				half4 shadowCoord : TEXCOORD3;
				UNITY_VERTEX_OUTPUT_STEREO
				// Ajoutez d'autres variables si nécessaire pour la lumière et les ombres
			};
			
			TEXTURE2D(_MainTex);
            TEXTURE2D(_GlobalDirtTex);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_GlobalDirtTex);
			uniform half3 _ToonProximityAmbience;
			uniform half _Dirt;

			v2f vert(appdata v)
			{
				v2f o;
				
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex);

				o.pos = TransformObjectToHClip(v.vertex);
				o.worldNorm = TransformObjectToWorldNormal(v.normal);
				o.worldPos = TransformObjectToWorld(v.vertex.xyz);
				o.uv = v.uv;

				// Calcul des coordonnées d'ombre pour la lumière principale
    			Light mainLight = GetMainLight();
    			o.shadowCoord = GetShadowCoord(vertexInput);

				return o;
			}

			half4 frag(v2f i) : SV_TARGET
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
								
				Light mainLight = GetMainLight();

				half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				
				// Apply dirt/extra texture if necessary
				half4 dirtColor = SAMPLE_TEXTURE2D(_GlobalDirtTex, sampler_GlobalDirtTex, i.uv * 0.25);
				color = lerp(color, dirtColor.rgb, _Dirt);

				// Main light information
				half3 lightColor = mainLight.color; // No need to multiply by intensity
				// Calcul de la direction de la lumière
				half3 lightDir = -mainLight.direction;

				// Calcul du produit scalaire entre la normale de la surface et la direction de la lumière
				// Utilisation de 'smoothstep' pour adoucir les transitions entre les zones éclairées et les zones ombragées
				half ndotl = max(0.0, dot(normalize(i.worldNorm), -lightDir));
				ndotl = smoothstep(0.0, 1.0, ndotl);

				// Calcul de l'éclairage en tenant compte de la couleur de la lumière et de l'atténuation des ombres
				// 'shadowIntensity' est un paramètre que vous pouvez ajuster pour contrôler l'intensité des ombres
				half shadowIntensity = 0.5; // Exemple : 0.5 pour des ombres moyennement prononcées
				half3 lighting = lightColor * (ndotl + shadowIntensity);

				// Add lighting to the color
				color = color * lighting;

				// Add ambient lighting
				half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * 1.;
				color += color * ambient;

				
				return half4(color, 1.0);
			}
			ENDHLSL
		}
	}

	Fallback "VertexLit"
}
