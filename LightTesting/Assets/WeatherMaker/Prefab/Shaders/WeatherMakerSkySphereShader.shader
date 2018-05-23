﻿//
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

// Resources:
// http://library.nd.edu/documents/arch-lib/Unity/SB/Assets/SampleScenes/Shaders/Skybox-Procedural.shader
//

// TODO: Better sky: https://github.com/ngokevin/kframe/blob/master/components/sun-sky/shaders/fragment.glsl
// TODO: Better sky: https://threejs.org/examples/js/objects/Sky.js

Shader "WeatherMaker/WeatherMakerSkySphereShader"
{
	Properties
	{
		_MainTex("Day Texture", 2D) = "blue" {}
		_DawnDuskTex("Dawn/Dusk Texture", 2D) = "orange" {}
		_NightTex("Night Texture", 2D) = "black" {}
		_NightSkyMultiplier("Night Sky Multiplier", Range(0, 1)) = 0
		_NightVisibilityThreshold("Night Visibility Threshold", Range(0, 1)) = 0
		_NightIntensity("Night Intensity", Range(0, 32)) = 2
		_NightTwinkleSpeed("Night Twinkle Speed", Range(0, 100)) = 16
		_NightTwinkleVariance("Night Twinkle Variance", Range(0, 10)) = 1
		_NightTwinkleMinimum("Night Twinkle Minimum Color", Range(0, 1)) = 0.02
		_NightTwinkleRandomness("Night Twinkle Randomness", Range(0, 5)) = 0.15
	}
	SubShader
	{
		Tags { "Queue" = "Geometry+497" "RenderType" = "Opaque" "IgnoreProjector" = "True" "PerformanceChecks" = "False" "PreviewType" = "Skybox" }

		CGINCLUDE

		#include "WeatherMakerSkyShader.cginc"

		#pragma target 3.0
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma glsl_no_auto_normalization
		#pragma multi_compile_instancing
		#pragma multi_compile __ UNITY_HDR_ON
		#pragma multi_compile ENABLE_TEXTURED_SKY ENABLE_PROCEDURAL_TEXTURED_SKY ENABLE_PROCEDURAL_TEXTURED_SKY_PREETHAM ENABLE_PROCEDURAL_SKY ENABLE_PROCEDURAL_SKY_PREETHAM
		#pragma multi_compile __ ENABLE_NIGHT_TWINKLE

		v2fSky vert(appdata_base v)
		{
			WM_INSTANCE_VERT(v, v2fSky, o);
			o.vertex = UnityObjectToClipPosFarPlane(v.vertex);
			o.uv = v.texcoord.xy; // TRANSFORM_TEX not supported
			o.ray = -WorldSpaceViewDir(v.vertex);
			procedural_sky_info i = CalculateScatteringCoefficients(_WeatherMakerSunDirectionUp, _WeatherMakerSunColor.rgb, 1.0, normalize(o.ray));
			o.inScatter = i.inScatter;
			o.outScatter = i.outScatter;
			o.normal = float3(0.0, 0.0, 0.0);
			return o;
		}

		fixed4 fragBase(v2fSky i)
		{
			WM_INSTANCE_FRAG(i);

			fixed4 result;
			i.ray = normalize(i.ray);

#if defined(ENABLE_PROCEDURAL_TEXTURED_SKY) || defined(ENABLE_PROCEDURAL_SKY)

			procedural_sky_info p = CalculateScatteringColor(_WeatherMakerSunDirectionUp, _WeatherMakerSunColor.rgb, _WeatherMakerSunVar1.x, i.ray, i.inScatter, i.outScatter);
			fixed4 skyColor = p.skyColor;
			skyColor.rgb *= _WeatherMakerSkyGradientColor.rgb * _WeatherMakerSkyGradientColor.a;
			fixed3 nightColor = GetNightColor(i.ray, i.uv, skyColor.a);

#elif defined(ENABLE_PROCEDURAL_TEXTURED_SKY_PREETHAM) || defined(ENABLE_PROCEDURAL_SKY_PREETHAM)

			fixed4 skyColor = CalculateSkyColorPreetham(i.ray, _WeatherMakerSunDirectionUp);
			skyColor.rgb *= _WeatherMakerSkyGradientColor.rgb * _WeatherMakerSkyGradientColor.a;
			fixed3 nightColor = GetNightColor(i.ray, i.uv, skyColor.a);

#else

			fixed3 nightColor = GetNightColor(i.ray, i.uv, 0.0);

#endif

			fixed sunMoon;

#if defined(ENABLE_PROCEDURAL_TEXTURED_SKY) || defined(ENABLE_PROCEDURAL_TEXTURED_SKY_PREETHAM)

			fixed4 dayColor = tex2Dlod(_MainTex, float4(i.uv, 0.0, 0.0)) * _WeatherMakerDayMultiplier;
			fixed4 dawnDuskColor = tex2Dlod(_DawnDuskTex, float4(i.uv, 0.0, 0.0));
			fixed4 dawnDuskColor2 = dawnDuskColor * _WeatherMakerDawnDuskMultiplier;
			dayColor += dawnDuskColor2;

			// hide night texture wherever dawn/dusk is opaque, reduce if clouds
			nightColor *= (1.0 - dawnDuskColor.a);

			// blend texture on top of sky
			result = ((dayColor * dayColor.a) + (skyColor * (1.0 - dayColor.a)));

			// blend previous result on top of night
			result = ((result * result.a) + (fixed4(nightColor, 1.0) * (1.0 - result.a)));

#elif defined(ENABLE_TEXTURED_SKY)

			fixed4 dayColor = tex2Dlod(_MainTex, float4(i.uv, 0.0, 0.0)) * _WeatherMakerDayMultiplier;
			fixed4 dawnDuskColor = (tex2Dlod(_DawnDuskTex, float4(i.uv, 0.0, 0.0)) * _WeatherMakerDawnDuskMultiplier);
			result = (dayColor + dawnDuskColor + fixed4(nightColor, 0.0));

#else

			// procedural or procedural preetham
			result = skyColor + fixed4(nightColor, 0.0);

#endif

			ApplyDither(result.rgb, i.uv, _WeatherMakerSkyDitherLevel);
			return result;
		}

		fixed4 frag(v2fSky i) : SV_Target
		{
			return fragBase(i);
		}

		ENDCG

		Pass
		{
			Tags { "LightMode" = "Always" }
			Cull Front Lighting Off ZWrite Off ZTest LEqual
			Blend One Zero

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}
	}

	FallBack Off
}
