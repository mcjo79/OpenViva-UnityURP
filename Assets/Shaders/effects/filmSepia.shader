Shader "SP2/filmSepia"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_FilmDirt ("Film Dirt", 2D) = "white" {}
		_FilmColor ("Skin base color",Color) = (1.,0.86,1.0)
        
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="UniversalForward" }
		LOD 100
		Offset -1, -1

		Pass
		{

			HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _MAIN_LIGHT_SHADOWS
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

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
            TEXTURE2D(_FilmDirt);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_FilmDirt);

			uniform half3 _FilmColor;

			v2f vert (appdata v)
			{
				v2f o;
				
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = TransformObjectToHClip(v.vertex);
				o.uv = v.uv;
				return o;
			}

			half screen( half a, half b ){
				return 1.-(1.-a)*(1.-b);
			}

			half3 screen( half3 a, half3 b ){
				return half3( screen(a.r,b.r), screen(a.g,b.g), screen(a.b,b.b) );
			}
			

			half4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)

				half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;
                col = screen(col, _FilmColor);
                col *= SAMPLE_TEXTURE2D(_FilmDirt, sampler_FilmDirt, i.uv).rgb;
                return half4(col, 1.0);

			}
			ENDHLSL
		}
    }
}
