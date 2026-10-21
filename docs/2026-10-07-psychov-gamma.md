# Continuation record: gamma encode after PsychoV (RenoDX)

- Task and scope: confirm that every game mod using PsychoV encodes after the PsychoV call, and fix any mod that does not. Scope is RenoDX `src/games/*` mod shaders. Reno OGL has no CODWAW or other COD mod folders and was not changed.
- Repository revision and pre-existing local changes: RenoDX HEAD last recorded as `8f065cc70b145ece23287bf925883c294012fc9d` (`.git/logs/HEAD`). The working tree was not checked with git; the only edited file is listed below.
- Game executable/version, API and architecture: WaW (`CODWAW`), DX9 pixel shader `output1_0x31031D0A.ps_3_0.hlsl`. Addon bitness not checked. No runtime or executable identity was checked.
- Addon target; loaded loader/addon identity; Original/Add-on/File state: not built, installed, or loaded. Build/install preference was "edit the source" only.
- Relevant source files and shader hashes: see the table below.
- Proven signal path, encodings, units, alpha use, resources and copy aliases: see the table below. PsychoV-24 and PsychoV-30 both take scene-linear BT.709 and return linear. PsychoV does not apply any gamma of its own (`src/shaders/tonemap/psychov/psychov.hlsl` and `test30.hlsl` were read).

## Per-mod PsychoV audit

| Mod | Shader | PsychoV | Input to PsychoV | Encode after PsychoV | Status |
| --- | --- | --- | --- | --- | --- |
| CODWW2 | `hdr.hlsli`, `tonemap_0xCB76A9C1.ps_6_1.hlsl` | PsychoV-30 | Linear (`sceneRelative`, BT.709 relative) | PQ encode after grading (`CODWW2PQEncodeNits`) | OK, unchanged |
| CODColdWar | `tonemap_0xCB76A9C1.ps_6_1.hlsl` | PsychoV-30 | Linear (`sceneRelative`, decoded from native PQ) | `RenderIntermediatePass`, then PQ encode | OK, unchanged |
| CODWAW | `output1_0x31031D0A.ps_3_0.hlsl` (`ApplyPsycho`) | PsychoV-30 | Was game-space direct output (not decoded). Now decoded with `renodx::color::gamma::DecodeSafe` (2.2) | Now `renodx::color::gamma::EncodeSafe` (2.2) after PsychoV, then the existing relative gamma and brightness step (identity at 2.2 and 203 nits) | **Edited** (see changes) |
| CODMW3 | `output_0x822A44B8`, `output2`, `output3`, `output4`, `output5` (`*.ps_3_0.hlsl`) | PsychoV-24 | Linear (decoded with `GammaDecode2` where the grade is gamma-2.0; `output5` mode 0 treats the grade as linear) | `RenderIntermediatePass` | OK, unchanged |
| CODBLOPS2 | `tonemapper_0x38B441CC.ps_4_0.hlsl` | PsychoV-24 | Linear (`combinedLinear` / `ApplyCommonPreTonemapPipeline`; the gamma-space gamut compression is in `ApplyCommonHDRDisplayMap`, which PsychoV skips) | Pre/post-grade and highlight restore stay linear, then `RenderIntermediatePass` | OK, unchanged |
| Skyrim SE | `tonemap_0x936CE1A3.ps_5_0.hlsl`, `tonemap2_0x1F60675B.ps_5_0.hlsl` | PsychoV-24 | Linear (`DecodeSafe` at the "Linearize and encode" step, then HDR boost) | `bt2020::from::BT709`, then `RenderIntermediatePass` | OK, unchanged |
| CODBLOPS (BO1) | `tonemapper_0x357DE7FD.ps_3_0.hlsl` | none found | n/a | n/a | No PsychoV call |
| CODGHOSTS | all staged shaders | none (uses Prism) | n/a | `GhostsEncodeOutput` / `GhostsRenderEncodedOutput` | Out of scope. `PsychoV24` fields in `shared.h` are unused storage |
| Gears 4 | `common.hlsl`, `shared.h`, `lutbuilders/legacy.hlsl` | none found | n/a | n/a | Not scanned: `lutbuilders/sm5` and `sm6` (about 200 files) |
| RE6 | `lut1`, `lut2`, `shared.h` | none found | n/a | n/a | No PsychoV call among staged files |

## Changes made

- `src/games/CODWAW/output1_0x31031D0A.ps_3_0.hlsl`, `ApplyPsycho()`:
  - Added `color = renodx::color::gamma::DecodeSafe(color);` immediately before `renodx::tonemap::psychov::psychotm_test30(...)`.
  - Replaced the final `return SafePositive(color);` with `return renodx::color::gamma::EncodeSafe(SafePositive(color));`.
  - Grading (`ApplyStandardRenoDXControlsForCustom`) and the gamma/brightness output step are unchanged.
  - Decided by the user: "Linearize before PsychoV, encode after". The decision was made with the look change in view, so the default image will change.
  - The file was committed to the device path with an mtime guard. The device size went from 20523 to 20819 bytes.
- No other files were edited.

## Validation performed

- Source read: PsychoV libraries, WaW shader and helpers, `renodx::color::gamma` (`src/shaders/color/gamma.hlsl`), include chain (`draw.hlsl` → `color.hlsl` → `color/gamma.hlsl`), and every PsychoV call site listed above.
- Not compiled. The build preference was "edit the source", so no FXC/addon build was run.
- Not in-game. No DevKit runtime was used.

## Known limits and next check

- WaW uses 2.2 for the decode/encode pair because the existing WaW gamma baseline is 2.2. If the game's direct-output values turn out to be sRGB-encoded rather than 2.2-encoded, switch both calls to `renodx::color::srgb` helpers. This is a real open question, not settled by the source.
- WaW's RenoDRT branch (`ApplyRenoDRT`) still receives the game-space color with no decode. Only the PsychoV branch was changed, so RenoDRT and PsychoV now handle the same input differently. Check whether RenoDRT should get the same treatment.
- Next in-game check (WaW): select PsychoV-30 and compare against the pre-edit build at default settings (Gamma 2.2, Game 203 nits). Check midtones, highlight rolloff, and black level. The change is expected to be visible.
- `src/games/CODColdWar/pyschov-30.hlsl` (a local copy with a typo in its name) defines `psychotm_test30`, but the staged Cold War shader includes the shared `psychov/psychov.hlsl`. Confirm the local copy is unused before deleting it.
- Gears 4 `lutbuilders/sm5` and `sm6` were not scanned for PsychoV calls.
- Reno OGL: its tree has no COD mod folders (directory listing only). Its other game folders were not scanned for PsychoV. No OGL files were changed.
