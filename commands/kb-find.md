---
description: Find KB notes by tag, category, or status using obsidian-cli queries
argument-hint: <tag|category|status> <value> [vault]
---

Find knowledge base notes using structured queries — by tag, category, or status.
Uses `obsidian tag`, `obsidian files`, and `obsidian base:query` depending on query type.

## Arguments

`$ARGUMENTS` — interpreted as: `<field> <value> [vault]`

Examples:
- `tag claude-context B2P` — all notes tagged claude-context in B2P vault
- `category decisions` — all decision notes in current project vault
- `status stale` — all stale notes
- `tag adr Global` — all ADRs in Global vault

## Steps

1. Parse field, value, vault from `$ARGUMENTS`
   - Default vault: current project vault + Global

2. Run the appropriate obsidian-cli query:

**By tag:**
```bash
obsidian tag name="$VALUE" vault="$VAULT" verbose format=json
```

**By category (folder):**
```bash
obsidian files folder="$VALUE" vault="$VAULT"
```

**By status (frontmatter grep):**
```bash
grep -rl "status: $VALUE" "$HOME/ObsidianVaults/$VAULT" --include="*.md"
```

**Structured base query (when Obsidian running):**
```bash
obsidian base:query file="_kb-index.base" vault="$VAULT" format=json
```

3. Present results as a table: note path | title | last_modified | status

4. Offer to read any note, update its status, or run `/kb-outline` on it
