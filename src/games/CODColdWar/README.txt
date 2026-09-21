Call of Duty: Black Ops Cold War - native HDR RenoDX mod

ACTIVE SHADERS
0xCB76A9C1.ps_6_1: scene composition, selected tone mapper and scene grading.
0xA93248D1.ps_6_1: late PQ LUT, black correction, highlight recovery and output.
Both are registered in addon.cpp. Vanilla retains the reconstructed native paths.

LUT COMPARISON AND CHANGES
Compared against these implementations in this checkout:
- aptinnocence/tonemap10_0xABA0921A.ps_5_0.hlsl samples the LUT black endpoint,
  decodes PQ and uses lut::CorrectBlack to remove a measured luminance floor.
- cp2077/tonemapper.hlsl and thewitcher3/lutsampling.hlsl sample LUT reference
  values and use lut::Unclamp / RecolorUnclamped to correct endpoints.
- bulletstormfullclip/common.hlsl samples a bounded SDR reference, then uses
  UpgradeToneMap to restore HDR energy while carrying the LUT grade forward.

Cold War's late LUT already takes and returns absolute HDR PQ. SDR LUT scaling
or UpgradeToneMap cannot simply be substituted without a matched SDR reference.
The late pass therefore keeps the native centered 32-cubed sampling and uses:

1. Measured black: sample PQ black at LOD 0, decode it and the graded pixel to
   nits, subtract the measured BT.2020 luminance floor, and scale RGB uniformly.
   This replaces the fixed 0.005-0.20 nit fade to ungraded PQ. It retains graded
   RGB ratios and adapts to the current LUT. A zero floor is a no-op. Intentional
   LUT black lift is also removed; this is deliberately part of the custom look.
2. Highlight recovery: retain the existing 40%-85% of display-peak transition,
   but normalize graded RGB and restore the target maximum channel directly.
   The old 4x cap no longer blocks recovery from a strongly compressing LUT.
   Near-zero graded output falls back smoothly to the pre-LUT colour direction.
   Recovery does not boost above the larger of input and graded maximum channels.
3. Continuous peak shoulder: start at 99% of display peak and asymptotically
   approach peak. The old overshoot-only mapping jumped down to 99% immediately
   above peak. At 800 nits, 792 is unchanged, 800 maps to about 797.06, and 808
   maps to about 798.92. RGB ratios remain unchanged by the shoulder.
4. Clamp custom output to nonnegative PQ as well as the display peak AFTER the
   original dither/quantization. Vanilla retains the original quantization.

Cost: one extra 3D LUT fetch for custom modes. Native sampling remains trilinear;
tetrahedral interpolation is a separate quality/performance choice and does not
by itself fix a raised endpoint or recover brightness removed by the LUT.

VALIDATION / LIVE TEST
Compile both shaders with DXC: -T ps_6_1 -HV 2021 -O3 -E main.
Keep shared.h, pragmap.hlsl and the repository shader includes available.

In-game checks still required (synthetic checks cannot validate the game's LUT):
- Compare Vanilla with the previous version at identical game HDR settings.
- In custom modes inspect a dark neutral ramp, coloured shadows and scene changes.
  Check that intentional shadow detail survives measured-floor removal.
- Compare bright clouds, lamps and saturated effects at 400/800/1500 nit peaks.
  Check for banding or noise revealed by stronger highlight recovery.
- Test RenoDRT, PsychoV30 and Pragmap, plus menus/HUD and scene grade strength.
  This late full-screen correction can also affect UI already in the source.
- Use a float HDR capture to inspect the result; an SDR screenshot is insufficient
  to establish absolute nit levels or the correctness of the native HDR convention.

The primary scene LUT and tone mappers are unchanged. This correction cannot
recover detail already clipped by an earlier pass. No runtime capture was used
to establish a new colour-space or brightness convention.
