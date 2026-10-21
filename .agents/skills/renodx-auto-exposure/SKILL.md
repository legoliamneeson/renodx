---
name: renodx-auto-exposure
description: "Investigate RenoDX auto exposure flicker, eye adaptation and dark-to-bright transitions; smooth a proven exposure signal while retaining engine bounds, history and steady-state brightness."
---

# Stabilize a measured exposure path

Use [DevKit investigation](../renodx-devkit-investigation/SKILL.md) to identify
exposure reduction, history and the final consumer. Source reference when
present: `src/games/CODGHOSTS/autoexposure_0xBAF5EC49.ps_5_0.hlsl` and its
`shared.h`, settings and README. This example does not establish other engines'
timing units or exposure direction.

Distinguish input lighting flicker, exposure adaptation, a changing LUT,
adaptive mapper blending, and temporal reconstruction. Freeze or hold one
signal at a time. If output flickers while exposure is stable, continue
downstream/upstream tracing instead of adding another exposure filter.

For a positive exposure multiplier, smoothing in log2 stops can damp small
fluctuations without changing the steady-state target. Reuse the game's
existing history and timing signal where valid. Retain directional limits,
min/max bounds and initialization behavior; guard invalid/zero values before
logarithms. Do not assume a timing constant is seconds without evidence.

Ghosts currently offers HDR Smooth and Original, with 20% adaptation speed
as a starting preference. Vanilla uses original full-speed adaptation.
Its 0% setting holds history subject to current engine bounds; changing
bounds can still change exposure. Keep speed separate from hidden strength
controls, and never clamp scene HDR merely to conceal exposure noise.

Test steady lighting, repeated light flicker, both transition directions,
startup/history reset, checkpoint reload and multiple frame rates. Check
Original at full speed against the baseline and report any uncertain frame-time
dependence. Preserve bloom/downsample alpha when it feeds metering. In Ghosts,
persistent flicker at held exposure also warrants inspection of the t4-driven
adaptive blend in tonemapper7.
