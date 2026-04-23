---
title: Claude Code Setup & Key Integrations
category: tools
tags: [claude-context]
last_modified: 2026-04-22
status: active
references: [~/.claude/settings.json]
---

# Claude Code Setup

## MCP Servers

| Server | Vault | Scope |
|--------|-------|-------|
| `obsidian-global` | `~/ObsidianVaults/Global/` | All sessions (global settings) |
| `obsidian-<project>` | `~/ObsidianVaults/<Project>/` | Per-project (project settings) |

## Hooks

| Event | Hook | Purpose |
|-------|------|---------|
| `SessionStart` | `load-vault.sh` | Inject `#claude-context` notes |
| `SessionStart` | `gstack-session-update` | gstack state sync |
| `PreToolUse` | `gitnexus-hook.cjs` | GitNexus graph enrichment |
| `PostToolUse` | `gitnexus-hook.cjs` | Index freshness check |

## Key Skills

- `/browse` — headless browser (always use instead of chrome tools)
- `/qa`, `/review`, `/ship` — code workflow
- `/office-hours` — YC-style forcing questions
- `/investigate` — systematic debugging

## Knowledge Base Hook Script

`~/.claude/scripts/load-vault.sh` — reads `#claude-context` tagged notes from
Global + active project vault, injects with `last_modified` metadata.
Token budget: 6000 tokens (~24000 chars). Notes exceeding budget are truncated by recency.
