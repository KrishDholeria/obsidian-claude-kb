---
title: Global Knowledge Base
type: index
last_modified: 2026-04-22
---

# Global Knowledge Base

Cross-project knowledge applicable to all Claude Code sessions.

## Categories

| Folder | What goes here |
|--------|---------------|
| `patterns/` | Reusable architectural and code patterns |
| `tools/` | Tool configs, setup notes, CLI references |
| `conventions/` | Code style, naming, workflow conventions |
| `context/` | Always-on context tagged `#claude-context` |
| `explorations/` | Experiments and ideas explored with Claude — findings, dead ends, conclusions |

## Tagging Rules

- `#claude-context` — injected automatically every session
- `#claude-context-conditional` — injected only when topic matches
- `#stale` — outdated, do not inject; archive or delete
- `#draft` — work in progress, not yet reliable

## Frontmatter Schema

```yaml
---
title: 
category: patterns | tools | conventions | context | explorations
tags: []
last_modified: YYYY-MM-DD
status: active | stale | deprecated
references: []   # file paths or URLs this note is based on
---
```
