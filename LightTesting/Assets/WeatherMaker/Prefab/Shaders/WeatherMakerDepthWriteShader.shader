Shader "WeatherMaker/WeatherMakerDepthWriteShader"
{
	SubShader
	{
		// Render the mask after regular geometry, but before masked geometry and transparency
		// Don't draw in the RGBA channels; just the depth buffer
		Tags{ "Queue" = "AlphaTest+70" }
		ColorMask 0
		ZWrite On
		Pass {} // empty pass

		/*
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f
			{
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert( appdata_base v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag( v2f i ) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
		*/

		/*
		Pass
		{
			Tags { "Queue" = "Geometry+1" "LightMode" = "Always" "RenderType" = "Transparent" }

			ZWrite On ZTest LEqual Cull Off
			Blend Zero One

			CGPROGRAM

			#include "WeatherMakerConstantsShaderInclude.cginc"

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing

			struct appdata
			{
				float4 vertex : POSITION;
				WM_BASE_VERTEX_INPUT
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				WM_BASE_VERTEX_TO_FRAG
			};

			v2f vert (appdata v)
			{
				WM_INSTANCE_VERT(v, v2f, o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				WM_INSTANCE_FRAG(i);
				return fixed4(0.0, 0.0, 0.0, 1.0);
			}

			ENDCG
		}
		*/
	}

	Fallback Off//"Diffuse"
}
