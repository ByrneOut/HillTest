using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DigitalRuby.WeatherMaker
{
    [RequireComponent(typeof(Light))]
    public class WeatherMakerDemoScriptSpotlightRotate : MonoBehaviour
    {
        public float Range;

        private Light _light;
        private MeshRenderer _meshRenderer;
        private MeshRenderer _meshRenderer2;
        private float baseIntensity;
        private Vector3 initialPos;
        private Vector3 startPos;
        private Vector3 endPos;
        private float currentDuration;
        private float totalDuration;
        private Quaternion startRotation;
        private Quaternion endRotation;

        private void Start()
        {
            initialPos = startPos = transform.position;
            _light = GetComponent<Light>();
            _meshRenderer = GetComponent<MeshRenderer>();
            if (_meshRenderer == null)
            {
                _meshRenderer = transform.parent.GetComponent<MeshRenderer>();
            }
            _meshRenderer2 = transform.childCount == 0 ? null : transform.GetChild(0).GetComponent<MeshRenderer>();
            _light.color = new Color(Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f));
            _light.intensity = baseIntensity = Random.Range(0.5f, 1.5f);
            if (_light.type == LightType.Spot)
            {
                _light.range = Random.Range(100.0f, 200.0f);
                _light.spotAngle = Random.Range(30.0f, 90.0f);
                _meshRenderer.transform.localScale *= (_light.range / 200.0f);
                Vector2 movement = Random.insideUnitCircle * Random.Range(-Range, Range);
                _meshRenderer.transform.Translate(movement.x, 0.0f, movement.y);
            }
            else if (_light.type == LightType.Point)
            {
                _light.range = Random.Range(32.0f, 64.0f);
                _meshRenderer.transform.localScale *= (_light.range / 100.0f);
            }
            if (_meshRenderer != null)
            {
                _meshRenderer.sharedMaterial = new Material(_meshRenderer.sharedMaterial);
                _meshRenderer.sharedMaterial.SetColor("_EmissionColor", _light.color);
            }
            if (_meshRenderer2 != null)
            {
                _meshRenderer2.sharedMaterial = new Material(_meshRenderer.sharedMaterial);
                _meshRenderer2.sharedMaterial.SetColor("_EmissionColor", Color.gray);
            }
        }

        private void Update()
        {
            currentDuration -= Time.deltaTime;
            if (_light.type == LightType.Spot || _light.type == LightType.Area)
            {
                if (currentDuration <= 0.0f)
                {
                    totalDuration = currentDuration = UnityEngine.Random.Range(3.0f, 6.0f);
                    Vector3 ray = UnityEngine.Random.insideUnitSphere;
                    ray.y = Mathf.Min(ray.y, -0.25f);
                    startRotation = _meshRenderer.transform.rotation;
                    endRotation = Quaternion.LookRotation(ray);
                }
                _meshRenderer.transform.rotation = Quaternion.Lerp(startRotation, endRotation, 1.0f - (currentDuration / totalDuration));
            }
            else if (_light.type == LightType.Point)
            {
                if (currentDuration <= 0.0f)
                {
                    totalDuration = currentDuration = UnityEngine.Random.Range(3.0f, 6.0f);
                    startPos = _meshRenderer.transform.position;
                    endPos = initialPos + new Vector3(Random.Range(-Range, Range), 0.0f, Random.Range(-Range, Range));
                }
                _meshRenderer.transform.position = Vector3.Lerp(startPos, endPos, 1.0f - (currentDuration / totalDuration));
            }
            if (_light.type != LightType.Area)
            {
                _light.intensity = baseIntensity * (0.5f + Mathf.PerlinNoise(Time.timeSinceLevelLoad * 0.01f, baseIntensity + _light.range));
            }
        }
    }
}