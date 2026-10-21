---
name: renodx-hdr-bloom
description: "Diagnose RenoDX HDR bloom blobs, darkening, clipped particle centers and bloom blend choices in Ghosts, World at War or MW3; preserve SDR tint, alpha and the proven native blur chain."
---

# Diagnose and adjust HDR bloom

Establish the actual chain with [DevKit investigation](../renodx-devkit-investigation/SKILL.md).
Identify prefilter, downsample, blur, composite, god rays and selected particles;
shader names alone do not establish their role. Preserve alpha used for exposure,
masks or blending. Read the target game's `bloom_blend.hpp`, shader includes,
registrations and README through the [source map](../renodx-context-handoff/references/source-map.md).

## Select the correct blend model

- Screen blend `S + D * (1 - S)` can darken destination values above 1 and
  invert contributions when S also exceeds 1. For proven luminous draws, an
  additive override may preserve HDR better. Do not apply it to smoke,
  ordinary alpha, modulate materials or every draw with a bright pixel.
- An energy-conserving scene/blur interpolation is a different algorithm.
  It needs matching linear units and normalized blur, and it spreads energy,
  so local peaks can decrease. Do not promise peak preservation.
- Ghosts uses a half-resolution separable Gaussian chain, not a multi-resolution
  upsample pyramid. Its current modes are Vanilla (default) and Energy-Conserving;
  the removed HDR peak-preserving experiment is not a recommended default.
  Its 30% composite / 85% internal mix are current game defaults, not constants
  to apply to other engines. Its alpha carries exposure-metering data upstream.
- WaW combines bloom with god rays and currently uses selected additive
  overrides. That source does not prove a threshold-free pyramid or a
  scene-to-blur interpolation. Trace the chain before changing its algorithm.

## Preserve the authored look

MW3's accepted direction preserves the native SDR tint and uses a single
brightness scale for HDR. Extra highlight boosts previously caused blobs.
Remove an unwanted boost at the actual extraction/composite rather than
flattening the entire scene. Preserve alpha bounds independently of HDR RGB.
Review both `CODMW3` and `CODMW3x86` when the user requests both variants.

Bracket blend changes around the actual native draw and restore all modified
RGB/alpha states on every exit. MW3 already hooks native draws; its current
pattern uses that stack scope rather than replaying draws through `on_drawn`.
Adding a second interception mechanism can cause re-entry and launch instability.

## Verify

Compare fixed scenes containing colored lights, fire/particles, smoke, god rays,
dark backgrounds and UI. Check no-op endpoints, unchanged Vanilla, preserved
exposure alpha, finite values, correct blend restoration and frame cost.
A bloom mode enum/UI change needs the matching addon build; a shader-only live
edit cannot update saved-key meanings or slider availability. Document pending
scene checks instead of treating shader compilation as visual confirmation.
