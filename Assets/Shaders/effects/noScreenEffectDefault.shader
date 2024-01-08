Shader "Effects/NoScreenEffectDefault"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
        _CloudsRT ("Cloud Render Texture", 2DArray) = "" {}
	}
	SubShader
	{
		LOD 100

		Pass
		{
			Tags {
				"RenderType"="Opaque"
			}
			Cull Back

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma require 2darray

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_OUTPUT_STEREO
			};

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D_ARRAY(_CloudsRT);
			SAMPLER(sampler_CloudsRT);

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = TransformObjectToHClip(v.vertex);
				//float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
				o.uv =  v.uv; //.xy * scaleOffset.xy + scaleOffset.zw * o.vertex.w;
                //UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(v, o); 
				return o;
			}

			half3 applyClouds( half4 color, half4 clouds ){
				half cloudAlpha = step(color.a,0.0)*clouds.a*0.9;
				return color.rgb*(1.-cloudAlpha)+clouds.rgb*cloudAlpha;
			}
			

			half luma(half3 rgb) {
				return dot(rgb, half3(0.2126, 0.7152, 0.0722));
			}

			half4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				

				half3 raw = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;
				half3 col = luma(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy).rgb) + raw;


				float4 clouds_col = SAMPLE_TEXTURE2D_ARRAY(_CloudsRT, sampler_CloudsRT, i.uv, 0);
				
				col.rgb = applyClouds( float4(col, 1.0), clouds_col );
				return half4(col, 1.0);
			}
			ENDHLSL
		}
    }
}
