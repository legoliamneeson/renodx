---
name: renodx-opengl-devkit
description: "Develop RenoOGL live GLSL and OpenGL SPIR-V replacements with the patched ReShade backend, Original/Add-on/File selection, std140 injection and state preservation; not the generic ARB profile path."
---

# Use the patched RenoOGL DevKit

This workflow requires the RenoOGL source integration. Check for
`README_OPENGL.md` and `src/addons/devkit_opengl` in the current root before
proceeding. Read that README and the addon README for exact build commands.
An ordinary RenoDX tree may lack this implementation; do not assume identical
behavior just because its generic OpenGL addon is present.

Build the matching architecture's `devkit_opengl` addon and the patched
ReShade DLL separately. The backend supplies the private
`ReShadeCreateOpenGLPipelineReplacement` export; addon CMake targets do not
build that DLL. Preserve local/pinned submodule changes and use the addon-enabled
configuration. Install the correct DLL as executable-local `opengl32.dll`;
that filename is used for either architecture. Use this DevKit instead of
the normal DevKit. Rebuild cooperating addons after shared allocator changes.

## Capture and select

Choose the OpenGL renderer and capture the relevant monolithic program.
Start with an unchanged replacement and toggle Original/Add-on/File. Keep
one live file per hash and verify selection changes at draws even without
another `glUseProgram`. Add-on selection requires registered code; File
selection alone does not allocate a game's settings buffer.

| Delivery | Typical fragment filename | Contract |
| --- | --- | --- |
| Driver GLSL | `0xHASH.frag.glsl` | Driver source compilation; no automatic include preprocessing |
| OpenGL SPIR-V | `0xHASH.frag.gl.spv` | Binary specialization with original metadata |
| Offline GLSL to OpenGL SPIR-V | `0xHASH.frag.gl.glsl` | OpenGL target semantics |

These are not the generic profile addon's `.ps.glsl` capture names. Inspect
the actual format, not only the extension. Use OpenGL glslang semantics
(`-G`), not Vulkan (`-V`). A program cannot mix GLSL and SPIR-V stages in this
path. Preserve entry point, specialization IDs/values, stage interfaces,
attribute and fragment-output locations. Opaque `glProgramBinary` caches
are not SPIR-V source captures. Byte-hash replacement can affect multiple
specializations even though their metadata is retained per program.

## Layout and state

Read the actual examples in `src/addons/devkit_opengl/examples/` for the
matching scalar C++ and std140 layout. Match every offset, total size and
binding; `alignas(16)` alone does not fix array/matrix/vec3 member offsets.
Register the affected shader and injection data in the game addon. The
shared implementation requires zero injection offset and pads trailing bytes.

The backend copies supported uniform and UBO/SSBO binding state to its
replacement before a draw/dispatch, then restores the original. Game uniform
updates must keep targeting the original program. Check sampler/image units,
arrays/matrices, integer types, relink invalidation, deletion and restoration.
Per-draw CPU uniform copies can cost performance; measure before optimizing.

## Respect supported scope

The documented replacement path requires OpenGL 4.3+, with 4.6 or
ARB_gl_spirv for SPIR-V. Separable pipelines, transform feedback, subroutine
uniforms, incompatible interfaces and ambiguous unnamed blocks are rejected.
ARB assembly and fixed-function work use a separate adapter; this path does
not translate them to GLSL. Consult the current README for remaining limits.

Use `test/opengl_shader_format`, `test/opengl_program_state` and
`test/process_heap_alignment` where their platform prerequisites are met.
Historical Linux/Mesa tests do not prove Windows x86 execution, native
SPIR-V capture or game HDR output. Verify those separately, and hand off
presentation work to [OpenGL HDR output](../renodx-opengl-hdr-output/SKILL.md).
