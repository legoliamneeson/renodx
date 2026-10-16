<# Build the patched ReShade (opengl32.dll) and the OpenGL DevKit with the RenoDX presets,
then stage them in dist\opengl\<arch>. Equivalent to:
  cmake --preset clang-<arch>
  cmake --build --preset clang-<arch>-release --target reshade_opengl   (and devkit_opengl, <GameTarget>)
Needs CMake, Ninja, LLVM (clang-cl), Git and Python on PATH; no developer shell required.
Nothing is installed into a game automatically. #>
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
Push-Location $root
try {
  foreach ($command in @('git', 'python', 'cmake', 'ninja', 'clang-cl')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
      throw "$command is missing. Install it and make sure it is on PATH (see docs/CONTRIBUTING.md; for Ninja: winget install Ninja-build.Ninja)."
    }
  }
  if (-not $SkipDependencies) {
    # No --force / --remote: keep an already patched ReShade and pinned dependency revisions.
    Invoke-Checked git @('submodule', 'update', '--init', '--recursive')
    Invoke-Checked python @('-m', 'pip', 'install', '-r', 'external/reshade/deps/glad/requirements.txt')
    & .\scripts\setup-dev-env.ps1 -Install -Tools @('dxc', 'slang', 'glslang')
  }

  $bits = if ($Architecture -eq 'x86') { '32' } else { '64' }
  $buildDir = if ($Architecture -eq 'x86') { 'build32' } else { 'build' }
  $targets = @('reshade_opengl', 'devkit_opengl')
  if ($GameTarget) { $targets += $GameTarget }

  Invoke-Checked cmake @('--preset', "clang-$Architecture")
  foreach ($target in $targets) {
    Invoke-Checked cmake @('--build', '--preset', "clang-$Architecture-release", '--target', $target)
  }

  $output = Join-Path $root "dist/opengl/$Architecture"
  New-Item -ItemType Directory -Path $output -Force | Out-Null
  Copy-Item "$buildDir/Release/opengl32.dll" $output -Force
  Copy-Item "$buildDir/Release/renodx-devkit_opengl.addon$bits" $output -Force
  if ($GameTarget) { Copy-Item "$buildDir/Release/renodx-$GameTarget.addon$bits" $output -Force }
  Copy-Item 'README_OPENGL.md' $output -Force
  Write-Host "Built files: $output"
} finally { Pop-Location }
