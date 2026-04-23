---
description: Append a note or finding to today's Obsidian daily note
argument-hint: [note or finding to log]
---

Append content to today's Obsidian daily note using obsidian-cli.

## Arguments

`$ARGUMENTS` — the text, finding, or note to append. If empty, synthesize a brief summary of the current session's key finding or decision.

## Steps

1. Determine content to append:
   - If `$ARGUMENTS` is provided, use it directly
   - If empty, summarize the most important thing discussed or decided in this session (1–3 bullet points)

2. Determine the target vault (first registered one in priority order: current project → Global → Krish):

```bash
for v in "$(basename ${CLAUDE_PROJECT_DIR:-$(pwd)})" "Global" "Krish"; do
  if obsidian vaults 2>/dev/null | awk '{print $1}' | grep -qx "$v"; then
    TARGET_VAULT="$v"
    break
  fi
done
```

3. Append to the daily note:

```bash
obsidian daily:append content="$CONTENT" vault="$TARGET_VAULT"
```

4. Confirm: which vault and today's date the content was appended to

5. If Obsidian is not running, write the note to a fallback file instead:

```bash
echo "$(date +%H:%M) $CONTENT" >> "$HOME/ObsidianVaults/$TARGET_VAULT/Daily Notes/$(date +%Y-%m-%d).md"
```
