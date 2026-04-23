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

mkdir -p "$VAULT_PATH/$CATEGORY"

if obsidian_running && obsidian_knows_vault "$VAULT"; then
  if obsidian files folder="$CATEGORY" vault="$VAULT" 2>/dev/null | grep -q "$SLUG\.md"; then
    # P1-1 fix: update last_modified AND append new content section (not silently discard)
    obsidian property:set name="last_modified" value="$TODAY" path="$REL_PATH" vault="$VAULT" &>/dev/null
    UPDATE_SECTION="\n\n---\n_Updated $TODAY_\n\n$CONTENT"
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
      echo "$FULL_CONTENT" > "$ABS_PATH"
      echo "Created $VAULT/$REL_PATH via filesystem (obsidian create failed)"
    fi
  fi
else
  echo "$FULL_CONTENT" > "$ABS_PATH"
  echo "Created $VAULT/$REL_PATH via filesystem (Obsidian not running or vault not registered)"
fi

# P1-2 fix: write to KB log so kb-session-end.sh can report what was saved
echo "$VAULT/$REL_PATH" >> "$KB_LOG"
