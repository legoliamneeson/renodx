---
name: renodx-runtime-diagnostics
description: "Diagnose RenoDX or RenoOGL crashes, startup retries, stutter, shader injection overhead, swapchain v1/v2 and x86 alignment issues using controlled comparisons and exact build identity."
---

# Diagnose crashes and performance with controlled evidence

Establish the executable build, API, bitness, loaded loader/addons, source
revision, installed hashes, live overrides, scene and launch route. Preserve
the working baseline. Use [setup-game-mod-dev](../setup-game-mod-dev/SKILL.md)
for target builds and [context handoff](../renodx-context-handoff/SKILL.md)
for a continuation record.

## Isolate one cost or failure at a time

Compare the same scene/settings while independently toggling replacement
shaders, injection/tracking, resource upgrades, output proxy and ReShade effects.
Removing shader entries may still leave shared tracking enabled: verify the
actual disabled path. Disable expensive HDR waveform/color-diagram analysis
and snapshot capture when timing. Use CPU/GPU timings and frametime tails,
not a single FPS number or static shader instruction count.

Swapchain v1 versus v2 is not a universal engine compatibility rule. Inspect
actual format, color space, flip behavior, copies, flushes, present settings,
fullscreen transitions and proxy ownership. UE3 addons can use v2 successfully;
Gears' source history contains several experiments, not a blanket reason to
switch every UE3 game to v1. FP16 bandwidth and full-resolution passes remain
costs even with simple shaders. Apply measured, local changes.

## Hook and memory failures

For MW3, inspect `hook_transaction.hpp`, `bloom_blend.hpp`, native draw hooks
and crash capture. Keep attach/detach transactions, thread handling, target
lifetime, re-entry guards and state restoration consistent. A draw replay
layer on top of existing native hooks can create additional failure paths.
Do not patch guessed executable addresses across game revisions or remove a
version check and call that a compatibility port.

For x86, inspect shared allocator alignment, matching allocation/free,
overflow and initialization in `src/utils/platform.hpp`. Native process-heap
alignment may be insufficient for over-aligned shared objects. Rebuild every
cooperating addon if the shared allocator ABI changes. Keep patched ReShade
changes intact; never reset a submodule as a troubleshooting shortcut.

For OpenGL Steam-only startup failures, distinguish the temporary Vulkan
interop device from the game's rendering API and from competing DXGI
swapchains. The Doom/generic workaround is process-scoped; do not disable
system-wide overlays or drivers. Use [OpenGL HDR output](../renodx-opengl-hdr-output/SKILL.md).

## Report the strength of the result

Capture exceptions, stacks and logs when possible. A named driver module is
a symptom location, not proof of cause. Repeated launches and transitions
are required for intermittent bugs. Improving from many retries to two still
leaves a crash unresolved. State whether evidence is source inspection,
compilation, a synthetic GPU test, or an actual game confirmation.
