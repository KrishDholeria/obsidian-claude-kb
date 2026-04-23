#!/usr/bin/env bash
# obsidian-claude-kb installer
# Idempotent — safe to run multiple times.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULTS_DIR="$HOME/ObsidianVaults"
SCRIPTS_DIR="$HOME/.claude/scripts"
GLOBAL_MCP="$HOME/.mcp.json"
SETTINGS="$HOME/.claude/settings.json"

# ── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}[ok]${RESET}  $*"; }
warn() { echo -e "${YELLOW}[warn]${RESET} $*"; }
info() { echo -e "      $*"; }

echo ""
echo "obsidian-claude-kb — installing"
echo "================================"
echo ""

# ── 1. Dependency checks ─────────────────────────────────────────────────────
echo "Checking dependencies..."

if command -v obsidian &>/dev/null; then
  ok "obsidian-cli found ($(obsidian version 2>/dev/null || echo 'version unknown'))"
else
  warn "obsidian-cli not found. Scripts will fall back to filesystem mode."
  info "Install: npm install -g obsidian-cli  (or follow https://github.com/oroce/obsidian-cli)"
fi

if command -v npx &>/dev/null; then
  ok "npx found"
else
  warn "npx not found — MCP servers use npx. Install Node.js from https://nodejs.org"
fi

if command -v jq &>/dev/null; then
  ok "jq found"
else
  warn "jq not found — MCP/hook merging will be skipped. Install: sudo apt install jq  OR  brew install jq"
  JQ_MISSING=1
fi

JQ_MISSING="${JQ_MISSING:-0}"
echo ""

# ── 2. Create Global vault from templates (skip if already exists) ─────────────
echo "Setting up Global vault..."

GLOBAL_VAULT="$VAULTS_DIR/Global"
if [ -d "$GLOBAL_VAULT" ]; then
  ok "Global vault already exists at $GLOBAL_VAULT — skipping"
else
  mkdir -p "$GLOBAL_VAULT"
  cp -r "$REPO_DIR/templates/global-vault/." "$GLOBAL_VAULT/"
  ok "Created Global vault at $GLOBAL_VAULT"
fi
echo ""

# ── 3. Copy scripts ────────────────────────────────────────────────────────────
echo "Installing scripts to $SCRIPTS_DIR..."
mkdir -p "$SCRIPTS_DIR"

for script in load-vault.sh kb-save.sh kb-search.sh kb-outline.sh kb-session-end.sh kb-health.sh kb-capture.sh; do
  src="$REPO_DIR/scripts/$script"
  dst="$SCRIPTS_DIR/$script"
  if [ -f "$dst" ] && diff -q "$src" "$dst" &>/dev/null; then
    ok "$script — already up to date"
  else
    cp "$src" "$dst"
    chmod +x "$dst"
    ok "$script — installed"
  fi
done
echo ""

# ── 4. Merge MCP servers into ~/.mcp.json ─────────────────────────────────────
echo "Merging MCP servers into $GLOBAL_MCP..."

if [ "$JQ_MISSING" = "1" ]; then
  warn "Skipping MCP merge — jq not installed"
else
  VAULTS_PATH_ESCAPED=$(echo "$VAULTS_DIR" | sed 's|/|\\/|g')

  # Build the two server entries with the real vault path substituted
  NEW_SERVERS=$(jq -n \
    --arg vaults "$VAULTS_DIR" \
    '{
      "obsidian-cli": {
        "command": "npx",
        "args": ["-y", "mcp-obsidian-cli"],
        "env": {}
      },
      "obsidian-global-fs": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", ($vaults + "/Global")],
        "env": {}
      }
    }')

  if [ -f "$GLOBAL_MCP" ]; then
    # Merge: existing entries win; only add keys that are missing
    MERGED=$(jq --argjson new "$NEW_SERVERS" \
      '.mcpServers = ($new + .mcpServers)' "$GLOBAL_MCP")
    echo "$MERGED" > "$GLOBAL_MCP"
    ok "Merged MCP servers into existing $GLOBAL_MCP"
  else
    echo '{"mcpServers":{}}' | jq --argjson new "$NEW_SERVERS" \
      '.mcpServers = $new' > "$GLOBAL_MCP"
    ok "Created $GLOBAL_MCP with MCP servers"
  fi
fi
echo ""

# ── 5. Merge hooks into ~/.claude/settings.json ───────────────────────────────
echo "Merging hooks into $SETTINGS..."

if [ "$JQ_MISSING" = "1" ]; then
  warn "Skipping hook merge — jq not installed"
elif [ ! -f "$SETTINGS" ]; then
  warn "$SETTINGS not found — creating minimal settings with hooks"
  mkdir -p "$(dirname "$SETTINGS")"
  cat > "$SETTINGS" <<EOF
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $SCRIPTS_DIR/load-vault.sh",
            "timeout": 10,
            "statusMessage": "Loading knowledge base context..."
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $SCRIPTS_DIR/kb-session-end.sh",
            "timeout": 10,
            "statusMessage": "Logging session to daily note..."
          }
        ]
      }
    ]
  }
}
EOF
  ok "Created $SETTINGS with SessionStart + SessionEnd hooks"
else
  # SessionStart: add load-vault.sh if not already present
  LOAD_CMD="bash $SCRIPTS_DIR/load-vault.sh"
  HAS_LOAD=$(jq --arg cmd "$LOAD_CMD" \
    '[.hooks.SessionStart[]?.hooks[]?.command] | map(select(. == $cmd)) | length' \
    "$SETTINGS" 2>/dev/null || echo "0")

  if [ "$HAS_LOAD" = "0" ]; then
    UPDATED=$(jq --arg cmd "$LOAD_CMD" \
      '.hooks.SessionStart //= [] |
       .hooks.SessionStart += [{
         "hooks": [{
           "type": "command",
           "command": $cmd,
           "timeout": 10,
           "statusMessage": "Loading knowledge base context..."
         }]
       }]' "$SETTINGS")
    echo "$UPDATED" > "$SETTINGS"
    ok "Added SessionStart → load-vault.sh"
  else
    ok "SessionStart → load-vault.sh already present"
  fi

  # SessionEnd: add kb-session-end.sh if not already present
  END_CMD="bash $SCRIPTS_DIR/kb-session-end.sh"
  HAS_END=$(jq --arg cmd "$END_CMD" \
    '[.hooks.SessionEnd[]?.hooks[]?.command] | map(select(. == $cmd)) | length' \
    "$SETTINGS" 2>/dev/null || echo "0")

  if [ "$HAS_END" = "0" ]; then
    UPDATED=$(jq --arg cmd "$END_CMD" \
      '.hooks.SessionEnd //= [] |
       .hooks.SessionEnd += [{
         "hooks": [{
           "type": "command",
           "command": $cmd,
           "timeout": 10,
           "statusMessage": "Logging session to daily note..."
         }]
       }]' "$SETTINGS")
    echo "$UPDATED" > "$SETTINGS"
    ok "Added SessionEnd → kb-session-end.sh"
  else
    ok "SessionEnd → kb-session-end.sh already present"
  fi

  # PostToolUse: add kb-capture.sh on Write|Edit if not already present
  CAPTURE_CMD="bash $SCRIPTS_DIR/kb-capture.sh"
  HAS_CAPTURE=$(jq --arg cmd "$CAPTURE_CMD" \
    '[.hooks.PostToolUse[]?.hooks[]?.command] | map(select(. == $cmd)) | length' \
    "$SETTINGS" 2>/dev/null || echo "0")

  if [ "$HAS_CAPTURE" = "0" ]; then
    UPDATED=$(jq --arg cmd "$CAPTURE_CMD" \
      '.hooks.PostToolUse //= [] |
       .hooks.PostToolUse += [{
         "matcher": "Write|Edit",
         "hooks": [{
           "type": "command",
           "command": $cmd,
           "timeout": 5,
           "async": true
         }]
       }]' "$SETTINGS")
    echo "$UPDATED" > "$SETTINGS"
    ok "Added PostToolUse(Write|Edit) → kb-capture.sh"
  else
    ok "PostToolUse → kb-capture.sh already present"
  fi
fi
echo ""

# ── 6. Post-install checklist ─────────────────────────────────────────────────
echo "================================"
echo "Installation complete."
echo "================================"
echo ""
echo "Next steps (manual):"
echo ""
echo "  1. Register the Global vault in Obsidian:"
echo "     Open Obsidian → Manage vaults → Open folder as vault"
echo "     Path: $GLOBAL_VAULT"
echo ""
echo "  2. (Optional) Install Obsidian plugins for best experience:"
echo "     - Dataview  (powers _kb-index.base queries)"
echo "     - Tasks     (powers open-tasks in kb-health.sh)"
echo ""
echo "  3. Start a new Claude Code session to verify SessionStart hook fires:"
echo "     You should see: 'Loading knowledge base context...'"
echo ""
echo "  4. To add a new project vault, run inside your project directory:"
echo "     bash $REPO_DIR/project-init.sh"
echo ""
echo "  5. Edit the always-load.md in your Global vault to add your preferences:"
echo "     $GLOBAL_VAULT/context/always-load.md"
echo ""
