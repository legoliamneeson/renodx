---
name: renodx-context-handoff
description: "Resume or transfer RenoDX and RenoOGL development context to another AI; identify the checkout, choose focused skills, locate prior game work, and distinguish source, build, installed, and runtime evidence."
---

# Resume a RenoDX or RenoOGL project

Use this entry point when receiving the repository without the original chat.
The pack captures reusable lessons through 2026-10-07. It is not a transcript
or a promise that every historical change is present in this checkout.

Read the root `AGENTS.md`, relevant nested guidance, and the
[skill index](../README.md). Select only the procedures needed for the task.
Read [source-map.md](references/source-map.md) for this copy's actual files,
and [prior-work.md](references/prior-work.md) when continuing a named game.

## Establish the working state

- Resolve the repository by `CMakeLists.txt` and `src/`, not by someone else's
  drive letter. RenoOGL may have an outer directory and an inner `renodx/` root.
- Inspect branch, revision, worktree changes, and submodule state. Existing
  uncommitted edits can contain the latest work; do not reset them to match notes.
- Identify the game's executable build, API, bitness, addon target, and active
  shader source: Original, Add-on, or File. Source on disk, compiled addon,
  installed addon, and live override are four different states.
- Inspect the actual available tools. If DevKit MCP is absent, continue source
  analysis and builds where useful; mark runtime claims unverified. The skills
  do not create an MCP connection or require access to the original chats.
- Existing setup and tonemap skills contain older examples, including PsychoV17.
  Select the actual implementation wired by the target game; do not replace
  PsychoV30 or Prism with an older example just to follow a template.

## Preserve the project's intent

Preserve authored SDR midtones, hue, contrast, grade, fades, and alpha while
extending proven upstream range. Expose artistic changes as explicit controls.
Do not describe final-frame SDR expansion as recovered scene HDR. Do not
infer a resource's encoding or units from its FP16 format alone.

The current user's scope and preferences govern builds, installation and game
restarts. Historical authorization does not authorize new external actions.
Complete useful source work without inventing a deployment requirement.

## Transfer a useful result

Use [handoff-record.md](templates/handoff-record.md) for a concise continuation
record. Record exact files and shader hashes, the active path, build status,
runtime evidence, remaining uncertainty, and the next reproducible check.
Do not publish machine paths, session handles, private chat transcripts,
game dumps, or proprietary binaries as part of a generic skill pack.

Read the [kickoff prompt](../../../AI_KICKOFF_PROMPT.md) for a ready-to-use
task prompt. A receiving AI without skill discovery can read these Markdown
files directly. Sharing the skill folders transfers procedures; source-based
changes still require the corresponding repository and permitted game evidence.
