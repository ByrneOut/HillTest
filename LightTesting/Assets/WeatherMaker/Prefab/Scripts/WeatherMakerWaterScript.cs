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

using System;
using UnityEngine;

namespace DigitalRuby.WeatherMaker
{
    /// <summary>
    /// Water rendering modes
    /// </summary>
    public enum WeatherMakerWaterRenderingMode
    {
        /// <summary>
        /// Render water in a single pass with all lights
        /// </summary>
        OnePass,

        /// <summary>
        /// Render water in a forward base + forward add pass
        /// </summary>
        ForwardBasePlusAdd
    }

    [ExecuteInEditMode]
    [RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
    public class WeatherMakerWaterScript : MonoBehaviour
    {
        [Tooltip("Water rendering mode")]
        public WeatherMakerWaterRenderingMode RenderMode = WeatherMakerWaterRenderingMode.OnePass;

        [Tooltip("Whether to blend to allow smooth transition as depth decreases.")]
        public bool EnableDepthBlend = true;

        [Tooltip("Enable depth write for water surface. The depth buffer is this many units below the water. 0 for no depth write. " +
            "Turn this on if you have fog or other depth effects over deep water.")]
        [Range(0.0f, 10000.0f)]
        public float WaterDepthThreshold = 0.0f;

        private MeshRenderer meshRenderer;
        private WeatherMakerReflectionScript reflection;

        private void UpdateShader()
        {
            if (RenderMode == WeatherMakerWaterRenderingMode.OnePass)
            {
                meshRenderer.sharedMaterial.shader.maximumLOD = 201;
            }
            else
            {
                meshRenderer.sharedMaterial.shader.maximumLOD = 101;
            }

            meshRenderer.sharedMaterial.SetFloat("_WaterDepthThreshold", (WaterDepthThreshold <= 0.0f ? float.MinValue : WaterDepthThreshold));

            if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Depth) && EnableDepthBlend)
            {
                meshRenderer.sharedMaterial.EnableKeyword("WATER_EDGEBLEND_ON");
            }
            else
            {
                EnableDepthBlend = false;
                meshRenderer.sharedMaterial.DisableKeyword("WATER_EDGEBLEND_ON");
            }

            if (reflection != null && reflection.enabled)
            {
                meshRenderer.sharedMaterial.EnableKeyword("WATER_REFLECTIVE");
            }
            else
            {
                meshRenderer.sharedMaterial.DisableKeyword("WATER_REFLECTIVE");
            }
        }

        internal void WaterTileBeingRendered(Transform tr, Camera currentCam)
        {
            if (currentCam && EnableDepthBlend && (currentCam.depthTextureMode & DepthTextureMode.Depth) == DepthTextureMode.None)
            {
                currentCam.depthTextureMode |= DepthTextureMode.Depth;
            }
        }

        private void OnEnable()
        {
            meshRenderer = GetComponent<MeshRenderer>();
            reflection = GetComponent<WeatherMakerReflectionScript>();
        }


        private void OnDisable()
        {
        }

        private void Update()
        {
            UpdateShader();
        }

        private void OnWillRenderObject()
        {
            if (EnableDepthBlend && (Camera.current.depthTextureMode & DepthTextureMode.Depth) == DepthTextureMode.None)
            {
                Camera.current.depthTextureMode |= DepthTextureMode.Depth;
            }
        }
    }
}