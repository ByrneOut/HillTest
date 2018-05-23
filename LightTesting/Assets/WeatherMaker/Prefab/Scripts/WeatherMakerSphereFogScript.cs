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

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DigitalRuby.WeatherMaker
{
    public class WeatherMakerSphereFogScript : WeatherMakerFogScript<WeatherMakerFogProfileScript>
    {
        private Renderer fogRenderer;

        protected override void Awake()
        {
            base.Awake();

            this.fogRenderer = GetComponent<Renderer>();
        }

        protected override void OnInitialize()
        {
            base.OnInitialize();
            this.fogRenderer.sharedMaterial = FogMaterial;
        }

        protected override void LateUpdate()
        {
            base.LateUpdate();

            Bounds b = fogRenderer.bounds;
            Vector3 shrinker = b.size * -(1.0f - FogProfile.FogPercentage);
            b.Expand(shrinker);
            float radius = transform.localScale.x * FogProfile.FogPercentage;
            Vector4 pos = transform.position;
            pos.w = radius * radius;
            FogMaterial.SetVector("_FogSpherePosition", pos);
            fogRenderer.enabled = (FogProfile.FogDensity > 0.0f);
        }
    }
}