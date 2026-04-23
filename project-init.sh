#!/usr/bin/env bash
# Initialize a project vault for the current directory.
# Run from inside your project directory.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_DIR="$(pwd)"
PROJ_NAME=$(basename "$PROJ_DIR")
VAULTS_DIR="$HOME/ObsidianVaults"
PROJECT_VAULT="$VAULTS_DIR/$PROJ_NAME"
TODAY=$(date +%Y-%m-%d)

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}[ok]${RESET}  $*"; }
warn() { echo -e "${YELLOW}[warn]${RESET} $*"; }
info() { echo -e "      $*"; }

echo ""
echo "obsidian-claude-kb — project init"
echo "==================================="
echo "Project:  $PROJ_NAME"
echo "Dir:      $PROJ_DIR"
echo "Vault:    $PROJECT_VAULT"
echo ""

# ── 1. Create project vault from template ─────────────────────────────────────
if [ -d "$PROJECT_VAULT" ]; then
  ok "Vault already exists at $PROJECT_VAULT — skipping creation"
else
  mkdir -p "$PROJECT_VAULT"

  # Copy template, substituting {{ProjectName}} and {{TODAY}} placeholders
  cp -r "$REPO_DIR/templates/project-vault/." "$PROJECT_VAULT/"

  # Replace placeholders in all markdown files
  find "$PROJECT_VAULT" -name "*.md" | while read -r f; do
    sed -i "s/{{ProjectName}}/$PROJ_NAME/g; s/{{TODAY}}/$TODAY/g" "$f"
  done

  ok "Created project vault at $PROJECT_VAULT"
fi
echo ""

# ── 2. Add .mcp.json to project directory ─────────────────────────────────────
MCP_FILE="$PROJ_DIR/.mcp.json"

if command -v jq &>/dev/null; then
  NEW_SERVERS=$(jq -n \
    --arg vaults "$VAULTS_DIR" \
    '{
      "obsidian-cli": {
        "command": "npx",
        "args": ["-y", "mcp-obsidian-cli"],
        "env": {}
      },
      "obsidian-project-fs": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", $vaults],
        "env": {}
      }
    }')

  if [ -f "$MCP_FILE" ]; then
    # Merge: existing entries win
    MERGED=$(jq --argjson new "$NEW_SERVERS" \
      '.mcpServers = ($new + .mcpServers)' "$MCP_FILE")
    echo "$MERGED" > "$MCP_FILE"
    ok "Merged MCP servers into existing $MCP_FILE"
  else
    echo '{"mcpServers":{}}' | jq --argjson new "$NEW_SERVERS" \
      '.mcpServers = $new' > "$MCP_FILE"
    ok "Created $MCP_FILE"
  fi
else
  warn "jq not found — writing .mcp.json template (edit OBSIDIAN_VAULTS_PATH manually)"
  if [ ! -f "$MCP_FILE" ]; then
    cp "$REPO_DIR/mcp/project.mcp.json" "$MCP_FILE"
    sed -i "s|OBSIDIAN_VAULTS_PATH|$VAULTS_DIR|g" "$MCP_FILE"
    ok "Created $MCP_FILE"
  else
    warn "$MCP_FILE already exists — not overwriting (jq unavailable for safe merge)"
  fi
fi
echo ""

# ── 3. Instructions ────────────────────────────────────────────────────────────
echo "================================"
echo "Project vault ready."
echo "================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Register the vault in Obsidian:"
echo "     Open Obsidian → Manage vaults → Open folder as vault"
echo "     Path: $PROJECT_VAULT"
echo ""
echo "  2. Edit the always-load context note to describe your project:"
echo "     $PROJECT_VAULT/context/always-load.md"
echo ""
echo "  3. The project .mcp.json has been written to:"
echo "     $MCP_FILE"
echo "     Claude Code will pick it up automatically in this project directory."
echo ""
echo "  4. Save knowledge during sessions:"
echo "     bash ~/.claude/scripts/kb-save.sh \"$PROJ_NAME\" \"decisions\" \"slug\" \"Title\" \"tags\" \"content\""
echo ""
echo "  5. Search across this project's vault:"
echo "     bash ~/.claude/scripts/kb-search.sh \"your query\" \"$PROJ_NAME\""
echo ""
