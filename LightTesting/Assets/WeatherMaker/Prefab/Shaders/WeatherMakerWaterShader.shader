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

Shader "WeatherMaker/WeatherMakerWaterShader"
{
	Properties
	{
		[HideInInspector] _WeatherMakerWaterReflectionTex("Water reflection", 2D) = "white" {}
		[HideInInspector] _WeatherMakerWaterReflectionTex2("Water reflection (right eye)", 2D) = "white" {}
	
		[Header(Main Textures)]
		_MainTex ("Water color (RGBA)", 2D) = "clear" {}
		_WaterBumpMap("Water normals", 2D) = "bump" {}
		[NoScaleOffset] _FoamTex("Foam (RGBA)", 2D) = "white" {}
		[NoScaleOffset] _FoamBump("Foam bump", 2D) = "bump" {}

		[Header(Appearance)]
		_BaseColor("Base color", Color) = (.54, .95, .99, 0.1)
		_WaterColor("Water tint color", Color) = (1.0, 1.0, 1.0, 1.0)
		_ReflectionColor("Reflection color", Color) = (.54, .95, .99, 0.5)
		_FresnelScale("FresnelScale", Range(0.15, 4.0)) = 0.75
		_DistortParams("Distortions (Bump waves, Reflection, Fresnel power, Fresnel bias)", Vector) = (1.0 ,1.0, 2.0, 1.15)
		_BumpTiling("Bump Tiling", Vector) = (1.0 ,1.0, -2.0, 3.0)
		_BumpDirection("Bump Direction & Speed", Vector) = (1.0 ,1.0, -1.0, 1.0)
		_InvFadeParemeter("Auto blend parameter (Depth, fade, transparency)", Vector) = (0.15 ,0.15, 0.5, 1.0)
		_Foam("Foam (Scale, intensity, shore strength, depth intensity)", Vector) = (0.0, 0.05, 0.0, 0.0)
		_WaterDepthThreshold("Water depth threshold", Float) = 0.0

		[Header(Specular)]
		_SpecularColor("Specular color", COLOR) = (.72, .72, .72, 1)
		_SpecularIntensity("Specular intensity", Float) = 3.0
		_Shininess("Shininess", Range(2.0, 500.0)) = 200.0
		[NoScaleOffset] _SparkleNoise("Sparkle Noise (Currently Unused)", 2D) = "white" {}
		_SparkleTintColor("Sparkle Tint", Color) = (0.45, 0.45, 0.45, 1.0)
		_SparkleScale("Sparkle Scale - scale, speed, visible threshold (0-1), intensity", Vector) = (1, 128, 1, 8)
		_SparkleOffset("Sparkle Offset - animation offsets (x,y,z,w)", Vector) = (32, 64, 128, 256)
		_SparkleFade("Sparkle Fade - visibility fade power, distance fade squared, 0, 0", Vector) = (8, 8192, 0, 0)

		[Header(Lighting)]
		_WaterDitherLevel ("Dithering", Range(0.0, 1.0)) = 0.001
		_WaterShadowStrength ("Water shadow strength", Range(0.0, 100.0)) = 64

		[Header(Caustics)]
		[NoScaleOffset] _CausticsTexture("Caustics Texture (3D)", 3D) = "white" {}
		_CausticsTintColor("Caustics Tint Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_CausticsScale("Caustics Scale (scale, intensity, depth fade, distort multiplier)", Vector) = (0.01, 0.5, 3.0, 1.0)
		_CausticsVelocity("Caustics Animation Velocity (x, y, z, 0)", Vector) = (0.01, 0.02, 5.0, 0.0)

		[Header(Volumetric Sun Shadows)]
		[IntRange] _VolumetricSampleCount ("Volumetric Sample Count", Range(0, 128)) = 16
		_VolumetricSampleMaxDistance ("Volumetric Sample Max Distance", Range(1.0, 1000.0)) = 32.0
		_VolumetricSampleDither ("Volumetric Sample Dither", Range(0.0, 1.0)) = 0.3
		_VolumetricShadowPower ("Volumetric Shadow Power", Range(0.0, 64.0)) = 8.0
		_VolumetricShadowPowerFade ("Volumetric Shadow Power Fade", Range(0.0, 1.0)) = 0.1
		_VolumetricShadowMinShadow ("Volumetric Shadow Min Shadow", Range(0.0, 1.0)) = 0.35

		[Header(Light multipliers)]
		_DirectionalLightMultiplier("Directional Light Multiplier", Range(0, 10)) = 1
		_PointSpotLightMultiplier("Point/Spot Light Multiplier", Range(0, 10)) = 1
		_AmbientLightMultiplier("Ambient light multiplier", Range(0, 4)) = 1

		[Header(Waves)]
		_GerstnerIntensity("Per vertex displacement", Float) = 1.0
		_GAmplitude("Wave Amplitude", Vector) = (0.3 ,0.35, 0.25, 0.25)
		_GFrequency("Wave Frequency", Vector) = (1.3, 1.35, 1.25, 1.25)
		_GSteepness("Wave Steepness", Vector) = (1.0, 1.0, 1.0, 1.0)
		_GSpeed("Wave Speed", Vector) = (1.2, 1.375, 1.1, 1.5)
		_GDirectionAB("Wave Direction AB", Vector) = (0.3 ,0.85, 0.85, 0.25)
		_GDirectionCD("Wave Direction CD", Vector) = (0.1 ,0.9, 0.5, 0.5)
	}

	// all light in one pass
	Subshader
	{
		Tags{ "Queue" = "AlphaTest+49" "RenderType" = "Transparent" }

		Lod 200
		Cull Off
		ZTest LEqual
		ColorMask RGBA
		ZWrite Off
		Fog { Mode Off }

		GrabPass { "_WeatherMakerWaterRefractionTex" }

		Pass
		{
			Tags { "LightMode" = "Always" }

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex vertWater
			#pragma fragment frag
			#pragma target 3.5
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma glsl_no_auto_normalization
			#pragma multi_compile_instancing
			#pragma multi_compile __ WATER_EDGEBLEND_ON
			#pragma multi_compile __ WATER_REFLECTIVE
			#pragma multi_compile __ WEATHER_MAKER_SHADOWS_ONE_CASCADE
			#pragma multi_compile __ WEATHER_MAKER_SHADOWS_HARD WEATHER_MAKER_SHADOWS_SOFT

			#define WATER_LIGHT_ALL
			#define WEATHER_MAKER_LIGHT_SPECULAR_SPARKLE

			#include "WeatherMakerWaterShaderInclude.cginc"

			fixed4 frag(v2fWater i) : SV_Target
			{
				float3 tmpNormal;
				return ComputeWaterColor(i.bumpCoords, i.normalInterpolator, i.viewInterpolator, i.reflectionPos, i.refractionPos, i.viewPos, i.worldPos, i.yDepthShadowCoords, 1.0, tmpNormal);
			}

			ENDCG
		}
	}

	// forward base + forward add pass
	Subshader
	{
		Tags { "Queue" = "AlphaTest+49" "RenderType" = "Transparent" }

		Lod 100
		Cull Off
		ZTest LEqual
		ColorMask RGBA
		ZWrite Off
		Fog { Mode Off }

		GrabPass { "_WeatherMakerWaterRefractionTex" }

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex vertWater
            #pragma fragment fragWaterForward
			#pragma target 3.5
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma glsl_no_auto_normalization
			#pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
			#pragma multi_compile __ WATER_EDGEBLEND_ON
			#pragma multi_compile __ WATER_REFLECTIVE
			#pragma multi_compile __ WEATHER_MAKER_SHADOWS_ONE_CASCADE
			#pragma multi_compile __ WEATHER_MAKER_SHADOWS_HARD WEATHER_MAKER_SHADOWS_SOFT

            #pragma target 3.0

			#ifndef UNITY_PASS_FORWARDBASE
			#define UNITY_PASS_FORWARDBASE
			#endif

			#include "WeatherMakerWaterShaderInclude.cginc"

			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }

			Blend One One

			CGPROGRAM

			#pragma vertex vertWater
			#pragma fragment fragWaterForward
			#pragma target 3.5
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma glsl_no_auto_normalization
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_instancing
			#pragma multi_compile __ WATER_EDGEBLEND_ON
			#pragma multi_compile __ WATER_REFLECTIVE
			#pragma multi_compile __ WEATHER_MAKER_SHADOWS_ONE_CASCADE
			#pragma multi_compile __ WEATHER_MAKER_SHADOWS_HARD WEATHER_MAKER_SHADOWS_SOFT

			#ifndef UNITY_PASS_FORWARDADD
			#define UNITY_PASS_FORWARDADD
			#endif

			#include "WeatherMakerWaterShaderInclude.cginc"

			ENDCG
		}
	}

	// shadow caster / depth pass using _WaterDepthThreshold for the base floor of the water
	Subshader
	{
		Pass
		{
			Tags { "LightMode" = "Shadowcaster" }
			Fog{ Mode Off }
			ZWrite On ZTest LEqual Cull Off
			Offset 1, 1

			CGPROGRAM

			#ifndef UNITY_PASS_SHADOWCASTER
			#define UNITY_PASS_SHADOWCASTER
			#endif

			#define _GLOSSYENV 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.5
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma glsl_no_auto_normalization
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing

			#include "WeatherMakerWaterShaderInclude.cginc"

			struct appdata_water_shadow_cast
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				WM_BASE_VERTEX_INPUT
			};

			struct v2fs
			{
				V2F_SHADOW_CASTER;
				WM_BASE_VERTEX_TO_FRAG
			};

			v2fs vert(appdata_water_shadow_cast v)
			{
				WM_INSTANCE_VERT(v, v2fs, o);

				float3 tmpWorldPos = WorldSpaceVertexPos(v.vertex).xyz;
				float3 tmpNormal, tmpOffsets;
				ApplyGerstner(v.vertex, tmpWorldPos, tmpNormal, tmpOffsets);
				v.vertex.y -= _WaterDepthThreshold;

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2fs i, float facing : VFACE) : SV_Target
			{
				float isFrontFace = (facing >= 0 ? 1 : 0);
				float faceSign = (facing >= 0 ? 1 : -1);
				WM_INSTANCE_FRAG(i);
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
	}

	/*
	// shadow collector pass
	Subshader
	{
		Pass
		{
			Tags { "LightMode" = "ShadowCollector" }
			Fog {Mode Off}
			ZWrite On ZTest LEqual

			CGPROGRAM

			#define SHADOW_COLLECTOR_PASS

			#pragma vertex vertsc
			#pragma fragment fragsc
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_shadowcollector
			
			#include "WeatherMakerWaterShaderInclude.cginc"

			struct appdata_water_shadow_collect
			{
				float4 vertex : POSITION;
				WM_BASE_VERTEX_INPUT
			};

			struct v2fsc
			{
				V2F_SHADOW_COLLECTOR;
				WM_BASE_VERTEX_TO_FRAG
			};

			v2fsc vertsc(appdata_water_shadow_collect v)
			{
				WM_INSTANCE_VERT(v, v2fsc, o);

				float3 tmpWorldPos, tmpNormal, tmpOffsets;
				ApplyGerstner(v.vertex, tmpWorldPos, tmpNormal, tmpOffsets);
				v.vertex.y -= _WaterDepthThreshold;

				TRANSFER_SHADOW_COLLECTOR(o);

				return o;
			}

			fixed4 fragsc(v2fsc i) : SV_Target
			{
				WM_INSTANCE_FRAG(i);
				SHADOW_COLLECTOR_FRAGMENT(i);
			}

			ENDCG
		}
	}
	*/

	Fallback "Transparent/Diffuse"
}
