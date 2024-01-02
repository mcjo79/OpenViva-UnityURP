float4 CustomObjectToClipPos(float3 positionOS) {
    float4 positionWS = mul(unity_ObjectToWorld, float4(positionOS, 1.0));
    float4 positionCS = mul(UNITY_MATRIX_VP, positionWS);
    return positionCS;
}

// Vous pouvez ajouter d'autres fonctions personnalisées ici
float3 WorldSpaceViewDir(float3 worldPos) {
    return _WorldSpaceCameraPos.xyz - worldPos;
}

float3 CustomWorldSpaceViewDir(float3 worldPos) {
    return normalize(_WorldSpaceCameraPos.xyz - worldPos);
}

half tri(half f) {
    return smoothstep(0.0, 1.0, abs(0.5 - frac(f)) * 2.0);
}

half3 ApplyWind(half time, half3 pos, half3 strength) {
    half3 offset;
    offset.x = tri(time + pos.x);
    offset.y = tri(time + pos.y + _SinTime.z);
    offset.z = tri(time + pos.z + _CosTime.w);
    return pos + offset * strength;
}

half zigZagNoise(half2 pos) {
    half o1 = abs(frac(pos.x) - 0.5) * 2.0;
    return abs(frac(pos.y + o1) - 0.5) * 2.0;
}
