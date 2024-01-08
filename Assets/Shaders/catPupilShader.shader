Shader "Surface/CatPupilShader" {

     Properties {
		_MainTex ("Base", 2D) = "white" {}
		_PupilShrink ("Pupil Shrink",Range(1.,4.)) = 1.0
		_PupilRight ("Pupil Right",Range(-1.,1.)) = 0.0
		_PupilUp ("Pupil Up",Range(-1.,1.)) = 0.0
		_Emission ("Pupil Up",2D) = "black" {}
     }

     SubShader {
        
        Tags {
             "RenderType"="Opaque"
             "PhotoData"="Opaque"
        }

        LOD 200

        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma Standard fullforwardshadows
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_Emission);
            SAMPLER(sampler_Emission);
            uniform half _PupilShrink;
            uniform half _PupilRight;
            uniform half _PupilUp;
            

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v) {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                //UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(v, o); 
                return o;
            }
            
            half4 frag(v2f i) : SV_Target {
            
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)

                half2 uv = i.uv;
                uv.x += _PupilRight;
                uv.x = (uv.x - 0.5) * _PupilShrink + 0.5;
                uv.y += _PupilUp;

                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
                half3 emission = SAMPLE_TEXTURE2D(_Emission, sampler_Emission, uv).rgb;

                return half4(albedo, 1) + half4(emission, 1);
            }
            ENDHLSL
        }
     }
 }