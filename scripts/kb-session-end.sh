#!/usr/bin/env bash
# SessionEnd hook: logs session summary to today's daily note.
# Writes to project vault if initialized, Global vault otherwise.
# Works with or without Obsidian running (filesystem fallback always available).

PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJ_NAME=$(basename "$PROJ_DIR")
TIMESTAMP=$(date +"%H:%M")
TODAY=$(date +"%Y-%m-%d")
KB_LOG="/tmp/claude-kb-writes-$TODAY.log"

obsidian_running() { obsidian version &>/dev/null; }

# Target the project vault — session log always goes to the project's own vault, not Global.
PROJECT_VAULT_PATH="$HOME/ObsidianVaults/$PROJ_NAME"

# Helper: write daily note to a vault path via filesystem.
# Respects "Daily Notes/" subfolder if it exists, otherwise writes to vault root.
write_daily_note() {
  local vault_path="$1"
  local content="$2"
  local daily_dir
  if [ -d "$vault_path/Daily Notes" ]; then
    daily_dir="$vault_path/Daily Notes"
  else
    daily_dir="$vault_path"
  fi
  mkdir -p "$daily_dir"
  printf '%s\n' "$content" >> "$daily_dir/$TODAY.md"
}

# P2-4 fix: include git commit summary for richer session log
# Include files written/edited this session (from kb-capture.sh PostToolUse hook)
CAPTURE_LOG="/tmp/claude-capture-$TODAY.log"
FILES_SUMMARY=""
if [ -f "$CAPTURE_LOG" ]; then
  FILE_COUNT=$(wc -l < "$CAPTURE_LOG")
  FILES_SUMMARY="
- Files changed: $FILE_COUNT
$(sort -u "$CAPTURE_LOG" | awk -F'] ' '{print "  - "$2}' | head -10)"
  rm -f "$CAPTURE_LOG"
fi

GIT_SUMMARY=""
if git -C "$PROJ_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  COMMIT_COUNT=$(git -C "$PROJ_DIR" log --oneline --since="4 hours ago" 2>/dev/null | wc -l)
  (( COMMIT_COUNT > 0 )) && GIT_SUMMARY="
- Git: $COMMIT_COUNT commit(s) in last 4h ($(git -C "$PROJ_DIR" log --oneline --since="4 hours ago" 2>/dev/null | head -3 | tr '\n' ';' | sed 's/;$//;s/;/ · /g'))"
fi

ENTRY="
### Claude Session — $TIMESTAMP ($PROJ_NAME)
- Project: $PROJ_NAME
- Session ended: $TIMESTAMP$FILES_SUMMARY$GIT_SUMMARY"

# Report KB notes written as Obsidian wikilinks (format: "Vault/cat/slug.md|Title")
if [ -f "$KB_LOG" ]; then
  LINKS=""
  while IFS='|' read -r note_path note_title; do
    # Strip vault prefix and .md → [[category/slug|Title]]
    rel="${note_path#*/}"       # remove "Global/" or "B2P/" prefix
    slug="${rel%.md}"           # remove .md
    if [ -n "$note_title" ]; then
      LINKS+="  - [[${slug}|${note_title}]]"$'\n'
    else
      LINKS+="  - [[${slug}]]"$'\n'
    fi
  done < "$KB_LOG"
  ENTRY+="
- KB notes written:
${LINKS%$'\n'}"
  rm -f "$KB_LOG"
fi

# Write session log to project vault if initialized, otherwise fall back to Global.
if [ -d "$PROJECT_VAULT_PATH" ]; then
  # Project vault exists — use it.
  # obsidian daily:append only works correctly for the active vault (vault= is ignored).
  ACTIVE_VAULT=$(obsidian_running && obsidian vault info=name 2>/dev/null | tr -d '\n' || echo "")
  if obsidian_running && [ "$ACTIVE_VAULT" = "$PROJ_NAME" ]; then
    obsidian daily:append content="$ENTRY" &>/dev/null || write_daily_note "$PROJECT_VAULT_PATH" "$ENTRY"
  else
    write_daily_note "$PROJECT_VAULT_PATH" "$ENTRY"
  fi
else
  # No project vault initialized — fall back to Global vault.
  GLOBAL_VAULT_PATH="$HOME/ObsidianVaults/Global"
  ACTIVE_VAULT=$(obsidian_running && obsidian vault info=name 2>/dev/null | tr -d '\n' || echo "")
  if obsidian_running && [ "$ACTIVE_VAULT" = "Global" ]; then
    obsidian daily:append content="$ENTRY" &>/dev/null || write_daily_note "$GLOBAL_VAULT_PATH" "$ENTRY"
  else
    write_daily_note "$GLOBAL_VAULT_PATH" "$ENTRY"
  fi
fi
