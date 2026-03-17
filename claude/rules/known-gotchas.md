---
description: Known gotchas and platform-specific issues. Read when debugging unexpected behavior.
tier: 2
entry_count: 55
last_updated: "2026-03-17"
---

# Known Gotchas

Platform-specific issues, tool quirks, and surprising behaviors discovered through past sessions.

## 1. Windows MSYS Bash Path Translation

**Added:** 2026-02-17 | **Source:** global | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** MSYS bash auto-translates Unix-style paths to Windows paths. Paths starting with `/c/` become `C:\`.
**Fix:** Use `MSYS_NO_PATHCONV=1` prefix or double-slash `//` to prevent translation.

## 6. React Compiler Lint: Refs During Render (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active

**Platform:** React 19+ / ESLint react-hooks

### Mutating refs during render

**Issue:** `onMessageRef.current = onMessage` at top level triggers "Cannot update ref during render".
**Fix:** Wrap in `useEffect(() => { onMessageRef.current = onMessage }, [onMessage])`.

### Callback ref for Popper anchors

**Issue:** MUI `Popper`/`Popover` needs `anchorEl` during render. Using `useRef` + `ref.current` triggers the refs rule.
**Fix:** Use callback ref with `useState`: `const [anchorEl, setAnchorEl] = useState(null)` then `<Button ref={setAnchorEl}>`.

### Recursive useCallback self-reference

**Issue:** Recursive `useCallback` (e.g., `connect()` calling itself in `onclose`) triggers "Cannot access variable before it is declared".
**Fix:** Store in a ref: `const connectRef = useRef<() => void>()` and call `connectRef.current?.()` for recursion.

## 8. Windows Python Aliases Shadow Real Python

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** `python3`/`python`/`py` resolve to Windows Store alias stubs. `command -v` reports them as found.
**Fix:** Check with `"$p" --version` (not `command -v`). Include explicit Windows paths in the search loop.

## 12. Swagger Cross-Platform Drift (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active
**See also:** AP#17

**Platform:** Go (swaggo/swag, cross-platform)

### time.Duration enum drift

**Issue:** `swag init` generates platform-specific `time.Duration` enum values.
**Fix:** Add `swaggertype:"integer"` struct tag to `time.Duration` fields.

### x-enum-descriptions drift

**Issue:** Windows `swag init` generates `x-enum-descriptions` blocks; Linux omits them.
**Fix:** Remove all `x-enum-descriptions` blocks after `swag init` on Windows.

### Perl regex corrupts YAML

**Issue:** Perl regex stripping `x-enum-descriptions` can join adjacent lines.
**Fix:** Verify YAML integrity after stripping. Consider using yq instead.

### Any handler/model change requires swag init

**Issue:** ANY change to Go types in swagger-annotated handlers requires regenerating the swagger spec.
**Fix:** Always run `swag init` (or `make swagger`) after modifying handlers/structs. Commit regenerated files alongside Go changes.

## 17. websocket.Dial Response Body Must Be Closed

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (all) / coder/websocket library
**Issue:** `websocket.Dial` returns `(*Conn, *http.Response, error)`. The `bodyclose` linter requires the response body closed.
**Fix:** Always capture and close: `if resp != nil && resp.Body != nil { resp.Body.Close() }`.

## 18. Windows PowerShell Process and JSON Quirks (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (PowerShell)

### Start-Process gives child real console

**Issue:** `Start-Process` gives child `ModeCharDevice=true` even with `-WindowStyle Hidden`.
**Fix:** Set environment variables before `Start-Process` to bypass interactive prompts.

### ConvertFrom-Json drops empty arrays (PS 5.1)

**Issue:** `ConvertFrom-Json` on `[]` returns `$null` instead of `@()`.
**Fix:** Use `Invoke-WebRequest` and check `$resp.StatusCode` instead of parsing JSON.

## 20. Stacked PR Rebase After Squash-Merge Requires Skip (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Git / GitHub
**Issue:** After squash-merge, downstream stacked branches have different hashes. `git rebase origin/main` produces conflicts. Also, local merge commits cause `git pull --ff-only` to fail after squash-merge.
**Fix:** Use `git rebase --skip` for each already-merged commit, or `git rebase --onto origin/main <old-base> <branch>`. For local main divergence: `git reset --hard origin/main`. Prevent with `git config pull.ff only`.

## 23. GitHub Rulesets and Protection (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active

**Platform:** GitHub

- Repos using rulesets return 404 from branch protection API. Check rulesets: `gh api repos/{owner}/{repo}/rulesets`.
- Both rulesets and branch protection requiring reviews doubles the requirement. Use rulesets for reviews; branch protection only for CI status checks.
- Split rulesets break Copilot. Use single combined ruleset. Template: `project-templates/copilot-ruleset.json`.

## 25. Parallel Background Agents Share Working Tree (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active

**Platform:** Claude Code (all)

All parallel agents write to the same working directory. Sort into branches via stage/stash/pop after agents complete.

**Key scenarios:** (1) `git checkout` destroys other agents' unstaged tracked files. (2) `go build` compiles untracked files from other agents -- stash before pushing. (3) Stash during running agents is unsafe -- commit one agent's files first. (4) Multiple `git worktree add`/`remove` operations (especially with parallel CC sessions) can flip `core.bare = true` in `.git/config` -- fix with `git config core.bare false`; detect with `git worktree list` showing `(bare)`.
**See also:** AP#127

## 26. Sequential Same-File PR Merge Requires Rebase Between Each

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Git / GitHub
**Issue:** Multiple PRs modifying the same file conflict after one merges.
**Fix:** Merge one at a time, rebase each subsequent branch onto updated main, force-push. Use `GIT_EDITOR=true git rebase --continue` when rebase pauses with no conflicts.

## 27. SQLite strftime Returns NULL for RFC3339Nano Timestamps

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** SQLite (all)
**Issue:** `strftime` returns NULL for RFC3339Nano format timestamps. SQL-side time-bucketing fails.
**Fix:** Do time-bucketing in Go: `ts.Truncate(interval).UTC().Format(time.RFC3339)`. Use `WHERE timestamp BETWEEN ? AND ?` for range queries.

## 28. Recharts v3 Uses TooltipContentProps, Not TooltipProps

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** React / recharts 3.x
**Issue:** `<Tooltip content={...} />` receives `TooltipContentProps`, not `TooltipProps`. Using JSX element form renders with empty `{}` initially.
**Fix:** Use `TooltipContentProps<number, string>`. For JSX element form, use `Partial<TooltipContentProps<...>>`. See AP#63 (archived).

## 29. Build-Tag Files Invisible to Local Lint on Different OS

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (cross-platform)
**Issue:** `//go:build !windows` files are excluded from `golangci-lint` on Windows. Lint errors only appear in Linux CI.
**Fix:** Mentally check for `filepathJoin`, `G115`, `paramTypeCombine`, `prealloc` in platform-specific files. Consider `GOOS=linux golangci-lint run`.

## 35. Go Race Detection Requires CGO on Windows MSYS

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** `go test -race` fails without CGO. Race detector is implemented in C.
**Fix:** Run `go test` locally without `-race`. Rely on CI Linux runners for race detection.

## 50. Winget Installation Gotchas (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (winget / PowerShell / MSYS)

### Exit codes for "already installed"

**Issue:** `winget install` returns `-1978335189` (already installed) or `-1978335184`. Scripts treat as failure.
**Fix:** Check for both exit codes and treat as success.

### PATH staleness after install

**Issue:** Winget-installed tools update registry PATH but current session has old PATH.
**Fix:** Refresh: `$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')`.

## 61. Claude Code Settings Scope and Gitignore (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (all)

### Settings do NOT cascade from parent directories

**Issue:** Each project is independent. Hierarchy: user (`~/.claude/`) > project (`.claude/`) > local.
**Fix:** Put broad wildcards in `~/.claude/settings.json`. Copy `project-templates/settings.json` for new projects. See AP#86.

### settings.local.json should be gitignored

**Issue:** `.claude/settings.local.json` contains local tool permissions. Can be accidentally committed.
**Fix:** Add `.claude/*` to `.gitignore` (use glob, not trailing slash -- see KG#92). If committed, `git rm --cached`.

## 62. Windows CRLF Breaks Tool String Matching (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active

**Platform:** Windows (all tools)

Windows CRLF (`\r\n`) causes silent failures across multiple tools. Three known surfaces:

- **Bash grep in CI:** `\r\n` in Windows-committed files causes trailing `\r` in grep output, breaking comparisons. Fix: `tr -d '\r' < "$file" > "$clean_file"`.
- **Claude Code Edit tool:** `old_string` matching fails silently on CRLF files. Workaround: use Write tool for new files, or Python binary-mode (`open('file', 'rb')`).
- **GitHub API body fields:** `gh api` returns `\r\n` in `body` field on Windows. Python regex fails silently. Fix: `body = body.replace("\r\n", "\n")` before parsing.

**Universal fix:** Normalize `\r\n` to `\n` before any string processing on Windows.

## 65. golangci-lint v2 Config and Schema (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (all) / GitHub Actions

### version field required

**Issue:** v1 configs lack `version: "2"` field. v2 exits with "unsupported version" error. Build/test pass fine.
**Fix:** Add `version: "2"` as first field. Update module path to `.../v2/cmd/golangci-lint`. Use devkit template `project-templates/golangci.yml`.

### Action v7 enforces strict schema

**Issue:** v7 enforces strict JSON schema. v2.1 config keys fail with v2.10 schema. `linters-settings:` moved under `linters: settings:`. `issues: exclude-rules:` moved to `linters: exclusions: rules:`.
**Fix:** Migrate config to v2.10 schema. Use `@v7` (not `@v6`) for golangci-lint v2. Default binary mode (not `goinstall`).

## 74. gh repo edit Lacks --disable-* Flags

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub CLI (gh)
**Issue:** `gh repo edit` has `--enable-*` but no `--disable-*` flags.
**Fix:** Use `gh api repos/{owner}/{repo} -X PATCH -f allow_merge_commit=false`.

## 77. Docker Desktop Extension Development Gotchas (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active

**Platform:** Docker Desktop Extensions

- **Marketplace:** Submit via docker/extensions-submissions. Run `docker extension validate` first.
- **hadolint:** DL3048/DL3045 false positives. Add `.hadolint.yaml` with `ignored: [DL3048, DL3045]`.
- **Vitest:** `@docker/extension-api-client` CJS/ESM mismatch. Add `resolve.alias` -> mock file. See KG#87.
- **Version drift:** Designate one source of truth. CI overrides Dockerfile ARG via `--build-arg`.
- **Labels:** Screenshots (JSON array, min 3, 2400x1600px), changelog (HTML), icon (local file).
- **Multi-arch:** Must build `linux/amd64` + `linux/arm64` via `docker buildx`.
- **MUI v5:** `@docker/docker-mui-theme` pins v5. Use `InputProps` not `slotProps.input`.
- **Update after rebuild:** Use `docker extension install` (not `update`) -- tracks by digest.

## 87. Vitest Cannot Resolve Browser-Only npm Package Exports

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** active

**Platform:** Vitest / Node.js
**Issue:** Packages with only `browser` field (no `main`/`exports`) fail in Vitest's Node.js resolution.
**Fix:** Add `resolve.alias` in `vitest.config.ts` pointing to the package's dist entry file. See also KG#77 (Docker extension-specific case).

## 88. .NET WPF Projects Fail dotnet restore on Linux CI

**Added:** 2026-03-02 | **Source:** IPScan | **Status:** active

**Platform:** .NET / GitHub Actions (Ubuntu)
**Issue:** `dotnet restore` on solution with WPF projects fails on Ubuntu with `NETSDK1100`.
**Fix:** Scope all `dotnet` commands to individual cross-platform .csproj files, not the .sln.

## 89. go get Does Not Resolve All Transitive Dependencies

**Added:** 2026-03-02 | **Source:** Samverk | **Status:** active

**Platform:** Go (all)
**Issue:** `go get` doesn't always resolve all transitive dependencies into `go.sum`. Build may fail after.
**Fix:** Always run `go mod tidy` after `go get`.

## 90. release-please node Type Requires package.json at Repo Root

**Added:** 2026-03-03 | **Source:** Runbooks | **Status:** active

**Platform:** GitHub Actions / release-please
**Issue:** `node` release type requires `package.json` at repo root. Subdirectory layouts fail silently.
**Fix:** Use `simple` release type with `VERSION` file. Template: `project-templates/release-please-config.json`. Use `# x-release-please-version` in Dockerfiles for auto-bump.

## 91. markdownlint-cli2 Nested node_modules Not Excluded by Root Pattern

**Added:** 2026-03-03 | **Source:** Samverk | **Status:** active

**Platform:** markdownlint-cli2 (all)
**Issue:** `"#node_modules"` only excludes root-level. Nested `web/node_modules/` causes thousands of lint errors.
**Fix:** Add `"#*/node_modules"` or `"#**/node_modules"` to exclusion patterns.

## 92. Gitignore Directory Slash Prevents Negation Override

**Added:** 2026-03-05 | **Source:** DigitalRain | **Status:** active

**Platform:** Git (all)
**Issue:** `.claude/` (trailing slash) ignores entire directory. `!.claude/settings.json` cannot override.
**Fix:** Use `.claude/*` (glob) instead. Glob-level ignores allow negation.

## 94. GITHUB_TOKEN-Created Tags Don't Trigger Push Events

**Added:** 2026-03-05 | **Source:** Runbooks | **Status:** active

**Platform:** GitHub Actions
**Issue:** Tags created by `GITHUB_TOKEN` don't trigger `on: push: tags:` in other workflows (anti-recursion).
**Fix:** Chain publish job in same workflow, or use `on: release: types: [published]`. For release-please, use `RELEASE_PLEASE_TOKEN` (PAT) -- see AP#120.

## 95. Release-Please Branch Updates Don't Always Trigger CI

**Added:** 2026-03-05 | **Source:** Runbooks | **Status:** active

**Platform:** GitHub Actions
**Issue:** `pull_request: synchronize` sometimes doesn't fire for release-please commits.
**Fix:** Deploy `retrigger-ci.yml`. Manual: `gh pr close N && sleep 2 && gh pr reopen N`.

## 96. Auto-Merge Requires Explicit Repo Setting

**Added:** 2026-03-05 | **Source:** Runbooks | **Status:** active

**Platform:** GitHub
**Issue:** `gh pr merge --auto` fails silently when auto-merge is not enabled on the repo.
**Fix:** `gh api repos/OWNER/REPO -X PATCH -f allow_auto_merge=true`.

## 97. Copilot Auto-Review Is UI-Only (No REST API)

**Added:** 2026-03-05 | **Source:** Runbooks | **Status:** active

**Platform:** GitHub
**Issue:** Copilot code review toggle in rulesets is UI-only. API can create the rule but UI may need manual confirmation.
**Fix:** After API ruleset creation, manually verify in Settings > Rules > Rulesets. Create a test PR to confirm.

## 98. Rules Files Over 40k Degrade Session Performance

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Rules files over 40k cause context to be silently dropped at task transitions.
**Fix:** Run `/rules-compact` to stay below 35k per file. `/conformance-audit` check #17 flags violations.

## 99. Copilot Cannot Approve PRs -- Review Is Informational Only (Consolidated Reference)

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Platform:** GitHub
**Issue:** Copilot can only COMMENT, never APPROVE. Setting `required_approving_review_count: 1` creates an unsatisfiable gate.
**Fix:** Set `required_approving_review_count: 0`. Keep `copilot_code_review` with `review_on_push: true` for informational comments. CI is the only merge gate. Use `--admin` only for CI infrastructure failures. Template: `project-templates/copilot-ruleset.json`.

### Sub-PR target branch

**Issue:** Copilot sub-PRs target the feature branch, not `main`. After squash-merge, merging these lands commits on a dead branch.
**Fix:** Check target first: `gh pr view <number> --json baseRefName,state`. If base is not `main`, apply fixes manually on a new branch.

## 104. PowerShell Tool and Variable Gotchas (Consolidated Reference)

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell (all)

### Unused variable warning

**Issue:** `$output = & command 2>&1 | Out-String` where `$output` is never read triggers `PSUseDeclaredVarsMoreThanAssignments`.
**Fix:** Use `$null = & command 2>&1` to explicitly discard output.

### Stderr mixes into parsed output

**Issue:** `& command 2>&1 | Out-String` merges stderr into stdout. Parsing line-by-line produces garbage entries.
**Fix:** Redirect stderr to a temp file: `$out = & command 2>$tmpErr | Out-String`. Check `$LASTEXITCODE` and read `$tmpErr` on failure.

### Invoke-ScriptAnalyzer has no -Include parameter

**Issue:** `-Include` parameter does not exist. Copilot and LLMs commonly generate this invalid syntax.
**Fix:** Use `Get-ChildItem -Recurse -Filter '*.ps1'` to collect files, then pipe each to `Invoke-ScriptAnalyzer`.

### $args is an automatic variable

**Issue:** Using `$args` as a local variable triggers `PSAvoidAssignmentToAutomaticVariable`.
**Fix:** Rename to `$cmdArgs`, `$labelArgs`, `$cliArgs`, or any non-reserved name. Other automatic variables: `$error`, `$input`, `$matches`, `$myinvocation`, `$psboundparameters`, `$pscmdlet`, `$psscriptroot`.

## 107. gh CLI Parameter Gotchas (Consolidated Reference)

**Added:** 2026-03-08 | **Source:** Samverk | **Status:** active

**Platform:** GitHub CLI (all)

### -f flags default to POST

**Issue:** `-f field=value` with `gh api` sets HTTP method to POST. GET requests fail with 422.
**Fix:** Embed params as URL query string: `gh api "repos/{owner}/{repo}/issues?milestone=5&state=open"`.

### --milestone takes title, not number

**Issue:** `gh issue create --milestone 5` fails -- CLI expects the milestone TITLE, not its number.
**Fix:** Pass title directly: `gh issue create --milestone "Gitea Migration"`. Note: REST API (`-F milestone=5`) does accept numbers.

### No milestone subcommand

**Issue:** `gh milestone` does not exist. Must use `gh api` directly.
**Fix:** Create: `gh api repos/OWNER/REPO/milestones -X POST -f title=...`. List: `gh api repos/OWNER/REPO/milestones --jq '.[] | {number, title}'`. Assign: `gh api repos/OWNER/REPO/issues/N -X PATCH -F milestone=M`.

## 110. GitHub Actions New CI Job Uses Base Branch Workflow, Not PR Branch

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** GitHub Actions
**Issue:** PR introducing a new CI job runs the workflow from `main`, so the new job is silently absent. PR passes, then subsequent PRs fail.
**Fix:** Verify the job ran in the CI check list. Merge a trivially correct version first, fix in follow-ups.

## 111. Markdown Editing Gotchas (Consolidated Reference)

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** All (markdownlint-cli2)

### 3-backtick fence broken by inner backtick blocks

**Issue:** Outer ` ``` ` fence is terminated by the first inner ` ``` `. Content after is treated as regular markdown.
**Fix:** Use 4-backtick outer fence when content contains triple-backtick fences.

### Inserting into numbered list requires full renumbering

**Issue:** Inserting mid-list without renumbering subsequent items triggers MD029.
**Fix:** Update every item number from insertion point to end in a single edit.

### Pipes in table cells parsed as column separators

**Issue:** Agent markdown tables have MD056 errors: pipes in code spans parsed as separators, or missing columns.
**Fix:** Run `npx markdownlint-cli2` on agent `.md` files. Use `&#124;` for pipes in cells. Verify column counts.

## 114. Set-StrictMode in Dot-Sourced PS Lib Pollutes Caller Scope

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell (all)
**Issue:** `Set-StrictMode -Version Latest` at the top level of a dot-sourced `.ps1` lib file propagates to the calling script's scope and all subsequently dot-sourced files.
**Fix:** Do NOT put `Set-StrictMode` in dot-sourced library files. Set it only in the entry-point script that owns its own execution context.

## 115. TypeScript API Interface Phantom Field Drift from Go Backend

**Added:** 2026-03-09 | **Source:** Samverk | **Status:** active

**Platform:** TypeScript / Go (full-stack)
**Issue:** TypeScript API interfaces accumulate phantom fields the Go backend never sends. Causes `undefined` React keys and silent failures.
**Fix:** Verify TS interfaces against actual Go JSON output (`curl` the endpoint). Grep for TS uses when changing Go JSON field names. See AP#79.

## 116. Go context.WithTimeout Cancels Cleanup Operations

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Go (all)
**Issue:** Wrapping task execution with `context.WithTimeout` cancels ALL downstream operations when timeout fires -- including session status updates, failure comments, and cost recording.
**Fix:** Create a separate `cleanupCtx := context.Background()` BEFORE timeout wrapping. Pass it to the runner for cleanup/persistence paths. Use timeout-wrapped ctx only for the provider call itself.

## 117. Claude Code Worktrees Cause markdownlint Hangs on node_modules

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Agent worktrees (`.claude/worktrees/`) create full repo copies including `web/node_modules/`. Markdownlint's `**/*.md` scans them -- 800+ files, 14k+ errors, hangs pre-push hook for 30+ minutes.
**Fix:** Add `**/.claude` and `**/node_modules` to markdownlint exclusion patterns (not just root-level). Clean up with `rm -rf .claude/worktrees && git worktree prune`.
**See also:** KG#91 (nested node_modules not excluded by root pattern)

## 118. Parallel git push Triggers Concurrent Pre-Push Hooks

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Git (all)
**Issue:** Two concurrent `git push` commands (from parallel agents or background tasks) trigger two parallel pre-push hooks sharing the same working directory, causing contention and hangs.
**Fix:** Always push sequentially. When using parallel agents with `isolation: "worktree"`, push one at a time after agents complete.
**See also:** KG#25 (parallel agents share working tree)

## 119. Always html.EscapeString Server-Injected Values in HTML

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Go (all)
**Issue:** Injecting server-side config values (auth tokens, URLs) into embedded HTML via string replacement without escaping creates XSS vulnerability.
**Fix:** Always use `html.EscapeString()` for values injected into HTML context. Applies to any Go server serving embedded SPAs with injected configuration.

## 120. Fine-Grained PAT as GITHUB_TOKEN Env Var Shadows gh Keyring OAuth

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Windows (MSYS_NT) / GitHub CLI
**Issue:** A fine-grained PAT set as Windows User env var `GITHUB_TOKEN` shadows `gh` CLI's keyring-stored OAuth token. Token precedence: `GITHUB_TOKEN` env > keyring OAuth > `GH_TOKEN` env. Fine-grained PATs often lack `issues:write` scope, causing 403 on `gh issue close/create`.
**Fix:** Remove the User env var: `[Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $null, 'User')`. PATs for CI (e.g., release-please) should only be GitHub Actions secrets, never local env vars. Inline override: `GITHUB_TOKEN= gh <command>`.
**See also:** KG#94 (GITHUB_TOKEN tags), AP#120 (secrets distribution)

## 121. MailChannels Free Tier Deprecated

**Added:** 2026-03-14 | **Source:** herbhall.net | **Status:** active

**Platform:** Cloudflare Workers
**Issue:** MailChannels shut down free Cloudflare Workers integration. `api.mailchannels.net/tx/v1/send` returns 401 Unauthorized.
**Fix:** Migrate to Cloudflare Email Routing `send_email` binding. See AP#126 for the replacement pattern.

## 122. Cloudflare Account Token Requires CLOUDFLARE_ACCOUNT_ID for Wrangler

**Added:** 2026-03-14 | **Source:** herbhall.net | **Status:** active

**Platform:** Cloudflare / Wrangler
**Issue:** Account API tokens fail on `/memberships` (error 10001) and `/user/tokens/verify` (error 9109). Wrangler calls `/memberships` on startup and fails with "Unable to authenticate request."
**Fix:** Set `CLOUDFLARE_ACCOUNT_ID` env var alongside Account API token. Wrangler skips memberships lookup when account ID is explicit. User API tokens work without this workaround.

## 123. Gitea API and Actions Gotchas (Consolidated Reference)

**Added:** 2026-03-14 | **Source:** Synapset | **Status:** active

**Platform:** Gitea / Git (all)

### API token from Git Credential Manager

**Issue:** When `tea` CLI is unavailable, need Gitea token for API calls.
**Fix:** Extract from git credential manager: `git credential fill <<< 'protocol=https\nhost=gitea.example.com' | grep password`. Use with `Authorization: token` header. Gitea REST API is largely GitHub-compatible.

### PR merge after rebase needs pause

**Issue:** After force-pushing a rebased branch, Gitea's merge API may reject immediately with "not mergeable" while it recalculates merge status.
**Fix:** Add a brief pause (2-3 seconds) between force-push and merge API call. Check mergeable status before merging.

### GITEA_ prefix reserved for secret names

**Issue:** Creating a secret starting with `GITEA_` via API returns `{"message":"invalid secret name"}`. Undocumented.
**Fix:** Use a different prefix (e.g., `CI_GITEA_TOKEN` instead of `GITEA_TOKEN`). Workflows referencing `secrets.GITEA_TOKEN` silently get empty values.

### Merge API returns empty body, not JSON

**Issue:** Gitea merge PR endpoint returns empty body (not JSON) on success. Returns HTTP 405 when PR is already merged. Scripts expecting JSON crash on both cases.
**Fix:** Check HTTP status code first (200 = success, 405 = already merged). Don't parse response body as JSON.

## 125. go:embed Cache Misses Embedded File Changes

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Go (all)
**Issue:** Go build cache doesn't detect changes to `go:embed` files when Go source hasn't changed. Embedded SPA files (`web/dist/` -> `internal/server/static/`) stay stale after frontend rebuild, causing deployed binary to serve old JS bundles.
**Fix:** Always use `make build` or `make redeploy` for projects with embedded SPAs. Consider `go build -a` or touching a Go source file after SPA rebuild to bust cache.
**Deploy:** Ensure deploy scripts rebuild the SPA before `go build`. Skipping frontend build silently serves stale JS bundles baked in at compile time.

## 126. Tailscale Funnel Rejects Host Header from Within Tailnet

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Tailscale
**Issue:** Funnel returns "Forbidden: invalid Host header" when accessed from a device within the same tailnet. Intra-tailnet traffic bypasses Funnel's public ingress path via WireGuard. External clients work fine.
**Fix:** Use Cloudflare Tunnel instead of Tailscale Funnel for universal access (both internal and external clients).

## 135. MCP Streamable HTTP Requires GET for SSE; OAuth Breaks Custom Connectors

**Added:** 2026-03-17 | **Source:** Samverk, Synapset | **Status:** active

**Platform:** MCP (all)
**Issue:** (1) MCP spec requires endpoint to handle both POST (messages) and GET (SSE streams). Register handler without method prefix. (2) Claude.ai Custom Connectors do NOT require OAuth 2.1. If `/.well-known/oauth-authorization-server` exists, Claude.ai attempts the OAuth flow; if it fails (e.g., empty auth token on server), the connection is rejected entirely. Synapset proves unauthenticated Custom Connectors work on both desktop and mobile.
**Fix:** Register handler without method prefix (go-sdk `StreamableHTTPHandler` handles all methods). Do NOT implement OAuth unless you have a working token exchange. For self-hosted MCP servers behind Cloudflare Tunnel, omit OAuth entirely -- Claude.ai falls back to unauthenticated mode.

## 136. SPA Catch-All Swallows Co-Hosted API Routes in Go ServeMux

**Added:** 2026-03-15 | **Source:** Samverk | **Status:** active

**Platform:** Go 1.22+ (ServeMux)
**Issue:** SPA catch-all route (`/ -> spaHandler`) intercepts paths not explicitly registered for all HTTP methods. Registering only `POST /mcp` causes GET/DELETE to fall through to SPA, returning HTML instead of JSON.
**Fix:** Register without method prefix: `mux.Handle("/mcp", handler)` when the handler routes methods internally.
**See also:** KG#28 (Go 1.22+ route pattern panic)

## 149. Worktree Isolation Agents Can Commit to Wrong Branch

**Added:** 2026-03-17 | **Source:** DevKit | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Parallel agents with `isolation: "worktree"` can commit to the wrong branch. Both agents' commits end up on one branch while the other branch has no unique commits. Root cause likely related to worktree sharing the same remote origin.
**Fix:** Verify branch assignments after parallel worktree agents complete. Recovery: cherry-pick each commit onto fresh branches from main, then create PRs from the fixed branches.
**See also:** KG#25 (parallel agents share working tree), AP#127 (worktree isolation pattern)

## 150. Go MCP SDK Rejects Non-Localhost Host Headers Behind Reverse Proxy

**Added:** 2026-03-17 | **Source:** Samverk | **Status:** active

**Platform:** Go (mcp-go SDK) / Cloudflare Tunnel
**Issue:** Go MCP SDK `StreamableHTTPHandler` rejects requests with non-localhost `Host` headers, returning 403 "Forbidden: invalid Host header". Reverse proxies (Cloudflare Tunnel, nginx) forward the original hostname, triggering the rejection.
**Fix:** Add `httpHostHeader: localhost:PORT` to cloudflared ingress config. For other proxies, rewrite the Host header to `localhost:PORT` before forwarding.
**Debugging tip:** Cloudflare Security Analytics "Mitigation: Not mitigated" immediately shows the block is from the origin server, not Cloudflare edge. Check this FIRST before investigating WAF rules.

## 151. Cloudflare Free Plan WAF Managed Ruleset Cannot Be Disabled

**Added:** 2026-03-17 | **Source:** Samverk | **Status:** active

**Platform:** Cloudflare (Free plan)
**Issue:** Cloudflare Free plan has an "Always active" managed WAF ruleset that cannot be disabled or skipped. WAF skip rules only affect user-deployed managed rules, not the built-in ones.
**Fix:** No workaround for disabling built-in rules. If built-in rules block legitimate traffic, use a different ingress method or upgrade to a paid plan with full WAF rule control.

## 152. Background Agents Cannot Use MCP Tools (Permissions Not Inherited)

**Added:** 2026-03-17 | **Source:** DevKit | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Background agents launched via the Agent tool (including `run_in_background: true`) cannot use MCP tools like `store_memory`. Tool permissions granted in the parent context are not inherited by subagents. The subagent gets "denied" on every MCP tool call.
**Fix:** Perform all MCP operations from the main context before or after delegating file-based work to the subagent. Do not rely on subagents for MCP-dependent tasks.
