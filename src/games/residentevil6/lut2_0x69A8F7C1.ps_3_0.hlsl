// SDR-accurate RE6 color grading; preserve the original matrix and table domain.
sampler2D SSFilter__tBaseMap             : register(s0);
sampler2D SSWrapPoint__tTVNoiseMap       : register(s1);
sampler2D SSWrapPoint__tTVNoiseMaskMap   : register(s2);
sampler2D SSLinear__tFilterTempMap2      : register(s3);
sampler2D SSPoint__tColorCorrectTableMap : register(s4);

row_major float4x4 fColorCorrectMatrix : register(c1);

float4 fTVNoisePower    : register(c5);
float4 fTVNoiseUVOffset : register(c6);
float4 fTVNoiseScanline : register(c7);
float4 fTVNoiseHVSync   : register(c8);

float4 CBBloomFilter__packed0 : register(c9);
float4 fColorCorrectColor     : register(c10);


float SafeFinitePositive1(float value)
{
    // NaN is the only floating-point value where value != value.
    value = (value == value) ? value : 0.0f;

    // Preserve HDR while remaining finite for upgraded FP16 targets.
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


float3 SRGBToLinear_Unclamped(float3 color)
{
    // Preserve the existing behavior: allow HDR above 1.0, but remove negative
    // values before pow() so upgraded float targets cannot create NaNs.
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


float3 LinearToSRGB_Unclamped(float3 color)
{
    // Do not clamp the upper range. The actual HDR tonemapper is later.
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
// Original TV-noise processing
// ============================================================================

float3 RGBToYCbCr_WithNoise(
    float3 rgb,
    float3 noise
)
{
    float y =
        dot(
            rgb,
            float3(0.299f, 0.587f, 0.114f)
        );

    float cb =
        dot(
            rgb.zxy,
            float3(0.5f, -0.169f, -0.331f)
        );

    float cr =
        dot(
            rgb,
            float3(0.5f, -0.419f, -0.081f)
        );

    y  += fTVNoisePower.x * noise.z;
    cb += fTVNoisePower.y * noise.x;
    cr += fTVNoisePower.y * noise.y;

    return float3(
        y,
        cb,
        cr
    );
}


float3 YCbCrToRGB(float3 ycbcr)
{
    float y  = ycbcr.x;
    float cb = ycbcr.y;
    float cr = ycbcr.z;

    float r =
        y + 1.402f * cr;

    float g =
        y
        - 0.344f * cb
        - 0.714f * cr;

    float b =
        y + 1.772f * cb;

    return float3(
        r,
        g,
        b
    );
}


// ============================================================================
// Original color-correction matrix
// ============================================================================

float3 ApplyColorCorrectMatrix(float3 color)
{
    // Matches the original assembly:
    //
    // r1 = color.y * c2
    // r1 = color.x * c1 + r1
    // r1 = color.z * c3 + r1
    // r1 = r1 + c4

    return
        color.r * fColorCorrectMatrix[0].xyz
        + color.g * fColorCorrectMatrix[1].xyz
        + color.b * fColorCorrectMatrix[2].xyz
        + fColorCorrectMatrix[3].xyz;
}


// ============================================================================
// Original SDR color-correction LUT
// ============================================================================

float3 SampleColorCorrectLUT(float3 coord)
{
    // The authored table itself remains SDR-domain.
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

    float3 lutSRGB;

    lutSRGB.r = rSample.r;
    lutSRGB.g = gSample.g;
    lutSRGB.b = bSample.b;

    // Convert LUT output to linear before measuring its post-process change.
    return SRGBToLinear_Unclamped(
        lutSRGB
    );
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

float4 main(
    float2 texcoord : TEXCOORD0,
    float2 noiseUV  : TEXCOORD1
) : COLOR0
{
    // ------------------------------------------------------------------------
    // Original TV-noise UV construction.
    // ------------------------------------------------------------------------

    float4 noiseCoords =
        noiseUV.xyxy
        * fTVNoisePower.zwzw
        + fTVNoiseUVOffset.xyxy;

    float4 noiseSampleA =
        tex2D(
            SSWrapPoint__tTVNoiseMap,
            noiseCoords.xy
        );

    float4 noiseSampleB =
        tex2D(
            SSWrapPoint__tTVNoiseMap,
            noiseCoords.zw
        );

    float3 tvNoise;

    tvNoise.x =
        noiseSampleB.y - 0.5f;

    tvNoise.y =
        noiseSampleB.z - 0.5f;

    tvNoise.z =
        noiseSampleA.x - 0.5f;

    tvNoise *=
        1.0f + fTVNoiseHVSync.z;


    // ------------------------------------------------------------------------
    // Base scene.
    // ------------------------------------------------------------------------

    float4 baseSample =
        tex2D(
            SSFilter__tBaseMap,
            texcoord
        );

    float3 baseLinear =
        SRGBToLinear_Unclamped(
            baseSample.rgb
        );


    // ------------------------------------------------------------------------
    // Original TV-noise modification in YCbCr.
    // ------------------------------------------------------------------------

    float3 ycbcr =
        RGBToYCbCr_WithNoise(
            baseLinear,
            tvNoise
        );

    float3 noisyRGB =
        YCbCrToRGB(
            ycbcr
        );


    // ------------------------------------------------------------------------
    // Original scanline mask.
    // ------------------------------------------------------------------------

    float2 scanlineUV =
        noiseUV
        * fTVNoiseScanline.z;

    float scanlineMask =
        tex2D(
            SSWrapPoint__tTVNoiseMaskMap,
            scanlineUV
        ).x;

    float scanlinePower =
        1.0f
        - (
            (1.0f - scanlineMask)
            * fTVNoiseScanline.y
        );

    noisyRGB *=
        scanlinePower;


    // ------------------------------------------------------------------------
    // Original bloom/filter-temp contribution.
    // ------------------------------------------------------------------------

    float4 bloomSample =
        tex2D(
            SSLinear__tFilterTempMap2,
            texcoord
        );

    float3 bloomLinear =
        SRGBToLinear_Unclamped(
            bloomSample.rgb
        );


    // Keep bloom and scene HDR-range. No upper clamp.
    float3 combined =
        noisyRGB
        + bloomLinear
        * CBBloomFilter__packed0.rgb;


    // Preserve finite positive values before color correction.
    //
    // Remove negative values without touching HDR values above 1.0.
    combined =
        max(
            combined,
            0.0f.xxx
        );


    // ------------------------------------------------------------------------
    // SDR-accurate LUT/color correction with HDR endpoint extension.
    //
    // The temporary SDR reference is used only internally. The returned signal
    // remains HDR and is intended for the real tonemapper later in the pipeline.
    // ------------------------------------------------------------------------

    float3 gradedLinear =
        ApplySDRAccurateGrade(
            combined
        );


    // ------------------------------------------------------------------------
    // Extended sRGB encode.
    //
    // No saturate() here. Preserve >1 values for the later HDR tonemapper.
    // ------------------------------------------------------------------------

    float3 finalColor =
        LinearToSRGB_Unclamped(
            gradedLinear
        );

    return float4(
        finalColor,
        1.0f
    );
}
