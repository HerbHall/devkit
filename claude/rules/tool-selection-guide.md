# Tool Selection Guide

Proactive decision tree for choosing the right tool the first time.
Reduces tool-cycling waste and context consumption. Tier 2 (learned).

## GitHub Operations

| Task | Preferred Tool | Why |
| --- | --- | --- |
| Issue CRUD (create, close, edit, list) | `gh` CLI | Fastest, most reliable, supports `--json` for parsing |
| PR create, merge, review | `gh pr` CLI | Native squash-merge, auto-merge support |
| Cross-repo code search | MCP_DOCKER `search_code` | Faster than `gh api` for multi-repo queries |
| Cross-repo issue search | MCP_DOCKER `search_issues` | Better filtering than `gh issue list` across repos |
| Repo settings (disable features) | `gh api` with PATCH | `gh repo edit` lacks `--disable-*` flags (KG#74) |
| GET requests with params | URL query string | `-f` flags default to POST, breaking GET (KG#107) |
| Milestone assignment | `--milestone "Title"` (string) | `--milestone N` fails; CLI takes title, not number (KG#108) |

## Web Content and Research

| Task | Preferred Tool | Why |
| --- | --- | --- |
| Library/framework docs | Context7 `resolve-library-id` then `query-docs` | Up-to-date, structured, no hallucination |
| Reddit content | `gh api -X GET "$URL.json"` | WebFetch blocked by Reddit (KG#31) |
| General web research | WebSearch first | Broad coverage, then WebFetch specific URLs |
| Specific URL content | WebFetch | Direct fetch, returns markdown |
| Microsoft/Azure docs | MCP_DOCKER `microsoft_docs_search/fetch` | Official content, structured |

## File Operations

| Task | Preferred Tool | Why |
| --- | --- | --- |
| Read files | Read tool | Never `cat`, `head`, `tail` in Bash |
| Search file content | Grep tool | Never `grep` or `rg` in Bash |
| Find files by pattern | Glob tool | Never `find` or `ls` in Bash |
| Edit existing files | Edit tool | Never `sed` or `awk` in Bash |
| Create new files | Write tool | Never `echo >` or heredoc in Bash |
| Codebase exploration | Agent (Explore type) | Preserves main context, handles multi-step search |

## Go Development

| Task | Preferred Tool | Why |
| --- | --- | --- |
| Run pinned tool version | `go run tool@vX.Y.Z` | No install, no PATH issues, exact version (AP#91) |
| Local Go binary | Avoid on MSYS | Permission denied on Windows MSYS (KG#60) |
| Swagger regeneration | `go run github.com/swaggo/swag/cmd/swag@v1.16.4 init ...` | Pinned version, cross-platform |
| golangci-lint | `go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest run` | Avoids install issues |

## Shell and Scripting (Windows MSYS)

| Task | Preferred Tool | Why |
| --- | --- | --- |
| JSON parsing | Python `json` module | `jq` unavailable on MSYS (AP#122) |
| Complex regex in bash | Standalone `.py` file | Heredoc escaping breaks regex (AP#122) |
| PowerShell from MSYS | Temp `.ps1` file | Inline PS breaks with `$env:`, special chars (AP#76) |
| Unicode-heavy output | Set `PYTHONIOENCODING=utf-8` | Windows cp1252 crashes on Unicode (AP#122) |
| Python detection | Test with `"$p" --version` | `command -v` resolves Windows Store aliases that hang (KG#8) |

## Knowledge and Memory

| Task | Preferred Tool | Why |
| --- | --- | --- |
| **Session start: load machine context** | Synapset `query_memory(pool="machines", source=<hostname>)` | Deterministic structured retrieval of CPU, GPU, RAM, dev tools, paths, network for current host |
| Structured lookup (known pool/source/category) | Synapset `query_memory` | Exact-match filters, no embedding overhead, deterministic results |
| Semantic concept search (one pool) | Synapset `search_memory` | KNN vector similarity finds related memories even with different wording |
| Semantic concept search (all pools) | Synapset `search_all` | Cross-pool KNN; note mixed embedding models affect score comparability |
| Store a learning or pattern | Synapset `store_memory` | Pool: `devkit` for cross-project, project name for project-specific |
| Update stale machine/project data | Synapset `update_memory` | Preserves memory ID, auto-re-embeds on content change |
| Cross-session knowledge graph | MCP Memory (`create_entities`, `search_nodes`) | Persistent graph with relations, entity types, structured observations |
| Complex reasoning | Sequential Thinking MCP | Structured multi-step analysis |
| Current session tracking | TodoWrite tool | Tasks, progress, completion |
| Long-term preferences | Memory files in `.claude/projects/` | Local file-based, indexed in MEMORY.md |

## Tool Routing Entries (Autolearn-Populated)

New entries added here when a tool fails and an alternative succeeds.

| Date | Task Pattern | Failed Tool | Succeeded Tool | Source |
| --- | --- | --- | --- | --- |
| 2026-03-14 | Fetch Reddit content | WebFetch | `gh api` with .json | KG#31 |
| 2026-03-14 | Close GitHub issue | `gh` with GITHUB_TOKEN env | `GITHUB_TOKEN= gh` (clear env) | Session discovery |
| 2026-03-14 | Unset env var in MSYS | `unset VAR` | `VAR=` inline prefix | KG (new) |
