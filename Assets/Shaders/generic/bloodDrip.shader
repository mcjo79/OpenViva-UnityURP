Shader "Surface/BloodDrip" {
	Properties {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _RoughnessMetallic ("Roughness", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump" {}
        _BloodColor ("Blood Color", Color) = (1,0,0,1)
        _BloodNormal ("Blood Normal", 2D) = "bump" {}
        _BloodRoughness ("Blood Smoothness", Range(0,1)) = 0.0
        _Blood ("Blood Amount", Range(0,1)) = 0.0
        _SolveColor ("Solve Normal", Color) = (0,0.7,1,1)
        _Solve ("Solve Amount", Range(0,1)) = 0.0
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }
        LOD 200
        Cull Off

        Pass {
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "../Custom.hlsl"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float3 worldNorm : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_RoughnessMetallic);
            TEXTURE2D(_Normal);
            TEXTURE2D(_BloodNormal);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_RoughnessMetallic);
            SAMPLER(sampler_Normal);
            SAMPLER(sampler_BloodNormal);

            uniform float4 _BloodColor;
            uniform float _BloodRoughness;
            uniform float _Blood;
            uniform float4 _SolveColor;
            uniform float _Solve;

            v2f vert(appdata v) {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.uv_MainTex = v.uv_MainTex;
                o.worldNorm = TransformObjectToWorldNormal(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                return o;
            }

            float4 frag(v2f i) : SV_Target {
                float4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv_MainTex);
                float3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv_MainTex));
                float3 bloodNormalMap = UnpackNormal(SAMPLE_TEXTURE2D(_BloodNormal, sampler_BloodNormal, i.uv_MainTex));

                float random = cos(_SinTime.w + (i.uv_MainTex.y + sin(i.uv_MainTex.x * 4.0)) * 4.0 + _Time.w);
                float blood = smoothstep(_Blood * (0.9 + random * 0.2), 0.0, baseColor.a);
                baseColor.rgb = lerp(baseColor.rgb, _BloodColor.rgb, blood);

                float3 finalNormal = lerp(normalMap, bloodNormalMap, blood * (0.95 + random * 0.1));

                float2 roughnessMetallicMap = SAMPLE_TEXTURE2D(_RoughnessMetallic, sampler_RoughnessMetallic, i.uv_MainTex).rg;
                float metallic = roughnessMetallicMap.g;
                float smoothness = lerp(roughnessMetallicMap.r, _BloodRoughness, blood);

                float3 emission = lerp(float3(0.0, 0.0, 0.0), _SolveColor.rgb, _Solve * blood);
				//return float4(baseColor.xyz, 1.0);
                // Final pixel color
                float4 finalColor = baseColor;
				finalColor.rgb += emission; // Add emission
				
				return finalColor;
            }
            ENDHLSL
        }
    }
    FallBack "Universal Render Pipeline/Lit"
}
