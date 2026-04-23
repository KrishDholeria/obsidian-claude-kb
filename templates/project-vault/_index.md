---
title: {{ProjectName}} Knowledge Base
type: index
last_modified: {{TODAY}}
---

# {{ProjectName}} Knowledge Base

Project-specific knowledge for {{ProjectName}}.

## Categories

| Folder | What goes here |
|--------|---------------|
| `architecture/` | System design, data flows, component relationships |
| `decisions/` | Architecture Decision Records (ADRs) — why X was chosen |
| `runbooks/` | Step-by-step operational procedures (deploy, migrate, debug) |
| `context/` | Current sprint, open questions, known issues |
| `sessions/` | Claude-written session summaries (auto-generated, do not edit) |
| `integrations/` | Third-party integration specifics |
| `domain/` | Business domain knowledge |
| `explorations/` | Experiments and ideas explored with Claude — findings, dead ends, conclusions |

## Tagging Rules

- `#claude-context` — injected automatically every session for this project
- `#claude-context-conditional` — injected only when topic matches
- `#stale` — outdated; verify against code before trusting
- `#draft` — in progress, not yet reliable
- `#adr` — Architecture Decision Record

## Frontmatter Schema

```yaml
---
title:
category: architecture | decisions | runbooks | context | sessions | integrations | domain | explorations
tags: []
last_modified: YYYY-MM-DD
status: active | stale | deprecated
references: []   # file paths, git commits, or PR links
---
```
