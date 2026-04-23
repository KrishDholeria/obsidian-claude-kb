#!/usr/bin/env bash
# PostToolUse hook: tracks files written/edited during a session.
# Called after every Write/Edit tool use. Appends to a session capture log
# so kb-session-end.sh can include a summary of what changed.
#
# Input (from Claude Code via stdin): JSON with tool_name and file_path
# This script is intentionally lightweight — no Obsidian call, just a log append.

TODAY=$(date +%Y-%m-%d)
CAPTURE_LOG="/tmp/claude-capture-$TODAY.log"

# Read tool info from stdin (Claude Code passes hook context as JSON)
INPUT=$(cat 2>/dev/null)
TOOL=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
FILE=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); p=d.get('tool_input',{}); print(p.get('file_path', p.get('path','')))" 2>/dev/null)

[ -z "$FILE" ] && exit 0

PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Only log files within the current project (ignore vault writes, tmp, etc.)
[[ "$FILE" == "$PROJ_DIR"* ]] || exit 0

TIMESTAMP=$(date +"%H:%M:%S")
echo "$TIMESTAMP [$TOOL] $FILE" >> "$CAPTURE_LOG"
