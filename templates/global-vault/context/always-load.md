---
title: Global Always-Load Context
category: context
tags: [claude-context]
last_modified: 2026-04-22
status: active
references: []
---

# Global Always-Load Context

Notes here are injected into every Claude Code session regardless of project.

## User Preferences

- Krish works across multiple projects; each has its own vault under `~/ObsidianVaults/<ProjectName>/`
- Use `/browse` skill for all web browsing — never use `mcp__claude-in-chrome__*` directly
- Default to terse responses; no trailing summaries unless asked
- No emojis unless explicitly requested

## Tool Defaults

- Browser: gstack `/browse` skill
- Code intelligence: GitNexus MCP tools (run impact analysis before editing any symbol)
- Knowledge base: read from `~/ObsidianVaults/Global/` and the active project vault

## How to Write Back to This Vault

After a session produces reusable knowledge, write a note:
- File: `~/ObsidianVaults/Global/<category>/<slug>.md`
- Include frontmatter with `category`, `tags`, `last_modified`, `status`
- Tag `#claude-context` only if it should load every session
