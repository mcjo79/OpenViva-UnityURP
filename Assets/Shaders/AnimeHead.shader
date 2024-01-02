
Shader "Anime/AnimeHead"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_SkinColor ("Skin color",Color) = (1.,0.86,0.82)
		_SkinShadeColor ("Skin Shade color",Color) = (1.,0.86,0.82)
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
				UNITY_VERTEX_OUTPUT_STEREO
				// Ajoutez d'autres variables si nécessaire pour la lumière et les ombres
			};
			
			TEXTURE2D(_MainTex);
            TEXTURE2D(_GlobalDirtTex);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_GlobalDirtTex);
			uniform half3 _SkinColor;
			uniform half3 _SkinShadeColor;
			half3 _ToonProximityAmbience;
			half _Dirt;

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.pos = TransformObjectToHClip(v.vertex);

				o.pos = TransformObjectToHClip(v.vertex);
				o.worldNorm = TransformObjectToWorldNormal(v.normal);
				o.worldPos = TransformObjectToWorld(v.vertex.xyz);
				o.uv = v.uv;
				return o;
			}

			half4 frag(v2f i) : SV_TARGET
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
								
				Light mainLight = GetMainLight();

				half worldRim = saturate( dot( mainLight.direction, i.worldNorm ) );
				half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

				half4 dirtColor = SAMPLE_TEXTURE2D(_GlobalDirtTex, sampler_GlobalDirtTex, i.uv * 0.25);
				color = lerp(color, dirtColor.rgb, _Dirt);

				// Récupérez les informations de la lumière principale	
				half3 lightDir = mainLight.direction;
				half3 lightColor = mainLight.color;



				// Calculs d'éclairage
				half ndotl = max(0.0, dot(normalize(i.worldNorm), normalize(lightDir)));
				half3 lighting = lightColor * ndotl * _ToonProximityAmbience;

				// Ajoutez l'éclairage à la couleur
				color = color * lighting;
				
				return half4(color, 1);
			}
			ENDHLSL
		}
	}

	Fallback "VertexLit"
}
