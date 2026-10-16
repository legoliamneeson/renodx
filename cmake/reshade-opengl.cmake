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
# VCVARS_BAT (fallback), VCVARS_ARG, GIT_EXECUTABLE. Optional: VSWHERE_EXECUTABLE.

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

# ReShade.vcxproj defaults to the v141 toolset, which current Visual Studio does not
# ship. Pick an installed Visual Studio (2022 Build Tools, 2026 Community, ...) that
# has a v14x toolset for this platform, preferring v143, and use its vcvarsall.
set(SELECTED_VS "")
set(SELECTED_TOOLSET "")
if(VSWHERE_EXECUTABLE AND EXISTS "${VSWHERE_EXECUTABLE}")
  execute_process(
    COMMAND "${VSWHERE_EXECUTABLE}" -all -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    OUTPUT_VARIABLE VS_PATHS OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
  string(REPLACE "\r" "" VS_PATHS "${VS_PATHS}")
  string(REPLACE "\n" ";" VS_PATHS "${VS_PATHS}")
  foreach(VS_PATH IN LISTS VS_PATHS)
    file(TO_CMAKE_PATH "${VS_PATH}" VS_PATH)
    if(NOT EXISTS "${VS_PATH}/VC/Auxiliary/Build/vcvarsall.bat")
      continue()
    endif()
    file(GLOB TOOLSET_DIRS LIST_DIRECTORIES true "${VS_PATH}/MSBuild/Microsoft/VC/*/Platforms/${PLATFORM}/PlatformToolsets/v14*")
    foreach(TOOLSET_DIR IN LISTS TOOLSET_DIRS)
      get_filename_component(TOOLSET "${TOOLSET_DIR}" NAME)
      if(NOT TOOLSET MATCHES "^v14[0-9]$" OR NOT IS_DIRECTORY "${TOOLSET_DIR}")
        continue()
      endif()
      if(SELECTED_TOOLSET STREQUAL "v143")
        break()
      endif()
      if(TOOLSET STREQUAL "v143" OR SELECTED_TOOLSET STREQUAL "" OR TOOLSET STRGREATER SELECTED_TOOLSET)
        set(SELECTED_TOOLSET "${TOOLSET}")
        set(SELECTED_VS "${VS_PATH}")
      endif()
    endforeach()
  endforeach()
endif()
if(SELECTED_VS)
  set(VCVARS_BAT "${SELECTED_VS}/VC/Auxiliary/Build/vcvarsall.bat")
  message(STATUS "Building ReShade with ${SELECTED_TOOLSET} from ${SELECTED_VS}")
else()
  set(SELECTED_TOOLSET "v143")
  message(STATUS "No Visual Studio toolset detected through vswhere; trying v143")
endif()

set(BUILD_LOG "${OUTPUT_DIR}/reshade-opengl-build.log")
# ReShade.sln names its platforms "32-bit"/"64-bit"; they build the projects as Win32/x64.
set(MSBUILD_ARGS "\"${RESHADE_DIR}/ReShade.sln\" /t:ReShade /m /nologo /v:minimal /p:Configuration=Release \"/p:Platform=${BITS}-bit\" /p:PlatformToolset=${SELECTED_TOOLSET} \"/flp:logfile=${BUILD_LOG};verbosity=normal\"")
set(BUILD_SCRIPT "${OUTPUT_DIR}/reshade-opengl-build.cmd")
file(MAKE_DIRECTORY "${OUTPUT_DIR}")
file(REMOVE "${BUILD_LOG}")
# Plain \n: CMake on Windows writes text files with CRLF translation already.
set(SCRIPT_TEXT "@echo off\n")
if(EXISTS "${VCVARS_BAT}")
  string(APPEND SCRIPT_TEXT "call \"${VCVARS_BAT}\" ${VCVARS_ARG} >nul\n")
  string(APPEND SCRIPT_TEXT "if errorlevel 1 (echo vcvarsall.bat ${VCVARS_ARG} failed: \"${VCVARS_BAT}\" & exit /b 1)\n")
endif()
# Without vcvarsall, rely on msbuild already being on PATH (VS developer shell).
string(APPEND SCRIPT_TEXT "where msbuild >nul 2>nul || (echo msbuild was not found after vcvarsall & exit /b 1)\n")
string(APPEND SCRIPT_TEXT "msbuild ${MSBUILD_ARGS}\n")
file(WRITE "${BUILD_SCRIPT}" "${SCRIPT_TEXT}")
execute_process(COMMAND cmd.exe /D /C "${BUILD_SCRIPT}" RESULT_VARIABLE BUILD_RESULT)
if(NOT BUILD_RESULT EQUAL 0)
  set(ERROR_SUMMARY "")
  if(EXISTS "${BUILD_LOG}")
    file(STRINGS "${BUILD_LOG}" ERROR_LINES REGEX "error|Error|ERROR")
    list(REMOVE_DUPLICATES ERROR_LINES)
    list(LENGTH ERROR_LINES ERROR_COUNT)
    if(ERROR_COUNT GREATER 25)
      list(SUBLIST ERROR_LINES 0 25 ERROR_LINES)
    endif()
    list(JOIN ERROR_LINES "\n" ERROR_SUMMARY)
  endif()
  message(FATAL_ERROR "ReShade build failed (exit ${BUILD_RESULT}). Full log: ${BUILD_LOG}\n${ERROR_SUMMARY}\n"
                      "One-time setup if glad generation failed: python -m pip install -r external/reshade/deps/glad/requirements.txt")
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
