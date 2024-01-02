Shader "Surface/ParallaxCorrected" {
    Properties{
        _MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
        _Roughness("Metallic Roughness Texture", 2D) = "white" {}
        _NormalTex("Normal Texture", 2D) = "bump" {}
        _CubeMap("Cube Map", CUBE) = "" {}
        _CubeCenter("Cube center",Vector) = (0,0,0)
        _CubeMin("Cube min",Vector) = (0,0,0)
        _CubeMax("Cube max",Vector) = (0,0,0)
        _PhotoDataColor("Photo Data Color", Color) = (0,0,0,1)
    }

        SubShader{
            Tags {
                "RenderType" = "Opaque"
                "PhotoData" = "Opaque"
            }

            LOD 200
            Cull Back

            Pass {
                HLSLPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                struct Attributes {
                    float4 positionOS : POSITION;
                    float2 uv_MainTex : TEXCOORD0;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                };

                struct Varyings {
                    float4 positionCS : SV_POSITION;
                    float2 uv_MainTex : TEXCOORD0;
                    float3 worldRefl : TEXCOORD1;
                    float3 worldPos : TEXCOORD2;
                };

                TEXTURE2D(_MainTex);
                TEXTURE2D(_Roughness);
                TEXTURE2D(_NormalTex);
                TEXTURECUBE(_CubeMap);
                SAMPLER(sampler_MainTex);
                SAMPLER(sampler_Roughness);
                SAMPLER(sampler_NormalTex);
                SAMPLER(sampler_CubeMap);

                uniform float4 _CubeCenter;
                uniform float3 _CubeMin;
                uniform float3 _CubeMax;

                float3 WorldSpaceViewDir(float3 worldPos) {
                    return _WorldSpaceCameraPos - worldPos;
                }

                Varyings vert(Attributes IN) {
                    Varyings OUT;
                    OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                    OUT.uv_MainTex = IN.uv_MainTex;

                    float3 worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                    float3 worldTangent = TransformObjectToWorldDir(IN.tangentOS.xyz);
                    float3 worldBinormal = cross(worldNormal, worldTangent) * IN.tangentOS.w;
                    float3x3 TBN = float3x3(worldTangent, worldBinormal, worldNormal);

                    OUT.worldRefl = mul(TBN, -WorldSpaceViewDir(IN.positionOS.xyz));
                    OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);

                    return OUT;
                }

                half4 frag(Varyings IN) : SV_Target{
                    half3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv_MainTex));
                    half2 data = SAMPLE_TEXTURE2D(_Roughness, sampler_Roughness, IN.uv_MainTex).ra;
                    half metallic = data.r;
                    half smoothness = data.g;

                    // Utilisez la normale pour échantillonner directement la cubemap
                    half3 cubeColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, normal).rgb;

                    // Couleur albedo du matériau
                    half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex).rgb;

                    // Mélanger la couleur cubemap avec l'albedo basé sur la rugosité/le lissage de la surface
                    half3 finalColor = lerp(albedo, cubeColor, smoothness);

                    return half4(finalColor, 1);
                }


                ENDHLSL
            }
        }

            FallBack "Universal Render Pipeline/Lit"
}
