Shader "CustomEffects/Blur"
{
    HLSLINCLUDE
    
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        // The Blit.hlsl file provides the vertex shader (Vert),
        // the input structure (Attributes), and the output structure (Varyings)
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        #define E 2.71828f

        float _Spread;
        uint _GridSize;
        float _VerticalBlur;
        float _HorizontalBlur;

        float gaussian(int x)
		{
			float sigmaSqu = _Spread * _Spread;
			return (1 / sqrt(TWO_PI * sigmaSqu)) * pow(E, -(x * x) / (2 * sigmaSqu));
		}
    
        float4 BlurVertical (Varyings input) : SV_Target
        {
            float3 col = float3(0.0f, 0.0f, 0.0f);
			float gridSum = 0.0f;

			int upper = ((_GridSize - 1) / 2);
			int lower = -upper;

			for (int y = lower; y <= upper; ++y)
			{   
				float gauss = gaussian(y);
				gridSum += gauss;
				float2 uv = input.texcoord + float2(0.0f, _BlitTexture_TexelSize.y * y);
				col += gauss * SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv).xyz;
			}

			col /= gridSum;

			return float4(col, 1.0f);
        }

        float4 BlurHorizontal (Varyings input) : SV_Target
        {
            float3 col = float3(0.0f, 0.0f, 0.0f);
			float gridSum = 0.0f;

			int upper = ((_GridSize - 1) / 2);
			int lower = -upper;

			for (int x = lower; x <= upper; ++x)
			{
				float gauss = gaussian(x);
				gridSum += gauss;
				float2 uv = input.texcoord + float2(_BlitTexture_TexelSize.x * x, 0.0f);
				col += gauss * SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv).xyz;
			}

			col /= gridSum;

			return float4(col, 1.0f);
        }
    
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZWrite Off Cull Off
        Pass
        {
            Name "BlurPassVertical"

            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment BlurVertical
            
            ENDHLSL
        }
        
        Pass
        {
            Name "BlurPassHorizontal"

            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment BlurHorizontal
            
            ENDHLSL
        }
    }
}
