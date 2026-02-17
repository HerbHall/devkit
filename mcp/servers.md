# MCP Server Inventory

Servers configured for Claude Desktop and Claude Code. Install in priority order.

## Essential (install first)

| Server | Package | Purpose | Requires |
|--------|---------|---------|----------|
| **memory** | `@modelcontextprotocol/server-memory` | Persistent knowledge graph across sessions | Node.js |
| **sequential-thinking** | `@modelcontextprotocol/server-sequential-thinking` | Structured reasoning for complex problems | Node.js |
| **context7** | `@upstash/context7-mcp` | Up-to-date library documentation | Node.js |
| **MCP_DOCKER** | Docker MCP Gateway | Comprehensive toolbox (GitHub, browser, sandbox, file ops) | Docker Desktop |

## Recommended

| Server | Package | Purpose | Requires |
|--------|---------|---------|----------|
| **github** | `@modelcontextprotocol/server-github` | GitHub API (issues, PRs, code search) | Node.js + PAT |
| **sqlite** | `mcp-sqlite` | Local SQL database for persistent data | Node.js |
| **docker-local** | `mcp-server-docker` | Local Docker container management | Python (uv) + Docker |

## Optional (project-specific)

| Server | Package | Purpose | Requires |
|--------|---------|---------|----------|
| **gitlab** | `@modelcontextprotocol/server-gitlab` | GitLab API access | Node.js + PAT |
| **hass-mcp** | `hass-mcp` | Home Assistant integration | Python (uv) + HA instance |
| **docker-unraid** | `mcp-server-docker` | Remote Docker via SSH | Python (uv) + SSH access |
| **filesystem-docker** | `mcp/filesystem` | Containerized filesystem access | Docker |
| **playwright-docker** | `mcp/playwright` | Browser automation | Docker |

## Installation

### Prerequisites

```bash
# Node.js (required for most servers)
# Download from https://nodejs.org/ or use winget:
winget install OpenJS.NodeJS.LTS

# Python + uv (required for Docker and HA servers)
# Download from https://docs.astral.sh/uv/getting-started/installation/
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Docker Desktop (required for MCP_DOCKER gateway)
# Download from https://www.docker.com/products/docker-desktop/
```

### Setup

1. Copy `claude-desktop.template.json` to `%APPDATA%\Claude\claude_desktop_config.json`
2. Replace all `<PLACEHOLDER>` values with your actual paths and tokens
3. On Windows, replace `npx` with full path: `C:\Program Files\nodejs\npx.cmd`
4. On Windows, replace `uvx` with full path: `C:\Users\<YOU>\.local\bin\uvx.exe`
5. Restart Claude Desktop

### MCP_DOCKER Gateway

The Docker MCP Gateway bundles many tools inside Docker:

- GitHub operations (search, issues, PRs, repos)
- Browser automation (Playwright — navigate, click, screenshot)
- Sandbox execution (run JS, shell commands)
- File operations (read, write, create directories)
- Wikipedia, npm search, OpenAPI tools
- Obsidian vault access
- Desktop Commander (processes, file I/O)

It auto-discovers installed add-on servers. Additional servers can be added at runtime with `mcp-find` and `mcp-add` tools.

### Claude Code Plugins

Claude Code has its own plugin system separate from MCP servers. Plugins are enabled in `~/.claude/settings.json` under `enabledPlugins`. See `claude/settings.template.json` for the full list.

Key plugins:

- **taches-cc-resources** — Skills, plans, prompts, debugging, hooks
- **context7** — Library documentation
- **superpowers** — Advanced workflow skills
- **commit-commands** — Git workflow automation
- **pr-review-toolkit** — PR review agents
- **plugin-dev** — Plugin development tools
