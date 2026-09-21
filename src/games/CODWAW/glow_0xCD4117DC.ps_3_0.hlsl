// World at War fullscreen bloom + god rays (original shader 0xCD4117DC).
// The original vertex shader supplies TEXCOORD0 only; this is not a particle.
sampler2D colorMapSampler : register(s0);
sampler2D godRaysSampler : register(s4);
float4 glowApply : register(c5);
// Matches shared.h / ShaderInjectData without importing the tone-map library.
float4 bloomControls : register(c59);

float SafePositive(float value) {
    return (value == value) ? min(max(value, 0.0f), 65504.0f) : 0.0f;
}

float3 SafePositive(float3 value) {
    return float3(SafePositive(value.r), SafePositive(value.g), SafePositive(value.b));
}

float4 main(float2 uv : TEXCOORD0) : COLOR0 {
    float3 bloom = SafePositive(tex2D(colorMapSampler, uv).rgb);
    float3 rays = SafePositive(tex2D(godRaysSampler, uv).rgb);
    float3 glow = bloom * SafePositive(glowApply.w)
                + rays * SafePositive(glowApply.z);
    glow = SafePositive(glow * SafePositive(bloomControls.y));
    // Preserve original zero alpha. Bloom must not introduce scene opacity.
    // Preserve HDR energy; only guard the representable FP16 range.
    return float4(glow, 0.0f);
}
