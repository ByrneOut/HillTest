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

#ifndef __WEATHER_MAKER_SHADER__
#define __WEATHER_MAKER_SHADER__

#include "WeatherMakerLightShaderInclude.cginc"
#include "WeatherMakerNoiseShaderInclude.cginc"

// globals
#if defined(WM_IS_FULL_SCREEN_EFFECT) && (defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED))

uniform UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
uniform UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex2);
uniform UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraDepthNormalsTexture);

#else

uniform sampler2D _MainTex;
uniform sampler2D _MainTex2;
uniform sampler2D _CameraDepthNormalsTexture;

#endif

uniform float4 _MainTex_ST;
uniform float4 _MainTex_TexelSize;
uniform float4 _MainTex2_ST;
uniform float4 _MainTex2_TexelSize;
uniform float4 _CameraDepthNormalsTexture_ST;
uniform float4 _CameraDepthNormalsTexture_TexelSize;

//uniform sampler2D _WeatherMakerDitherTexture;
//uniform float4 _WeatherMakerDitherTexture_ST;
//uniform float4 _WeatherMakerDitherTexture_TexelSize;

uniform float _WeatherMakerSkySphereRadius;
uniform float _WeatherMakerSkySphereRadiusSquared;
uniform fixed4 _WeatherMakerSkyGradientColor = fixed4(1.0, 1.0, 1.0, 1.0);
uniform fixed _WeatherMakerSkyDitherLevel;

// contains un-normalized direction to frustum corners for left and right eye : bottom left, top left, bottom right, top right, use unity_StereoEyeIndex * 4 to index
uniform float3 _WeatherMakerCameraFrustumRays[8];

// inverse view matrix for each eye, use unity_StereoEyeIndex to idnex
uniform float4x4 _WeatherMakerInverseView[2];

// inverse proj matrix for each eye, using unity_StereoEyeIndex to index
uniform float4x4 _WeatherMakerInverseProj[2];

#if defined(SOFTPARTICLES_ON)

float _InvFade;

#endif

#if defined(WM_IS_FULL_SCREEN_EFFECT) && (defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED))

#define WM_SAMPLE_FULL_SCREEN_TEXTURE(tex, uv) UNITY_SAMPLE_TEX2DARRAY_LOD(tex, float3((uv).xy, (float)unity_StereoEyeIndex), 0.0)

#else

#define WM_SAMPLE_FULL_SCREEN_TEXTURE(tex, uv) tex2Dlod(tex, float4((uv).xy, 0.0, 0.0))

#endif

inline float GetDepth01(float2 uv)
{
	return Linear01Depth(WM_SAMPLE_DEPTH(uv));
}

inline void GetDepth01AndNormal(float2 uv, out float depth, out float3 normal)
{
	float4 samp = WM_SAMPLE_FULL_SCREEN_TEXTURE(_CameraDepthNormalsTexture, uv);
	DecodeDepthNormal(samp, depth, normal);
}

inline fixed LerpFade(float4 lifeTime, float timeSinceLevelLoad)
{
	// the vertex will fade in, stay at full color, then fade out
	// x = creation time seconds
	// y = fade time in seconds
	// z = life time seconds

	// debug
	// return 1;

	float peakFadeIn = lifeTime.x + lifeTime.y;
	float startFadeOut = lifeTime.x + lifeTime.z - lifeTime.y;
	float endTime = lifeTime.x + lifeTime.z;
	float lerpMultiplier = saturate(ceil(timeSinceLevelLoad - peakFadeIn));
	float lerp1Scalar = saturate(((timeSinceLevelLoad - lifeTime.x + 0.000001) / max(0.000001, (peakFadeIn - lifeTime.x))));
	float lerp2Scalar = saturate(max(0, ((timeSinceLevelLoad - startFadeOut) / max(0.000001, (endTime - startFadeOut)))));
	float lerp1 = lerp1Scalar * (1.0 - lerpMultiplier);
	float lerp2 = (1.0 - lerp2Scalar) * lerpMultiplier;
	return lerp1 + lerp2;
}

inline float4 UnityObjectToClipPosFarPlane(float4 vertex)
{
	float4 pos = UnityObjectToClipPos(float4(vertex.xyz, 1.0));
	if (UNITY_NEAR_CLIP_VALUE == 1.0)
	{
		// DX
		pos.z = 0.0;
	}
	else
	{
		// OpenGL
		pos.z = pos.w;
	}
	return pos;
}

inline float3 WorldSpaceVertexPosNear(float3 vertex)
{
	return mul(unity_ObjectToWorld, float4(vertex.xyz, 0.0)).xyz;
}

inline float3 WorldSpaceVertexPosFar(float3 vertex)
{
	return mul(unity_ObjectToWorld, float4(vertex.xyz, 1.0)).xyz;
}

inline float3 WorldSpaceVertexPos(float4 vertex)
{
	return mul(unity_ObjectToWorld, vertex).xyz;
}

inline deferred_fragment ColorToDeferredFragment(float4 color)
{
	deferred_fragment f;
	f.gBuffer0 = float4(0.0, 0.0, 0.0, 0.0);
	f.gBuffer1 = float4(0.0, 0.0, 0.0, 0.0);
	f.gBuffer2 = float4(0.0, 0.0, 0.0, 1.0);

#if defined(UNITY_HDR_ON)

	f.gBuffer3 = color;

#else

	// TODO: Something is wrong with alpha channel in deferred non-HDR
	f.gBuffer3 = float4(exp2(-color.rgb), color.a);

#endif

	return f;
}

float3 GetFarPlaneVectorFullScreen(float2 uv, int eyeIndex)
{
	uv.x = (uv.x > 0.5);
	uv.y = (uv.y > 0.5);
	return _WeatherMakerCameraFrustumRays[(eyeIndex * 4) + ((uv.x * 2) + uv.y)];
}

inline void GetFullScreenBoundingBox(float height, out float3 boxMin, out float3 boxMax)
{
	boxMin = float3(_WorldSpaceCameraPos.x - _ProjectionParams.z, -_ProjectionParams.z, _WorldSpaceCameraPos.z - _ProjectionParams.z);
	boxMax = float3(_WorldSpaceCameraPos.x + _ProjectionParams.z, height, _WorldSpaceCameraPos.z + _ProjectionParams.z);
}

inline void GetFullScreenBoundingBox2(float minHeight, float maxHeight, out float3 boxMin, out float3 boxMax)
{
	boxMin = float3(_WorldSpaceCameraPos.x - _ProjectionParams.z, minHeight, _WorldSpaceCameraPos.z - _ProjectionParams.z);
	boxMax = float3(_WorldSpaceCameraPos.x + _ProjectionParams.z, maxHeight, _WorldSpaceCameraPos.z + _ProjectionParams.z);
}

inline float CalculateNoiseXZ(sampler2D noiseTex, float3 worldPos, float scale, float2 offset, float2 velocity, float multiplier, float adder)
{
	float2 noiseUV = float2(worldPos.x * scale, worldPos.z * scale);
	noiseUV += offset + velocity;
	float4 uvlod = float4(noiseUV.x, noiseUV.y, 0, 0);
	return (tex2Dlod(noiseTex, uvlod).a + adder) * multiplier;
}

inline float2 AdjustFullScreenUV(float2 uv)
{
	uv = UnityStereoTransformScreenSpaceTex(uv);
	//uv = UnityStereoScreenSpaceUVAdjust(uv, _MainTex_ST);

#if UNITY_UV_STARTS_AT_TOP

	if (_MainTex_TexelSize.y < 0)
	{
		uv.y = 1.0 - uv.y;
	}

#endif

	return uv;
}

inline float GetNearPlane()
{

#if defined(UNITY_REVERSED_Z)

	return 1.0 - UNITY_NEAR_CLIP_VALUE;

#else

	return UNITY_NEAR_CLIP_VALUE;

#endif

}

inline float3 GetRayFromForwardLine(float3 forwardLine)
{

#if defined(WEATHER_MAKER_CUBEMAP)

	// see https://github.com/chriscummings100/worldspaceposteffect/blob/master/Assets/WorldSpacePostEffect/WorldSpacePostEffect.shader
	float2 uvClip = forwardLine.xy * 2.0 - 1.0;

#if defined(UNITY_REVERSED_Z)

	float4 clipPos = float4(uvClip, GetNearPlane(), 1.0);

#else

	// WTF OpenGL requires -1.0 w and flipping the x???
	float4 clipPos = float4(uvClip, GetNearPlane(), -1.0);
	clipPos.x *= -1;

#endif

	float4 viewPos = mul(_WeatherMakerInverseProj[unity_StereoEyeIndex], clipPos); // inverse projection by clip position
	//float4 viewPos = mul(unity_CameraInvProjection, clipPos);
	viewPos /= viewPos.w; // perspective division
	return normalize(mul(_WeatherMakerInverseView[unity_StereoEyeIndex], viewPos).xyz);
	//return normalize(mul(unity_CameraToWorld, viewPos).xyz);

#else

	return normalize(forwardLine);

#endif

}

// only works for wrapping coordinates, sin / cos
inline float2 RotateUV(float2 uv, float s, float c)
{
	return float2((uv.x * c) - (uv.y * s), (uv.x * s) + (uv.y * c));
}

inline void ApplyDither(inout fixed3 rgb, float2 screenUV, fixed l)
{
	fixed3 gradient = frac(cos(dot(screenUV * _WeatherMakerTime.x, ditherMagic.xy)) * ditherMagic.z) * l;
	rgb = max(0, (rgb - gradient));
}

inline void ApplyDitherNoTime(inout fixed3 rgb, float2 screenUV, fixed l)
{
	fixed3 gradient = frac(cos(dot(screenUV, ditherMagic.xy)) * ditherMagic.z) * l;
	rgb = max(0, (rgb - gradient));
}

inline volumetric_data GetVolumetricData(appdata_base v)
{
	WM_INSTANCE_VERT(v, volumetric_data, o);
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.normal = UnityObjectToWorldNormal(v.normal);
	o.projPos = ComputeScreenPos(o.vertex);
	o.worldPos = WorldSpaceVertexPos(v.vertex);
	o.rayDir = -WorldSpaceViewDir(v.vertex);
	o.viewPos = UnityObjectToViewPos(v.vertex);
	return o;
}

full_screen_fragment full_screen_vertex_shader(full_screen_vertex v)
{
	WM_INSTANCE_VERT(v, full_screen_fragment, o);
	o.vertex = UnityObjectToClipPosFarPlane(v.vertex);
	o.uv = AdjustFullScreenUV(v.uv);

#if defined(WEATHER_MAKER_CUBEMAP)

	o.forwardLine = float3(o.uv, 0.0);

#else

	o.forwardLine = GetFarPlaneVectorFullScreen(v.uv, eyeIndex);

#endif

	return o;
}

#endif // __WEATHER_MAKER_SHADER__
