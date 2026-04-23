---
description: Search the Obsidian knowledge base for notes matching a concept or keyword
argument-hint: <query> [vault] [limit]
---

Search the Obsidian knowledge base using `search:context` (obsidian-cli) or filesystem grep fallback.

## Arguments

`$ARGUMENTS` — interpreted as: `<query> [vault] [limit]`

- **query** (required): concept, keyword, or phrase to find
- **vault**: `Global` | project name | `all` (default: `all`)
- **limit**: max files to return (default: 5)

## Steps

1. Parse query, vault, and limit from `$ARGUMENTS`
2. Run the search:

```bash
bash ~/.claude/scripts/kb-search.sh "$QUERY" "${VAULT:-all}" "${LIMIT:-5}"
```

3. Present the results clearly:
   - For each matching note: show the file path, the matching lines with context, and the `last_modified` date from frontmatter
   - If 0 results: suggest alternative search terms or check if the vault is registered in Obsidian
   - If results look relevant: offer to read the full note (`obsidian read path=... vault=...`)

4. If the query matches something important and no note exists yet, offer to create one with `/kb-save`
