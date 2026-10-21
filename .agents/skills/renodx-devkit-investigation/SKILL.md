---
name: renodx-devkit-investigation
description: "Trace RenoDX DevKit MCP frames, draws, shader hashes, resources and live overrides; prove where HDR is lost and establish an unchanged shader baseline before editing."
---

# Investigate a live rendering path

For connection/build setup use [setup-game-mod-dev](../setup-game-mod-dev/SKILL.md).
For output decisions use [swapchain-resource-analysis](../swapchain-resource-analysis/SKILL.md).
Inspect `docs/DEVKIT_MCP.md` and the available tool schemas before invoking
tools; names and response fields are version-dependent.

## Evidence loop

1. Select the connection for the intended process and the active rendering
   device. A proxy D3D11 device or a device with zero draws is not necessarily
   the OpenGL/game renderer. Record API, architecture and output state.
2. Queue one snapshot, wait for its capture, then work backward from the final
   output. Inspect shader hash/stage, inputs, render targets, copies/resolves,
   blend state, resource formats and original-versus-clone identity.
3. Read the same candidate signal before and after the suspected loss. Record
   RGB range, finite/NaN counts, dimensions and encoding. Ignore depth/masks
   in alpha when claiming HDR. Values above 1 in encoded or arbitrary-unit
   textures are not measured display nits.
4. Identify scene, LUT/grade, bloom, temporal/upscaler, UI and final output
   stages. Missing above-white output can be a shader clamp, a UNORM write,
   a stale alias, a blend equation or middleware behavior.
5. Dump original bytecode outside live shader/source folders. Keep one active
   replacement per hash. Compile and load an unchanged decompilation first,
   then compare with Original before introducing a shader edit.

## Avoid misleading captures

Resource handles, draw indices and connection IDs are session-local. Save
hashes and descriptor/usage relationships as evidence, not hardcoded handles
for future resource-upgrade rules. Follow the current source's matching APIs.

Compare a fixed scene or paired samples in one frame where possible. A moving
camera, auto exposure, particles or changing LUT can invalidate sequential
pixel differences. A successful load or green status only proves acceptance.

Use bounded snapshots/readbacks. Stop continuous capture and expensive
analysis effects before performance measurements. If a tool errors or a
connection disappears, inspect status/logs before retrying; do not repeatedly
trigger expensive captures into a failing renderer.

## Turn experiments into durable changes

Verify the active shader is the intended file or addon replacement. A live
shader for a new hash does not add that hash to an older addon's injection
registration. New controls/registrations need a matching build and restart.
Restore temporary probes and record any intentionally retained live override.

Deliver a short pass/resource table and a justified edit target. If the useful
source is already clipped, continue upstream instead of inventing missing
highlights. See [shader-settings](../renodx-shader-settings/SKILL.md) when
controls work in one scene and disappear after an action.
