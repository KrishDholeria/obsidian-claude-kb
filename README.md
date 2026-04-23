# obsidian-claude-kb

A persistent second-brain for Claude Code, backed by Obsidian vaults.

## One-liner install

```bash
git clone https://github.com/YOUR_USERNAME/obsidian-claude-kb.git && bash obsidian-claude-kb/install.sh
```

## What it does

- **Auto-loads context** — a `SessionStart` hook injects notes tagged `#claude-context` from your Global vault (and active project vault) at the start of every Claude Code session, so Claude already knows your preferences, conventions, and project state.
- **Persists knowledge** — Claude writes discoveries, decisions, and patterns back to your vault via `kb-save.sh`. Session activity is logged to Obsidian's daily note on `SessionEnd`.
- **Works offline** — scripts have a filesystem fallback for when Obsidian isn't running; obsidian-cli is used as the primary path for semantic search and graph traversal.

## Prerequisites

| Tool | Required | Purpose |
|------|----------|---------|
| [Claude Code](https://claude.ai/code) | Yes | The CLI this extends |
| [Node.js / npx](https://nodejs.org) | Yes | Runs MCP servers |
| [jq](https://stedolan.github.io/jq/) | Yes | JSON config merging |
| [Obsidian](https://obsidian.md) | Recommended | Vault UI, graph, search |
| [obsidian-cli](https://github.com/oroce/obsidian-cli) | Recommended | Semantic search + daily notes |

Install on macOS: `brew install jq node` and `npm install -g obsidian-cli`
Install on Linux: `sudo apt install jq nodejs npm` and `npm install -g obsidian-cli`

## Post-install steps

After running `install.sh`:

1. **Register the Global vault in Obsidian**
   Open Obsidian → Manage vaults → "Open folder as vault"
   Path: `~/ObsidianVaults/Global`

2. **Restart Claude Code** (or start a new session) to activate the `SessionStart` hook.
   You'll see: `Loading knowledge base context...`

3. **Edit your always-load note** to add your real preferences:
   `~/ObsidianVaults/Global/context/always-load.md`

4. *(Optional)* Install Obsidian plugins: **Dataview** (for `_kb-index.base` queries) and **Tasks** (for open-task surfacing in `kb-health.sh`).

## Adding a new project

Run inside any project directory:

```bash
bash /path/to/obsidian-claude-kb/project-init.sh
```

This creates `~/ObsidianVaults/<ProjectName>/` from the template, writes `.mcp.json` into the current directory, and prints registration instructions.

Then register the new vault in Obsidian (same as step 1 above).

## Using the scripts

### Save a note

```bash
bash ~/.claude/scripts/kb-save.sh \
  "<vault>" "<category>" "<slug>" "<title>" "<tags>" "<content>"

# Examples:
bash ~/.claude/scripts/kb-save.sh \
  "Global" "patterns" "retry-with-backoff" \
  "Exponential backoff retry pattern" \
  "claude-context-conditional" \
  "Always use exponential backoff with jitter for external API calls..."

bash ~/.claude/scripts/kb-save.sh \
  "MyProject" "decisions" "why-postgres-not-mongo" \
  "Why PostgreSQL over MongoDB" \
  "adr,claude-context-conditional" \
  "Chose Postgres because of JSONB + relational joins needed for reporting..."
```

Vault names: `Global` or the basename of your project directory (e.g. `MyProject`).

Categories for Global: `patterns`, `tools`, `conventions`, `context`, `explorations`
Categories for projects: `architecture`, `decisions`, `runbooks`, `context`, `domain`, `integrations`, `sessions`, `explorations`

### Search the vault

```bash
# Search everywhere
bash ~/.claude/scripts/kb-search.sh "retry logic"

# Search a specific vault
bash ~/.claude/scripts/kb-search.sh "SQS queue" MyProject

# Limit results
bash ~/.claude/scripts/kb-search.sh "auth flow" Global 3
```

### Get a note's heading outline (before reading a large file)

```bash
bash ~/.claude/scripts/kb-outline.sh MyProject architecture/data-pipeline.md
bash ~/.claude/scripts/kb-outline.sh Global conventions/kb-management.md
```

### Check vault health

Surfaces orphaned notes, dead-ends, stale notes (last_modified > 60 days), and open tasks.

```bash
# Check all vaults
bash ~/.claude/scripts/kb-health.sh

# Check a specific vault
bash ~/.claude/scripts/kb-health.sh MyProject
bash ~/.claude/scripts/kb-health.sh Global
```

Requires Obsidian to be running (uses obsidian-cli for orphan/deadend detection).

## Tag reference

| Tag | Meaning |
|-----|---------|
| `claude-context` | Injected automatically every session |
| `claude-context-conditional` | Available via search, not auto-injected |
| `adr` | Architecture Decision Record |
| `stale` | Do not inject; verify before trusting |
| `draft` | Work in progress; not yet reliable |

## Vault layout

```
~/ObsidianVaults/
  Global/                  # Loaded in every Claude Code session
    context/               # always-load.md — your preferences
    conventions/           # KB management rules, style guides
    patterns/              # Reusable architectural patterns
    tools/                 # Tool configs, CLI references
    explorations/          # Experiments and findings
  <ProjectName>/           # Loaded when Claude Code opens that project
    architecture/          # System design, data flows
    decisions/             # ADRs
    runbooks/              # Step-by-step procedures
    context/               # always-load.md — project state
    domain/                # Business domain knowledge
    integrations/          # Third-party API specifics
    sessions/              # Auto-written by kb-session-end.sh
    explorations/          # Experiments specific to this project
```

## Uninstall

Removes scripts and hooks. Your vault notes are never touched.

```bash
bash /path/to/obsidian-claude-kb/uninstall.sh
```

## How it works

1. **`SessionStart` hook** (`load-vault.sh`) — queries obsidian-cli for `#claude-context` notes in Global + project vault, respects a 24 000-character budget, truncates notes > 80 lines with a marker, and prints them as a fenced block Claude reads before the first user message.
2. **`SessionEnd` hook** (`kb-session-end.sh`) — appends a timestamped entry to Obsidian's daily note listing the project, git commits from the last 4 hours, and any KB notes written during the session.
3. **MCP servers** — `obsidian-cli` MCP enables Claude to do semantic `search:context`, `backlinks`, `outline`, `property:set`, and `daily:append` calls directly. The filesystem MCP (`obsidian-global-fs` / `obsidian-project-fs`) is the silent fallback.
