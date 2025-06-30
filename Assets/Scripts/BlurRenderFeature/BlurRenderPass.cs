using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;
using UnityEngine.UI;
using static BlurRendererFeature;

public class BlurRenderPass : ScriptableRenderPass
{
    private BlurSettings defaultSettings;
    private Material material;

    private TextureDesc blurTextureDescriptor;
    private RTHandle rtHandle;

    public BlurRenderPass(Material material, BlurSettings defaultSettings)
    {
        this.material = material;
        this.defaultSettings = defaultSettings;
    }

    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    {
        UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

        UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

        RenderTextureDescriptor textureProperties = new RenderTextureDescriptor((int)(Screen.width / 2f), (int)(Screen.height / 2f), RenderTextureFormat.Default, 0);
        TextureHandle textureHandle = UniversalRenderer.CreateRenderGraphTexture(renderGraph, textureProperties, defaultSettings.OutputTextureName, false);

        TextureHandle textureHandleSecondary = UniversalRenderer.CreateRenderGraphTexture(renderGraph, textureProperties, defaultSettings.OutputTextureName, false);

        TextureHandle source = resourceData.activeColorTexture;
        
        blurTextureDescriptor = textureHandle.GetDescriptor(renderGraph);
        blurTextureDescriptor.name = k_BlurTextureName;
        blurTextureDescriptor.depthBufferBits = 0;
        var dst = renderGraph.CreateTexture(blurTextureDescriptor);

        // The following line ensures that the render pass doesn't blit from the back buffer.
        if (resourceData.isActiveTargetBackBuffer)
            return;

        // Update the blur settings in the material
        UpdateBlurSettings();

        // This check is to avoid an error from the material preview in the scene
        if (!textureHandle.IsValid() || !dst.IsValid())
            return;

        RenderGraphUtils.BlitMaterialParameters paraInitial = new(source, dst, Blitter.GetBlitMaterial(TextureDimension.Tex2D), 0);
        renderGraph.AddBlitPass(paraInitial);

        RenderGraphUtils.BlitMaterialParameters paraVertical = new(dst, textureHandleSecondary, material, 0);
        renderGraph.AddBlitPass(paraVertical, k_VerticalPassName);

        RenderGraphUtils.BlitMaterialParameters paraHorizontal = new(textureHandleSecondary, textureHandle, material, 1);
        renderGraph.AddBlitPass(paraHorizontal, k_HorizontalPassName);

        if (defaultSettings.blitToScreen)
        {
            RenderGraphUtils.BlitMaterialParameters paraCopy = new(textureHandle, source, Blitter.GetBlitMaterial(TextureDimension.Tex2D), 0);
            renderGraph.AddBlitPass(paraCopy);
        }

        if (rtHandle == null)
            rtHandle = RTHandles.Alloc(defaultSettings.outputTexture);

        var tex = renderGraph.ImportTexture(rtHandle);
        RenderGraphUtils.BlitMaterialParameters paraTexture = new(textureHandle, tex, Blitter.GetBlitMaterial(TextureDimension.Tex2D), 0);
        renderGraph.AddBlitPass(paraTexture);
    }

    private void UpdateBlurSettings()
    {
        if (material == null) return;

        int gridSize = Mathf.CeilToInt(defaultSettings.strength * 5.0f);

        if(gridSize % 2 == 0)
        {
            gridSize++;
        }

        material.SetInteger("_GridSize", gridSize);
        material.SetFloat("_Spread", defaultSettings.strength);
    }

    private const string k_BlurTextureName = "_BlurTexture";
    private const string k_VerticalPassName = "VerticalBlurRenderPass";
    private const string k_HorizontalPassName = "HorizontalBlurRenderPass";
}
