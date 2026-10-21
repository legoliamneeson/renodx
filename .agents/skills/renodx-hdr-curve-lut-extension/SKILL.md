---
name: renodx-hdr-curve-lut-extension
description: "Extend proven RenoDX Hable, LUTless, SDR LUT or native HDR LUT paths while preserving vanilla midtones and highlight color; compare RenoDRT, PsychoV30 and Prism without double compression."
---

# Extend the measured curve and LUT path

First use [handle-sdr-tonemap-lut](../handle-sdr-tonemap-lut/SKILL.md) for the
signal definitions and [DevKit investigation](../renodx-devkit-investigation/SKILL.md)
if the upstream signal is not proven. This skill supplies lessons from Ghosts,
WWII, Cold War, IW7 and Gears; their constants and strategies are not interchangeable.
Find available examples through [source-map.md](../renodx-context-handoff/references/source-map.md).

## Classify before changing math

Document input units/color space, exposure, native curve, range adjustment,
LUT address shaper, dimensions, sampler, LUT output encoding, blend strength,
later grading and final output. Distinguish an SDR LUT from an absolute PQ HDR
LUT. Preserve centered coordinates, axis order and the engine's sampler.
Tetrahedral sampling is a quality choice, not a remedy for wrong units.

Read disassembly when decompiled branches appear implausible. WWII stores
integer bit patterns in float-declared cbuffer slots; `asuint` tests preserve
its `if_nz/if_z` semantics. Numeric float conversion can select the wrong
encoding path. Apply bit reinterpretation only where the original proves it.

## Choose the appropriate extension

- **Analytic Hable/LUTless:** include the original exposure and output-range
  adjustment. Solve for the scene input that maps to output midgray, then
  evaluate the local derivative there. Input 0.18 is not necessarily output
  midgray. Preserve the lower curve and test the extension join and slope.
  Ghosts' `lutless_extension.hlsl` and `lut_extension.hlsl` illustrate distinct
  range conventions; do not replace them with a guessed inflection point.
- **SDR LUT bridge:** keep upstream HDR, an engineered neutral SDR reference,
  and the actual pixel's graded SDR response separate. Decode samples before
  linear reconstruction. Preserve strength/masks and avoid undoing an earlier
  rolloff by restoring its old unbounded luminance. A gray sample cannot fully
  describe a nonlinear LUT's response to each saturated color.
- **Native HDR LUT:** preserve its actual PQ/gamut conventions. WWII measures
  the currently bound LUT and extends its highlight response; its two-point
  fit is game-specific and needs other grades/scenes tested. Cold War corrects
  a measured late-LUT black floor and uses a continuous shoulder. Removing an
  intentional black lift changes the look and must be identified as such.

## Preserve color and useful controls

Independent tangent extensions can drive colored highlights toward white.
Where appropriate, take chromaticity from the original curve at the boundary
along the same RGB ray, blend into that direction smoothly, and scale its
luminance/range separately. Guard zero denominators, negative power/log inputs,
NaNs and near-black reference colors without deleting meaningful negative gamut.

Match reference-white units and shared grading across RenoDRT, PsychoV30 and
Prism. Apply exposure/grade once; do not stack a second midtone-compressing
mapper onto an already display-mapped result. Different curves can legitimately
change average brightness in highlight-heavy scenes. Do not hardcode one
scene's mean as a universal match or replace one mode's curve silently.

A uniform RGB scale can impose a max-channel bound without independently
clipping channel ratios in that working space. Name the space and units of
the bound. Recheck after gamut conversion, dither, temporal processing and UI;
a scene-pass bound alone does not prove final display peak.

## Validation

Test black, dark gray, output midgray, diffuse white, join neighborhoods,
large HDR values, saturated primaries and nonneutral slider settings. Check
continuity, expected slope/monotonicity, finite values and the actual peak
contract. Compile every registered variant in its real shader model.
Compare unchanged Vanilla separately; test LUT strength endpoints, fades,
vignette, alternate scenes and UI. Keep synthetic results distinct from game
validation. Use [shader-settings](../renodx-shader-settings/SKILL.md) to audit
mode-specific controls and [analysis-graphing](../analysis-graphing/SKILL.md)
for reproducible curve comparisons.
