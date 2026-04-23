#!/usr/bin/env bash
# Get the heading outline of a KB note before deciding whether to read the full content.
# Use this to navigate large notes or read only a specific section.
#
# Usage: kb-outline.sh <vault> <path>
#   vault: Global | <ProjectName>  (ProjectName = basename of project dir)
#   path:  relative path within vault (e.g. architecture/data-pipeline.md)
#
# Example: kb-outline.sh MyProject architecture/data-pipeline.md

VAULT="${1:?vault required}"
PATH_ARG="${2:?path required}"

obsidian_running() { obsidian version &>/dev/null; }
obsidian_knows_vault() { obsidian vaults 2>/dev/null | awk '{print $1}' | grep -qx "$1"; }

if obsidian_running && obsidian_knows_vault "$VAULT"; then
  obsidian outline path="$PATH_ARG" vault="$VAULT" format=json 2>/dev/null \
    | python3 -c "
import json, sys
try:
    headings = json.load(sys.stdin)
    for h in headings:
        indent = '  ' * (h['level'] - 1)
        print(f'{indent}[L{h[\"level\"]} line {h[\"line\"]}] {h[\"heading\"]}')
except: pass
" 2>/dev/null
else
  # Filesystem fallback: grep headings
  ABS="$HOME/ObsidianVaults/$VAULT/$PATH_ARG"
  grep -n '^#' "$ABS" 2>/dev/null | while IFS=: read -r line text; do
    level=$(echo "$text" | grep -o '^#*' | wc -c)
    level=$(( level - 1 ))
    indent=$(printf '%*s' "$level" '')
    heading=$(echo "$text" | sed 's/^#* //')
    echo "${indent}[L${level} line ${line}] $heading"
  done
fi
