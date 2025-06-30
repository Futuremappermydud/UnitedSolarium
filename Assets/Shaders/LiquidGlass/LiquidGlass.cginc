//https://github.com/iyinchao/liquid-glass-studio/blob/main/src/shaders/fragment-main.glsl

#define PI (3.14159265359)

#define N_R (1.0 - 0.02)
#define N_G (1.0)
#define N_B (1.0 + 0.02)

float3 hsv2rgb(float3 c) {
  float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

#define TWO_PI 6.28318530718

static const float3 D65_WHITE = float3(0.95045592705, 1.0, 1.08905775076);
static const float3 D50_WHITE = float3(0.96429567643, 1.0, 0.82510460251);

static float3 WHITE = D65_WHITE;

static const float3 LUMA_VEC = float3(0.2126, 0.7152, 0.0722);

static const float3x3 XYZ_TO_XYZ50_M = float3x3(
    1.0479298208405488, 0.029627815688159344, -0.009243058152591178,
    0.022946793341019088, 0.990434484573249, 0.015055144896577895,
    -0.05019222954313557, -0.01707382502938514, 0.7518742899580008
);
static const float3x3 XYZ50_TO_XYZ_M = float3x3(
    0.9554734527042182, -0.028369706963208136, 0.012314001688319899,
    -0.023098536874261423, 1.0099954580058226, -0.020507696433477912,
    0.0632593086610217, 0.021041398966943008, 1.3303659366080753
);

static const float3x3 RGB_TO_XYZ_M = float3x3(
    0.4124, 0.2126, 0.0193,
    0.3576, 0.7152, 0.1192,
    0.1805, 0.0722, 0.9505
);
static const float3x3 XYZ_TO_RGB_M = float3x3(
    3.2406255, -0.9689307, 0.0557101,
    -1.5372080, 1.8757561, -0.2040211,
    -0.4986286, 0.0415175, 1.0569959
);

float UNCOMPAND_SRGB(float a) {
    return (a > 0.04045) ? pow((a + 0.055) / 1.055, 2.4) : (a / 12.92);
}
float3 SRGB_TO_RGB(float3 srgb) {
    return float3(UNCOMPAND_SRGB(srgb.x), UNCOMPAND_SRGB(srgb.y), UNCOMPAND_SRGB(srgb.z));
}
float COMPAND_RGB(float a) {
    return (a <= 0.0031308) ? (12.92 * a) : (1.055 * pow(a, 0.41666666666) - 0.055);
}
float3 RGB_TO_SRGB(float3 rgb) {
    return float3(COMPAND_RGB(rgb.x), COMPAND_RGB(rgb.y), COMPAND_RGB(rgb.z));
}

float3 RGB_TO_XYZ(float3 rgb) {
    return all(WHITE == D65_WHITE) ? mul(RGB_TO_XYZ_M, rgb) : mul(XYZ_TO_XYZ50_M, mul(RGB_TO_XYZ_M, rgb));
}
float3 XYZ_TO_RGB(float3 xyz) {
    return all(WHITE == D65_WHITE) ? mul(XYZ_TO_RGB_M, xyz) : mul(XYZ_TO_RGB_M, mul(XYZ50_TO_XYZ_M, xyz));
}

float XYZ_TO_LAB_F(float x) {
    //          (24/116)^3                         1/(3*(6/29)^2)     4/29
    return x > 0.00885645167 ? pow(x, 0.333333333) : 7.78703703704 * x + 0.13793103448;
}
float3 XYZ_TO_LAB(float3 xyz) {
    float3 xyz_scaled = xyz / WHITE;
    xyz_scaled = float3(
        XYZ_TO_LAB_F(xyz_scaled.x),
        XYZ_TO_LAB_F(xyz_scaled.y),
        XYZ_TO_LAB_F(xyz_scaled.z)
    );
    return float3(
        (116.0 * xyz_scaled.y) - 16.0,
        500.0 * (xyz_scaled.x - xyz_scaled.y),
        200.0 * (xyz_scaled.y - xyz_scaled.z)
    );
}
float LAB_TO_XYZ_F(float x) {
    //                                     3*(6/29)^2         4/29
    return (x > 0.206897) ? x * x * x : (0.12841854934 * (x - 0.137931034));
}
float3 LAB_TO_XYZ(float3 Lab) {
    float w = (Lab.x + 16.0) / 116.0;
    return WHITE * float3(
        LAB_TO_XYZ_F(w + Lab.y / 500.0),
        LAB_TO_XYZ_F(w),
        LAB_TO_XYZ_F(w - Lab.z / 200.0)
    );
}

float3 LAB_TO_LCH(float3 Lab) {
    return float3(
        Lab.x,
        sqrt(dot(Lab.yz, Lab.yz)),
        atan2(Lab.z, Lab.y) * 57.2957795131
    );
}
float3 LCH_TO_LAB(float3 LCh) {
    return float3(
        LCh.x,
        LCh.y * cos(LCh.z * 0.01745329251),
        LCh.y * sin(LCh.z * 0.01745329251)
    );
}

float3 XYY_TO_XYZ(float3 xyY) {
    return float3(
        xyY.z * xyY.x / xyY.y,
        xyY.z,
        xyY.z * (1.0 - xyY.x - xyY.y) / xyY.y
    );
}

// Composite function one-liners
float3 SRGB_TO_XYZ(float3 srgb) { return RGB_TO_XYZ(SRGB_TO_RGB(srgb)); }
float3 XYZ_TO_SRGB(float3 xyz)  { return RGB_TO_SRGB(XYZ_TO_RGB(xyz));  }

float3 SRGB_TO_LAB(float3 srgb) { return XYZ_TO_LAB(SRGB_TO_XYZ(srgb)); }
float3 LAB_TO_SRGB(float3 lab)  { return XYZ_TO_SRGB(LAB_TO_XYZ(lab));  }

float3 SRGB_TO_LCH(float3 srgb) { return LAB_TO_LCH(SRGB_TO_LAB(srgb)); }
float3 LCH_TO_SRGB(float3 lch)  { return LAB_TO_SRGB(LCH_TO_LAB(lch));  }

float float2ToAngle(float2 v) {
  float angle = atan2(v.y, v.x);
  if (angle < 0.0) angle += 2.0 * PI;
  return angle;
}

float3 float2ToRgb(float2 v) {
  float angle = atan2(v.y, v.x);
  if (angle < 0.0) angle += 2.0 * PI;
  float hue = angle / (2.0 * PI);
  float3 hsv = float3(hue, 1.0, 1.0);
  return hsv2rgb(hsv);
}

float4 getTextureDispersion(sampler2D tex, float2 offset, float factor, float2 uv) {
  float4 pixel = float4(1.0, 1.0, 1.0, 1.0);
  pixel.r = tex2D(tex, uv + offset * (1.0 - (N_R - 1.0) * factor)).r;
  pixel.g = tex2D(tex, uv + offset * (1.0 - (N_G - 1.0) * factor)).g;
  pixel.b = tex2D(tex, uv + offset * (1.0 - (N_B - 1.0) * factor)).b;

  return pixel;
}