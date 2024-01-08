Shader "Anime/AnimeClothing"
{
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
        _ToonProximityAmbience ("Toon Proximity Ambience",Color) = (1.,1.,1.)
        _Cutoff("Cutout", Range(0,1)) = 0.5
        _OutSizeMin ("Outline Size Min",Range(0.,0.003)) = 0.001
        _OutSizeMax ("Outline Size Max",Range(0.,0.003)) = 0.001
        _PhotoDataColor ("Photo Data Color",Color) = (0.,1.,0.,1.)
        _Dirt ("Dirt",Range(0.,1)) = 0
    }

    SubShader{
        Tags { "Queue"="Transparent-1" "IgnoreProjector"="True" "RenderType"="TransparentCutout" }
        LOD 200
 
        // Pass for shadows removed as URP handles shadows differently
 
        Pass{
            Tags{
                "LightMode" = "UniversalForward"
                "RenderType"="Transparent"
                "Queue"="AlphaTest+1"
            }
            Cull off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos: TEXCOORD1;
                float3 worldNorm: TEXCOORD2;
                float3 worldViewDir : TEXCOORD3;
            };

			TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
			TEXTURE2D(_GlobalDirtTex);
            SAMPLER(sampler_GlobalDirtTex);
            uniform float3 _ToonProximityAmbience;
            uniform float _Dirt;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = TransformObjectToHClip(v.vertex);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldNorm = TransformObjectToWorldNormal(v.normal);

                o.uv = v.uv;
                o.worldViewDir = -_WorldSpaceCameraPos.xyz + o.worldPos; // In world space
                return o;
            }

            float4 frag(v2f i) : SV_Target
			{
				//UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)

				// Sampling the main texture
				float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

				// Fetching the main light properties
				Light mainLight = GetMainLight();
				float3 lightDir = mainLight.direction;
				float3 lightColor = mainLight.color;

				// Calculating the dot product between the normal and the light direction
				float ndotl = max(0.0, dot(i.worldNorm, -lightDir));

				// Applying a smoothstep function to soften the transition between light and shadow
				ndotl = smoothstep(0.0, 1.0, ndotl);

				// Optional: Adding a bias to the shadow transition to make it less harsh
				float shadowBias = 0.8; // Value to control shadow softness
				ndotl += shadowBias;

				// Calculating the final lighting with ambient and the main light
				float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.xyz;
				float3 finalLighting = ambientLight + lightColor * ndotl;

				// Applying the final lighting to the color
				color.rgb *= finalLighting;

				return color;
			}
            ENDHLSL
        }
    }

    Fallback "Universal Render Pipeline/Lit"
}
