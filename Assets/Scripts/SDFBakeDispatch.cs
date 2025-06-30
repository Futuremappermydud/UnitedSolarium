using System;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

[ExecuteInEditMode]
public class SDFBakeDispatch : MonoBehaviour
{
    [SerializeField]
    ComputeShader computeShader;
    [SerializeField]
    RenderTexture resultTexture;
    [SerializeField]
    bool dispatch;
    [SerializeField]
    List<Element> data = new List<Element>()
    {
        new Element(new float2(0f, 0f), new float2(700f, 500f), 200f, 2f),
    };
    ComputeBuffer sdfBuffer;

    static readonly int resultId = Shader.PropertyToID("_Result");
    private int PixelWidth => Camera.main.pixelWidth;
    private int PixelHeight => Camera.main.pixelHeight;

    void OnEnable()
    {
        sdfBuffer = new ComputeBuffer(PixelWidth * PixelHeight, 4*6);
        Shader.SetGlobalTexture("_SDFResult", resultTexture);
    }
    void OnDisable()
    {
        sdfBuffer.Release();
        sdfBuffer = null;
    }

    void Start()
    {
        
    }

    void Update()
    {
        if (!dispatch) return;

        sdfBuffer.SetData(data);
        computeShader.SetInt("_SDFBufferSize", data.Count);
        computeShader.SetBuffer(0, "_SDFBuffer", sdfBuffer);

        computeShader.SetTexture(0, resultId, resultTexture);

        computeShader.Dispatch(0, PixelWidth / 8, PixelHeight / 8, 1);
    }
    [Serializable]
    struct Element
    {
        public Element(float2 pos, float2 size, float radius, float superEllipseFactor)
        {
            Pos = pos;
            Size = size;
            Radius = radius;
            SuperEllipseFactor = superEllipseFactor;
        }

        public float2 Pos;
        public float2 Size;
        public float Radius;
        public float SuperEllipseFactor;
    };
}
