// SDR-accurate RE6 color grading; preserve the original matrix and table domain.
sampler2D SSPoint__tBaseMap : register(s0);
sampler2D SSPoint__tColorCorrectTableMap : register(s1);

row_major float4x4 fColorCorrectMatrix : register(c1);
float4 fColorCorrectColor : register(c5);


float SafeFinitePositive1(float value)
{
    // NaN is the only floating-point value where value != value.
    value = (value == value) ? value : 0.0f;

    // Preserve HDR values while staying inside the finite FP16 range.
    return min(
        max(value, 0.0f),
        65504.0f
    );
}


float3 SafePositive(float3 color)
{
    return float3(
        SafeFinitePositive1(color.r),
        SafeFinitePositive1(color.g),
        SafeFinitePositive1(color.b)
    );
}


float3 SRGBToLinear(float3 color)
{
    color = SafePositive(color);

    float3 low =
        color / 12.92f;

    float3 high =
        pow(
            max(
                (color + 0.055f) / 1.055f,
                0.0f.xxx
            ),
            2.4f.xxx
        );

    return SafePositive(
        lerp(
            high,
            low,
            color <= 0.03928f
        )
    );
}


// Extended positive sRGB encode.
//
// Do not clamp the result to 1.0. This pass must preserve values for the real
// tonemapper that executes later.
float3 LinearToSRGB_Unclamped(float3 color)
{
    color = SafePositive(color);

    float3 low =
        color * 12.92f;

    float3 high =
        1.055f
        * pow(
            max(color, 0.0f.xxx),
            (1.0f / 2.4f).xxx
        )
        - 0.055f;

    return SafePositive(
        lerp(
            high,
            low,
            color <= 0.003131f
        )
    );
}


// ============================================================================
// Original color-correction LUT
// ============================================================================

float3 SampleColorCorrectLUT(float3 coord)
{
    // The authored color-correction table itself is SDR-domain.
    coord = saturate(coord);

    float4 rSample =
        tex2D(
            SSPoint__tColorCorrectTableMap,
            coord.xx
        );

    float4 gSample =
        tex2D(
            SSPoint__tColorCorrectTableMap,
            coord.yy
        );

    float4 bSample =
        tex2D(
            SSPoint__tColorCorrectTableMap,
            coord.zz
        );

    float3 lutColor;

    lutColor.r = rSample.r;
    lutColor.g = gSample.g;
    lutColor.b = bSample.b;

    // Convert the LUT's encoded result back to linear light before measuring
    // its luminance/chrominance effect.
    return SRGBToLinear(lutColor);
}

// Match the original per-channel table coordinates throughout 0..1.
// Above white, extend each curve with its endpoint gain. This is an HDR
// extrapolation, not authored SDR data; it is continuous and leaves SDR intact.
float3 ApplySDRAccurateGrade(float3 color) {
    float3 coord = color.r * fColorCorrectMatrix[0].xyz
                 + color.g * fColorCorrectMatrix[1].xyz
                 + color.b * fColorCorrectMatrix[2].xyz
                 + fColorCorrectMatrix[3].xyz;
    coord = SafePositive(coord);
    float3 graded = SampleColorCorrectLUT(saturate(coord));
    graded *= max(coord, 1.0f.xxx);
    // Keep the game's blend parameter, including any authored extrapolation.
    return SafePositive(lerp(color, graded, fColorCorrectColor.w));
}

float4 main(float2 texcoord : TEXCOORD0) : COLOR0 {
    float4 baseSample = tex2D(SSPoint__tBaseMap, texcoord);
    float3 color = SRGBToLinear(baseSample.rgb);
    return float4(LinearToSRGB_Unclamped(ApplySDRAccurateGrade(color)), baseSample.a);
}