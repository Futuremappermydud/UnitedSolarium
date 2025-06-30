//https://github.com/iyinchao/liquid-glass-studio/blob/main/src/shaders/fragment-main.glsl

float superellipseCornerSDF(float2 p, float r, float n) {
    p = abs(p);
    float v = pow(pow(p.x, n) + pow(p.y, n), 1.0 / n);
    return v - r;
}

float roundedRectSDF(float2 p, float2 center, float width, float height, float cornerRadius, float n) {
    p -= center;

    float cr = cornerRadius;

    float2 d = abs(p) - float2(width, height) * 0.5;

    float dist;

    if (d.x > -cr && d.y > -cr) {
        float2 cornerCenter = sign(p) * (float2(width, height) * 0.5 - float2(cr, cr));
        float2 cornerP = p - cornerCenter;
        dist = superellipseCornerSDF(cornerP, cr, n);
    } else {
        dist = min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
    }

    return dist;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(b, a, h) - k * h * (1.0 - h);
}

float mainSDF(float2 p) {
    float d2 = 999999;

    for (int i = 0; i < _SDFBufferSize; i++) {
        Element element = _SDFBuffer[i];
        float2 p1 = -float2(element.Pos.x, element.Pos.y) / float2(_ScreenWidth, _ScreenHeight);
        float2 p1n = p1 + p / _ScreenHeight;

        float d = roundedRectSDF(
            p1n,
            float2(0., 0.),
            element.Size.x / _ScreenHeight,
            element.Size.y/ _ScreenHeight,
            element.Radius / _ScreenHeight,
            element.SuperEllipseFactor
        );
        d2 = smin(d2, d, 0.05);
    }

    return d2;
}

float2 getNormal(float2 p) {
    float eps = 0.001;
    
    float sdf_right = mainSDF(p + float2(eps, 0.0));
    float sdf_left = mainSDF(p - float2(eps, 0.0));
    float sdf_up = mainSDF(p + float2(0.0, eps));
    float sdf_down = mainSDF(p - float2(0.0, eps));
    
    float2 grad = float2(
        sdf_right - sdf_left,
        sdf_up - sdf_down
    ) / (2.0 * eps);
    
    float gradLength = length(grad);
    
    if (gradLength < 0.00001) {
        return float2(1.0, 0.0); 
    }
    
    return normalize(grad);
}