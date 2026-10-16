---
name: renodx-opengl-source-replacement
description: "Use the generic_opengl RenoDX addon for captured GLSL or ARB source replacements, executable-local profiles, 64-float parameters and opt-in fixed-function adaptation; distinct from RenoOGL live DevKit."
---

# Develop with the generic OpenGL profile addon

Read `src/games/generic_opengl/README.md` and its `profile` examples first.
This is the source-upload/profile path. For Original/Add-on/File live
program selection use [OpenGL DevKit](../renodx-opengl-devkit/SKILL.md).
For presentation use [OpenGL HDR output](../renodx-opengl-hdr-output/SKILL.md).

Start capture-only with the correct architecture's addon-enabled ReShade.
The profile root is `renodx-opengl` beside the executable, independent of the
launcher's working directory. Source/profile structure changes need restart;
already compiled programs are not automatically recompiled by this addon.

Captures use `0xHASH.ps.glsl` or `0xHASH.ps.arb` (and the corresponding stages).
CRC32 is calculated on submitted source after trailing NUL removal. Retain
the original key, copy from `dump` to `replacements`, and verify an unchanged
replacement first. Explicit relative file mappings stay inside the profile
and override same-named replacements. Engine preprocessing means the captured
source may differ from a shader file in an archive.

Verify both submission and driver-acceptance log entries. GLSL compilation
success does not guarantee game program link success; preserve versions,
attributes, varyings, uniforms and stage interfaces. A later link failure is
not automatically rolled back by this path. Binary caches, SPIR-V and non-ARB
vendor assembly are outside this source-replacement implementation.

## Parameter interface

The profile supplies 64 floats packed into 16 vec4 values (256 bytes):

```glsl
layout(std140) uniform RenoDX {
    vec4 renodx_params[16];
};
```

The addon binds this block by name; its default temporary binding is 13.
Keep the exact block size and select a valid slot. For older GLSL use
`uniform vec4 renodx_params[16];`. For ARB use configured `program.local`
or `program.env` slots (the example starts at 80), within driver limits and
avoiding parameters the original shader still needs. Do not substitute an
arbitrary HLSL cbuffer or the DevKit's separate example block.

Slider values persist in ReShade.ini. `parameter_values.json` updates live
without relinking; invalid updates are rejected atomically. Profile structure
still needs restart. Injection targets recognized replacements and restores
original uniform/ARB values, block mapping, indexed ranges and generic UBO
bindings after the operation. Test these invariants when changing hooks.

## Fixed-function scope

Enable unclamping or a custom fragment program only after proving the game
uses compatible fixed-function draws. A float destination is still required.
The teaching fragment examples do not emulate arbitrary combiners, fog,
lighting or materials. UI may use the same eligible path; mixed materials
require a selector. Do not remove every clamp in an ARB program: masks,
shadows, alpha and interpolation bounds have separate purposes.

Consult the README's current draw-hook exclusions, core-profile limitations,
display-list and shared-program restrictions. Run the isolated WGL harness
in the matching architecture (`tests/run.ps1` under this game folder) before
game checks. Driver compilation needs no separately shipped runtime compiler
for GLSL/ARB; rebuilding C++ still needs the normal toolchain. Existing NVIDIA
test results are not proof for all GPUs or games.
