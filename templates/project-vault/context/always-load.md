---
title: "{{ProjectName}} Always-Load Context"
category: context
type: context
tags:
  - claude-context
last_modified: {{TODAY}}
status: active
component: ""
references: []
---

# {{ProjectName}} Always-Load Context

Notes here are injected into every Claude Code session for this project.

## Project Overview

<!-- Describe what this project is and its key purpose -->

## Stack at a Glance

| Layer | Tech |
|-------|------|
| Frontend | |
| Backend | |
| Infra | |
| Auth | |

## Key Files & Entry Points

<!-- List the most important files Claude should be aware of -->

## Active Priorities

<!-- Current sprint focus, open bugs, in-progress features — keep this updated -->

## Known Gotchas

<!-- Quirks, non-obvious behaviors, things that surprised you -->

## How to Save Knowledge

```bash
# Save a decision
bash ~/.claude/scripts/kb-save.sh "{{ProjectName}}" "decisions" "slug" "Title" "adr,claude-context-conditional" "content"

# Search the vault
bash ~/.claude/scripts/kb-search.sh "topic" {{ProjectName}}

# Check KB health
bash ~/.claude/scripts/kb-health.sh {{ProjectName}}
```
