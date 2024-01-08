Shader "SP2/underwaterEffect"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_Tint("Water Color",Color)=(1,1,1)
	}
	SubShader
	{
        
        Tags {
            "RenderType"="Opaque"
        }

        Cull Back
        LOD 100

		Pass
		{
			HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"   
			#include "../custom.hlsl"

        
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            uniform half3 _Tint;

			struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
				float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;

                UNITY_VERTEX_OUTPUT_STEREO
            };

			v2f vert (appdata v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = TransformObjectToHClip(v.vertex);
				o.uv.xy = TransformStereoScreenSpaceTex( v.uv, o.vertex.w );
				o.uv.zw = float2(3.0,3.0)/_ScreenParams.xy;
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(v, o);
				
				return o;
			}

			

			// Fonction pour échantillonner la texture avec un décalage UV
			half4 sampleTextureWithOffset(half2 uvOffset) {
				return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvOffset);
			}

			half4 frag(v2f i) : SV_Target {
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				// Calcul de l'offset pour l'effet d'ondulation
				half2 offset;
				offset.x = sin((i.uv.x + _SinTime.w) * 13.0);
				offset.y = cos((i.uv.y + _CosTime.w) * 11.1 + offset.x);
				offset *= 0.0008;

				// Calcul des coordonnées UV ajustées
				half2 uv = i.uv.xy + offset;
				// Arrondir aux pixels les plus proches
				uv.x = floor(uv.x * _ScreenParams.x) / _ScreenParams.x;
				uv.y = floor(uv.y * _ScreenParams.y) / _ScreenParams.y;

				// Accumulation des échantillons de texture avec différents offsets
				half4 col = sampleTextureWithOffset(uv + half2(0, 0)) * 2.0;
				col.rgb += sampleTextureWithOffset(uv + half2(i.uv.z, i.uv.w)).rgb;
				col.rgb += sampleTextureWithOffset(uv + half2(-i.uv.z, -i.uv.w)).rgb;
				col.rgb += sampleTextureWithOffset(uv + half2(i.uv.z, -i.uv.w)).rgb;

				// Application du Tint et division par le nombre total d'échantillons
				col.rgb *= _Tint / 5.0;

				return half4(col.rgb, 1.0);
			}

			ENDHLSL
		}
    }
}
