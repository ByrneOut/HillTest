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
    [ExecuteInEditMode]
    [RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
    public class WeatherMakerPlaneCreatorScript : MonoBehaviour
    {
        public MeshRenderer MeshRenderer { get; private set; }
        public MeshFilter MeshFilter { get; private set; }

#if UNITY_EDITOR

        [Header("Plane generation")]
        [Tooltip("The number of rows in the plane. The higher the number, the higher number of vertices.")]
        [Range(4, 124)]
        public int PlaneRows = 96;

        [SerializeField]
        [HideInInspector]
        private int lastPlaneRows = -1;

        [Tooltip("The number of columns in the plane. The higher the number, the higher number of vertices.")]
        [Range(4, 124)]
        public int PlaneColumns = 32;

        [SerializeField]
        [HideInInspector]
        private int lastPlaneColumns = -1;

        [Tooltip("Plane scale, increases space between vertices.")]
        [Range(0.01f, 10000.0f)]
        public float PlaneScale = 1.0f;

        [SerializeField]
        [HideInInspector]
        private float lastPlaneScale = -1;

        [Tooltip("True if plane forward is z axis (xy plane) false otherwise (xz plane).")]
        public bool PlaneForwardIsZAxis = true;

        private void DestroyMesh()
        {
            if (MeshFilter.sharedMesh != null)
            {
                GameObject.DestroyImmediate(MeshFilter.sharedMesh, false);
                MeshFilter.sharedMesh = null;
            }
        }

        private Mesh CreatePlaneMesh()
        {
            DestroyMesh();
            Mesh m = new Mesh { name = "WeatherMakerPlane" };
            int vertIndex = 0;
            float stepX = PlaneScale * (1.0f / (float)PlaneColumns);
            float stepY = PlaneScale * (1.0f / (float)PlaneRows);
            float start = PlaneScale * -0.5f;
            float end = PlaneScale * 0.5f;
            List<Vector3> vertices = new List<Vector3>(PlaneColumns * PlaneRows);
            List<Vector2> uvs = new List<Vector2>(PlaneColumns * PlaneRows);
            List<Vector3> normals = new List<Vector3>();
            List<int> triangles = new List<int>();
            for (float colPos = start; colPos < end; colPos += stepX)
            {
                for (float rowPos = start; rowPos < end; rowPos += stepY)
                {
                    if (PlaneForwardIsZAxis)
                    {
                        vertices.Add(new Vector3(colPos, rowPos, 0.0f));
                        vertices.Add(new Vector3(colPos, rowPos + stepY, 0.0f));
                        vertices.Add(new Vector3(colPos + stepX, rowPos + stepY, 0.0f));
                        vertices.Add(new Vector3(colPos + stepX, rowPos, 0.0f));
                        normals.Add(Vector3.forward);
                        normals.Add(Vector3.forward);
                        normals.Add(Vector3.forward);
                        normals.Add(Vector3.forward);
                    }
                    else
                    {
                        vertices.Add(new Vector3(colPos, 0.0f, rowPos));
                        vertices.Add(new Vector3(colPos, 0.0f, rowPos + stepY));
                        vertices.Add(new Vector3(colPos + stepX, 0.0f, rowPos + stepY));
                        vertices.Add(new Vector3(colPos + stepX, 0.0f, rowPos));
                        normals.Add(Vector3.up);
                        normals.Add(Vector3.up);
                        normals.Add(Vector3.up);
                        normals.Add(Vector3.up);
                    }
                    uvs.Add(new Vector2(colPos + 0.5f, rowPos + 0.5f));
                    uvs.Add(new Vector2(colPos + 0.5f, rowPos + stepY + 0.5f));
                    uvs.Add(new Vector2(colPos + stepX + 0.5f, rowPos + stepY + 0.5f));
                    uvs.Add(new Vector2(colPos + stepX + 0.5f, rowPos + 0.5f));
                    triangles.Add(vertIndex++);
                    triangles.Add(vertIndex++);
                    triangles.Add(vertIndex);
                    triangles.Add(vertIndex -= 2);
                    triangles.Add(vertIndex += 2);
                    triangles.Add(++vertIndex);
                    vertIndex++; // get ready for next position
                }
            }
            m.SetVertices(vertices);
            m.SetUVs(0, uvs);
            m.SetTriangles(triangles, 0);
            m.SetNormals(normals);
            m.bounds = new Bounds(Vector3.zero, PlaneScale * Vector3.one);
            return m;
        }

#endif

        protected virtual void Awake()
        {
            MeshRenderer = GetComponent<MeshRenderer>();
            MeshRenderer.sortingOrder = int.MinValue;
            MeshFilter = GetComponent<MeshFilter>();
        }

        protected virtual void Update()
        {

#if UNITY_EDITOR

            if (MeshFilter.sharedMesh == null || lastPlaneColumns != PlaneColumns || lastPlaneRows != PlaneRows || lastPlaneScale != PlaneScale)
            {
                lastPlaneColumns = PlaneColumns;
                lastPlaneRows = PlaneRows;
                lastPlaneScale = PlaneScale;
                MeshFilter.sharedMesh = CreatePlaneMesh();
            }

#endif

        }
    }
}
