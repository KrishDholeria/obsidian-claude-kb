---
description: Show heading outline of a KB note — navigate large notes without reading them fully
argument-hint: <vault> <path>
---

Get the heading structure of a knowledge base note before deciding whether to read it in full.
Uses `obsidian outline` (obsidian-cli) or filesystem grep fallback.

## Arguments

`$ARGUMENTS` — interpreted as: `<vault> <note-path>`

- **vault**: `Global` | project name (e.g. `B2P`)
- **note-path**: relative path within vault (e.g. `architecture/data-pipeline.md`)

If only a note name is given (no vault), search both Global and the current project vault.

## Steps

1. Parse vault and path from `$ARGUMENTS`
2. If path is ambiguous, run a quick search first:

```bash
bash ~/.claude/scripts/kb-search.sh "$ARGUMENTS" all 3
```

3. Get the outline:

```bash
bash ~/.claude/scripts/kb-outline.sh "$VAULT" "$PATH"
```

4. Present the heading tree clearly with level indicators and line numbers
5. Ask the user which section they want to read, then use:

```bash
obsidian read path="$PATH" vault="$VAULT"
```

to fetch only what's needed (or the full note if it's short)
