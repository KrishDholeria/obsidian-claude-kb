#!/usr/bin/env bash
# KB health check: surfaces orphaned notes, stale entries, and open KB tasks.
# Run manually: bash ~/.claude/scripts/kb-health.sh [vault]
# Requires Obsidian to be running.

VAULT_ARG="${1:-all}"
PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJ_NAME=$(basename "$PROJ_DIR")

obsidian_running() { obsidian version &>/dev/null; }
obsidian_knows_vault() { obsidian vaults 2>/dev/null | awk '{print $1}' | grep -qx "$1"; }

if ! obsidian_running; then
  echo "Obsidian is not running. Start Obsidian to run KB health check."
  exit 1
fi

check_vault() {
  local vault_name="$1"
  obsidian_knows_vault "$vault_name" || { echo "Vault '$vault_name' not registered in Obsidian."; return; }

  echo "========================================"
  echo "  KB Health: $vault_name"
  echo "========================================"

  echo ""
  echo "### Stale Notes (status: stale)"
  STALE=$(grep -rl --include="*.md" 'status: stale' "$HOME/ObsidianVaults/$vault_name" 2>/dev/null)
  if [ -n "$STALE" ]; then
    echo "$STALE" | while read -r f; do
      last_mod=$(grep 'last_modified:' "$f" | head -1 | sed 's/.*: //')
      echo "  - ${f#$HOME/ObsidianVaults/$vault_name/} (last_modified: $last_mod)"
    done
  else
    echo "  None"
  fi

  echo ""
  echo "### Orphaned Notes (no incoming links)"
  orphans_out=$(obsidian orphans vault="$vault_name" 2>/dev/null)
  if [ -n "$orphans_out" ]; then
    echo "$orphans_out" | grep '\.md$' | grep -v '_index' | head -10 | sed 's/^/  - /'
  else
    echo "  None"
  fi

  echo ""
  echo "### Dead-end Notes (no outgoing links)"
  deadends_out=$(obsidian deadends vault="$vault_name" 2>/dev/null)
  if [ -n "$deadends_out" ]; then
    echo "$deadends_out" | grep '\.md$' | grep -v '_index' | head -10 | sed 's/^/  - /'
  else
    echo "  None"
  fi

  echo ""
  echo "### Potentially Stale (last_modified > 60 days ago)"
  CUTOFF=$(date -d "60 days ago" +%Y-%m-%d 2>/dev/null || date -v-60d +%Y-%m-%d 2>/dev/null)
  find "$HOME/ObsidianVaults/$vault_name" -name "*.md" | while read -r f; do
    last_mod=$(grep 'last_modified:' "$f" | head -1 | sed 's/.*last_modified: //')
    # P2-5 fix: guard against malformed or placeholder dates before comparing
    [[ "$last_mod" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
    [[ "$last_mod" < "$CUTOFF" ]] && echo "  - ${f#$HOME/ObsidianVaults/$vault_name/} ($last_mod)"
  done | head -10

  echo ""
  echo "### Open KB Tasks"
  obsidian tasks todo vault="$vault_name" format=json 2>/dev/null \
    | python3 -c "
import json, sys
try:
    tasks = json.load(sys.stdin)
    for t in tasks[:10]:
        print(f'  [{t[\"file\"]}:{t[\"line\"]}] {t[\"text\"].strip()}')
    if not tasks:
        print('  None')
except:
    print('  (error reading tasks)')
" 2>/dev/null

  echo ""
}

case "$VAULT_ARG" in
  all)
    check_vault "Global"
    [ -d "$HOME/ObsidianVaults/$PROJ_NAME" ] && check_vault "$PROJ_NAME"
    ;;
  *) check_vault "$VAULT_ARG" ;;
esac
