Shader "SP2/playerHurt"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_Overlay ("Overlay Texture", 2D) = "white" {}
		_Alpha ("Hurt Alpha",Range(0.,1.0)) = 1.0
		_CloudsRT ("Cloud Render Texture", 2D) = "white" {}
        
	}
	SubShader
	{
		Tags {
				"RenderType"="Opaque"
		}
		LOD 100
		Cull Back

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
            TEXTURE2D(_Overlay);
            SAMPLER(sampler_Overlay);
            TEXTURE2D(_CloudsRT);
            SAMPLER(sampler_CloudsRT);
			uniform float _Alpha;

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = TransformObjectToHClip(v.vertex);
				o.uv = TransformStereoScreenSpaceTex( v.uv, o.vertex.w );
				return o;
			}
			

			half4 frag (v2f i) : SV_Target
			{
				
    			half4 col =SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				col.rgb += SAMPLE_TEXTURE2D(_CloudsRT, sampler_CloudsRT, i.uv).rgb*saturate(1.-col.a);
				half overlay = SAMPLE_TEXTURE2D(_Overlay, sampler_Overlay, i.uv).r*_Alpha;
                col.bg -= overlay;
				col.r *= 1.-overlay;
				return half4( col.rgb, 1. );
			}
			ENDHLSL
		}
    }
}
