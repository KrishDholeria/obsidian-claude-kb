#!/usr/bin/env bash
# SessionEnd hook: logs session summary to today's Obsidian daily note.
# Uses daily:append via obsidian-cli; skips silently if Obsidian not running.

PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJ_NAME=$(basename "$PROJ_DIR")
TIMESTAMP=$(date +"%H:%M")
TODAY=$(date +"%Y-%m-%d")
KB_LOG="/tmp/claude-kb-writes-$TODAY.log"

obsidian_running() { obsidian version &>/dev/null; }
obsidian_knows_vault() { obsidian vaults 2>/dev/null | awk '{print $1}' | grep -qx "$1"; }

obsidian_running || exit 0

# FIX: detect the active vault — daily:append vault= param is silently ignored by obsidian-cli.
# We always append to the active vault (no vault= arg), so just verify obsidian is running.
ACTIVE_VAULT=$(obsidian vault info=name 2>/dev/null | tr -d '\n')
[ -z "$ACTIVE_VAULT" ] && exit 0
TARGET_VAULT="$ACTIVE_VAULT"

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

# P1-2: report KB notes written (populated by kb-save.sh)
if [ -f "$KB_LOG" ]; then
  ENTRY+="
- KB notes written:
$(sed 's/^/  - /' "$KB_LOG")"
  rm -f "$KB_LOG"
fi

# FIX: don't pass vault= — obsidian-cli silently ignores it and uses the active vault anyway.
# Filesystem fallback writes to the active vault's daily notes directory.
if ! obsidian daily:append content="$ENTRY" &>/dev/null; then
  DAILY_DIR="$HOME/ObsidianVaults/$ACTIVE_VAULT/Daily Notes"
  DAILY_FILE="$DAILY_DIR/$TODAY.md"
  mkdir -p "$DAILY_DIR"
  printf '%s\n' "$ENTRY" >> "$DAILY_FILE"
fi
