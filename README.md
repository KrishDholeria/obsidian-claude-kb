# obsidian-claude-kb

A persistent second-brain for Claude Code, backed by Obsidian vaults.

## Install

```bash
git clone https://github.com/KrishDholeria/obsidian-claude-kb.git && bash obsidian-claude-kb/install.sh
```

Installs 7 scripts, 7 slash commands, MCP server config, and `SessionStart` / `SessionEnd` / `PostToolUse` hooks — all idempotent.

## What it does

- **Auto-loads context** — `SessionStart` injects `#claude-context` tagged notes from your Global and project vault before every session
- **Slash commands** — `/kb-save`, `/kb-search`, `/kb-outline`, `/kb-health`, `/kb-init`, `/kb-daily`, `/kb-find` available in every Claude Code session
- **Passive capture** — `PostToolUse` tracks every file edited; `SessionEnd` logs the session summary to Obsidian's daily note
- **obsidian-cli primary** — uses semantic `search:context`, `backlinks`, `outline`, `tag`, and `daily:append`; falls back to filesystem when Obsidian isn't running

## Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| [Claude Code](https://claude.ai/code) | Yes | — |
| [Node.js / npx](https://nodejs.org) | Yes | `brew install node` / `apt install nodejs npm` |
| [jq](https://stedolan.github.io/jq/) | Yes | `brew install jq` / `apt install jq` |
| [Obsidian](https://obsidian.md) | Recommended | Download or `snap install obsidian --classic` |
| [obsidian-cli](https://github.com/oroce/obsidian-cli) | Recommended | `npm install -g obsidian-cli` |

## Post-install (manual steps)

1. **Register the Global vault in Obsidian**
   Open Obsidian → Manage vaults → "Open folder as vault" → `~/ObsidianVaults/Global`

2. **Restart Claude Code** to activate the SessionStart hook.
   You'll see: `Loading knowledge base context...`

3. **Edit your always-load note** with your real preferences:
   `~/ObsidianVaults/Global/context/always-load.md`

4. *(Optional)* Install Obsidian plugins: **Dataview** (for `_kb-index.base`) and **Tasks** (for `kb-health` task listing)

## Slash commands

| Command | What it does |
|---------|-------------|
| `/kb-save [vault] [category] [slug] [title] [tags] [content]` | Save a note — Claude infers values from context if not provided |
| `/kb-search <query> [vault] [limit]` | Search vaults using `search:context` with surrounding line context |
| `/kb-outline <vault> <path>` | Get heading tree of a note before reading it |
| `/kb-health [vault]` | Orphans, dead-ends, stale notes, open tasks |
| `/kb-init [project-name]` | Create a vault + `.mcp.json` for the current project |
| `/kb-daily [note]` | Append a finding to today's daily note |
| `/kb-find <tag\|category\|status> <value> [vault]` | Find notes by tag, category, or status |

## Add a project vault

Run inside any project directory:

```bash
/kb-init
```

Or directly:

```bash
bash /path/to/obsidian-claude-kb/project-init.sh
```

Then register the vault in Obsidian (same as step 1).

## Tag reference

| Tag | Behaviour |
|-----|-----------|
| `claude-context` | Auto-injected every session |
| `claude-context-conditional` | Available via `/kb-search`, not auto-injected |
| `adr` | Architecture Decision Record |
| `stale` | Never injected; verify before trusting |
| `draft` | Not yet reliable |

## Vault layout

```
~/ObsidianVaults/
  Global/                  # Every session
    context/               # always-load.md — preferences, conventions
    conventions/           # KB management rules
    patterns/              # Reusable architectural patterns
    tools/                 # Tool configs and CLI references
    explorations/          # Experiments and findings
  <ProjectName>/           # Active project session only
    architecture/          # System design, data flows
    decisions/             # ADRs (template-adr.md)
    runbooks/              # Step-by-step procedures
    context/               # always-load.md — project state
    domain/                # Business domain knowledge
    integrations/          # Third-party API specifics
    sessions/              # Auto-written session logs
    explorations/          # Project-specific experiments
```

## Repo layout

```
obsidian-claude-kb/
  install.sh          # Idempotent installer (scripts + commands + MCP + hooks)
  uninstall.sh        # Removes scripts and hooks; never touches vault notes
  project-init.sh     # Init a vault for the current project
  scripts/            # 7 bash scripts (called by hooks and commands)
  commands/           # 7 Claude Code slash command definitions
  templates/
    global-vault/     # Starter notes for Global vault
    project-vault/    # Starter notes for project vault ({{ProjectName}} substituted at init)
  mcp/                # MCP server config templates
```

## Uninstall

```bash
bash /path/to/obsidian-claude-kb/uninstall.sh
```

Removes scripts, commands, and hook entries. Vault notes are never deleted.
