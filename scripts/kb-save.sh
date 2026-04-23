#!/usr/bin/env bash
# Save a knowledge note to the correct vault and category.
# PRIMARY: obsidian-cli (create/append with full Obsidian graph awareness)
# FALLBACK: direct filesystem write (when Obsidian not running)
#
# Usage: kb-save.sh <vault> <category> <slug> <title> <tags> <content>
#
# vault:    Global | <ProjectName>  (ProjectName = basename of project dir)
# category: patterns | tools | conventions | context | explorations |
#           architecture | decisions | runbooks | integrations | domain | sessions
# slug:     kebab-case filename (no .md)
# title:    Human-readable title
# tags:     comma-separated (e.g. "claude-context,adr") — empty string for none
# content:  Note body (markdown)

VAULT="${1:?vault required}"
CATEGORY="${2:?category required}"
SLUG="${3:?slug required}"
TITLE="${4:?title required}"
TAGS="${5:-}"
CONTENT="${6:?content required}"

TODAY=$(date +%Y-%m-%d)
VAULT_PATH="$HOME/ObsidianVaults/$VAULT"
REL_PATH="$CATEGORY/$SLUG.md"
ABS_PATH="$VAULT_PATH/$REL_PATH"
KB_LOG="/tmp/claude-kb-writes-$TODAY.log"

# P1-4 fix: empty tags → `tags: []` not null
if [ -n "$TAGS" ]; then
  TAGS_YAML="tags:
$(echo "$TAGS" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/^/  - /')"
else
  TAGS_YAML="tags: []"
fi

FULL_CONTENT="---
title: $TITLE
category: $CATEGORY
$TAGS_YAML
last_modified: $TODAY
status: active
references: []
---

$CONTENT"

obsidian_running() { obsidian version &>/dev/null; }
obsidian_knows_vault() { obsidian vaults 2>/dev/null | awk '{print $1}' | grep -qx "$1"; }

# FIX: detect active vault once — obsidian-cli vault= param is silently ignored
ACTIVE_VAULT=$(obsidian_running && obsidian vault info=name 2>/dev/null | tr -d '\n' || echo "")

mkdir -p "$VAULT_PATH/$CATEGORY"

# FIX: only use obsidian-cli for the active vault; fall back to filesystem for non-active vaults
if obsidian_running && obsidian_knows_vault "$VAULT" && [ "$VAULT" = "$ACTIVE_VAULT" ]; then
  if obsidian files folder="$CATEGORY" vault="$VAULT" 2>/dev/null | grep -q "$SLUG\.md"; then
    # P1-1 fix: update last_modified AND append new content section (not silently discard)
    obsidian property:set name="last_modified" value="$TODAY" path="$REL_PATH" vault="$VAULT" &>/dev/null
    # FIX Bug A: use $'\n' so newlines expand; FIX Bug B: use ${TODAY} not $TODAY_
    UPDATE_SECTION=$'\n\n---\n'"_Updated ${TODAY}_"$'\n\n'"${CONTENT}"
    if obsidian append path="$REL_PATH" vault="$VAULT" content="$UPDATE_SECTION" &>/dev/null; then
      echo "Updated $VAULT/$REL_PATH via obsidian-cli"
    else
      printf '\n\n---\n_Updated %s_\n\n%s\n' "$TODAY" "$CONTENT" >> "$ABS_PATH"
      echo "Updated $VAULT/$REL_PATH via filesystem (obsidian append failed)"
    fi
  else
    if obsidian create path="$REL_PATH" content="$FULL_CONTENT" vault="$VAULT" &>/dev/null; then
      echo "Created $VAULT/$REL_PATH via obsidian-cli"
    else
      printf '%s\n' "$FULL_CONTENT" > "$ABS_PATH"
      echo "Created $VAULT/$REL_PATH via filesystem (obsidian create failed)"
    fi
  fi
else
  printf '%s\n' "$FULL_CONTENT" > "$ABS_PATH"
  echo "Created $VAULT/$REL_PATH via filesystem (Obsidian not running, vault not registered, or not active vault)"
fi

# P1-2 fix: write to KB log so kb-session-end.sh can report what was saved
echo "$VAULT/$REL_PATH" >> "$KB_LOG"

# IMPROVEMENT: find related notes and echo suggestions (does not modify the note)
add_wikilinks() {
  local vault_name="$1" slug="$2" title="$3" vault_path="$4"
  local keywords
  keywords=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ' | tr ' ' '\n' | grep -v '^.\{0,3\}$' | head -3 | tr '\n' ' ')

  local related=""
  for kw in $keywords; do
    local hits
    hits=$(grep -rl --include="*.md" -i "$kw" "$vault_path" 2>/dev/null | grep -v "/$slug\.md" | head -3)
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      local rel_hit="${hit#$vault_path/}"
      local note_slug="${rel_hit%.md}"
      local note_title
      note_title=$(grep '^title:' "$hit" | head -1 | sed 's/title: *//')
      [ -n "$note_title" ] && related="$related [[$note_slug|$note_title]]"
    done <<< "$hits"
  done

  if [ -n "$related" ]; then
    echo "  Related notes:$related"
  fi
}

if [ -d "$VAULT_PATH" ]; then
  add_wikilinks "$VAULT" "$SLUG" "$TITLE" "$VAULT_PATH"
fi
