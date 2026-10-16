# Portable RenoDX / RenoOGL AI handoff

Prepared 2026-10-07 for the RenoOGL source tree.

Start with [the kickoff prompt](AI_KICKOFF_PROMPT.md), then
[context handoff](.agents/skills/renodx-context-handoff/SKILL.md) and the
[skill index](.agents/skills/README.md). The six original skills are retained;
12 additional skills capture specialized workflows from the prior work.

## Sharing with another AI

Share the corresponding source repository together with `AGENTS.md`, this file,
`AI_KICKOFF_PROMPT.md`, and the whole `.agents/skills/` folder, including references
and templates. Hidden folders may be omitted by file pickers; include `.agents`
explicitly. The files are ordinary Markdown with skill frontmatter. An AI that
does not recognize the folder convention can read the files named in the prompt.

A documentation-only skill bundle does not contain the game source or binaries.
Use it alongside the matching repository. Do not blindly merge the RenoDX and
RenoOGL copies: the [source map](.agents/skills/renodx-context-handoff/references/source-map.md)
records which references are actually present in this tree.

## What this transfers

Reusable reasoning, source landmarks, implementation constraints, and known
validation limits: DevKit tracing, HDR/LUT/curve work, bloom, exposure, settings,
DX9 readback, runtime diagnosis, upscaler boundaries and OpenGL workflows.
The [prior-work reference](.agents/skills/renodx-context-handoff/references/prior-work.md)
summarizes game-specific lessons and unresolved checks without embedding chats.
This is a curated handoff, not an exhaustive archive of every conversation.

Current source and fresh evidence supersede dated notes. Historical compilation,
isolated tests, installation and game validation are explicitly different claims.
The skills do not install tools, connect MCP, grant permissions or establish
that a game's current binary is supported.

## Maintaining the pack

Keep original procedures in their owning skill, add only useful task-specific
lessons, and update source maps when moving files. Use the
[continuation record](.agents/skills/renodx-context-handoff/templates/handoff-record.md)
after meaningful work. Read `.agents/skills/AGENTS.md` before editing skills.
