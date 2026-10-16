# RenoOGL: OpenGL RenoDX and DevKit

**Experimental.** This branch adds an OpenGL DevKit target, a Generic OpenGL
addon, an OpenGL backend patch for ReShade, and the x86 process-heap alignment
fix. It is set up exactly like RenoDX: dependencies are git submodules, addons
build with the normal CMake presets, and the only extra step is applying
`patches/reshade-opengl.patch` before building the ReShade DLL itself.

## Get the source

```powershell
git clone --recurse-submodules -b renoogl https://github.com/legoliamneeson/renodx.git
cd renodx
```

In an existing clone: `git fetch origin`, `git switch renoogl`, then
`git submodule update --init --recursive`.

`external/reshade` is the stock ReShade submodule pinned by RenoDX
(`4a50d1eddace85734871d91792ff214f13f66c01`, tag `v6.7.3`). The patch is applied
on top of it at build time, so `git status` will show `external/reshade` as
modified after a build. That is expected; do not commit the submodule.

## What changed

- An OpenGL-only `devkit_opengl` target, with x86 and x64 metadata. It shares the
  normal DevKit implementation and filters out non-OpenGL devices.
- Inspect GLSL text, SPIR-V disassembly, registered Add-on code, and file code.
  Linked vertex/fragment/compute shader bytes are retained before draw capture.
- Original / Add-on / File selection. Automatic reload keeps the selected
  source; explicit Load Shaders selects file replacements. Shader compilation
  or linking failures leave the original program available.
- Native `glShaderBinary`, `glSpecializeShader`, and `glSpecializeShaderARB`
  capture. Entry point and specialization IDs/values are retained and copied
  into the cached pipeline descriptors. Relinking invalidates the old program
  record before publishing the new one.
- A private ReShade export builds replacement programs with original attribute
  and fragment-output bindings. Before a draw/dispatch, the backend copies
  supported loose uniforms and UBO/SSBO block bindings, binds the replacement,
  then restores the original. Game `glUniform` calls keep targeting the original.
  Selection/file changes are refreshed at draws, even without another
  `glUseProgram` call.
- Correct OpenGL UBO injection binding, zero-offset enforcement, and zero-filled
  trailing padding to a 16-byte boundary. This does not fix mismatched field
  offsets inside a C++/GLSL layout.
- Binary-safe dumping and reload detection for `.glsl` and `.spv`; OpenGL
  decompilation semantics; owned Add-on bytes; specialization-array lifetime
  and descriptor-array allocation/free fixes.
- The recovered x86 fix uses matched aligned process-heap allocation/free for
  shared objects and containers, with allocation-size overflow checks.

The backend changes live in `patches/reshade-opengl.patch` and target ReShade
`4a50d1eddace85734871d91792ff214f13f66c01`.

## Build on Windows with RenoDX CMake presets

Install the tools listed in [docs/CONTRIBUTING.md](./docs/CONTRIBUTING.md):
Visual Studio 2022 Build Tools (or Visual Studio) with the C++ workload and v143
toolset, Windows SDK **10.0.26100.0**+, plus standalone **CMake**, **LLVM**
(clang-cl) and **Ninja** on your PATH, and Git and Python 3. With those on PATH a
normal PowerShell window works; you do not need a Visual Studio developer shell.

Ninja is the one most often missing, because Visual Studio only puts its own copy
on PATH inside its developer shells. Install it once and open a new window:

```powershell
winget install Ninja-build.Ninja
where.exe ninja; where.exe clang-cl   # both must print a path
```

If configure fails with `unable to find a build program corresponding to "Ninja
Multi-Config"`, Ninja is not on PATH: fix that, delete `build32` (or `build`),
then run the configure command again.

Everything, the addons and the patched ReShade `opengl32.dll`, builds with
RenoDX's normal presets:

| | 32-bit (x86) | 64-bit (x64) |
| --- | --- | --- |
| Configure | `cmake --preset clang-x86` | `cmake --preset clang-x64` |
| Build | `cmake --build --preset clang-x86-release --target <target>` | `cmake --build --preset clang-x64-release --target <target>` |
| Output folder | `build32\Release\` | `build\Release\` |

Configure once per architecture, and again after adding a new addon folder.
`<target>` is an addon folder name under `src\games\` or `src\addons\`, or
`reshade_opengl` for the patched ReShade DLL.

### One-time dependency setup

```powershell
git submodule update --init --recursive
python -m pip install -r .\external\reshade\deps\glad\requirements.txt
.\scripts\setup-dev-env.ps1 -Install -Tools @('dxc', 'slang', 'glslang')
```

Do not add `--force` or `--remote` to the submodule command: `--force` discards
an applied ReShade patch and `--remote` moves off RenoDX's pinned revisions.
Pass Tools as a PowerShell array as shown.

### Addons

```powershell
cmake --preset clang-x86
cmake --build --preset clang-x86-release --target doom3          # build32\Release\renodx-doom3.addon32
cmake --build --preset clang-x86-release --target devkit_opengl  # build32\Release\renodx-devkit_opengl.addon32
```

Use `clang-x64` / `clang-x64-release` for 64-bit games; outputs end in
`.addon64` under `build\Release\`. Rebuild every RenoDX addon you load together
so they share the same allocator and injection code.

### Patched ReShade: 32-bit and 64-bit `opengl32.dll`

The OpenGL replacement path needs ReShade built with
`patches/reshade-opengl.patch`; stock ReShade lacks the replacement export.
The `reshade_opengl` target does the whole job:

```powershell
# 32-bit
cmake --preset clang-x86
cmake --build --preset clang-x86-release --target reshade_opengl  # build32\Release\opengl32.dll

# 64-bit
cmake --preset clang-x64
cmake --build --preset clang-x64-release --target reshade_opengl  # build\Release\opengl32.dll
```

The target fetches ReShade's git tags if they are missing (ReShade reads its
version from them), applies the patch to `external/reshade` once (later builds
detect it as applied), builds ReShade's own solution with MSBuild in Release using
an installed Visual Studio that has a v14x toolset (v143 preferred), checks
the DLL contains the RenoOGL export, and copies `ReShade32.dll` / `ReShade64.dll`
to `opengl32.dll` next to your addons. It is not part of a plain
`cmake --build --preset ...`, so CI and full builds are unchanged.

After this, `git status` shows `external/reshade` as modified. That is the
applied patch; do not commit the submodule. To return it to stock:
`git -C external/reshade checkout -- .` and
`git -C external/reshade clean -fd -- source/opengl`.

`scripts\build-opengl.ps1 -Architecture x86|x64 [-GameTarget <target>]` runs the
same steps and also copies everything into `dist\opengl\<arch>`.

## Install and inspect

1. Back up the game's existing local ReShade DLL/addons. Match the game
   executable's architecture (Doom 3 is 32-bit): copy `opengl32.dll` and the
   addons you need (`renodx-devkit_opengl.addon32`, `renodx-doom3.addon32`, ...)
   from `build32\Release\` (or `build\Release\` for 64-bit) into the folder
   that contains the game's `.exe`. Do not copy them into a Windows system folder.
2. Use this DevKit **instead of** the normal DevKit. Use the patched ReShade
   built from this tree; stock ReShade lacks the replacement export. You can
   also load a rebuilt game-specific RenoDX addon to supply its settings buffer.
3. Launch the game and open the ReShade overlay. In RenoDX DevKit, capture a
   snapshot and select a shader. Inspect original GLSL/SPIR-V, Add-on code,
   or the Live Shader view. Linked/pending/unavailable counts report build
   state, not proof of correct rendering.
4. Dump a shader, put a copy in the configured live-shader folder, and keep its
   original hash in the filename. Start by loading an unchanged shader.
5. Click **Load Shaders**, then switch **Original**, **Add-on**, or **File** in
   the Source column. Add-on requires a registered replacement. Enable Live
   Shaders for reload while editing. Keep only one file per hash in that folder.
6. Make a small visible change and switch back to Original. Check textures,
   animation, UI, resize/alt-tab and `ReShade.log`. Test with your target GPU.

## GLSL source and SPIR-V

| Input | Example filename | Behavior |
| --- | --- | --- |
| Driver GLSL source | `0xHASH.frag.glsl` | Driver compiles text. `#include "name.glsl"` is expanded at configure time, looking in the file's folder and then `src/shaders/glsl/`. Output is still plain GLSL, not SPIR-V |
| OpenGL-targeted SPIR-V | `0xHASH.frag.gl.spv` | Driver specializes the binary |
| Offline GLSL to OpenGL SPIR-V | `0xHASH.frag.gl.glsl` | Existing glslang workflow uses OpenGL semantics |

Use `.vert` / `.comp` for vertex / compute stages. Replace `HASH` with the
DevKit hash. Binary SPIR-V starts with the magic word `0x07230203`; the file
extension alone does not establish its format or target environment. For
OpenGL use glslang `-G`, **not** Vulkan `-V`. Supply `glslangValidator.exe`
(or `glslang.exe`), `spirv-dis.exe`, and `spirv-cross.exe` through Tools Path
for their respective compilation/disassembly/decompilation features.

GLSL source and SPIR-V are two shader delivery formats. `glProgramBinary`
is a third, opaque driver program-cache path; it is not a SPIR-V shader file.
SPIR-V source capture needs the game to call the hooked binary/specialization
functions after the patched backend is loaded. Opaque cached programs cannot
be reconstructed into original shader modules by this patch.

A linked program cannot mix GLSL and SPIR-V stages. Keep replacement format,
entry point, specialization IDs, and stage interfaces compatible with the
original program. There is no automatic whole-program conversion. Same module
bytes used with different entry points/specializations share a byte hash, so
file replacement by hash affects all such uses; their metadata stays per-program.

## Settings injection

See `src/addons/devkit_opengl/examples/injection_layout.hpp` and
`injection_layout.glsl.txt` for matching scalar layouts. OpenGL uses a GLSL
`layout(std140, binding = N) uniform` block in place of an HLSL cbuffer. Pick
an unused binding within the driver's limits and configure the game addon to
inject into that same slot. Match field order and every std140 offset; C++
`alignas(16)` alone does not align vec3/array/matrix members correctly.
The game addon must register the injection data and the affected shader.
Choosing File in DevKit does not create a settings buffer by itself.

## Supported scope and known limits

- Replacement state preservation requires an **OpenGL 4.3+** context. SPIR-V
  additionally needs OpenGL 4.6 or `GL_ARB_gl_spirv`. Older source shaders may be
  inspectable, but this backend declines the new replacement path there.
- Intended path: monolithic linked vertex/fragment/compute programs using
  ordinary numeric uniforms, texture/image unit uniforms, UBOs and SSBOs.
  CPU readback/copy of uniforms on each draw can cost performance.
- Separable pipelines, transform-feedback programs, subroutine uniforms,
  incompatible uniform types, ambiguous unnamed block matches, and multiple
  attached shader objects in one stage are rejected for replacement.
- Bindless handles, unusual compatibility built-ins, concurrent mutation of
  shared programs across contexts, geometry/tessellation inspection, and
  specialized draw extension paths are not validated/supported by this DevKit.
  The main OpenGL draw/dispatch hooks are covered, not every vendor extension.
- Legacy `!!ARBfp` / `!!ARBvp` assembly can be identified/inspected where exposed,
  but is not replaceable through the GLSL pipeline path. Doom 3 direct-ARB hooks
  remain a separate implementation. Fixed-function draws have no GLSL shader.
- This is shader development/injection infrastructure. It does not automatically
  remove game clamps, port DirectX bytecode replacements, add Psycho settings,
  upgrade framebuffer formats, or establish a correct HDR output path for every
  OpenGL game. Those require game-specific shader and output work.

## Validation in this environment

Passed on Linux with GCC 13 and Mesa 25.2.8, OpenGL 4.5 core:

- Byte-format tests: GLSL termination, empty inputs, SPIR-V header/alignment,
  and ARB identification.
- Real GL programs: attribute bindings, float/vector/array/matrix/integer/uint
  and sampler state, UBO/SSBO block bindings, updated values on later draws,
  invalidated replacement lifetime, and incompatible uniform rejection.
- Pixel readback: original red -> replacement half-red -> original red, without
  an intervening application program bind.
- Actual allocator function bodies with a mock heap, simulating native
  8-byte/x86 and 16-byte/x64 alignment: over-alignment, zeroing, overflow,
  shared-object construction, and matched frees.

Not run: Windows x86/x64 addon or ReShade compilation, native SPIR-V capture
on a Windows driver, actual x86 execution, game integration, or HDR validation.
The PowerShell build script is supplied but was not executable here.

Portable test commands from the repository root:

```bash
g++ -std=c++20 test/opengl_shader_format/tests.cpp -o /tmp/format-test
/tmp/format-test
python3 test/process_heap_alignment/run.py
python3 -m pip install -r external/reshade/deps/glad/requirements.txt
PYTHONPATH=external/reshade/deps/glad python3 -m glad --api gl:compatibility=4.6 --out-path /tmp/renoogl-glad --reproducible c --mx
g++ -std=c++20 -I/tmp/renoogl-glad/include test/opengl_program_state/tests.cpp /tmp/renoogl-glad/src/gl.c /lib/x86_64-linux-gnu/libEGL.so.1 -ldl -o /tmp/state-test
/tmp/state-test
```

The GL integration test requires Mesa's surfaceless EGL platform on Linux.

Reference: Khronos [ARB_gl_spirv specification](https://github.com/KhronosGroup/OpenGL-Registry/blob/main/extensions/ARB/ARB_gl_spirv.txt), including binary specialization and unnamed-resource reflection.
