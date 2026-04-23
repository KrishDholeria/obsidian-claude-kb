---
description: Save a knowledge note to the Obsidian vault with correct category and frontmatter
argument-hint: [vault] [category] [slug] [title] [tags] [content]
---

Save a knowledge note to the Obsidian second-brain vault.

## Arguments

Arguments can be passed inline: `$ARGUMENTS`

If no arguments are given, infer the best values from the current conversation context:
- **vault**: current project name (basename of `$CLAUDE_PROJECT_DIR` or `pwd`) for project-specific knowledge; "Global" for cross-project patterns or conventions
- **category**: pick the best fit from `patterns | tools | conventions | context | explorations | architecture | decisions | runbooks | integrations | domain | sessions`
- **slug**: kebab-case, descriptive, no date prefix
- **title**: human-readable, sentence case
- **tags**: comma-separated from `claude-context, claude-context-conditional, adr, draft, stale`
- **content**: the actual markdown body — synthesize from conversation context, do NOT just repeat the user's message

## Steps

1. Determine vault, category, slug, title, tags, and content (from arguments or conversation context)
2. Run the save script:

```bash
bash ~/.claude/scripts/kb-save.sh "$VAULT" "$CATEGORY" "$SLUG" "$TITLE" "$TAGS" "$CONTENT"
```

3. Confirm what was saved: vault path, category, tags applied, and whether it was created or updated
4. If the note was tagged `claude-context`, mention it will auto-load in future sessions

## Tag selection guide

| Knowledge type | Tags |
|---|---|
| Should always be in context | `claude-context` |
| Only relevant to specific topics | `claude-context-conditional` |
| Architecture Decision Record | `adr,claude-context-conditional` |
| Experimental / unverified | `draft` |
