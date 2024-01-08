Shader "Surface/OnsenSurface" {

     Properties {
        _PrimaryWaterColor ("Primary Water Color", Color) = (0.,0.,1.,0.)
        _EdgeMap ("EdgeMap", 2D ) = "black" {}
        _EdgeAlphaFalloff ("Edge Alpha Falloff", Range(0.,1.0)) = 0.25
        _EdgeColorFalloff ("Edge Color Falloff", Range(0.,1.0)) = 0.25
        _MainTex ("Normal", 2D ) = "bump" {}
        _NoiseScale ("Noise Scale", Range(0.,8.0)) = 1.0
        _Smoothness ("Smoothness", Range(0.,1.0)) = 0.25
        _NormalStrength ("Normal Strength Mult", Range(0.,1.0)) = 0.5
        _NoiseSpeed ("Noise Speed", Range(0.,2.)) = 2.
        _FlowSpeed ("Flow Speed", Range(0.,4.)) = 2.
     }

     SubShader {
        
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Cull off
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        LOD 200

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"   

        
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_EdgeMap);
            SAMPLER(sampler_EdgeMap);
            uniform half _NoiseScale;
            uniform half _EdgeAlphaFalloff;
            uniform half _EdgeColorFalloff;
            uniform half _NoiseSpeed;
            uniform half4 _PrimaryWaterColor;
            uniform half _Smoothness;
            uniform half _FlowSpeed;
            uniform half _NormalStrength;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v) {
                
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.vertex).xyz;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                //UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(v, o); // Pour la prise en charge stéréo
                return o;
            }

            

            half noiseBlend( half f ){
                half p = step( 0.5, f );
                half r = f*2.*(1.-p)+(1.-(f-.5)*2.)*p;
                return smoothstep( 0., 1., r );
            }

            half2 pseudoRandomSample( Texture2D<float4> tex, SamplerState sampler_Tex,  half2 uv, half time ){
                half n1 = noiseBlend( frac( time ) );
                half n2 = noiseBlend( frac( time+0.3333 ) );
                half n3 = noiseBlend( frac( time+0.6666 ) );
                half flowSpeed = _Time.x*_FlowSpeed;
                half2 sample1 = SAMPLE_TEXTURE2D(tex, sampler_Tex, uv + half2(flowSpeed, 0.0) + floor(time) * 0.541).rg;
                half2 sample2 = SAMPLE_TEXTURE2D(tex, sampler_Tex, uv + half2(-0.5 * flowSpeed, 0.87 * flowSpeed) - floor(time + 0.3333) * 0.781).gr;
                half2 sample3 = SAMPLE_TEXTURE2D(tex, sampler_Tex, uv + half2(-0.5 * flowSpeed, -0.87 * flowSpeed) + floor(time + 0.6666) * 0.367).rg;

                return (sample1 * n1 + sample2 * n2 + sample3 * n3) * 0.6666;
            }

            half4 frag(v2f i) : SV_Target {
                half edge = SAMPLE_TEXTURE2D(_EdgeMap, sampler_EdgeMap, i.uv).r;
                half alpha = _PrimaryWaterColor.a - edge * _EdgeAlphaFalloff;
                half3 albedo = _PrimaryWaterColor.rgb - edge * _EdgeColorFalloff;


                // Calcul du bruit pseudo-aléatoire

                half2 noise = pseudoRandomSample(_MainTex, sampler_EdgeMap, i.uv * _NoiseScale, _Time.y * _NoiseSpeed) * _NormalStrength;

                half3 lightDirection = normalize(_MainLightPosition - i.worldPos);
                //half3 normal = normalize(i.worldNormal);
                half3 normal = normalize(half3(noise.rg, 1.0));
                half Lambertian = max(0, dot(normal, lightDirection));

                // Appliquez la couleur de la lumière et l'intensité de la lumière
                half3 lighting = _MainLightColor.rgb * _MainLightColor.a * Lambertian;
                // Normalisez le bruit et créez une normale
                //half3 normal = normalize(half3(noise.rg, 1.0));

                // Calculez l'éclairage en utilisant la fonction Unity standard
                ///half3 lighting = LightingStandard(i.worldPos, i.worldNormal, half3(0, 0, 1));

                // Appliquez la couleur, la transparence et le lissage
                half3 finalColor = albedo * lighting * _Smoothness;
                half4 finalPixel = half4(finalColor, alpha * 0.8);

                return finalPixel;
            }

            ENDHLSL
        }
     }
 }