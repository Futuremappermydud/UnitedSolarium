Shader "Unlit/LiquidGlassV2"
{
    Properties
    {
        _SmallBlur ("Small Blur", 2D) = "white" {}

        _ScreenWidth ("Screen Width", Float) = 1.
        _ScreenHeight ("Screen Height", Float) = 1.

        _Thickness ("Thickness", Float) = 1.
        _ReflectionFactor ("Reflection Factor", Float) = 1.
        _DispGain ("Dispersion Gain", Float) = 1.

        _Tint ("Tint", Color) = (1., 1., 1., 1.)

        _FresnelRange ("Fresnel Size", Float) = 1.
        _FresnelHardness ("Fresnel Hardness", Float) = 1.
        _FresnelIntensity ("Fresnel Intensity", Float) = 1.

        _GlareRange ("Glare Size", Float) = 1.
        _GlareHardness ("Glare Hardness", Float) = 1.
        _GlareConvergence ("Glare Convergence", Float) = 1.
        _GlareOppositeFactor ("Glare Opposite Side", Float) = 1.
        _GlareIntensity ("Glare Intensity", Float) = 1.
        _GlareAngle ("Glare Angle", Float) = 1.

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _ScreenWidth;
            float _ScreenHeight;

            float _Thickness;
            float _ReflectionFactor;
            float _DispGain;

            float _FresnelRange;
            float _FresnelHardness;
            float _FresnelIntensity;

            float4 _Tint;

            float _GlareRange;
            float _GlareHardness;
            float _GlareConvergence;
            float _GlareOppositeFactor;
            float _GlareIntensity;
            float _GlareAngle;

            #include "UnityCG.cginc"
            #include "LiquidGlass.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _SmallBlur;
            float4 _SmallBlur_ST;

            sampler2D _SDFResult;
            float4 _SDFResult_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _SmallBlur);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 Screen = float2(_ScreenWidth, _ScreenHeight);
                float3 sdf = tex2D(_SDFResult, i.uv);
                float merged = sdf.r;
                
                float4 outColor;
                if (merged < 0.005) {
                    float nmerged = -1.0 * (merged * Screen.y);

                    // calculate refraction edge factor:
                    float x_R_ratio = 1.0 - nmerged / _Thickness;
                    float thetaI = asin(pow(x_R_ratio, 2.0));
                    float thetaT = asin(1.0 / _ReflectionFactor * sin(thetaI));
                    float edgeFactor = -1.0 * tan(thetaT - thetaI);
                    // Will have value > 0 inside of shape, force normalize here
                    if (nmerged >= _Thickness) {
                        edgeFactor = 0.0;
                    }

                    if (edgeFactor <= 0.0) {
                        outColor = tex2D(_SmallBlur, i.uv);
                        outColor = lerp(outColor, float4(_Tint.r, _Tint.g, _Tint.b, 1.0), _Tint.a * 0.8);
                    } else {
                        // calculate parameters
                        float3 normal = float3(sdf.gb, 0.);
                        float4 blurredPixel = getTextureDispersion(
                            _SmallBlur,
                            -normal *
                            edgeFactor *
                            0.05 *
                            float2(
                                Screen.y / (Screen.x), /* resolution independent */
                                1.0
                            ),
                            _DispGain,
                            i.uv
                        );

                        // basic tint
                        outColor = lerp(blurredPixel, float4(_Tint.r, _Tint.g, _Tint.b, 1.0), _Tint.a * 0.8);

                        float fresnelFactor = clamp(
                            pow(
                            1.0 +
                                merged * Screen.y / 1500.0 * pow(500.0 / _FresnelRange, 2.0) +
                                _FresnelHardness,
                            5.0
                            ),
                            0.0,
                            1.0
                        );

                        float3 fresnelTintLCH = SRGB_TO_LCH(
                            lerp(float3(1., 1., 1.), float3(_Tint.r, _Tint.g, _Tint.b), _Tint.a * 0.5)
                        );
                        fresnelTintLCH.x += 20.0 * fresnelFactor * _FresnelIntensity;
                        fresnelTintLCH.x = clamp(fresnelTintLCH.x, 0.0, 100.0);

                        outColor = lerp(
                            outColor,
                            float4(LCH_TO_SRGB(fresnelTintLCH), 1.0),
                            fresnelFactor * _FresnelIntensity * 0.7
                        );

                        // add glare
                        float glareGeoFactor = clamp(
                            pow(
                            1.0 +
                                merged * Screen.y / 1500.0 * pow(500.0 / _GlareRange, 2.0) +
                                _GlareHardness,
                            5.0
                            ),
                            0.0,
                            1.0
                        );

                        float glareAngle = (float2ToAngle(normalize(normal)) - PI / 4.0 + _GlareAngle) * 2.0;
                        int glareFarside = 0;
                        if (
                            glareAngle > PI * (2.0 - 0.5) && glareAngle < PI * (4.0 - 0.5) ||
                            glareAngle < PI * (0.0 - 0.5)
                        ) {
                            glareFarside = 1;
                        }
                        float glareAngleFactor =
                            (0.5 + sin(glareAngle) * 0.5) *
                            (glareFarside == 1
                            ? 1.2 * _GlareOppositeFactor
                            : 1.2) *
                            _GlareIntensity;
                        glareAngleFactor = clamp(pow(glareAngleFactor, 0.1 + _GlareConvergence * 2.0), 0.0, 1.0);

                        float3 glareTintLCH = SRGB_TO_LCH(
                            lerp(float3(1., 1., 1.), float3(_Tint.r, _Tint.g, _Tint.b), _Tint.a * 0.5)
                        );
                        glareTintLCH.x += 20.0 * glareAngleFactor * glareGeoFactor;
                        glareTintLCH.x = clamp(glareTintLCH.x, 0.0, 100.0);

                        outColor = lerp(
                            outColor,
                            float4(LCH_TO_SRGB(glareTintLCH), 1.0),
                            glareAngleFactor * glareGeoFactor
                        );
                    }
                }
                return fixed4(outColor.rgb, 1.-smoothstep(-0.001, 0.001, merged));
            }
            ENDCG
        }
    }
}
