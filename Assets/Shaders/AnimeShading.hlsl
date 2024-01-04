 

float3 AnimeShade4PointLights (
	float4 lightPosX, float4 lightPosY, float4 lightPosZ,
	float3 lightColor0, float3 lightColor1,
	float3 lightColor2, float3 lightColor3,
	float4 lightAttenSq, float3 pos, float3 normal) {
	// to light vectors
	float4 toLightX = lightPosX - pos.x;
	float4 toLightY = lightPosY - pos.y;
	float4 toLightZ = lightPosZ - pos.z;
	// squared lengths
	float4 lengthSq = 0;
	lengthSq += toLightX * toLightX;
	lengthSq += toLightY * toLightY;
	lengthSq += toLightZ * toLightZ;
	// NdotL
	float4 ndotl = 0;
	ndotl += toLightX * normal.x;
	ndotl += toLightY * normal.y;
	ndotl += toLightZ * normal.z;
	// correct NdotL
	float4 corr = rsqrt(lengthSq);
	ndotl = max(float4(0,0,0,0), ndotl * corr);
	// attenuation
	float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
	//float4 diff = ( 0.3+smoothstep( 0.4, 0.8, ndotl )*0.7 ) * atten;
	float4 diff = ( 0.7+ndotl*0.3 ) * atten;
    //diff = saturate( diff*1.05-0.05 );
	// final color
	float3 col = 0;
	col += lightColor0 * diff.x;
	col += lightColor1 * diff.y;
	col += lightColor2 * diff.z;
	col += lightColor3 * diff.w;
	return col;
}

half screenChannel( half a, half b ){
	a = 1.-a;
	b = 1.-b;
	return 1.-a*b;
}

half3 screenColor( half3 a, half3 b ){
	return half3( screenChannel( a.r, b.r ), screenChannel( a.g, b.g ), screenChannel( a.b, b.b ) );
}

half3 ApplyColorFromLight( half3 a, half3 b, half sun, half camRim, half worldRim ){
	half3 lightColor = GetMainLight().color;
	half4 _LightColor0 = half4(lightColor, 1.0);

    half lightRim = saturate(3.0-camRim*6.)*worldRim;
    camRim = 1.-saturate(camRim+0.3);
    camRim *= camRim;
    a *= saturate(1.-camRim); //darkening
	a = screenColor( a, _LightColor0*sun );	//lights
    a += _LightColor0*lightRim;	//lights
    return a;
}