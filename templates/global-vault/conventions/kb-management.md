---
title: KB Management Conventions
category: conventions
tags:
  - claude-context
last_modified: 2026-04-23
status: active
references: [~/.claude/scripts/kb-save.sh, ~/.claude/scripts/load-vault.sh]
---

# KB Management Conventions

## When Claude Should Save to KB

Save a note when a session produces something **reusable and non-obvious**:
- A decision with a non-obvious rationale (→ `decisions/` or `patterns/`)
- A workflow or procedure that took multiple steps to figure out (→ `runbooks/`)
- A surprising integration behavior (→ `integrations/`)
- An exploration with clear findings or dead ends (→ `explorations/`)
- Architecture discovered by reading code, not docs (→ `architecture/`)

Do NOT save: in-progress work, task lists, things already in CLAUDE.md, obvious stdlib usage.

## How Claude Saves Notes

Use `kb-save.sh` via Bash:

```bash
bash ~/.claude/scripts/kb-save.sh \
  "<vault>" "<category>" "<slug>" "<title>" "<tags>" "<content>"
```

**Example — saving a B2P decision:**
```bash
bash ~/.claude/scripts/kb-save.sh \
  "B2P" "decisions" "why-sqs-fifo-per-client" \
  "Why SQS FIFO queues are per-client" \
  "claude-context-conditional,adr" \
  "Each B2P client has 4 dedicated FIFO queues (Order/NonOrder/Customer/Error).\nReason: prevents high-volume clients from blocking others. Decided 2024-Q3."
```

**Example — saving a global pattern:**
```bash
bash ~/.claude/scripts/kb-save.sh \
  "Global" "patterns" "react-query-tanstack-pattern" \
  "TanStack React Query data fetching pattern" \
  "claude-context-conditional" \
  "..."
```

## Tag Selection Guide

| Situation | Tag |
|-----------|-----|
| Always relevant every session | `claude-context` |
| Relevant only to specific topics | `claude-context-conditional` |
| Needs to be verified before trusting | `stale` |
| Still being written | `draft` |
| Architecture Decision Record | `adr` |

## MCP Priority

**obsidian-cli MCP is PRIMARY.** Use it for all KB operations when Obsidian is running.
Filesystem MCP (`obsidian-global-fs`, `obsidian-b2p-fs`) is the silent fallback only.

Prefer obsidian-cli because:
- `tag` / `search:context` gives semantic retrieval, not just filename matches
- `backlinks` traverses the knowledge graph — find everything referencing a note
- `property:set` maintains structured frontmatter without raw file edits
- `daily:append` logs session activity to today's note automatically

## Obsidian CLI Interaction Patterns

### Find relevant notes by concept (search:context)
```bash
# Returns matching files + surrounding line context — use before deciding what to read
bash ~/.claude/scripts/kb-search.sh "OLF metrics" B2P
bash ~/.claude/scripts/kb-search.sh "webhook retry" all

# Direct obsidian-cli
obsidian search:context query="SQS FIFO" vault="B2P" format=json limit=5
```

### Navigate a large note without reading it all (outline)
```bash
# Get heading structure + line numbers first, then read only what's needed
bash ~/.claude/scripts/kb-outline.sh B2P architecture/data-pipeline.md

# Direct obsidian-cli
obsidian outline path="architecture/data-pipeline.md" vault="B2P" format=json
```

### Query KB as structured data (base:query)
```bash
# _kb-index.base in each vault indexes all notes by title/category/status/tags
obsidian base:query file="_kb-index.base" vault="B2P" format=json
obsidian base:query file="_kb-index.base" vault="Global" format=json
```

### Check open KB tasks
```bash
obsidian tasks todo vault="B2P" format=json
obsidian tasks todo vault="Global" format=json
```

### Traverse knowledge graph (backlinks / links)
```bash
# Find everything that references a note
obsidian backlinks path="architecture/data-pipeline.md" vault="B2P" format=json

# Find what a note links to
obsidian links path="decisions/why-sqs-fifo-per-client.md" vault="B2P" format=json
```

### Log session work to daily note (daily:append)
```bash
# Auto-runs on SessionEnd via kb-session-end.sh hook
# Also call manually to log a finding mid-session
obsidian daily:append content="## Finding\nOLF uses SQS FIFO per client." vault="B2P"
```

### KB health check (orphans / deadends / stale)
```bash
bash ~/.claude/scripts/kb-health.sh B2P
bash ~/.claude/scripts/kb-health.sh all
```

### CRUD
```bash
# Read
obsidian read path="domain/olf-metrics.md" vault="B2P"

# Update property
obsidian property:set name="status" value="stale" path="decisions/old.md" vault="B2P"
obsidian property:set name="last_modified" value="2026-04-23" path="..." vault="B2P"

# Append
obsidian append path="explorations/obsidian-setup.md" vault="B2P" content="## Update\n..."

# List files in a category
obsidian files folder="decisions" vault="B2P"

# Save a new note (handles create + frontmatter)
bash ~/.claude/scripts/kb-save.sh "B2P" "decisions" "slug" "Title" "tags" "content"
```

## Staleness Rule

Before trusting any KB note: check `last_modified`. If > 60 days old AND references code paths,
run `obsidian property:set name="status" value="stale"` and verify against current code before citing.
