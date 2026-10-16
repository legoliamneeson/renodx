[![Clang](https://github.com/clshortfuse/renodx/actions/workflows/clang-x64.yml/badge.svg)](https://github.com/clshortfuse/renodx/actions/workflows/clang-x64.yml) [![Ninja](https://github.com/clshortfuse/renodx/actions/workflows/ninja-x64.yml/badge.svg)](https://github.com/clshortfuse/renodx/actions/workflows/ninja-x64.yml) [![Visual Studio](https://github.com/clshortfuse/renodx/actions/workflows/visual-studio-x64.yml/badge.svg)](https://github.com/clshortfuse/renodx/actions/workflows/visual-studio-x64.yml) 

[![Discord](https://img.shields.io/discord/1408098019194310818?logo=discord&logoColor=%23fff&label=Discord&labelColor=%235865F2)](https://discord.gg/F6AUTeWJHM)

# renodx
RenoDX, short for "Renovation Engine for DirectX Games", is a toolset to mod games. Currently it can replace shaders, inject buffers, add overlays, upgrade swapchains, upgrade texture resources, and write user settings to disk. Because RenoDX uses Reshade's add-on system, compatibility is expected to be pretty wide. Using Reshade simplifies all the hooks necessary to tap into DirectX without worrying about patching version-specific exe files.


# Contributing

* See [CONTRIBUTING.md](./docs/CONTRIBUTING.md)
* For the live devkit and MCP workflow, see [DEVKIT_MCP.md](./docs/DEVKIT_MCP.md)

# Mods

* See [Mods page](https://github.com/clshortfuse/renodx/wiki/Mods)

# RenoOGL (OpenGL)

This `renoogl` branch adds OpenGL support: an OpenGL DevKit (`devkit_opengl`), the Doom 3 addon (`doom3`), a Generic OpenGL addon (`generic_opengl`) and a patched ReShade build (`reshade_opengl` → `opengl32.dll`). Everything builds with the normal presets, for example:

```powershell
git clone --recurse-submodules -b renoogl https://github.com/legoliamneeson/renodx.git renodx-ogl
cd renodx-ogl
cmake --preset clang-x86
cmake --build --preset clang-x86-release --target reshade_opengl
cmake --build --preset clang-x86-release --target doom3
```

See [README_OPENGL.md](./README_OPENGL.md) for the required tools, one-time setup, installing into a game and troubleshooting.

# Utilities

* [renodx-fpslimiter.addon64](https://clshortfuse.github.io/renodx/renodx-fpslimiter.addon64) &ndash; FPS Limiter
* [renodx-devkit.addon64](https://clshortfuse.github.io/renodx/renodx-devkit.addon64) &ndash; Developer kit to help build addons
* [decomp.exe](https://clshortfuse.github.io/renodx/decomp.exe) &ndash; Shader Model 6.0+ Decompiler

