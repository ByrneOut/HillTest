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

#include "UnityShadowLibrary.cginc"

UNITY_DECLARE_SHADOWMAP(_WeatherMakerShadowMapTexture);
uniform float4 _WeatherMakerShadowMapTexture_TexelSize;

#if defined(WEATHER_MAKER_SHADOWS_ONE_CASCADE)
#define GET_CASCADE_WEIGHTS(wpos, z) getCascadeWeights1(wpos, z)
#define GET_SHADOW_COORDINATES(wpos, cascadeWeights) getShadowCoord1(wpos)
#else
#define GET_CASCADE_WEIGHTS(wpos, z) getCascadeWeights4(wpos)
#define GET_SHADOW_COORDINATES(wpos, cascadeWeights) getShadowCoord4(wpos, cascadeWeights)
#endif

/**
* Gets the cascade weights based on the world position of the fragment and the poisitions of the split spheres for each cascade.
* Returns a float4 with only one component set that corresponds to the appropriate cascade.
*/
inline float4 getCascadeWeights4(float3 wpos)
{
	float3 fromCenter0 = wpos - unity_ShadowSplitSpheres[0].xyz;
	float3 fromCenter1 = wpos - unity_ShadowSplitSpheres[1].xyz;
	float3 fromCenter2 = wpos - unity_ShadowSplitSpheres[2].xyz;
	float3 fromCenter3 = wpos - unity_ShadowSplitSpheres[3].xyz;
	float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));
	float4 weights = float4(distances2 < unity_ShadowSplitSqRadii);
	weights.yzw = saturate(weights.yzw - weights.xyz);
	return weights;
}

/**
* Gets the cascade weights based on the world position of the fragment.
* Returns a float4 with only one component set that corresponds to the appropriate cascade.
*/
inline float4 getCascadeWeights1(float3 wpos, float z)
{
	float4 zNear = float4(z >= _LightSplitsNear);
	float4 zFar = float4(z < _LightSplitsFar);
	float4 weights = zNear * zFar;
	return weights;
}

/**
* Returns the shadowmap coordinates for the given fragment based on the world position and z-depth.
* These coordinates belong to the shadowmap atlas that contains the maps for all cascades.
*/
inline float4 getShadowCoord4(float4 wpos, float4 cascadeWeights)
{
	float3 sc0 = mul(unity_WorldToShadow[0], wpos).xyz;
	float3 sc1 = mul(unity_WorldToShadow[1], wpos).xyz;
	float3 sc2 = mul(unity_WorldToShadow[2], wpos).xyz;
	float3 sc3 = mul(unity_WorldToShadow[3], wpos).xyz;
	float4 shadowMapCoordinate = float4(sc0 * cascadeWeights[0] + sc1 * cascadeWeights[1] + sc2 * cascadeWeights[2] + sc3 * cascadeWeights[3], 1.0);
#if defined(UNITY_REVERSED_Z)
	float  noCascadeWeights = 1 - dot(cascadeWeights, float4(1, 1, 1, 1));
	shadowMapCoordinate.z += noCascadeWeights;
#endif
	return shadowMapCoordinate;
}

/**
* Same as the getShadowCoord; but optimized for single cascade
*/
inline float4 getShadowCoord1(float4 wpos)
{
	return float4(mul(unity_WorldToShadow[0], wpos).xyz, 0);
}

#define SHAD4MULT1 0.3
#define SHAD4MULT2 0.6
#define SHAD4OFFS1 (_WeatherMakerShadowMapTexture_TexelSize.x * SHAD4MULT1)
#define SHAD4OFFS2 (_WeatherMakerShadowMapTexture_TexelSize.x * SHAD4MULT2)
#define SHAD4OFFS3 (_WeatherMakerShadowMapTexture_TexelSize.y * SHAD4MULT1)
#define SHAD4OFFS4 (_WeatherMakerShadowMapTexture_TexelSize.y * SHAD4MULT2)


#define UNITY_SAMPLE_SHADOW_4(tex, coord) \
	(( \
	UNITY_SAMPLE_SHADOW(tex, (float4(coord.x - SHAD4OFFS1, coord.y - SHAD4OFFS4, coord.z, coord.w))) + \
	UNITY_SAMPLE_SHADOW(tex, (float4(coord.x - SHAD4OFFS2, coord.y + SHAD4OFFS3, coord.z, coord.w))) + \
	UNITY_SAMPLE_SHADOW(tex, (float4(coord.x + SHAD4OFFS2, coord.y - SHAD4OFFS3, coord.z, coord.w))) + \
	UNITY_SAMPLE_SHADOW(tex, (float4(coord.x + SHAD4OFFS1, coord.y + SHAD4OFFS4, coord.z, coord.w))) \
	) * 0.25)
