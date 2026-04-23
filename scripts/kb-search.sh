#!/usr/bin/env bash
# Search KB using obsidian-cli search:context — finds notes relevant to a concept.
# Returns matching notes with surrounding line context, ranked by match count.
# Falls back to filesystem grep when Obsidian is not running.
#
# Usage: kb-search.sh <query> [vault] [limit]
#   query:  search term or concept
#   vault:  Global | <ProjectName> | all (default: all)
#   limit:  max files to return (default: 5)

QUERY="${1:?query required}"
VAULT_ARG="${2:-all}"
LIMIT="${3:-5}"

GLOBAL_VAULT="$HOME/ObsidianVaults/Global"
PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJ_NAME=$(basename "$PROJ_DIR")
PROJECT_VAULT="$HOME/ObsidianVaults/$PROJ_NAME"

obsidian_running() { obsidian version &>/dev/null; }
obsidian_knows_vault() { obsidian vaults 2>/dev/null | awk '{print $1}' | grep -qx "$1"; }

search_obsidian() {
  local vault_name="$1"
  obsidian search:context query="$QUERY" vault="$vault_name" limit="$LIMIT" format=json 2>/dev/null \
    | python3 -c "
import json, sys
try:
    results = json.load(sys.stdin)
    for r in results:
        f = r.get('file','')
        matches = r.get('matches', [])
        print(f'## {f} ({len(matches)} match(es))')
        for m in matches:
            print(f'  line {m[\"line\"]}: {m[\"text\"].strip()}')
        print()
except Exception as e:
    pass
" 2>/dev/null
}

search_filesystem() {
  local vault_path="$1"
  local vault_name="$2"
  grep -rl --include="*.md" -i "$QUERY" "$vault_path" 2>/dev/null \
    | head -"$LIMIT" \
    | while read -r f; do
        rel="${f#$vault_path/}"
        echo "## $vault_name/$rel"
        grep -n -i "$QUERY" "$f" | head -5 | while IFS=: read -r line text; do
          echo "  line $line: $text"
        done
        echo
      done
}

run_search() {
  local vault_name="$1"
  local vault_path="$2"
  echo "### Vault: $vault_name"
  if obsidian_running && obsidian_knows_vault "$vault_name"; then
    search_obsidian "$vault_name"
  elif [ -d "$vault_path" ]; then
    search_filesystem "$vault_path" "$vault_name"
  else
    echo "(vault not available)"
  fi
}

echo "=== KB SEARCH: \"$QUERY\" ==="
echo

case "$VAULT_ARG" in
  Global) run_search "Global" "$GLOBAL_VAULT" ;;
  all)
    run_search "Global" "$GLOBAL_VAULT"
    # FIX: use if-then instead of && to avoid exit code 1 when project vault doesn't exist
    if [ -d "$PROJECT_VAULT" ]; then
      run_search "$PROJ_NAME" "$PROJECT_VAULT"
    fi
    ;;
  *)
    run_search "$VAULT_ARG" "$HOME/ObsidianVaults/$VAULT_ARG"
    ;;
esac
