---
name: renodx-upscaler-hdr
description: "Diagnose RenoDX HDR through DLSS or other upscalers, including native-versus-clone textures, SDR clipping in FP16, gamma/linear boundaries, render rectangles and post-upscale peak overshoot."
---

# Preserve HDR through an upscaler boundary

Start with [DevKit investigation](../renodx-devkit-investigation/SKILL.md) and
the game's actual wrapper contract. Gears Redux is the concrete example in
`src/games/gearsofwarredux/README.md`, `dlss.hpp`, the decoder compute shader
and its final motion-blur shader. These files may be absent in the OpenGL copy;
the [source map](../renodx-context-handoff/references/source-map.md) identifies that.

Compare input and output in native/DLAA and actual upscaling modes. Record
allocated size, active render rect, format, resource identity and encoding.
An engine can allocate at output resolution while rendering a smaller rect.
An external API receiving the original texture pointer may bypass ReShade
shader-bound clones: a bright clone and black original can yield a black
upscaler result. A native upgrade can address that boundary when supported;
include non-RTV UAV/SRV outputs and copy aliases in the proven resource chain.

FP16 storage does not select HDR processing inside middleware. If a finite
input above 1 becomes exactly 0..1 downstream, inspect feature creation,
exposure and encoding contracts. Preserve unrelated flags and feature-reuse
behavior. Gears uses a version-specific Redux interface-3 wrapper; its flags,
exports and DLAA special case are evidence for that wrapper, not a universal
hook recipe. Unsupported interfaces must retain their existing behavior.

If converting gamma input to linear at the boundary, preserve the rest of
the engine's gamma-space post-process by converting at the matching later
point. Avoid an extra tone mapper. Reuse conversion textures by compatible
dimensions/device, recreate on changes, respect render-rect offsets, and
restore all compute bindings. Preserve motion vectors, sample locations,
fades and alpha/depth data.

Reconstruction can exceed the input peak. Recheck after the final temporal
and blur stages using the actual output-white scale, not an earlier scale
that has already been changed. A uniform RGB limit preserves channel ratios
in its working space. Test native, DLAA, quality/performance modes, UI white
unequal to game white, resolution changes and nonzero render origins.

A WARP/isolated conversion test verifies local math and state restoration;
it does not validate the vendor's reconstruction or game visual equivalence.
Keep performance evidence and image-correctness evidence separate.
