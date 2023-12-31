﻿Shader "Effects/photoDataAlphaCutout"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader
	{
		LOD 100
		Cull Back

		Tags{ "PhotoData"="Opaque"}

		Pass
		{
			
			Tags {
				"LightMode" = "ForwardBase"
				"RenderType"="Opaque"
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;

                UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _MainTex;
			float4 _PhotoDataColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)

                return _PhotoDataColor;
			}
			ENDCG
		}
	}
}
