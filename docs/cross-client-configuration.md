# Cross-Client Claude Configuration

How to keep Claude informed across all clients: Claude Code, claude.ai (web/desktop/mobile), and future tools. Each client has different mechanisms for persistent instructions and MCP access.

## Client Landscape

| Client | Instructions Source | MCP Access | Auto-Sync |
|--------|-------------------|------------|-----------|
| **Claude Code** (CLI/VS Code) | `~/.claude/CLAUDE.md` + rules/ + skills/ | `~/.claude.json` + `claude mcp add` | SessionStart hook auto-pulls DevKit |
| **claude.ai Web** | Profile Preferences + Project instructions + knowledge files | Custom Connectors | Manual (re-upload files when they change) |
| **claude.ai Desktop** | Same as web | Same as web | Manual |
| **claude.ai Mobile** | Same as web | Same as web | Manual |

## Claude Code (Automatic via DevKit)

Claude Code gets the richest context automatically:

1. **SessionStart hook** pulls latest DevKit on each new session (rate-limited to 1/hour)
2. **Symlinks** from `~/.claude/` point to the DevKit clone, so pulled changes are instantly live
3. **Rules files** (11 files, 140+ patterns) are auto-loaded into every session
4. **Skills** (23 skills) are available via `/skill-name` invocation
5. **MCP servers** configured in `~/.claude.json` are available in every session

No manual action needed. Start a new session and everything is current.

## claude.ai (Manual Setup)

claude.ai has no filesystem access and no equivalent of CLAUDE.md. Instructions reach Claude through three mechanisms, listed by scope:

### 1. Profile Preferences (account-wide, all conversations)

**Location:** Settings -> General -> Profile -> "What personal preferences should Claude consider"

This is the broadest scope -- applies to every conversation, every project, every device. Keep it concise and high-signal. Include:

- Communication style preferences
- MCP server summaries (what each does, key tool selection rules)
- General workflow preferences

**Current content:**

```text
I'm a software developer. Call me Herb. Be concise and direct -- no emojis,
no filler. Technical accuracy over politeness.

I have two custom MCP servers:

SYNAPSET (semantic vector memory):
- My persistent knowledge base across all sessions and projects
- Pools: "devkit" (cross-project dev patterns/gotchas), "machines" (hardware
  specs per host), "samverk" (agent session history), "mcp-memory" (knowledge
  graph bridge)
- Use query_memory when I specify a pool + source/category/tags (exact-match)
- Use search_memory when I ask a fuzzy question (semantic similarity)
- Use search_all only when the right pool is unknown
- Always pass pool explicitly -- SYNAPSET_POOL is not set
- At session start when I mention a machine name, load context:
  query_memory(pool="machines", source="<hostname-lowercase>")

SAMVERK (project management):
- Agent orchestration and issue processing platform
- May be unavailable; if connection fails, skip gracefully

General preferences:
- Use conventional commits: feat:, fix:, refactor:, docs:
- Never commit directly to main -- always branch + PR
- When I ask about code patterns or gotchas, search Synapset first
- Cite Synapset results when they inform your answer
```

**When to update:** When MCP servers change, pools are added/removed, or workflow preferences shift.

### 2. Projects (scoped to a workspace)

**Location:** claude.ai -> Projects (left sidebar) -> Create/Edit project

Projects provide two things Profile Preferences cannot:

- **Custom Instructions**: Detailed, project-specific guidance (like a CLAUDE.md)
- **Knowledge Files**: Uploaded documents Claude can reference (like skills/references)

#### Development Project

For general development work with Synapset context:

- **Custom Instructions**: Full Synapset decision framework (query_memory vs search_memory, pool conventions, storage conventions, autonomy tiers)
- **Knowledge Files**:
  - `claude/skills/synapset/references/pool-conventions.md` (from DevKit)
  - `claude/skills/synapset/references/tool-decision-guide.md` (from DevKit)

#### Samverk Project

For check-ins and project management:

- **Custom Instructions**: Samverk architecture overview, MCP tool reference, autonomy tiers, check-in workflow, Synapset integration for session history
- **Knowledge Files**:
  - `README.md` (from Samverk)
  - `docs/concept.md` (from Samverk)
  - `docs/architecture.md` (from Samverk)
  - `docs/mcp-server.md` (from Samverk -- MCP tools reference)
  - `docs/communication-protocol.md` (from Samverk -- issue schema)
  - `.samverk/status.md` (from Samverk -- current state)

**When to update:** Re-upload knowledge files when the source documents change significantly (architecture shifts, new MCP tools added, status changes).

### 3. Custom Connectors (MCP servers)

**Location:** Settings -> Connectors -> Add custom connector

Custom Connectors expose MCP server tools to claude.ai. The tool descriptions defined in the MCP server's code are what Claude sees -- no additional configuration is needed per-tool.

**Current connectors:**

| Connector | URL | Status |
|-----------|-----|--------|
| Synapset MCP | `https://synapset.herbhall.net/mcp` | Connected |
| Samverk MCP | `https://samverk.herbhall.net/mcp` | Pending fix (samverk#600) |

**Key finding:** Claude.ai Custom Connectors do NOT require OAuth 2.1. If `/.well-known/oauth-authorization-server` exists and the OAuth flow fails, the connection is rejected. Servers behind Cloudflare Tunnel should omit OAuth entirely -- Claude.ai falls back to unauthenticated mode. See KG#135.

## Keeping Things in Sync

### What auto-syncs (no action needed)

- Claude Code rules, skills, and CLAUDE.md (via DevKit SessionStart hook)
- MCP server tool descriptions (defined in server code, always live)
- Synapset memory content (always live via MCP)

### What requires manual updates

| Item | When to Update | How |
|------|----------------|-----|
| Profile Preferences | MCP servers added/removed, pool changes | Settings -> Profile -> edit text |
| Project Instructions | Architecture changes, new MCP tools | Project -> Settings -> edit instructions |
| Project Knowledge Files | Source docs change significantly | Project -> Knowledge -> re-upload files |
| Custom Connectors | New MCP server deployed | Settings -> Connectors -> Add |

### Sync checklist after major changes

When a project's architecture, MCP tools, or documentation changes significantly:

1. Update the source docs in the project repo (committed via PR)
2. DevKit auto-pulls for Claude Code (automatic)
3. Re-upload changed knowledge files to the relevant claude.ai Project (manual)
4. Update Profile Preferences if MCP server list or pool conventions changed (manual)
5. If MCP server endpoint changed, update the Custom Connector URL (manual)

## Relationship to DevKit Settings Strategy

This document covers **cross-client** configuration. For Claude Code-specific settings (permissions, hooks, plugins), see [settings-strategy.md](settings-strategy.md).

| Concern | Document |
|---------|----------|
| Claude Code permissions and tool access | [settings-strategy.md](settings-strategy.md) |
| Cross-client instructions and MCP setup | This document |
| MCP server research and architecture | [mcp-lazy-loading-research.md](mcp-lazy-loading-research.md) |
| Credentials and secrets | [credentials.md](credentials.md) |
