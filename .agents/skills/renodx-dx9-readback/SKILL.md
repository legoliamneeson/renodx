---
name: renodx-dx9-readback
description: "Repair RenoDX D3D9 FP16 clone copies and HDR-to-SDR readback, reusable staging caches and GPU blits in MW3 or World at War without stale resources, state leaks or recursive hooks."
---

# Preserve D3D9 copies and readback after an upgrade

Reference the target's current implementation, especially the D3D9
cloned-resource copy/readback section in `src/games/CODWAW/addon.cpp`, and
the MW3 readback blit shaders and native hooks. Locate files through the
[source map](../renodx-context-handoff/references/source-map.md).
Use [runtime diagnostics](../renodx-runtime-diagnostics/SKILL.md) for crashes.

Prove which operation fails. `GetRenderTargetData` reaches ReShade's copy
event; `StretchRect`, `UpdateSurface`, and resolves can take different paths.
A game-created 8-bit system-memory destination cannot directly accept an
upgraded FP16 surface through an incompatible native copy.

## Select the narrow conversion path

- For GPU copies where both resources have compatible clones, propagate the
  upgraded resources consistently. Verify aliases, dimensions and sample counts.
- For the existing CPU fallback, read into matching CPU-visible FP16 staging,
  then convert to the game's expected 8-bit destination. Honor row pitches,
  channel order, alpha and the proven linear/encoded convention. The current
  WaW fallback is restricted to full surfaces, equal dimensions and supported
  formats; do not silently extend it to rectangles, scaling or arbitrary MSAA.
- Where a game already has a tested GPU conversion/blit, reuse it and restore
  its shaders, constants, textures, targets, viewport and blend/sampler state.
  A display-mapping conversion for a screenshot/CPU consumer must not alter
  the main HDR scene or become an additional tone curve in the display path.

## Cache safely

Key reusable staging by device and complete relevant descriptor. Recreate on
size/format/sample changes. A clone-to-original cache must validate against
live tracking: handles can be destroyed and reused. Invalidate on resource
destruction, reset and device teardown. Keep ownership and locking consistent
with re-entrant resource callbacks; never destroy through a stale device.

Guard recursive replacement calls. Report a copy handled only when the full
replacement succeeds. On unsupported operations preserve the original path;
log a bounded failure rather than claiming success with black or stale data.
Preserve the current sRGB-encoding/opaque-alpha choices only after checking
the consumer's contract. No global change of all copies is justified.

Verify known pixel patterns in CPU output, successive frames, warm-cache
behavior, resize/reset, alpha, channel order and state restoration. Compare
frametime distributions with and without the fix in the same scene. Caching
allocations can reduce overhead but cannot by itself remove GPU/CPU sync.
