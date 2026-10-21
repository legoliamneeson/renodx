# RenoDX Workflow Skills

This folder contains project-local workflow skills for AI agents and contributors. Skills are on-demand procedures: use them when a task matches their domain instead of putting every workflow detail in always-on instructions.

RenoDX keeps shared workflow skills under `.agents/skills/` for the tool-neutral Agent Skills convention.

Default RenoDX mod behavior should be neutral: preserve the vanilla/original SDR art direction and extend its proven pipeline limits into HDR. Default settings should match the original look as closely as practical; visual augmentation belongs in explicit sliders or presets such as `HDR Look`, not in the baseline. Do not assume HDR means more contrast, more saturation, or a new look.

## How to use

- Agents: match the request to the table below, read the relevant `SKILL.md`, then follow its boundaries and handoffs.
- Users: mention the skill name or trigger terms in chat when you want a specific RenoDX workflow.
- Keep `AGENTS.md` for always-on repository rules; keep skills for specialized multi-step work.

## Skill index

| Skill | Use when | Handoff boundary |
| --- | --- | --- |
| `setup-game-mod-dev` | Starting or resuming a game mod, setting up DevKit, configuring build targets, linking into a game folder, or creating baseline verification. | Hand off to `swapchain-resource-analysis` for resource/output proof and to `handle-sdr-tonemap-lut` for proven shader math. |
| `swapchain-resource-analysis` | Tracing final output, swapchain formats, render resources, `SwapChainPass`, proxy resources, SDR/HDR toggles, or proving whether scene HDR data still exists. | Hand off to `setup-game-mod-dev` for addon wiring/builds and to `handle-sdr-tonemap-lut` after the shader-side target signal is proven. |
| `handle-sdr-tonemap-lut` | Editing shader-side tonemap, hard clip, LUT/color grade, RenoDRT, vanilla/0 `ToneMapPass`, Preset Off vanilla reset, PsychoV, gamut compression, hue/saturation clip emulation, or HDR bridge logic after upstream signals are known. | Hand off to `swapchain-resource-analysis` if the target pass/resource or source signal is not proven. |
| `analysis-graphing` | Creating dark-theme plots, curve comparisons, hue sweeps, gamut comparisons, LUT statistics, or image diagnostic panels. | Hand off to `hdr-test-pattern-generation` for source pattern generation and to `bt2020-png-generation` for final HDR PNG output. |
| `hdr-test-pattern-generation` | Generating deterministic SDR/HDR ramps, charts, sweeps, color bars, checkerboards, gamut stress images, or validation sources. | Hand off to `analysis-graphing` for plotting results and to `bt2020-png-generation` for PQ PNG encoding/signaling. |
| `bt2020-png-generation` | Producing or validating BT.2020/BT.2100 PQ PNGs, cICP chunks, ICC/cicpTag behavior, or HDR PNG artifacts from analysis data. | Hand off to `hdr-test-pattern-generation` for synthetic sources and to `analysis-graphing` for plots. |

## Maintenance notes

- The `description` field in each `SKILL.md` is the discovery surface. Put important trigger phrases there.
- Skill folders may include referenced templates, snippets, scripts, and resources; link them from `SKILL.md` so agents can load them when needed.
- Keep overlapping skills connected by explicit handoff text instead of copying the same procedure into multiple files.
- Keep examples tied to stable RenoDX concepts or committed project patterns.
- Validate changed Markdown files before committing.

## Portable continuation skills

Start with [AI_HANDOFF.md](../../AI_HANDOFF.md) and [the kickoff prompt](../../AI_KICKOFF_PROMPT.md) when handing this repository to another AI.

| Skill | Use when |
| --- | --- |
| [renodx-context-handoff](renodx-context-handoff/SKILL.md) | Resume or transfer RenoDX and RenoOGL development context to another AI; identify the checkout, choose focused skills, locate prior game work, and distinguish source, build, installed, and runtime evidence. |
| [renodx-devkit-investigation](renodx-devkit-investigation/SKILL.md) | Trace RenoDX DevKit MCP frames, draws, shader hashes, resources and live overrides; prove where HDR is lost and establish an unchanged shader baseline before editing. |
| [renodx-hdr-curve-lut-extension](renodx-hdr-curve-lut-extension/SKILL.md) | Extend proven RenoDX Hable, LUTless, SDR LUT or native HDR LUT paths while preserving vanilla midtones and highlight color; compare RenoDRT, PsychoV30 and Prism without double compression. |
| [renodx-hdr-bloom](renodx-hdr-bloom/SKILL.md) | Diagnose RenoDX HDR bloom blobs, darkening, clipped particle centers and bloom blend choices in Ghosts, World at War or MW3; preserve SDR tint, alpha and the proven native blur chain. |
| [renodx-auto-exposure](renodx-auto-exposure/SKILL.md) | Investigate RenoDX auto exposure flicker, eye adaptation and dark-to-bright transitions; smooth a proven exposure signal while retaining engine bounds, history and steady-state brightness. |
| [renodx-shader-settings](renodx-shader-settings/SKILL.md) | Wire and debug RenoDX shared.h settings, cbuffer layouts, shader registrations and mapper controls; fix sliders that disappear after gameplay actions or differ across RenoDRT, PsychoV30 and Prism. |
| [renodx-dx9-readback](renodx-dx9-readback/SKILL.md) | Repair RenoDX D3D9 FP16 clone copies and HDR-to-SDR readback, reusable staging caches and GPU blits in MW3 or World at War without stale resources, state leaks or recursive hooks. |
| [renodx-runtime-diagnostics](renodx-runtime-diagnostics/SKILL.md) | Diagnose RenoDX or RenoOGL crashes, startup retries, stutter, shader injection overhead, swapchain v1/v2 and x86 alignment issues using controlled comparisons and exact build identity. |
| [renodx-upscaler-hdr](renodx-upscaler-hdr/SKILL.md) | Diagnose RenoDX HDR through DLSS or other upscalers, including native-versus-clone textures, SDR clipping in FP16, gamma/linear boundaries, render rectangles and post-upscale peak overshoot. |
| [renodx-opengl-source-replacement](renodx-opengl-source-replacement/SKILL.md) | Use the generic_opengl RenoDX addon for captured GLSL or ARB source replacements, executable-local profiles, 64-float parameters and opt-in fixed-function adaptation; distinct from RenoOGL live DevKit. |
| [renodx-opengl-devkit](renodx-opengl-devkit/SKILL.md) | Develop RenoOGL live GLSL and OpenGL SPIR-V replacements with the patched ReShade backend, Original/Add-on/File selection, std140 injection and state preservation; not the generic ARB profile path. |
| [renodx-opengl-hdr-output](renodx-opengl-hdr-output/SKILL.md) | Build or diagnose RenoDX OpenGL FP16 rendering and D3D11 HDR presentation, default-framebuffer redirection, depth/stencil and copies, Steam launch interop issues, and scRGB versus HDR10 output. |
