---
name: renodx-shader-settings
description: "Wire and debug RenoDX shared.h settings, cbuffer layouts, shader registrations and mapper controls; fix sliders that disappear after gameplay actions or differ across RenoDRT, PsychoV30 and Prism."
---

# Verify settings from UI to the active shader

Use this skill for C++/HLSL plumbing; use
[curve/LUT extension](../renodx-hdr-curve-lut-extension/SKILL.md) for the math.
OpenGL has two distinct layouts covered by
[source replacement](../renodx-opengl-source-replacement/SKILL.md) and
[OpenGL DevKit](../renodx-opengl-devkit/SKILL.md).

Trace each control through saved key, enum/value conversion, C++ field,
buffer layout, registration, shader macro and selected branch. Preserve saved
setting meanings and padding unless deliberately migrating them. Check the
entire shared structure, byte offsets, shader-model register/space and binding
lifetime. `b13` names one binding slot, not thirteen buffers.

Prefer the established shared injection module. Gears Redux's optional direct
D3D11 backend is a measured game-specific alternative: it replaces at shader
creation, tracks recognized pipelines, uses one buffer per recording context,
uploads changed data, and rebinds after another pass may have occupied the slot.
Do not generalize it to every API or bypass required lifecycle cleanup.

## When controls stop after an action

Capture the working and broken states. Compare active shader hashes,
replacement source and input resources before editing the mapper. WWII's
bayonet charge switches from `0x1A5B4531` to `0x0031657D`; the latter needed
registration and the same shared logic. A File replacement can render while
an old addon supplies no settings to that hash. Rebuild/restart to verify
persistent registration, then test without temporary diagnostic probes.

## Make controls honest

Apply shared grading once, keep internal mapper grading neutral where the
design requires it, and trace game-white/UI-white scaling through output.
A scale divided away later makes a slider ineffective. Test scene and UI
separately; UI baked into a scene cannot become independent through a label.

Build a small mode/control table. Disable or explain controls with no effect
in a mode (for example, a mapper-specific flare or scaling option). Distinguish
Vanilla tone mapping, Preset Off/reset and an actual native SDR output switch.
Changing the label or output encoding while retaining the old swapchain
color space is invalid; output-format changes may require restart.

Where an existing version marker is used, preserve its fallback for absent
or incompatible data. Do not invent a new cross-game layout unless needed.
Test each meaningful slider at two distinct values in every advertised mode,
after scene/action transitions, with live overrides removed for the final
addon check. Report source, compile, installed and runtime status separately.
