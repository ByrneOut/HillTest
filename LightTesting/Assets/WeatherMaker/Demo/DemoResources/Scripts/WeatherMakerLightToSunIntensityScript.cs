using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DigitalRuby.WeatherMaker
{
    [RequireComponent(typeof(Light))]
    public class WeatherMakerLightToSunIntensityScript : MonoBehaviour
    {
        [Range(0.0f, 8.0f)]
        public float LightMinIntensity = 0.0f;

        [Range(0.0f, 8.0f)]
        public float LightIntensity = 0.35f;

        private Light _light;
        

        private void Start()
        {
            _light = GetComponent<Light>();
            if (LightIntensity <= 0.0f)
            {
                LightIntensity = _light.intensity;
            }
        }

        private void Update()
        {
            _light.intensity = Mathf.Clamp(LightIntensity, LightMinIntensity, Mathf.Max(LightMinIntensity, Mathf.Min(LightIntensity, WeatherMakerScript.Instance.Sun.Light.intensity)));
        }
    }
}
