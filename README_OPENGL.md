# RenoOGL: OpenGL RenoDX and DevKit

**Experimental.** The `renoogl` branch adds OpenGL support to RenoDX:

- `devkit_opengl`: an OpenGL-only DevKit for inspecting and live-replacing GLSL/SPIR-V shaders.
- `doom3`: the Doom 3 addon (32-bit).
- `generic_opengl`: a profile-driven generic OpenGL addon.
- `reshade_opengl`: builds ReShade with `patches/reshade-opengl.patch` as `opengl32.dll`. Stock ReShade
  cannot run OpenGL shader replacements; this patched build is required.

It is set up exactly like RenoDX: dependencies are git submodules and everything builds with the normal
CMake presets.

## Quick start (32-bit, e.g. Doom 3)

After installing the tools in step 1, in a normal PowerShell window:

```powershell
git clone --recurse-submodules -b renoogl https://github.com/legoliamneeson/renodx.git renodx-ogl
cd renodx-ogl
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
python -m pip install -r .\external\reshade\deps\glad\requirements.txt
.\scripts\setup-dev-env.ps1 -Install -Tools @('dxc', 'slang', 'glslang')
cmake --preset clang-x86
cmake --build --preset clang-x86-release --target reshade_opengl
cmake --build --preset clang-x86-release --target devkit_opengl
cmake --build --preset clang-x86-release --target doom3
```

Results land in `build32\Release\`: `opengl32.dll`, `renodx-devkit_opengl.addon32`, `renodx-doom3.addon32`.
If anything fails, see [Troubleshooting](#troubleshooting).

## 1. Install the tools

Install these once (the same list as [docs/CONTRIBUTING.md](./docs/CONTRIBUTING.md)):

| Tool | Why | Install | Check (new PowerShell window) |
| --- | --- | --- | --- |
| Visual Studio 2022 Build Tools (or Visual Studio 2022) | MSVC headers/libs, MSBuild and the **v143** toolset that ReShade builds with | [vs_BuildTools.exe](https://aka.ms/vs/17/release/vs_BuildTools.exe), workload **Desktop development with C++** | `& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -products * -property displayName` |
| Windows SDK 10.0.26100.0+ | Windows headers, `fxc.exe` | Included in the VS workload, or `winget install --id Microsoft.WindowsSDK -e` | |
| LLVM | `clang-cl`, the addon compiler | [LLVM releases](https://github.com/llvm/llvm-project/releases/) (tick *Add LLVM to the system PATH*) | `where.exe clang-cl` |
| CMake 3.27+ | Build system | [cmake.org](https://cmake.org/download/) | `cmake --version` |
| Ninja | Build tool used by the presets | `winget install Ninja-build.Ninja` | `where.exe ninja` |
| Git | Source and submodules | [git-scm.com](https://git-scm.com/) | `git --version` |
| Python 3 | ReShade generates its OpenGL loader (glad) with Python | [python.org](https://www.python.org/) (tick *Add to PATH*) | `python --version` |

Every **Check** command must print something. CMake, LLVM, Ninja, Git and Python have to be on your PATH;
you do **not** need a Visual Studio developer shell. Visual Studio's own Ninja is only on PATH inside its
developer shells, so install Ninja separately as shown. If `winget` reports Ninja is already installed but
`where.exe ninja` finds nothing, see [Troubleshooting](#ninja-is-installed-but-not-found).

Having Visual Studio 2026 installed as well is fine: the ReShade build picks the installation that has the
v143 toolset.

## 2. Get the source

```powershell
git clone --recurse-submodules -b renoogl https://github.com/legoliamneeson/renodx.git renodx-ogl
cd renodx-ogl
```

Already cloned without submodules, or switching an existing RenoDX clone to this branch:

```powershell
git fetch origin
git switch renoogl
git submodule update --init --recursive
```

Do not add `--force` or `--remote` to the submodule command: `--force` throws away the applied ReShade
patch and `--remote` moves dependencies off RenoDX's pinned revisions.

## 3. One-time setup

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
python -m pip install -r .\external\reshade\deps\glad\requirements.txt
.\scripts\setup-dev-env.ps1 -Install -Tools @('dxc', 'slang', 'glslang')
```

`Set-ExecutionPolicy -Scope Process` allows local scripts for this window only. The setup script downloads
`dxc`, `slangc` and `glslang` into `.\bin` and copies `fxc.exe` there; CMake finds them automatically.

## 4. Configure and build

Configure once per architecture (and again after adding a new addon folder), then build any target:

| | 32-bit (x86) | 64-bit (x64) |
| --- | --- | --- |
| Configure | `cmake --preset clang-x86` | `cmake --preset clang-x64` |
| Build | `cmake --build --preset clang-x86-release --target <target>` | `cmake --build --preset clang-x64-release --target <target>` |
| Output folder | `build32\Release\` | `build\Release\` |
| Addon extension | `.addon32` | `.addon64` |

Use the architecture of the **game's executable** (Doom 3 is 32-bit). `<target>` is:

| Target | Output | Notes |
| --- | --- | --- |
| `reshade_opengl` | `opengl32.dll` | Patched ReShade, see below |
| `devkit_opengl` | `renodx-devkit_opengl.addon32/64` | OpenGL DevKit |
| `doom3` | `renodx-doom3.addon32` | Any folder name under `src\games\` works the same way |
| `generic_opengl` | `renodx-generic_opengl.addon32/64` | Generic OpenGL profile addon |

Without `--target`, `cmake --build --preset ...` builds every RenoDX addon (slow) but not `reshade_opengl`.

### How the patched ReShade is built

ReShade is not a CMake project; it is built with MSBuild from its own Visual Studio solution,
`external\reshade\ReShade.sln`. The `reshade_opengl` target is a shortcut that:

1. fetches ReShade's git tags if missing (ReShade takes its version number from them),
2. applies `patches/reshade-opengl.patch` to `external\reshade` once (later builds see it is applied and skip it),
3. finds a Visual Studio installation with the v143 toolset and runs MSBuild on `ReShade.sln`
   (Release, solution platform `32-bit` or `64-bit`), logging to `<output folder>\reshade-opengl-build.log`,
4. checks the DLL contains the RenoOGL export and copies `ReShade32.dll` / `ReShade64.dll` to `opengl32.dll`.

The equivalent manual command, from an x86 or x64 **Developer PowerShell for VS 2022** after the patch is applied:

```powershell
msbuild external\reshade\ReShade.sln /t:ReShade /p:Configuration=Release "/p:Platform=32-bit" /p:PlatformToolset=v143
```

(`"/p:Platform=64-bit"` for 64-bit; output in `external\reshade\bin\Win32\Release\` or `bin\x64\Release\`.)

After a ReShade build, `git status` shows `external/reshade` as modified. That is the applied patch; do not
commit it. To return the submodule to stock: `git -C external/reshade checkout -- .` and
`git -C external/reshade clean -fd -- source/opengl`.

`scripts\build-opengl.ps1 -Architecture x86 -GameTarget doom3` runs steps 3 and 4 in one go and copies the
results into `dist\opengl\x86`.

## 5. Install into a game

Copy from the output folder into the folder that contains the game's `.exe`:

- `opengl32.dll` (the patched ReShade; back up any existing `opengl32.dll` first),
- the game addon, e.g. `renodx-doom3.addon32`,
- `renodx-devkit_opengl.addon32` only while developing (use it instead of the normal DevKit).

Never copy these into a Windows system folder. Rebuild and recopy all RenoDX addons you load together, so they
share the same allocator and injection code.

## Updating

```powershell
git pull
git submodule update --init --recursive
cmake --build --preset clang-x86-release --target doom3
```

If a pull changes `patches/reshade-opengl.patch`, reset the submodule (commands in step 4) and build
`reshade_opengl` again.

## Troubleshooting

**`... cannot be loaded because running scripts is disabled on this system`**
Run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` in that window, then the script again.
(`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` makes it permanent.)

**`CMake was unable to find a build program corresponding to "Ninja Multi-Config"`**
Ninja is not on PATH. Install it (`winget install Ninja-build.Ninja`), open a **new** PowerShell window, check
`where.exe ninja`, delete the failed build folder (`Remove-Item -Recurse -Force build32`, or `build`), and run
`cmake --preset ...` again. The build commands after a failed configure all fail with
`build tool execution failed`; fix the configure first.

<a id="ninja-is-installed-but-not-found"></a>
**`winget` says Ninja is installed but `where.exe ninja` finds nothing**
winget's link folder is not on your PATH. Add the folder that contains `ninja.exe` permanently:

```powershell
$ninja = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet" -Recurse -Filter ninja.exe -ErrorAction SilentlyContinue | Select-Object -First 1
[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path','User') + ";$($ninja.DirectoryName)", 'User')
$env:Path += ";$($ninja.DirectoryName)"
where.exe ninja
```

**`msbuild : The term 'msbuild' is not recognized`**
MSBuild is only on PATH inside a Visual Studio developer shell. Use the `reshade_opengl` target, which finds
MSBuild itself, or open **Developer PowerShell for VS 2022** for manual MSBuild commands.

**`error MSB4126: The specified solution configuration "Release|Win32" is invalid`**
ReShade's solution platforms are `32-bit` and `64-bit`, not `Win32`/`x64`. Pull the latest `renoogl`; the
`reshade_opengl` target uses the right names. For manual builds use `"/p:Platform=32-bit"`.

**`ReShade build failed`**
Read `build32\Release\reshade-opengl-build.log` (or `build\Release\...`); the error lines are also printed.
Common causes: Python or the glad requirements missing (step 3), or no Visual Studio with the v143 toolset
(add **MSVC v143 - VS 2022 C++ x64/x86 build tools** in the Visual Studio Installer).

**`patches/reshade-opengl.patch does not apply to external/reshade`**
The submodule has other local changes or a different revision. Reset it (step 4), run
`git submodule update --init --recursive`, and build again.

**`external/reshade is at <hash>; ... targets 4a50d1e`**
Run `git submodule update --init --recursive` (without `--remote`).

**Lots of `warning:` lines (deprecated, unwind semantics, X3571)**
Warnings from RenoDX and stock ReShade; they do not stop the build. Only lines with `error` matter.

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

## Using the OpenGL DevKit

1. Install `opengl32.dll` and `renodx-devkit_opengl.addon32`/`.addon64` as in
   [step 5](#5-install-into-a-game).
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

## Validation

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

Built on Windows (VS 2022 Build Tools v143, LLVM clang-cl, Ninja): the 32-bit
`opengl32.dll`, `renodx-devkit_opengl.addon32` and `renodx-doom3.addon32`.
Not yet run on this branch: the 64-bit builds, native SPIR-V capture on a
Windows driver, game integration and HDR validation.

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
