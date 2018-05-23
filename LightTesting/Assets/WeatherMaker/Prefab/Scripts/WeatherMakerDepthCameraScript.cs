using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DigitalRuby.WeatherMaker
{
    //[ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class WeatherMakerDepthCameraScript : MonoBehaviour
    {
        public int RenderTextureSize = 512;
        public float YOffset = 100.0f;

        private Camera cam;
        private RenderTexture depthTarget;

        private static readonly Matrix4x4 bias = new Matrix4x4()
        {
            m00 = 0.5f, m01 = 0,    m02 = 0,    m03 = 0.5f,
            m10 = 0,    m11 = 0.5f, m12 = 0,    m13 = 0.5f,
            m20 = 0,    m21 = 0,    m22 = 0.5f, m23 = 0.5f,
            m30 = 0,    m31 = 0,    m32 = 0,    m33 = 1,
        };

        private void Update()
        {
        }

        private void OnEnable()
        {
            Camera.onPreCull += CameraPreCull;
        }

        private void OnDisable()
        {
            Camera.onPreCull -= CameraPreCull;
            if (depthTarget != null)
            {
                depthTarget.Release();
                depthTarget = null;
            }
        }

        private void CameraPreCull(Camera cullCamera)
        {
            if (this.cam != cullCamera && cullCamera.cameraType == CameraType.Game &&
                WeatherMakerFullScreenEffect.GetCameraType(cullCamera) == WeatherMakerCameraType.Normal)
            {
                RenderCamera(cullCamera);
            }
        }

        private void UpdateResources()
        {
            if (depthTarget == null || depthTarget.width != RenderTextureSize)
            {
                if (depthTarget != null)
                {
                    depthTarget.Release();
                }
                int size = Mathf.Max(RenderTextureSize, 16);
                depthTarget = new RenderTexture(size, size, 16, RenderTextureFormat.Depth);
                depthTarget.wrapMode = TextureWrapMode.Clamp;
                depthTarget.filterMode = FilterMode.Bilinear;
                depthTarget.autoGenerateMips = false;
                depthTarget.useMipMap = false;
                depthTarget.name = "WeatherMaperYDepthTexture";
                Shader.SetGlobalTexture("_WeatherMakerDepthYShadowTex", depthTarget);
            }
            if (cam == null)
            {
                cam = GetComponent<Camera>();
                cam.clearFlags = CameraClearFlags.Depth;
                cam.backgroundColor = Color.black;
                cam.orthographic = true;
                cam.nearClipPlane = 0.0f;
                cam.allowHDR = true;
                cam.cullingMask = ~4;
                cam.allowMSAA = false;
                cam.useOcclusionCulling = true;
                cam.name = "InternalYDepth_Reflection";
                cam.enabled = false;
            }

            if (cam.targetTexture != depthTarget)
            {
                cam.targetTexture = depthTarget;
            }
            cam.depthTextureMode = DepthTextureMode.Depth;
        }

        private void RenderCamera(Camera cullCamera)
        {
            UpdateResources();
            Vector3 offset = (new Vector3(cullCamera.transform.forward.x, 0.0f, cullCamera.transform.forward.z) * cullCamera.farClipPlane * 0.2f);
            Vector3 pos = cullCamera.transform.position + offset;
            pos.y = cullCamera.transform.position.y + YOffset;
            cam.transform.position = pos;
            cam.transform.forward = Vector3.down;
            cam.orthographicSize = cullCamera.farClipPlane * 0.2f;
            cam.cullingMatrix = cullCamera.cullingMatrix;
            cam.Render();
            Matrix4x4 mtx = bias * cam.projectionMatrix * cam.worldToCameraMatrix;
            Shader.SetGlobalMatrix("_WeatherMakerDepthYShadowMatrix", mtx);
            Shader.SetGlobalVector("_WeatherMakerDepthYParams", new Vector4(0.0f, 0.0f, cam.farClipPlane, 1.0f / cam.farClipPlane));
            Shader.SetGlobalVector("_WeatherMakerDepthYPosition", cam.transform.position);
        }
    }
}
