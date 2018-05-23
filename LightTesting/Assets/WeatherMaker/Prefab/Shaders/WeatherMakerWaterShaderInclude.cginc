//
// Weather Maker for Unity
// (c) 2016 Digital Ruby, LLC
// Source code may be used for personal or commercial projects.
// Source code may NOT be redistributed or sold.
// 
// *** A NOTE ABOUT PIRACY ***
// 
// If you got this asset off of leak forums or any other horrible evil pirate site, please consider buying it from the Unity asset store at https ://www.assetstore.unity3d.com/en/#!/content/60955?aid=1011lGnL. This asset is only legally available from the Unity Asset Store.
// 
// I'm a single indie dev supporting my family by spending hundreds and thousands of hours on this and other assets. It's very offensive, rude and just plain evil to steal when I (and many others) put so much hard work into the software.
// 
// Thank you.
//
// *** END NOTE ABOUT PIRACY ***
//

#ifndef __WEATHER_MAKER_WATER_INCLUDED__
#define __WEATHER_MAKER_WATER_INCLUDED__

#include "WeatherMakerShader.cginc"

// textures
uniform sampler2D _WaterBumpMap;
uniform float4 _WaterBumpMap_ST;
uniform sampler2D _WeatherMakerWaterReflectionTex;
uniform float4 _WeatherMakerWaterReflectionTex_ST;
uniform sampler2D _WeatherMakerWaterReflectionTex2;
uniform float4 _WeatherMakerWaterReflectionTex2_ST;
uniform sampler2D _WeatherMakerWaterRefractionTex;
uniform float4 _WeatherMakerWaterRefractionTex_ST;
uniform sampler2D _FoamTex;
uniform sampler2D _FoamBump;

// water y depth...
uniform sampler2D _WeatherMakerDepthYShadowTex;
uniform float4x4 _WeatherMakerDepthYShadowMatrix;
uniform float4 _WeatherMakerDepthYParams;
uniform float4 _WeatherMakerDepthYPosition;

#if defined(WEATHER_MAKER_LIGHT_SPECULAR_SPARKLE)

uniform sampler2D _SparkleNoise;
uniform fixed4 _SparkleTintColor;
uniform fixed4 _SparkleScale;
uniform fixed4 _SparkleOffset;
uniform fixed4 _SparkleFade;

#endif

uniform sampler3D _CausticsTexture;
uniform fixed4 _CausticsTintColor;
uniform fixed4 _CausticsScale;
uniform fixed4 _CausticsVelocity;

// colors in use
uniform fixed4 _SpecularColor;
uniform fixed _SpecularIntensity;
uniform fixed4 _BaseColor;
uniform fixed4 _WaterColor;
uniform fixed4 _ReflectionColor;

// edge & shore fading
uniform float4 _InvFadeParemeter;

// specularity
uniform float _Shininess;

// fresnel, vertex & bump displacements & strength
uniform float4 _DistortParams;
uniform float _FresnelScale;
uniform float4 _BumpTiling;
uniform float4 _BumpDirection;

uniform half _GerstnerIntensity;
uniform float4 _GAmplitude;
uniform float4 _GFrequency;
uniform float4 _GSteepness;
uniform float4 _GSpeed;
uniform float4 _GDirectionAB;
uniform float4 _GDirectionCD;

// foam
uniform float4 _Foam;

// water floor for shadow / depth pass
uniform fixed _WaterDepthThreshold;

uniform fixed _WaterDitherLevel;
uniform fixed _WaterShadowStrength;

uniform int _VolumetricSampleCount;
uniform fixed _VolumetricSampleMaxDistance;
uniform fixed _VolumetricSampleDither;
uniform fixed _VolumetricShadowPower;
uniform fixed _VolumetricShadowPowerFade;
uniform fixed _VolumetricShadowMinShadow;

// shortcuts
#define PER_PIXEL_DISPLACE _DistortParams.x
#define REALTIME_DISTORTION _DistortParams.y
#define FRESNEL_POWER _DistortParams.z
#define VERTEX_WORLD_NORMAL normalInterpolator.xyz
#define FRESNEL_BIAS _DistortParams.w
#define NORMAL_DISPLACEMENT_PER_VERTEX _InvFadeParemeter.z
#define DISTANCE_SCALE 0.01

struct appdata_water
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	WM_BASE_VERTEX_INPUT
};

struct v2fWater
{
	float4 pos : SV_POSITION;
	float4 normalInterpolator : NORMAL;
	float4 viewInterpolator : TEXCOORD0;
	float4 bumpCoords : TEXCOORD1;
	float4 reflectionPos : TEXCOORD2;
	float4 refractionPos : TEXCOORD3;
	float3 worldPos : TEXCOORD4;
	float3 viewPos : TEXCOORD5;
	float4 yDepthShadowCoords : TEXCOORD6;

#if defined(UNITY_PASS_FORWARDADD)

	LIGHTING_COORDS(7, 8)

#elif defined(UNITY_PASS_FORWARDBASE)

	//SHADOW_COORDS(7)

#endif

	WM_BASE_VERTEX_TO_FRAG
};

inline half3 PerPixelNormal(sampler2D bumpMap, half4 coords, half3 vertexNormal, half bumpStrength)
{
	half3 bump = (UnpackNormal(tex2D(bumpMap, coords.xy)) + UnpackNormal(tex2D(bumpMap, coords.zw))) * 0.5;
	half3 worldNormal = vertexNormal + bump.xxy * bumpStrength * half3(1, 0, 1);
	return normalize(worldNormal);
}

inline half3 PerPixelNormalUnpacked(sampler2D bumpMap, half4 coords, half bumpStrength)
{
	half4 bump = tex2D(bumpMap, coords.xy) + tex2D(bumpMap, coords.zw);
	bump = bump * 0.5;
	half3 normal = UnpackNormal(bump);
	normal.xy *= bumpStrength;
	return normalize(normal);
}

inline half3 GetNormal(half4 tf)
{
	return half3(2, 1, 2) * tf.rbg - half3(1, 0, 1);
}

inline half GetDistanceFadeout(half screenW, half speed) {
	return 1.0f / abs(0.5f + screenW * speed);
}

half4 GetDisplacement3(half4 tileableUv, half4 tiling, half4 directionSpeed, sampler2D mapA, sampler2D mapB, sampler2D mapC)
{
	half4 displacementUv = tileableUv * tiling + _Time.xxxx * directionSpeed;
	half4 tf = tex2Dlod(mapA, half4(displacementUv.xy, 0.0, 0.0));
	tf += tex2Dlod(mapB, half4(displacementUv.zw, 0.0, 0.0));
	tf += tex2Dlod(mapC, half4(displacementUv.xw, 0.0, 0.0));
	tf *= 0.333333;
	return tf;
}

half4 GetDisplacement2(half4 tileableUv, half4 tiling, half4 directionSpeed, sampler2D mapA, sampler2D mapB)
{
	half4 displacementUv = tileableUv * tiling + _Time.xxxx * directionSpeed;
	half4 tf = tex2Dlod(mapA, half4(displacementUv.xy, 0.0, 0.0));
	tf += tex2Dlod(mapB, half4(displacementUv.zw, 0.0, 0.0));
	tf *= 0.5;
	return tf;
}

inline half3 PerPixelNormalUnpacked(sampler2D bumpMap, half4 coords, half bumpStrength, half2 perVertxOffset)
{
	half4 bump = tex2D(bumpMap, coords.xy) + tex2D(bumpMap, coords.zw);
	bump = bump * 0.5;
	half3 normal = UnpackNormal(bump);
	normal.xy *= bumpStrength;
	normal.xy += perVertxOffset;
	return normalize(normal);
}

inline half3 PerPixelNormalLite(sampler2D bumpMap, half4 coords, half3 vertexNormal, half bumpStrength)
{
	half4 bump = tex2D(bumpMap, coords.xy);
	bump.xy = bump.wy - half2(0.5, 0.5);
	half3 worldNormal = vertexNormal + bump.xxy * bumpStrength * half3(1, 0, 1);
	return normalize(worldNormal);
}

inline fixed4 Foam(sampler2D foamTex, half4 coords)
{
	fixed4 foam = (tex2D(foamTex, coords.xy) + tex2D(foamTex, coords.zw)) * 0.5;
	return foam;
}

inline half Fresnel(half3 viewVector, half3 worldNormal, half bias, half power)
{
	half facing = clamp(1.0 - max(dot(-viewVector, worldNormal), 0.0), 0.0, 1.0);
	half refl2Refr = saturate(bias + (1.0 - bias) * pow(facing, power));
	return refl2Refr;
}

inline half FresnelViaTexture(half3 viewVector, half3 worldNormal, sampler2D fresnel)
{
	half facing = saturate(dot(-viewVector, worldNormal));
	half fresn = tex2D(fresnel, half2(facing, 0.5f)).b;
	return fresn;
}

inline void VertexDisplacementHQ(sampler2D mapA, sampler2D mapB,
	sampler2D mapC, half4 uv,
	half vertexStrength, half3 normal,
	out half4 vertexOffset, out half2 normalOffset)
{
	half4 tf = tex2Dlod(mapA, half4(uv.xy, 0.0, 0.0));
	tf += tex2Dlod(mapB, half4(uv.zw, 0.0, 0.0));
	tf += tex2Dlod(mapC, half4(uv.xw, 0.0, 0.0));
	tf /= 3.0;

	tf.rga = tf.rga - half3(0.5, 0.5, 0.0);

	// height displacement in alpha channel, normals info in rgb

	vertexOffset = tf.a * half4(normal.xyz, 0.0) * vertexStrength;
	normalOffset = tf.rg;
}

inline void VertexDisplacementLQ(sampler2D mapA, sampler2D mapB,
	sampler2D mapC, half4 uv,
	half vertexStrength, half normalsStrength,
	out half4 vertexOffset, out half2 normalOffset)
{
	// @NOTE: for best performance, this should really be properly packed!

	half4 tf = tex2Dlod(mapA, half4(uv.xy, 0.0, 0.0));
	tf += tex2Dlod(mapB, half4(uv.zw, 0.0, 0.0));
	tf *= 0.5;

	tf.rga = tf.rga - half3(0.5, 0.5, 0.0);

	// height displacement in alpha channel, normals info in rgb

	vertexOffset = tf.a * half4(0, 1, 0, 0) * vertexStrength;
	normalOffset = tf.rg * normalsStrength;
}

half4  ExtinctColor(half4 baseColor, half extinctionAmount)
{
	// tweak the extinction coefficient for different coloring
	return baseColor - extinctionAmount * half4(0.15, 0.03, 0.01, 0.0);
}

half3 GerstnerOffsets(half2 xzVtx, half steepness, half amp, half freq, half speed, half2 dir)
{
	half3 offsets;

	offsets.x =
		steepness * amp * dir.x *
		cos(freq * dot(dir, xzVtx) + speed * _Time.x);

	offsets.z =
		steepness * amp * dir.y *
		cos(freq * dot(dir, xzVtx) + speed * _Time.x);

	offsets.y =
		amp * sin(freq * dot(dir, xzVtx) + speed * _Time.x);

	return offsets;
}

half3 GerstnerOffset4(half2 xzVtx, half4 steepness, half4 amp, half4 freq, half4 speed, half4 dirAB, half4 dirCD)
{
	half3 offsets;

	half4 AB = steepness.xxyy * amp.xxyy * dirAB.xyzw;
	half4 CD = steepness.zzww * amp.zzww * dirCD.xyzw;

	half4 dotABCD = freq.xyzw * half4(dot(dirAB.xy, xzVtx), dot(dirAB.zw, xzVtx), dot(dirCD.xy, xzVtx), dot(dirCD.zw, xzVtx));
	half4 TIME = _Time.yyyy * speed;

	half4 COS, SIN;
	sincos(dotABCD + TIME, SIN, COS);

	offsets.x = dot(COS, half4(AB.xz, CD.xz));
	offsets.z = dot(COS, half4(AB.yw, CD.yw));
	offsets.y = dot(SIN, amp);

	return offsets;
}

half3 GerstnerNormal(half2 xzVtx, half steepness, half amp, half freq, half speed, half2 dir)
{
	half3 nrml = half3(0, 0, 0);

	nrml.x -=
		dir.x * (amp * freq) *
		cos(freq * dot(dir, xzVtx) + speed * _Time.x);

	nrml.z -=
		dir.y * (amp * freq) *
		cos(freq * dot(dir, xzVtx) + speed * _Time.x);

	return nrml;
}

half3 GerstnerNormal4(half2 xzVtx, half4 amp, half4 freq, half4 speed, half4 dirAB, half4 dirCD)
{
	half3 nrml = half3(0, 2.0, 0);

	half4 AB = freq.xxyy * amp.xxyy * dirAB.xyzw;
	half4 CD = freq.zzww * amp.zzww * dirCD.xyzw;

	half4 dotABCD = freq.xyzw * half4(dot(dirAB.xy, xzVtx), dot(dirAB.zw, xzVtx), dot(dirCD.xy, xzVtx), dot(dirCD.zw, xzVtx));
	half4 TIME = _Time.yyyy * speed;

	half4 COS = cos(dotABCD + TIME);

	nrml.x -= dot(COS, half4(AB.xz, CD.xz));
	nrml.z -= dot(COS, half4(AB.yw, CD.yw));

	nrml.xz *= _GerstnerIntensity;
	nrml = normalize(nrml);

	return nrml;
}

void Gerstner(out half3 offs, out half3 nrml,
	half3 vtx, half3 tileableVtx,
	half4 amplitude, half4 frequency, half4 steepness,
	half4 speed, half4 directionAB, half4 directionCD)
{
	offs = GerstnerOffset4(tileableVtx.xz, steepness, amplitude, frequency, speed, directionAB, directionCD);
	nrml = GerstnerNormal4(tileableVtx.xz + offs.xz, amplitude, frequency, speed, directionAB, directionCD);
}

void ApplyGerstner(inout float4 vertex, inout float3 worldPos, out float3 normal, out float3 offsets)
{
	float3 vtxForAni = worldPos.xzz;
	Gerstner
	(
		offsets, normal, vertex.xyz, vtxForAni,						// offsets, nrml will be written
		_GAmplitude,												// amplitude
		_GFrequency,												// frequency
		_GSteepness,												// steepness
		_GSpeed,													// speed
		_GDirectionAB,												// direction # 1, 2
		_GDirectionCD												// direction # 3, 4
	);
	vertex.xyz += offsets;

	// re-calculate worldPos with new offsets
	worldPos = WorldSpaceVertexPos(vertex).xyz;
}

fixed3 ComputeWaterCaustics(float3 worldPos, float3 rayDir, float z, float2 distortOffset, fixed reducer, fixed density) // density of 0 is fully opaque
{
	float3 depthPos = (_WorldSpaceCameraPos + (rayDir * z));
	float y = depthPos.y;
	fixed waterAmount = distance(worldPos, depthPos);
	fixed toWaterAmount = z - waterAmount;

	// reduce by shadow power and by direction from straight up
	reducer *= CalculateDirLightShadowPower(depthPos, 0);
	reducer *= saturate(0.5 + dot(float3(0.0, 1.0, 0.0), _WeatherMakerSunDirectionUp));
	reducer = pow(reducer, 4.0);

	// if rotating to light, no need to swap z and y as the rotation does it
	depthPos = RotatePointZeroOriginQuaternion(depthPos, _WeatherMakerSunQuaternion);
	//depthPos.y = depthPos.z;

	// rotation animation
	//float sinV, cosV;
	//sincos(_WeatherMakerTime.x * 5, sinV, cosV);
	//depthPos.xy -= _WorldSpaceCameraPos.xz;
	//depthPos.x = depthPos.x * cosV - depthPos.y * sinV;
	//depthPos.y = depthPos.x * sinV + depthPos.y * cosV;
	//depthPos.xy += _WorldSpaceCameraPos.xz;

	// adjust z (depth) animation
	fixed zAnimation = (_WeatherMakerTime * _CausticsVelocity.y);
	float3 samplePos = float3(depthPos.xy * _CausticsScale.x, zAnimation);

	// adjust texture lookup animation
	samplePos.xy -= (_WeatherMakerTime.x * _CausticsVelocity.xz * _BumpDirection.xy);

	// adjust distortion animation
	samplePos.xy += (distortOffset * _CausticsScale.w);

	fixed c = tex3D(_CausticsTexture, samplePos).a * _CausticsScale.y;
	
	// reduce
	c *= reducer;

	// reduce with increased depth, fade linear
	reducer = max(1.0, density * (worldPos.y - y));
	c /= reducer;

	// reduce with small water depth, fade squared
	reducer = min(1.0, waterAmount * _CausticsScale.z);
	c *= (reducer * reducer);

	// reduce with increased distance to water surface from eye, fade linear
	reducer = max(1.0, toWaterAmount * 0.01);
	c /= reducer;

#if defined(WATER_LIGHT_ALL)

	c *= CalculateDirLightShadowPower(depthPos, 0);

#endif

	// reduce caustics squared
	return c * c * _CausticsTintColor * _WeatherMakerSunColor.rgb * _WaterColor.rgb * _WaterColor.rgb;
}

#if defined(WATER_LIGHT_ALL)

void ComputeWaterColorAllLight(float3 worldPos, float3 worldNormal, float3 viewVector,
	
#if defined(WATER_EDGEBLEND_ON)
	
	fixed shadowPowerReducer,
	
#if defined(WEATHER_MAKER_SHADOWS_SOFT) || defined(WEATHER_MAKER_SHADOWS_HARD)

	float sceneZ,

#endif

#endif	
	
	inout fixed4 baseColor, fixed4 specColor)
{

#if defined(WATER_EDGEBLEND_ON) && (defined(WEATHER_MAKER_SHADOWS_SOFT) || defined(WEATHER_MAKER_SHADOWS_HARD))

	int doVolumetricShadows = (_VolumetricSampleCount > 0 && _VolumetricShadowPower > 0.0 && _VolumetricShadowMinShadow < 1.0);
	if (doVolumetricShadows)
	{
		fixed shadowStrength = CalculateSunVolumetricShadowPower
		(
			_VolumetricSampleCount,
			worldPos,
			viewVector,
			_VolumetricSampleDither,
			sceneZ,
			_VolumetricSampleMaxDistance,
			_VolumetricShadowPower * shadowPowerReducer,
			_VolumetricShadowPowerFade,
			_VolumetricShadowMinShadow
		);
		baseColor.rgb *= shadowStrength;
		baseColor.a = max(1.0 - shadowStrength, baseColor.a);
	}

#endif

	baseColor.rgb = CalculateLightColorWorldSpace
	(
		worldPos,
		worldNormal,
		baseColor.rgb,
		viewVector,
		specColor,
		_Shininess,

#if defined(WEATHER_MAKER_LIGHT_SPECULAR_SPARKLE)

		_SparkleNoise,
		_SparkleTintColor,
		_SparkleScale,
		_SparkleOffset,
		_SparkleFade,

#endif

		_WeatherMakerAmbientLightColorGround,
		_WaterShadowStrength
	).rgb;
}

#endif

fixed4 ComputeWaterColor
(
	float4 bumpCoords,
	float4 normalInterpolator,
	float4 viewInterpolator,
	float4 reflectionPos,
	float4 refractionPos,
	float3 viewPos,
	float3 worldPos,
	float4 yDepthShadowCoords,
	float atten,
	out float3 worldNormal
)
{
	WM_INSTANCE_FRAG(i);

	worldNormal = PerPixelNormal(_WaterBumpMap, bumpCoords, VERTEX_WORLD_NORMAL, PER_PIXEL_DISPLACE);
	float3 viewVector = normalize(viewInterpolator.xyz);
	float2 distortOffset = worldNormal.xz * REALTIME_DISTORTION * 10.0;
	float2 reflectionUV = (reflectionPos.xy + distortOffset) / max(0.001, reflectionPos.w);
	float2 refractionUV = (refractionPos.xy) / max(0.001, refractionPos.w);
	fixed4 rtRefractionsNoDistort = tex2Dproj(_WeatherMakerWaterRefractionTex, refractionPos);
	float refrFix = LinearEyeDepth(WM_SAMPLE_DEPTH(refractionUV));
	fixed4 rtRefractions = tex2Dlod(_WeatherMakerWaterRefractionTex, float4(refractionUV + (distortOffset / refractionPos.w), 0.0, 0.0));

#if defined(WATER_REFLECTIVE)
	fixed4 rtReflections = lerp(tex2Dlod(_WeatherMakerWaterReflectionTex, float4(reflectionUV, 0.0, 0.0)),
	tex2Dlod(_WeatherMakerWaterReflectionTex2, float4(reflectionUV, 0.0, 0.0)), reflectionPos.z);
#endif

	// shading for fresnel term
	worldNormal.xz *= _FresnelScale;
	half refl2Refr = Fresnel(viewVector, worldNormal, FRESNEL_BIAS, FRESNEL_POWER) * (FRESNEL_BIAS > -100.0);

#if defined(WATER_EDGEBLEND_ON)

	int tmp = (refrFix < refractionPos.z);
	rtRefractions = (tmp * rtRefractionsNoDistort) + (!tmp * rtRefractions);
	viewPos = normalize(viewPos);
	float depth = refrFix;
	float sceneZ = length(depth / viewPos.z);

	// get distance to depth in y plane
	//float yDepth = _WeatherMakerDepthYPosition.y - (_WeatherMakerDepthYParams.z - (_WeatherMakerDepthYParams.z * tex2Dproj(_WeatherMakerDepthYShadowTex, yDepthShadowCoords).r));
	//yDepth = worldPos.y - yDepth;
	//yDepth += (99999.0 * (yDepth < 0.0));

	float invSceneZ = max(0, depth - _ProjectionParams.g);
	float partZ = max(0, refractionPos.z - _ProjectionParams.g);
	float fade = (pow(saturate((invSceneZ - partZ) / _InvFadeParemeter.x), _InvFadeParemeter.y) * saturate((invSceneZ - partZ) / _InvFadeParemeter.z));
	fixed shadowPowerReducer = fade * (1.0 - refl2Refr);

#if defined(WATER_EDGEBLEND_ON) && !defined(UNITY_PASS_FORWARDADD)

	if (_CausticsScale.x > 0.0 && _CausticsScale.y > 0.0)
	{
		fixed reducer = shadowPowerReducer * atten * min(1.0, _WeatherMakerSunColor.a) * saturate(1.5 - (REALTIME_DISTORTION + PER_PIXEL_DISPLACE));
		rtRefractions.rgb += ComputeWaterCaustics(worldPos, viewVector, sceneZ, distortOffset, reducer, _BaseColor.a);
	}

#endif

#else
	float fade = 1.0;
#endif

	// base, depth & reflection colors
	fixed4 specColor = _SpecularColor;
	specColor.a *= _SpecularIntensity;
	fixed4 baseColor = _BaseColor;

	baseColor = ExtinctColor(baseColor, viewInterpolator.w * _InvFadeParemeter.w);
#if defined(WATER_REFLECTIVE)
	half4 reflectionColor = lerp(rtReflections, _ReflectionColor, _ReflectionColor.a);
#else
	half4 reflectionColor = _ReflectionColor;
#endif

	baseColor = lerp(lerp(rtRefractions, baseColor, baseColor.a), reflectionColor, refl2Refr);

#if defined(WATER_EDGEBLEND_ON)

	// shore foam
	if (_Foam.x > 0.0 && _Foam.y > 0.0 && _Foam.z > 0.0)
	{
		// foam color
		fixed4 foamColor = Foam(_FoamTex, bumpCoords * _Foam.x); // foam scale

		// foam normal
		float3 foamNormal = PerPixelNormal(_FoamBump, bumpCoords, VERTEX_WORLD_NORMAL, PER_PIXEL_DISPLACE);

		// foam intensity is higher in shallow water
		//fixed foamIntensity = max(0.0, 1.0 - (min(sceneZ, yDepth) * _Foam.w));
		fixed foamIntensity = max(0.0, 1.0 - (sceneZ * _Foam.w));

		// add intensity as water level rises above default
		foamIntensity *= foamColor.a; // foam intensity
		foamIntensity = _Foam.y * pow(foamIntensity, _Foam.z); // foam intensity, foam power

		// adjust world normal to foam normal
		worldNormal = lerp(worldNormal, foamNormal, foamIntensity * 0.5);

		// add foam based on water color and intensity
		baseColor.rgb += (foamColor.rgb * _WaterColor.rgb * foamIntensity);

		// reduce specular color where there is foam, foam is not very specular
		specColor.a *= saturate(1.0 - foamIntensity);
	}

#endif

	baseColor.a = fade;

#if defined(WATER_LIGHT_ALL)

	ComputeWaterColorAllLight(worldPos, worldNormal, viewVector,
		
#if defined(WATER_EDGEBLEND_ON)
		
		shadowPowerReducer,
		
#if defined(WEATHER_MAKER_SHADOWS_SOFT) || defined(WEATHER_MAKER_SHADOWS_HARD)

		sceneZ,
		
#endif

#endif
		
		baseColor, specColor);

#endif

	ApplyDither(baseColor.rgb, worldPos.xz, _WaterDitherLevel);

	return baseColor;
}

#if !defined(WATER_LIGHT_ALL)

fixed4 ApplyWaterLightForwardBaseAdd(fixed4 baseColor, fixed atten, float3 lightDir, float3 worldPos, float3 worldNormal, fixed4 specularColor, fixed specularPower)
{
	float3 cameraPos = normalize(worldPos - _WorldSpaceCameraPos);

#if defined(UNITY_PASS_FORWARDBASE)

	UnityLight light;
#ifdef LIGHTMAP_OFF
	light.color = baseColor.rgb;
	light.dir = lightDir;
	light.ndotl = LambertTerm(worldNormal, light.dir);
#else
	light.color = half3(0.f, 0.f, 0.f);
	light.ndotl = 0.0f;
	light.dir = half3(0.f, 0.f, 0.f);
#endif
	UnityGIInput d;
	d.light = light;
	d.worldPos = worldPos;
	d.worldViewDir = cameraPos;
	d.atten = atten;
#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
	d.boxMin[0] = unity_SpecCube0_BoxMin;
	d.boxMin[1] = unity_SpecCube1_BoxMin;
#endif
#if UNITY_SPECCUBE_BOX_PROJECTION
	d.boxMax[0] = unity_SpecCube0_BoxMax;
	d.boxMax[1] = unity_SpecCube1_BoxMax;
	d.probePosition[0] = unity_SpecCube0_ProbePosition;
	d.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif
	d.probeHDR[0] = unity_SpecCube0_HDR;
	d.probeHDR[1] = unity_SpecCube1_HDR;
	Unity_GlossyEnvironmentData ugls_en_data;
	ugls_en_data.roughness = 0.45; // 1.0 - gloss
	float3 viewReflectDirection = reflect(-cameraPos, worldNormal);
	ugls_en_data.reflUVW = viewReflectDirection;
	UnityGI gi = UnityGlobalIllumination(d, 1, worldNormal, ugls_en_data);
	lightDir = gi.light.dir;
	baseColor.rgb = gi.light.color;

#endif

	fixed3 finalColor = saturate(dot(lightDir, worldNormal));
	finalColor = finalColor * baseColor.rgb * _LightColor0.rgb * atten; // diffuse color * light color
	finalColor += CalculateSpecularColor(fixed4(_LightColor0.rgb, 1.0), lightDir, cameraPos, worldNormal, specularColor, specularPower, atten);

	return fixed4(finalColor, baseColor.a);
}

#endif

v2fWater vertWater(appdata_water v)
{
	WM_INSTANCE_VERT(v, v2fWater, o);

	float3 normal, offsets;
	float3 worldPos = o.worldPos = WorldSpaceVertexPos(v.vertex).xyz;
	ApplyGerstner(v.vertex, worldPos, normal, offsets);
	o.yDepthShadowCoords = mul(_WeatherMakerDepthYShadowMatrix, float4(o.worldPos.x, worldPos.y, o.worldPos.z, 1.0));
	o.worldPos = worldPos;
	o.pos = UnityObjectToClipPos(v.vertex);
	half2 tileableUv = o.worldPos.xz;
	o.bumpCoords.xyzw = (tileableUv.xyxy + _Time.xxxx * _BumpDirection.xyzw) * _BumpTiling.xyzw;
	o.bumpCoords.xy = TRANSFORM_TEX(o.bumpCoords.xy, _WaterBumpMap);
	o.bumpCoords.zw = TRANSFORM_TEX(o.bumpCoords.zw, _WaterBumpMap);
	o.viewInterpolator.xyz = -WorldSpaceViewDir(v.vertex);
	o.reflectionPos = ComputeNonStereoScreenPos(o.pos);

#if defined(UNITY_SINGLE_PASS_STEREO)

	o.reflectionPos.z = unity_StereoEyeIndex;

#else

	// When not using single pass stereo rendering, eye index must be determined by testing the
	// sign of the horizontal skew of the projection matrix.
	o.reflectionPos.z = (unity_CameraProjection[0][2] > 0.0);

#endif

	o.refractionPos = ComputeScreenPos(o.pos);
	COMPUTE_EYEDEPTH(o.refractionPos.z);
	o.normalInterpolator.xyz = normal;
	o.viewInterpolator.w = saturate(offsets.y);
	o.normalInterpolator.w = max(0.0, offsets.y);//GetDistanceFadeout(o.refractionPos.w, DISTANCE_SCALE);
	o.viewPos = UnityObjectToViewPos(v.vertex);

#if defined(UNITY_PASS_FORWARDADD)

	TRANSFER_VERTEX_TO_FRAGMENT(o);

#elif defined(UNITY_PASS_FORWARDBASE)

	//TRANSFER_SHADOW(o);

#endif

	return o;
}

#if !defined(WATER_LIGHT_ALL)

fixed4 fragWaterForward(v2fWater i) : SV_Target
{
	WM_INSTANCE_FRAG(i);
	float3 worldNormal;

#if defined(UNITY_PASS_FORWARDBASE)

	// TODO: Figure out why Unity can't sample the shadow map in forward base pass properly
	float atten = CalculateDirLightShadowPower(i.worldPos, 0);
	//float atten = SHADOW_ATTENUATION(i);
	float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

#else

	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	float3 lightDir = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.worldPos, _WorldSpaceLightPos0.w));

#endif

	fixed4 baseColor = ComputeWaterColor(i.bumpCoords, i.normalInterpolator, i.viewInterpolator, i.reflectionPos, i.refractionPos, i.viewPos, i.worldPos, i.yDepthShadowCoords, atten, worldNormal);
	fixed4 specColor = _SpecularColor;
	specColor.rgb *= _SpecularIntensity;

#if defined(UNITY_PASS_FORWARDBASE)

	specColor.a *= _WeatherMakerDirLightPower[0].z;

#endif

	return ApplyWaterLightForwardBaseAdd(baseColor, atten, lightDir, i.worldPos, worldNormal, specColor, _Shininess);
}

#endif

#endif
