<# Build the patched full-addon ReShade plus the OpenGL DevKit.
Run in a VS 2022 developer PowerShell for the requested target architecture.
Outputs are staged locally; nothing is installed into a game automatically. #>
param(
  [ValidateSet('x64', 'x86')][string]$Architecture = 'x64',
  [string]$GameTarget = '',
  [switch]$SkipDependencies
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
function Invoke-Checked([string]$Executable, [string[]]$Arguments) {
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Executable failed with exit code $LASTEXITCODE" }
}
# Probe a git command without stopping the script on its stderr output.
function Test-Git([string[]]$Arguments) {
  $previous = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & git @Arguments 2>&1 | Out-Null
    return $LASTEXITCODE -eq 0
  } finally { $ErrorActionPreference = $previous }
}
Push-Location $root
try {
  foreach ($command in @('git', 'python', 'cmake', 'ninja', 'clang-cl', 'msbuild', 'dumpbin')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
      throw "$command is missing. Use a VS 2022 developer PowerShell with C++, LLVM, CMake/Ninja and Python installed."
    }
  }
  if ($env:VSCMD_ARG_TGT_ARCH -ne $Architecture) {
    throw "Open a VS developer PowerShell targeting $Architecture; current target is '$env:VSCMD_ARG_TGT_ARCH'."
  }
  if (-not $SkipDependencies) {
    # No --force / --remote: keep an already patched ReShade and pinned dependency revisions.
    Invoke-Checked git @('submodule', 'update', '--init', '--recursive')
    Invoke-Checked python @('-m', 'pip', 'install', '-r', 'external/reshade/deps/glad/requirements.txt')
    & .\scripts\setup-dev-env.ps1 -Install -Tools @('dxc', 'slang', 'glslang')
  }
  $backend = (git -C external/reshade rev-parse HEAD).Trim()
  if ($backend -ne '4a50d1eddace85734871d91792ff214f13f66c01') {
    throw "Unexpected ReShade revision $backend. Review the patch against this revision before building."
  }

  # ReShade derives its version from git tags; a tagless submodule would build as 0.0.0.
  if (-not (Test-Git @('-C', 'external/reshade', 'describe', '--tags'))) {
    Invoke-Checked git @('-C', 'external/reshade', 'fetch', '--tags', 'origin')
  }

  # Apply the OpenGL backend patch to the stock submodule once; re-runs detect it as applied.
  # --ignore-whitespace lets the LF patch match a CRLF checkout (core.autocrlf=true).
  $patch = Join-Path $root 'patches/reshade-opengl.patch'
  if (-not (Test-Git @('-C', 'external/reshade', 'apply', '--ignore-whitespace', '--reverse', '--check', $patch))) {
    if (-not (Test-Git @('-C', 'external/reshade', 'apply', '--ignore-whitespace', '--check', $patch))) {
      throw 'patches/reshade-opengl.patch does not apply to external/reshade. Reset the submodule with: git -C external/reshade checkout -- . ; git -C external/reshade clean -fd -- source/opengl'
    }
    Invoke-Checked git @('-C', 'external/reshade', 'apply', '--ignore-whitespace', '--whitespace=nowarn', $patch)
    Write-Host 'Applied patches/reshade-opengl.patch to external/reshade.'
  }
  $platform = if ($Architecture -eq 'x86') { 'Win32' } else { 'x64' }
  $bits = if ($Architecture -eq 'x86') { '32' } else { '64' }
  $buildDir = if ($Architecture -eq 'x86') { 'build32' } else { 'build' }
  Invoke-Checked msbuild @('external/reshade/ReShade.sln', '/t:ReShade', '/m', '/p:Configuration=Release', "/p:Platform=$platform", '/p:PlatformToolset=v143')
  Invoke-Checked cmake @('--preset', "clang-$Architecture")
  Invoke-Checked cmake @('--build', $buildDir, '--config', 'Release', '--target', 'devkit_opengl')
  if ($GameTarget) {
    Invoke-Checked cmake @('--build', $buildDir, '--config', 'Release', '--target', $GameTarget)
  }
  $dll = "external/reshade/bin/$platform/Release/ReShade$bits.dll"
  $exports = & dumpbin /exports $dll
  if ($LASTEXITCODE -ne 0 -or -not ($exports -match '\bReShadeCreateOpenGLPipelineReplacement\b')) {
    throw 'The ReShade DLL is missing the required OpenGL replacement export.'
  }
  $output = Join-Path $root "dist/opengl/$Architecture"
  New-Item -ItemType Directory -Path $output -Force | Out-Null
  Copy-Item $dll (Join-Path $output 'opengl32.dll') -Force
  Copy-Item "$buildDir/Release/renodx-devkit_opengl.addon$bits" $output -Force
  if ($GameTarget) { Copy-Item "$buildDir/Release/renodx-$GameTarget.addon$bits" $output -Force }
  Copy-Item 'README_OPENGL.md' $output -Force
  Write-Host "Built files: $output"
} finally { Pop-Location }
