#!/usr/bin/env bash
# obsidian-claude-kb uninstaller
# Removes scripts and hooks. Does NOT delete vault data (your notes are safe).
set -euo pipefail

SCRIPTS_DIR="$HOME/.claude/scripts"
SETTINGS="$HOME/.claude/settings.json"
GLOBAL_MCP="$HOME/.mcp.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}[ok]${RESET}  $*"; }
warn() { echo -e "${YELLOW}[warn]${RESET} $*"; }

echo ""
echo "obsidian-claude-kb — uninstalling"
echo "==================================="
echo ""
echo "NOTE: Vault data in ~/ObsidianVaults/ is NOT touched."
echo ""

# ── Remove scripts ────────────────────────────────────────────────────────────
for script in load-vault.sh kb-save.sh kb-search.sh kb-outline.sh kb-session-end.sh kb-health.sh; do
  target="$SCRIPTS_DIR/$script"
  if [ -f "$target" ]; then
    rm "$target"
    ok "Removed $target"
  fi
done

# ── Remove hooks from settings.json ──────────────────────────────────────────
if command -v jq &>/dev/null && [ -f "$SETTINGS" ]; then
  LOAD_CMD="bash $SCRIPTS_DIR/load-vault.sh"
  END_CMD="bash $SCRIPTS_DIR/kb-session-end.sh"

  UPDATED=$(jq \
    --arg load "$LOAD_CMD" \
    --arg end "$END_CMD" \
    '
    if .hooks.SessionStart then
      .hooks.SessionStart |= map(.hooks |= map(select(.command != $load)) | select(length > 0)) |
      .hooks.SessionStart |= (if length == 0 then empty else . end)
    else . end |
    if .hooks.SessionEnd then
      .hooks.SessionEnd |= map(.hooks |= map(select(.command != $end)) | select(length > 0)) |
      .hooks.SessionEnd |= (if length == 0 then empty else . end)
    else . end
    ' "$SETTINGS" 2>/dev/null)

  if [ -n "$UPDATED" ]; then
    echo "$UPDATED" > "$SETTINGS"
    ok "Removed KB hooks from $SETTINGS"
  else
    warn "Could not parse $SETTINGS — hooks left in place"
  fi
else
  warn "jq not found or $SETTINGS missing — hooks not removed"
fi

# ── Remove MCP servers from ~/.mcp.json ──────────────────────────────────────
if command -v jq &>/dev/null && [ -f "$GLOBAL_MCP" ]; then
  UPDATED=$(jq 'del(.mcpServers["obsidian-cli"], .mcpServers["obsidian-global-fs"])' "$GLOBAL_MCP" 2>/dev/null)
  if [ -n "$UPDATED" ]; then
    echo "$UPDATED" > "$GLOBAL_MCP"
    ok "Removed obsidian-cli and obsidian-global-fs from $GLOBAL_MCP"
  fi
fi

echo ""
echo "Uninstall complete."
echo "Your vault data in ~/ObsidianVaults/ is untouched."
echo ""
