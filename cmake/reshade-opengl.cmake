# Builds the RenoOGL-patched ReShade DLL and stages it as opengl32.dll.
#
# Invoked by the reshade_opengl target (cmake --build --preset clang-x86-release
# --target reshade_opengl); not meant to be included. Steps:
#   1. Fetch ReShade's git tags if missing (its version comes from git describe).
#   2. Apply patches/reshade-opengl.patch to external/reshade once. A patch that
#      is already applied is detected and skipped.
#   3. Build ReShade's own Visual Studio solution with MSBuild (Release).
#   4. Copy ReShade32.dll / ReShade64.dll to <OUTPUT_DIR>/opengl32.dll.
#
# Required -D variables: SOURCE_DIR, OUTPUT_DIR, PLATFORM (Win32|x64), BITS (32|64),
# VCVARS_BAT, VCVARS_ARG, GIT_EXECUTABLE.

foreach(VAR SOURCE_DIR OUTPUT_DIR PLATFORM BITS GIT_EXECUTABLE)
  if(NOT DEFINED ${VAR} OR "${${VAR}}" STREQUAL "")
    message(FATAL_ERROR "reshade-opengl.cmake: ${VAR} is not set")
  endif()
endforeach()

set(RESHADE_DIR "${SOURCE_DIR}/external/reshade")
set(PATCH_FILE "${SOURCE_DIR}/patches/reshade-opengl.patch")

if(NOT EXISTS "${RESHADE_DIR}/ReShade.sln")
  message(FATAL_ERROR "external/reshade is empty. Run: git submodule update --init --recursive")
endif()

execute_process(
  COMMAND "${GIT_EXECUTABLE}" -C "${RESHADE_DIR}" rev-parse HEAD
  OUTPUT_VARIABLE RESHADE_REVISION OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT RESHADE_REVISION STREQUAL "4a50d1eddace85734871d91792ff214f13f66c01")
  message(FATAL_ERROR "external/reshade is at ${RESHADE_REVISION}; patches/reshade-opengl.patch targets 4a50d1e. Run: git submodule update --init --recursive")
endif()

execute_process(
  COMMAND "${GIT_EXECUTABLE}" -C "${RESHADE_DIR}" describe --tags
  RESULT_VARIABLE DESCRIBE_RESULT OUTPUT_QUIET ERROR_QUIET)
if(NOT DESCRIBE_RESULT EQUAL 0)
  message(STATUS "Fetching ReShade tags for its version number")
  execute_process(COMMAND "${GIT_EXECUTABLE}" -C "${RESHADE_DIR}" fetch --tags origin COMMAND_ERROR_IS_FATAL ANY)
endif()

# --ignore-whitespace lets the LF patch match a CRLF checkout (core.autocrlf=true).
execute_process(
  COMMAND "${GIT_EXECUTABLE}" -C "${RESHADE_DIR}" apply --ignore-whitespace --reverse --check "${PATCH_FILE}"
  RESULT_VARIABLE ALREADY_APPLIED OUTPUT_QUIET ERROR_QUIET)
if(NOT ALREADY_APPLIED EQUAL 0)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" -C "${RESHADE_DIR}" apply --ignore-whitespace --whitespace=nowarn "${PATCH_FILE}"
    RESULT_VARIABLE APPLY_RESULT)
  if(NOT APPLY_RESULT EQUAL 0)
    message(FATAL_ERROR "patches/reshade-opengl.patch does not apply to external/reshade. "
                        "Reset it with: git -C external/reshade checkout -- . ; git -C external/reshade clean -fd -- source/opengl")
  endif()
  message(STATUS "Applied patches/reshade-opengl.patch to external/reshade")
endif()

# ReShade.vcxproj defaults to the v141 toolset; build with VS 2022's v143.
set(MSBUILD_ARGS "\"${RESHADE_DIR}/ReShade.sln\" /t:ReShade /m /nologo /v:minimal /p:Configuration=Release /p:Platform=${PLATFORM} /p:PlatformToolset=v143")
set(BUILD_SCRIPT "${OUTPUT_DIR}/reshade-opengl-build.cmd")
file(MAKE_DIRECTORY "${OUTPUT_DIR}")
if(EXISTS "${VCVARS_BAT}")
  file(WRITE "${BUILD_SCRIPT}" "@echo off\r\ncall \"${VCVARS_BAT}\" ${VCVARS_ARG} >nul || exit /b 1\r\nmsbuild ${MSBUILD_ARGS}\r\n")
else()
  # No vcvarsall found: rely on msbuild already being on PATH (VS developer shell).
  file(WRITE "${BUILD_SCRIPT}" "@echo off\r\nmsbuild ${MSBUILD_ARGS}\r\n")
endif()
execute_process(COMMAND cmd.exe /D /C "${BUILD_SCRIPT}" RESULT_VARIABLE BUILD_RESULT)
if(NOT BUILD_RESULT EQUAL 0)
  message(FATAL_ERROR "ReShade build failed. One-time setup: python -m pip install -r external/reshade/deps/glad/requirements.txt")
endif()

set(RESHADE_DLL "${RESHADE_DIR}/bin/${PLATFORM}/Release/ReShade${BITS}.dll")
if(NOT EXISTS "${RESHADE_DLL}")
  message(FATAL_ERROR "ReShade build finished but ${RESHADE_DLL} is missing")
endif()
file(READ "${RESHADE_DLL}" DLL_HEX HEX)
string(HEX "ReShadeCreateOpenGLPipelineReplacement" EXPORT_HEX)
string(FIND "${DLL_HEX}" "${EXPORT_HEX}" EXPORT_FOUND)
if(EXPORT_FOUND EQUAL -1)
  message(FATAL_ERROR "${RESHADE_DLL} is missing the RenoOGL export; the patch was not compiled in")
endif()

file(COPY_FILE "${RESHADE_DLL}" "${OUTPUT_DIR}/opengl32.dll" ONLY_IF_DIFFERENT)
message(STATUS "Patched ReShade: ${OUTPUT_DIR}/opengl32.dll")
