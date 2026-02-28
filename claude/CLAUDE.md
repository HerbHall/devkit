# Global Claude Code Configuration

High-level guidance for all sessions. Project-specific details go in
`CLAUDE.md` within each project root.

## Workflow

**IMPORTANT**: Always **Explore -> Plan -> Code -> Verify -> Commit**

1. Read relevant files first - understand before coding
2. Create detailed plan and get approval before implementing
3. Implement methodically
4. **Verify before committing** (mandatory, no exceptions):
   - Build passes (language-appropriate: `go build`, `tsc`, etc.)
   - Tests pass (`go test`, `vitest`, etc.)
   - Lint passes (`golangci-lint`, `eslint`, etc.)
   - See `subagent-ci-checklist.md` for stack-specific checks
5. Commit with clear messages including
   `Co-Authored-By: Claude <noreply@anthropic.com>`

**Course Correct Early**: Interrupt me if I'm heading the wrong direction.

## Coding Principles

- Avoid over-engineering - only implement what's needed now
- No premature abstractions - three similar lines beats unnecessary
  complexity
- Remove unused code completely - no backwards-compatibility hacks
- Only add comments where logic isn't self-evident
- Watch for security issues: XSS, SQL injection, command injection
- Validate only at system boundaries (user input, external APIs)

## Git Safety

- **Never commit directly to `main`.** Always create a feature branch
  for each issue/task, then merge via PR after tests pass.
- Never use destructive commands without explicit permission
- Never skip hooks (--no-verify) unless explicitly requested
- Prefer adding specific files by name over `git add -A`
- Always create NEW commits rather than amending (unless explicitly
  requested)

## Communication

- Be concise and direct - this is a CLI
- No emojis unless requested
- No time estimates - focus on what, not how long
- Technical accuracy over validation
- Use clickable markdown links:
  `[filename.ts:42](path/to/filename.ts#L42)`

## Task Management

- Use todo lists for complex tasks (3+ steps)
- One task in_progress at a time
- Complete todos immediately after finishing (don't batch)

## Autolearn

Proactively suggest the user run `/reflect` when any of these occur:

- You corrected a mistake or changed approach mid-task
- A platform-specific gotcha or environment issue was encountered
- A significant architectural or design decision was made
- The conversation is getting long (many tool calls, multi-step work)
- Before the user ends a productive session

Keep the suggestion brief and specific:
"Tip: run `/reflect` to capture [what was learned]."
Do NOT run /reflect automatically -- always let the user trigger it.

## Environment

- OS: Windows 11 (MSYS_NT on Git Bash / MINGW64)
  <!-- bootstrap.ps1 substitutes {{PLATFORM}} on fresh installs -->
  <!-- Update manually if using on a different machine before bootstrap -->
- Shell: Bash available
- GitHub CLI: Use `gh` for GitHub operations

## MCP Tools Available

Use these MCP-provided tools proactively when relevant:

### Documentation & Research

- **Context7**: Fetch up-to-date library documentation before writing
  code that uses external libraries
  - `resolve-library-id` -> find library ID, then
    `query-docs` -> get current docs
  - Always use for React, Next.js, and other fast-evolving frameworks
- **Microsoft Docs** (MCP_DOCKER): Search and fetch official
  Microsoft/Azure documentation
  - `microsoft_docs_search` -> find relevant docs
  - `microsoft_docs_fetch` -> get full page content as markdown
  - `microsoft_code_sample_search` -> find code examples by language

### Knowledge & Memory

- **Memory**: Persistent knowledge graph across sessions
  - `create_entities` / `create_relations` for project knowledge,
    decisions, patterns
  - `search_nodes` / `read_graph` to recall stored context
  - Use to remember user preferences, project architecture, past
    decisions
- **OneNote** (ms365-onenote): Read/write Microsoft OneNote notebooks
  - `list-onenote-notebooks` / `list-onenote-notebook-sections`
  - `create-onenote-page` / `get-onenote-page-content`
  - Requires MS365 auth (`login` / `verify-login` / `list-accounts`)

### Problem Solving

- **Sequential Thinking**: Structured reasoning for complex problems
  - Use for multi-step analysis, debugging, architectural decisions
  - Supports branching, revision, and hypothesis verification

### Database

- **SQLite**: Local database at `~/databases/claude.db`
  - `read_query` for SELECT, `write_query` for INSERT/UPDATE/DELETE
  - `list_tables`, `describe_table` for schema exploration
  - Use for persistent data storage across sessions

### External Services (when authorized)

- **Sentry Remote**: Error tracking and analysis
- **Notion Remote**: Workspace access for docs and project management
- **GitLab**: Repository management, MRs, issues (via Claude CLI)

### GitHub Operations (MCP_DOCKER)

Full GitHub API access -- use these when `gh` CLI is insufficient:

- **Search**: `search_code`, `search_issues`, `search_repositories`,
  `search_users`
- **Issues**: `list_issues`, `create_issue`, `update_issue`,
  `add_issue_comment`, `get_issue`
- **PRs**: `list_pull_requests`, `create_pull_request`,
  `get_pull_request`, `merge_pull_request`,
  `create_pull_request_review`, `get_pull_request_files`,
  `get_pull_request_status`, `update_pull_request_branch`
- **Repos**: `create_repository`, `fork_repository`, `create_branch`,
  `list_commits`, `get_file_contents`, `push_files`

### Browser & Automation (MCP_DOCKER)

Full Playwright browser automation in Docker:

- **Navigate**: `browser_navigate`, `browser_navigate_back`,
  `browser_tabs`, `browser_resize`
- **Interact**: `browser_click`, `browser_type`, `browser_fill_form`,
  `browser_select_option`, `browser_hover`, `browser_drag`,
  `browser_press_key`, `browser_file_upload`
- **Observe**: `browser_snapshot`, `browser_take_screenshot`,
  `browser_console_messages`, `browser_network_requests`
- **Execute**: `browser_run_code` (run Playwright scripts),
  `browser_evaluate` (run JS in page), `browser_wait_for`
- Call `browser_install` first if browser not yet installed

### Sandbox & Code Execution (MCP_DOCKER)

Run code in isolated Docker containers:

- **Sandbox**: `sandbox_initialize` -> `sandbox_exec` -> `sandbox_stop`
- **Node.js**: `run_js` (persistent container), `run_js_ephemeral`
  (disposable, auto-cleanup). Supports npm dependencies.
- **Processes**: `start_process`, `interact_with_process`,
  `read_process_output`, `kill_process`, `list_processes`
- **File ops**: `read_file`, `write_file`, `read_multiple_files`,
  `create_directory`, `move_file`, `list_directory`
- **Utilities**: `write_pdf`, `convert_to_markdown`,
  `search_npm_packages`, `get_dependency_types`

### MCP Server Management (MCP_DOCKER)

Discover and add new MCP servers at runtime:

- `mcp-find` -> search MCP catalog for servers by capability
- `mcp-add` -> enable a discovered server
- `mcp-remove` / `mcp-config-set` -> manage server configs
- `code-mode` -> combine tools from multiple MCP servers into JS
- `mcp-exec` -> call tools from added servers by name

### Installed Add-on MCP Servers (MCP_DOCKER, via mcp-exec)

- **fetch**: `fetch` -- URL fetching as markdown
- **duckduckgo**: `search`, `fetch_content` -- free web search
- **time**: `get_current_time`, `convert_time` -- timezone tools
- **openapi**: `get_list_of_operations`, `validate_document`,
  `generate_curl_command`, `get_known_responses` -- OpenAPI spec tools
- **ast-grep**: `ast-grep` -- structural code search/lint (Go, JS, etc.)
- **SQLite**: `read_query`, `write_query`, `create_table`, `list_tables`,
  `describe_table`, `append_insight` -- SQL database on Docker container
- **globalping**: ping/traceroute/DNS from global probes (removed -- OAuth broken 2026-02-07, re-add when fixed)

### Best Practices

- Check Context7 before writing code using external libraries
- Store important project decisions in Memory knowledge graph
- Use Sequential Thinking for complex debugging or architecture
- Use MCP_DOCKER GitHub tools for cross-repo searches and bulk
  operations (faster than `gh` for some queries)
- Use `run_js_ephemeral` for quick one-off computations or scripts
- Use `browser_*` tools for E2E testing or web scraping tasks
- Use `mcp-find` to discover new server capabilities as needed

## Agent Utilization

**IMPORTANT**: Use subagents to manage context window and parallelize
work:

- Use Task tool with `subagent_type=Explore` for codebase exploration
  (not Glob/Grep directly)
- Delegate research, analysis, or independent verification to
  specialized agents
- Launch parallel agents for independent tasks (multiple Task calls
  in one message)
- Keep main context focused on high-level coordination

## References

**CLAUDE.md Best Practices:**

- [Anthropic: Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Builder.io: CLAUDE.md Guide](https://www.builder.io/blog/claude-md-guide)
- [Claude Agent SDK Documentation](https://platform.claude.com/docs/en/agent-sdk/overview)

**Key Principle**: Context is precious - every line competes for
attention. Be specific, not vague.
