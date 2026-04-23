#!/usr/bin/env bash
# Loads #claude-context tagged notes into session context.
# PRIMARY: obsidian-cli (tag queries, search:context, backlinks)
# FALLBACK: filesystem grep (when Obsidian is not running)

GLOBAL_VAULT="$HOME/ObsidianVaults/Global"
GLOBAL_VAULT_NAME="Global"
CHAR_BUDGET=24000
OUTPUT=""
CHAR_COUNT=0

PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJ_NAME=$(basename "$PROJ_DIR")
PROJECT_VAULT="$HOME/ObsidianVaults/$PROJ_NAME"
PROJECT_VAULT_NAME="$PROJ_NAME"

obsidian_running() { obsidian version &>/dev/null; }
obsidian_knows_vault() { obsidian vaults 2>/dev/null | awk '{print $1}' | grep -qx "$1"; }

# P0-2 fix: use search query="tag:#claude-context" — tag verbose format=json does not output JSON
collect_via_obsidian() {
  local vault_name="$1"
  obsidian search query="tag:#claude-context" vault="$vault_name" format=json 2>/dev/null \
    | python3 -c "
import json, sys
try:
    files = json.load(sys.stdin)
    for f in files:
        print(f if isinstance(f, str) else f.get('path', ''))
except: pass
" 2>/dev/null
}

# P1-6 fix: add truncation marker when note exceeds 80 lines
read_via_obsidian() {
  local vault_name="$1" path="$2"
  local content
  content=$(obsidian read path="$path" vault="$vault_name" 2>/dev/null)
  local lines
  lines=$(echo "$content" | wc -l)
  if (( lines > 80 )); then
    echo "$content" | head -80
    echo "... [truncated: $lines lines total — use obsidian read to get full content]"
  else
    echo "$content"
  fi
}

# Matches both YAML formats:
#   block:  "  - claude-context"  (on its own line)
#   inline: "tags: [claude-context]" or "tags: [claude-context, adr]"
collect_via_filesystem() {
  local vault_path="$1"
  grep -rl --include="*.md" \
    -P '(^\s*-\s*claude-context\s*$|tags:\s*\[([^\]]*,\s*)?claude-context(\s*,|\s*\]))' \
    "$vault_path" 2>/dev/null \
    | while read -r f; do
        # Exclude conditional — both inline and block forms
        grep -qP '(^\s*-\s*claude-context-conditional|tags:.*claude-context-conditional)' "$f" 2>/dev/null && continue
        # Exclude stale/deprecated/draft
        grep -q 'status: stale\|status: deprecated\|status: draft' "$f" 2>/dev/null && continue
        grep -qP '(^\s*-\s*(draft|stale)\s*$|tags:.*\b(draft|stale)\b)' "$f" 2>/dev/null && continue
        echo "$(stat -c %Y "$f" 2>/dev/null) $f"
      done \
    | sort -rn | awk '{print $2}'
}

# P1-6 fix: same truncation marker for filesystem path
read_via_filesystem() {
  local abs="$1"
  local lines
  lines=$(wc -l < "$abs" 2>/dev/null)
  if (( lines > 80 )); then
    head -80 "$abs"
    echo "... [truncated: $lines lines total]"
  else
    cat "$abs"
  fi
}

# P2-3 fix: track whether budget was hit to emit marker
append_note() {
  local label="$1" last_mod="$2" content="$3"
  local entry="
---
[KB: $label | last_modified: ${last_mod:-unknown}]
$content
"
  local len=${#entry}
  if (( CHAR_COUNT + len <= CHAR_BUDGET )); then
    OUTPUT+="$entry"
    CHAR_COUNT=$(( CHAR_COUNT + len ))
  else
    BUDGET_HIT=1
  fi
}

BUDGET_HIT=0

load_vault() {
  local vault_name="$1" vault_path="$2"

  if obsidian_running && obsidian_knows_vault "$vault_name"; then
    while IFS= read -r rel; do
      [ -z "$rel" ] && continue
      local content last_mod
      content=$(read_via_obsidian "$vault_name" "$rel")
      last_mod=$(echo "$content" | grep 'last_modified:' | head -1 | sed 's/.*: //')
      append_note "$vault_name/$rel" "$last_mod" "$content"
    done < <(collect_via_obsidian "$vault_name")
  elif [ -d "$vault_path" ]; then
    while IFS= read -r abs; do
      [ -z "$abs" ] && continue
      local rel="${abs#$vault_path/}"
      local last_mod content
      last_mod=$(grep 'last_modified:' "$abs" | head -1 | sed 's/.*: //')
      content=$(read_via_filesystem "$abs")
      append_note "$vault_name/$rel" "$last_mod" "$content"
    done < <(collect_via_filesystem "$vault_path")
  fi
}

load_vault "$GLOBAL_VAULT_NAME" "$GLOBAL_VAULT"
[ -d "$PROJECT_VAULT" ] && load_vault "$PROJECT_VAULT_NAME" "$PROJECT_VAULT"

if [ -n "$OUTPUT" ]; then
  echo "=== KNOWLEDGE BASE CONTEXT (Obsidian vaults) ==="
  echo "$OUTPUT"
  # P2-3: warn when notes were dropped due to budget
  (( BUDGET_HIT )) && echo "--- [KB: budget reached — use kb-search.sh to find additional notes] ---"
  echo "=== END KNOWLEDGE BASE CONTEXT ==="
fi
