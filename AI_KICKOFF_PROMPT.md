# Combined RenoDX and Reno OGL kickoff prompt

The paths below are filled in for this computer. When sharing with someone else,
replace them with the locations of their source copies.

---

Help me develop and maintain both the RenoDX and Reno OGL source trees.

In each repository, read:

- AGENTS.md
- AI_HANDOFF.md
- .agents/skills/renodx-context-handoff/SKILL.md
- Its source-map and prior-work references
- .agents/skills/README.md, then only the skills relevant to my task

Use these files to understand our previous work, established methods, confirmed
fixes, and unfinished experiments. Verify historical notes against the current
source.

Determine which repository owns the requested change. Keep RenoDX's generic_opengl
profile workflow separate from Reno OGL's patched live DevKit workflow. When
transferring a fix between them, check compatibility and adapt it deliberately.

Preserve existing edits, the game's authored appearance, shader interfaces,
alpha, resource lifetimes, and graphics state. For HDR changes, establish the
actual signal path, encoding, units, and clipping point before modifying shader
math.

Use available DevKit tools when helpful. If runtime access is unavailable,
continue useful source work and clearly identify what remains unverified.

Validate the changes and report separately what was edited, compiled, installed,
and tested in-game. Follow my build/install preferences and update the
continuation notes.

RenoDX source folder: `C:\Users\ctied\Documents\renodx`

Reno OGL source folder: `C:\Users\ctied\Documents\renoogl\renodx`

Game or subsystem: [name]

Task: [describe the change]

Build/install preferences: [describe]
