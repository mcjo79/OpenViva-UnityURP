Shader "Unlit/ghostNearbyEffect"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
        _Distortion ("Distortion", Range(0.0,0.001)) = 0.0005
        _Strength ("Strength", Range(-1.0,1.0)) = 0.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			
			Cull Back

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
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
				float4 uvKernel : TEXCOORD0;

				UNITY_VERTEX_OUTPUT_STEREO
			};

			TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            uniform half _Distortion;
            uniform half _Strength;

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.vertex = TransformObjectToHClip(v.vertex);
				float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
				o.uvKernel.xy = v.uv.xy * scaleOffset.xy + scaleOffset.zw * o.vertex.w;
				o.uvKernel.zw = float2(3.0,3.0)/_ScreenParams.xy;
				return o;
			}

            half luma( half3 rgb ){
                return dot( rgb, half3( 0.378, 0.599, 0.114 ) );
            }

			half4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				
				half2 offset;
				offset.x = sin( (i.uvKernel.x+_SinTime.y)*13. );
				offset.y = cos( (i.uvKernel.y+_CosTime.y)*11.1+offset.x );
				offset *= _Distortion*_Strength;
				half2 uv = i.uvKernel.xy+offset;
                
				half3 raw = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
				half3 col = luma(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uvKernel.xy).rgb) * _Strength + raw;

				return half4( col, 1. );
			}
			ENDHLSL
		}
    }
}
