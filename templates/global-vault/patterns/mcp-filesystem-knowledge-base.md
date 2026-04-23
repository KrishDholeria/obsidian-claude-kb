---
title: MCP Filesystem + Hook Knowledge Base Pattern
category: patterns
tags: [claude-context-conditional]
last_modified: 2026-04-22
status: active
references: [~/.claude/settings.json, ~/.claude/scripts/load-vault.sh]
---

# MCP Filesystem + Hook Knowledge Base Pattern

## What It Is

Obsidian vaults served to Claude via two mechanisms:
1. **MCP `@modelcontextprotocol/server-filesystem`** — explicit read/write during sessions
2. **`SessionStart` hook** — auto-injects `#claude-context` tagged notes at session open

## Vault Layout Convention

```
~/ObsidianVaults/
  Global/                    # Cross-project, loaded in all sessions
    _index.md                # Taxonomy + schema reference
    context/                 # Always-load notes (#claude-context)
    patterns/                # Reusable architectural patterns
    tools/                   # Tool configs and references
    conventions/             # Style and workflow conventions
    explorations/            # Claude + user experiment logs
  <ProjectName>/             # Project-specific, loaded per-project
    _index.md
    architecture/
    decisions/               # ADRs
    runbooks/
    context/                 # Always-load project context
    sessions/                # Auto-written session summaries
    integrations/
    domain/
    explorations/
```

## Frontmatter Schema (all notes)

```yaml
---
title: Human-readable title
category: <folder name>
tags: []          # claude-context | claude-context-conditional | stale | draft | adr
last_modified: YYYY-MM-DD
status: active | stale | deprecated
references: []    # file paths, git commits, URLs
---
```

## When to Use Which Tag

| Tag | Meaning | Hook behavior |
|-----|---------|---------------|
| `claude-context` | Always relevant | Injected every session |
| `claude-context-conditional` | Topic-specific | Manual retrieval via MCP |
| `stale` | Needs verification | Never injected |
| `draft` | Unreliable | Never injected |

## Staleness Rule

Any note referencing a specific function, class, or file should include the git commit hash
or file path in `references`. Before trusting it, verify the referenced code still exists.
