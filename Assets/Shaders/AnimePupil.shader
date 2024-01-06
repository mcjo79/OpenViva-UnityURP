Shader "Anime/AnimePupilShader"
{
	Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _ToonProximityAmbience ("Toon Proximity Ambience",Color) = (1.,1.,1.)
        _PupilShrink ("Pupil Shrink",Range(1.,2.)) = 1.0
        _SideMultiplier ("Side Multiplier",Range(-1.,1.)) = 1.0
        _PupilRight ("Pupil Right",Range(-1.,1.)) = 0.0
        _PupilUp ("Pupil Up",Range(-1.,1.)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            
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
				float3 normal : NORMAL; // Ajout de la normale mondiale
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 worldNorm : NORMAL;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            uniform float _PupilShrink;
            uniform float _PupilRight;
            uniform float _SideMultiplier;
            uniform float _PupilUp;
            uniform float3 _ToonProximityAmbience;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.uv = (o.uv - 0.5) * _PupilShrink + 0.5;
                o.uv.x += _PupilRight * _SideMultiplier;
                o.uv.y -= _PupilUp;
				o.worldNorm = TransformObjectToWorldNormal(v.normal); // Calcule de la normale mondiale
				
                return o;
            }

            float4 frag(v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i)

				// Sample the texture
				float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

				// Main light information
				Light mainLight = GetMainLight();
				float3 lightColor = mainLight.color; // No need to multiply by intensity

				// Compute the light direction
				float3 lightDir = -mainLight.direction;

				// Compute the dot product between the surface normal and the light direction
				// Use 'smoothstep' to soften the transitions between lit and shadowed areas
				float ndotl = max(0.0, dot(normalize(i.worldNorm), -lightDir));
				ndotl = smoothstep(0.0, 1.0, ndotl);

				// Compute lighting considering the light color and the shadow attenuation
				// 'shadowIntensity' is a parameter you can adjust to control the shadow intensity
				float shadowIntensity = 0.8; // Example: 0.5 for moderately pronounced shadows
				float3 lighting = lightColor * (ndotl + shadowIntensity);

				// Add lighting to the color
				color.rgb *= lighting;

				// Add ambient lighting
				float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				color.rgb += ambient;

				return color;
			}

            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}