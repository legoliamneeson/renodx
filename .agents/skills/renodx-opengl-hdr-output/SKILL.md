---
name: renodx-opengl-hdr-output
description: "Build or diagnose RenoDX OpenGL FP16 rendering and D3D11 HDR presentation, default-framebuffer redirection, depth/stencil and copies, Steam launch interop issues, and scRGB versus HDR10 output."
---

# Preserve OpenGL range through HDR presentation

Use [swapchain-resource-analysis](../swapchain-resource-analysis/SKILL.md)
for output proof. OpenGL shader replacement is separately covered by
[generic profiles](../renodx-opengl-source-replacement/SKILL.md) or
[RenoOGL DevKit](../renodx-opengl-devkit/SKILL.md).
Local examples are `src/games/generic_opengl` and, where available,
`src/games/doom3/opengl_framebuffer.hpp` and its output shaders.

Trace this architecture where the game adapter implements it:

```text
OpenGL scene draws -> FP16 color + matching depth/stencil
  -> compatible GPU screen copies / shared texture
  -> D3D11 output shader -> matching HDR swapchain
```

A float framebuffer and display proxy do not recover data already clipped
by shader instructions, fixed-function clamp state or earlier UNORM textures.
Prove each link. Do not call final-frame inverse tonemapping a completed port.

## Rendering and copies

For default-framebuffer redirection, preserve clears, read/draw targets,
viewport, depth/stencil, samples, resize and resource lifetime. Doom-style
stencil shadows need matching depth/stencil. Intermediate copies can still
lose range. Use supported GPU framebuffer blits where conversion is needed,
preserve surrounding GL state and guard recursive copy events. The generic
implementation currently supports one swapchain per device and initializes
at presentation; examine subsequent frames, not just first-frame state.

## Output agreement

Confirm the installed loader hooks the D3D11 proxy (`HookDirectX=1` in the
documented installation path) and enable the adapter's own proxy option.
Match actual scene encoding, reference-white scale, vertical orientation,
output shader, swapchain format and color space. Generic OpenGL documents
HDR10/PQ; older Doom experiments used scRGB, and the current source exposes
additional output choices. Read the active source/settings rather than
carrying an old default across builds. Use `SwapChainPass` consistently.

Check menu/HUD treatment. A composite-only mapper affects UI already baked
into the source. Independent UI brightness needs a separately identifiable
path, not just a new control. Float readback above 1 proves numerical range
at that sample point; it does not establish absolute display luminance.

## Startup and ownership failures

Test direct launch and Steam launch separately. The historical Steam conflict
involved a temporary Vulkan device used for interop; the renderer remained
OpenGL. Existing process-scoped overlay mitigation and the Doom auxiliary
swapchain matcher are specific workarounds, not permission to change global
driver/overlay configuration or every competing swapchain.

Older Doom testing found proxy callback/output ownership sensitive to addon
load order; loading the game addon before DevKit resolved black output/trails
there. Verify current logs and ownership before applying that workaround.
Also check same-window swapchain conflicts and resource lifetime on teardown.

Validate unchanged rendering first, then above-white scene data, copies,
distortion, shadows, UI, resize, fullscreen/Alt-Tab, repeated launches and
teardown. Keep isolated WGL tests distinct from in-game HDR validation.
