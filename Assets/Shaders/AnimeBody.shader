
Shader "Anime/AnimeBody"
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
		_FingerNailColor ("Finger Nail Color",Color) = (1.,1.,1.,1.)
		_ToeNailColor ("Toe Nail Color",Color) = (1.,1.,1.,1.)
		_PhotoDataColor ("Photo Data Color",Color) = (0.,1.,0.,1.)
		_Dirt ("Dirt",Range(0.,1)) = 0
	}

	SubShader
	{
		Tags {
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}
		LOD 100

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
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform float _OutSizeMin;
			uniform float _OutSizeMax;
			uniform float3 _OutlineColor;

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 worldNorm = TransformObjectToWorldNormal(v.normal);
				float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
				float dist = distance(_WorldSpaceCameraPos.xyz, worldPos);
				float outlineScale = max(_OutSizeMin, min(_OutSizeMax, dist));
				o.pos = TransformObjectToHClip(v.vertex + float4(worldNorm * outlineScale, 0.0));
				o.uv = v.uv;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				return float4(_OutlineColor, 1.0);
			}
			ENDHLSL
		}
		
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
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
				half4 pos : SV_POSITION;    // Used for TRANSFER_VERTEX_TO_FRAGMENT
				half2 uv : TEXCOORD0;
				half3 worldNorm : TEXCOORD1;
				half3 worldPos : TEXCOORD2;
				float4 shadowCoord : TEXCOORDx;
				UNITY_VERTEX_OUTPUT_STEREO
			};
			uniform half3 _SkinColor;
			uniform half3 _SkinShadeColor;
			uniform half3 _ToonProximityAmbience;
			uniform half _Dirt;
			uniform half3 _FingerNailColor;
			uniform half3 _ToeNailColor;

			TEXTURE2D(_MainTex);
            TEXTURE2D(_GlobalDirtTex);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_GlobalDirtTex);

			v2f vert (appdata v)
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
			
			half4 frag(v2f i) : SV_Target
			{

				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)



				// Texture sampling
				half3 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;

				// Determine nail or skin colors
				half isHand = step(0.75, baseColor.g);
				half isFinger = step(0.15, baseColor.g) * (1.0 - isHand);
				half neither = step(isHand + isFinger, 0.0);
				half3 color = _FingerNailColor * isHand + _ToeNailColor * isFinger + _SkinColor * neither;

				// Main light information
				Light mainLight = GetMainLight();
				half3 lightDir = -mainLight.direction;
				half3 lightColor = mainLight.color;

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
				half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				color += _SkinColor * ambient;
				
				return half4(color, 1.0);
			}
			ENDHLSL
		}
	}

	Fallback "VertexLit"
}
