# MCP Lazy-Loading Gateway Feasibility Research

**Date:** 2026-03-14
**Issue:** [#293](https://gitea.herbhall.net/samverk/devkit/issues/293)
**Status:** Complete

## Problem Statement

Claude runs across 5+ interfaces (VS Code Claude Code, CLI Claude Code, Desktop,
mobile claude.ai, Cowork). Each loads MCP tool schemas upfront into context.
With 5-10 MCP servers configured, tool definitions consume 40-50k tokens before
any work begins -- up to 33% of a 200k context window.

**Goal:** One shared tool registry, tools loaded on-demand, unloaded when idle.

## Findings

### 1. MCP Protocol: Dynamic Tool Loading Is Supported

The MCP spec ([2025-03-26](https://modelcontextprotocol.io/specification/2025-03-26/server/tools))
fully supports dynamic tool changes:

- Servers declare `tools` capability with `"listChanged": true`
- Servers send `notifications/tools/list_changed` when available tools change
- Clients re-fetch via `tools/list` to get the updated set
- Tools can be added or removed mid-session

**Conclusion:** The protocol supports a gateway that starts with zero tools and
adds them on-demand. No spec changes needed.

### 2. Claude Code ToolSearch (Already Shipped)

Claude Code already implements deferred tool loading via the ToolSearch mechanism:

- Tools are sent with `defer_loading: true` in the API `tools` array
- Full schemas are provided but never loaded into model context
- A search tool (`tool_search_tool_regex_20251119` or `tool_search_tool_bm25_20251119`)
  lets Claude discover and load tools on demand
- **Auto-activates** when MCP tool descriptions exceed 10% of context window
- **Measured impact:** ~85% reduction in tool definition overhead (51k -> 8.5k tokens)

**Key issues (all closed/implemented):**

- [#11364](https://github.com/anthropics/claude-code/issues/11364): Lazy-load MCP tool definitions
- [#12836](https://github.com/anthropics/claude-code/issues/12836): Support Tool Search beta
- [#23508](https://github.com/anthropics/claude-code/issues/23508): Lazy MCP tool group loading

**Open bugs/enhancements:**

- [#31569](https://github.com/anthropics/claude-code/issues/31569): "Tool loaded" renders as user input in VS Code
- [#31623](https://github.com/anthropics/claude-code/issues/31623): Extend deferred loading to built-in subagents
- [#33073](https://github.com/anthropics/claude-code/issues/33073): PreToolUse hooks cause hang after ToolSearch
- [#30516](https://github.com/anthropics/claude-code/issues/30516): ToolSearch blocks when data exfiltration classifier unavailable
- [#26005](https://github.com/anthropics/claude-code/issues/26005): Custom MCP tools not indexed in ToolSearch

### 3. Claude Desktop: On-Demand Connectors

Claude Desktop now has "on-demand connectors" where connectors are not loaded
until Claude searches for them based on the request. This is similar to
ToolSearch but the internal mechanism is not publicly documented.

### 4. Community Gateway/Proxy Ecosystem

#### Major projects (1,000+ stars)

| Project | Stars | What It Does |
|---------|-------|-------------|
| [lastmile-ai/mcp-agent](https://github.com/lastmile-ai/mcp-agent) | 8,103 | Agent framework with MCP aggregator |
| [katanemo/plano](https://github.com/katanemo/plano) | 5,959 | AI-native proxy on Envoy; routing, safety, observability |
| [IBM/mcp-context-forge](https://github.com/IBM/mcp-context-forge) | 3,412 | AI Gateway federating MCP + A2A + REST/gRPC |
| [sparfenyuk/mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) | 2,343 | Bridge between HTTP and stdio transports |
| [agentgateway/agentgateway](https://github.com/agentgateway/agentgateway) | 1,937 | Agentic proxy for A2A + MCP protocols |
| [envoyproxy/ai-gateway](https://github.com/envoyproxy/ai-gateway) | 1,430 | Envoy-based MCP support with OAuth, sessions |

#### Lazy-loading specific

| Project | Stars | Approach |
|---------|-------|----------|
| [voicetreelab/lazy-mcp](https://github.com/voicetreelab/lazy-mcp) | 77 | Meta-tools: `get_tools_in_category()` + `execute_tool()` |
| MCPlexor (SaaS, closed-source) | 1 | Semantic search to load relevant tools; claims 95% context reduction |

#### Server management

| Project | Stars | What It Does |
|---------|-------|-------------|
| [ravitemer/mcp-hub](https://github.com/ravitemer/mcp-hub) | 457 | Centralized manager with dynamic start/stop/monitor |
| [OldJii/mcp-dock](https://github.com/OldJii/mcp-dock) | 74 | Cross-platform manager; multi-client sync |

### 5. Open Feature Requests (Not Yet Implemented)

| Issue | Title | Status |
|-------|-------|--------|
| [#17668](https://github.com/anthropics/claude-code/issues/17668) | MCP Context Isolation -- assign MCPs to agent/skill contexts | Open (stale) |
| [#24000](https://github.com/anthropics/claude-code/issues/24000) | MCP Profiles for rapid context-aware tool switching | Open |
| [#3206](https://github.com/anthropics/claude-code/issues/3206) | Selective MCP tool activation for project-specific contexts | Open |

### 6. Community Mitigation Strategies

Published best practices from New Stack, CodeRabbit, Lunar, Writer, DomAIn Labs:

1. **Limit to 10-15 tools** per agent at a time
2. **Sub-agent architecture** -- 4 sub-agents with 10-15 tools each
3. **Selective activation** -- toggle servers on/off per task
4. **Skills-first architecture** -- conditionally loaded skill bundles (DevKit's approach)
5. **Gateway consolidation** -- single gateway with RBAC and audit
6. **Tool design quality** -- intentional agentic tools, not raw API wrappers
7. **Per-project `.mcp.json`** -- already supported by Claude Code

## Feasibility Assessment

### Build a Custom MCP Gateway?

**Verdict: Wait.** The problem is largely solved or actively being solved upstream.

**Arguments against building:**

- Claude Code's ToolSearch already provides ~85% context reduction automatically
- Claude Desktop now has on-demand connectors
- The remaining gap (cross-interface shared registry, tool profiles) is being
  tracked in open issues (#17668, #24000, #3206)
- `voicetreelab/lazy-mcp` exists as a lightweight alternative if needed
- Building a gateway means maintaining transport compatibility, auth, and
  lifecycle management -- significant ongoing cost

**Arguments for building:**

- No solution currently provides a unified tool registry across all Claude interfaces
- Per-session tool profiles don't exist natively
- Dynamic unloading after period of non-use is not implemented anywhere

**Recommendation:** Monitor open issues (#17668, #24000). File a feature request
for the specific gaps (shared registry, profiles, dynamic unloading). Use
ToolSearch + per-project `.mcp.json` as the current mitigation. Revisit in Q3
2026 if upstream progress stalls.

### What DevKit Already Does Well

DevKit's current approach aligns with community best practices:

- **Skills-first architecture** -- tools are loaded contextually via skills
- **Per-project MCP config** -- `.mcp.json` scoped to each project
- **Rules compaction** -- keeps context lean (just completed in this session)
- **Subagent delegation** -- agents get scoped tool access

### Remaining Gaps

1. **No shared tool registry** -- each interface (Desktop, CLI, VS Code) has
   independent MCP config
2. **No tool profiles** -- can't switch between "research mode" and "coding mode"
   tool sets without manual config changes
3. **No dynamic unloading** -- once loaded, tools stay in context until session ends

## Feature Request

Filed: [anthropics/claude-code#34471](https://github.com/anthropics/claude-code/issues/34471)

**Requested:**

- Shared tool registry across Claude interfaces (Desktop, CLI, VS Code, mobile)
- Per-session tool profiles (e.g., "research", "coding", "devops")
- Dynamic tool unloading after period of non-use

## References

- [MCP Spec: Tools](https://modelcontextprotocol.io/specification/2025-03-26/server/tools)
- [Anthropic API Docs: Tool Search](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)
- [Anthropic Engineering: Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use)
- [e2b-dev/awesome-mcp-gateways](https://github.com/e2b-dev/awesome-mcp-gateways)
