---
description: Initialize an Obsidian KB vault for the current project
argument-hint: [project-name]
---

Set up a new Obsidian knowledge vault for a project and wire it into Claude Code.

## Arguments

`$ARGUMENTS` — optional project name override. If empty, uses the current directory name.

## Steps

1. Determine the project name:
   - Use `$ARGUMENTS` if provided
   - Otherwise use `basename` of the current working directory

2. Run the project initializer:

```bash
bash /home/krish/Desktop/Projects/obsidian-claude-kb/project-init.sh "$PROJECT_NAME"
```

If the obsidian-claude-kb repo isn't available locally, run the inline steps instead:

```bash
PROJ_NAME="${ARGUMENTS:-$(basename $(pwd))}"
VAULT_DIR="$HOME/ObsidianVaults/$PROJ_NAME"
TEMPLATE_DIR="$HOME/Desktop/Projects/obsidian-claude-kb/templates/project-vault"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$VAULT_DIR"
cp -r "$TEMPLATE_DIR/." "$VAULT_DIR/"

# Substitute placeholders
find "$VAULT_DIR" -name "*.md" -exec sed -i "s/{{ProjectName}}/$PROJ_NAME/g; s/{{TODAY}}/$TODAY/g" {} +

echo "Vault created at $VAULT_DIR"
```

3. Create `.mcp.json` in the current project directory if it doesn't exist:

```bash
cat > .mcp.json <<EOF
{
  "mcpServers": {
    "obsidian-cli": {
      "command": "npx",
      "args": ["-y", "mcp-obsidian-cli"],
      "env": {}
    },
    "obsidian-project-fs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$HOME/ObsidianVaults"],
      "env": {}
    }
  }
}
EOF
```

4. Report what was created:
   - Vault path
   - Folder structure
   - Which `.mcp.json` was created/updated

5. Remind the user of the one manual step:
   > Open Obsidian → Manage Vaults → "Open folder as vault" → select `~/ObsidianVaults/<ProjectName>`
   > Once registered, obsidian-cli will have full access (search:context, backlinks, tag queries).
