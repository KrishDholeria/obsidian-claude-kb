---
description: Run a health check on the Obsidian KB — surfaces stale notes, orphans, dead ends, and open tasks
argument-hint: [vault]
---

Run a health check across the knowledge base vaults.
Reports: stale notes, orphaned notes (no incoming links), dead-end notes (no outgoing links), notes not updated in 60+ days, and open KB tasks.

## Arguments

`$ARGUMENTS` — vault name to check, or empty for all vaults

- Empty / `all`: checks Global + current project vault
- `Global`: checks only the Global vault
- `<ProjectName>`: checks only that project vault

## Steps

1. Run the health check:

```bash
bash ~/.claude/scripts/kb-health.sh "${ARGUMENTS:-all}"
```

2. Parse and present the report:
   - **Stale notes**: list with last_modified date — offer to update or mark as deprecated
   - **Orphaned notes**: notes with no incoming links — offer to add wikilinks from related notes or delete
   - **Dead-end notes**: notes with no outgoing links — offer to add references
   - **60-day stale**: list with dates — offer to verify against current code and update `last_modified`
   - **Open tasks**: list with file and line — ask if any should be closed

3. If Obsidian is not running, note that orphan/dead-end checks are unavailable and suggest opening Obsidian

4. Offer to fix any identified issues inline
