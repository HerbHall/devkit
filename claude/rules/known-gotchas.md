---
description: Known gotchas and platform-specific issues. Read when debugging unexpected behavior.
tier: 2
entry_count: 63
last_updated: "2026-03-14"
---

# Known Gotchas

Platform-specific issues, tool quirks, and surprising behaviors discovered through past sessions.

## 1. Windows MSYS Bash Path Translation

**Added:** 2026-02-17 | **Source:** global | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** MSYS bash auto-translates Unix-style paths to Windows paths. Paths starting with `/c/` become `C:\`.
**Fix:** Use `MSYS_NO_PATHCONV=1` prefix or double-slash `//` to prevent translation.

## 2. GitHub Branch Protection Requires --admin for Merge

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub
**Fix:** `gh pr merge --admin` bypasses protection when you're the only maintainer.

## 5. Incomplete Range Variable Replacement in Loop Refactoring

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (all)
**Issue:** Changing `for _, v := range slice` to `for i := range slice` -- easy to miss `v` references deeper in the loop body.
**Fix:** Search the entire loop body for the old variable name. Replace ALL occurrences with `slice[i]`.

## 6. React Compiler Lint: Refs During Render (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active

**Platform:** React 19+ / ESLint react-hooks

### Mutating refs during render

**Issue:** `onMessageRef.current = onMessage` at top level triggers "Cannot update ref during render".
**Fix:** Wrap in `useEffect(() => { onMessageRef.current = onMessage }, [onMessage])`.

### Callback ref for Popper anchors

**Issue:** MUI `Popper`/`Popover` needs `anchorEl` during render. Using `useRef` + `ref.current` triggers the refs rule.
**Fix:** Use callback ref with `useState`: `const [anchorEl, setAnchorEl] = useState(null)` then `<Button ref={setAnchorEl}>`.

## 7. React Compiler Lint: Recursive useCallback Self-Reference

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** React 19+ / ESLint react-hooks/immutability rule
**Issue:** Recursive `useCallback` (e.g., `connect()` calling itself in `onclose`) triggers "Cannot access variable before it is declared".
**Fix:** Store in a ref: `const connectRef = useRef<() => void>()` and call `connectRef.current?.()` for recursion.

## 8. Windows Python Aliases Shadow Real Python

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** `python3`/`python`/`py` resolve to Windows Store alias stubs. `command -v` reports them as found.
**Fix:** Check with `"$p" --version` (not `command -v`). Include explicit Windows paths in the search loop.

## 11. GitHub API Returns Empty Without User-Agent Header

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** All (curl, fetch)
**Issue:** GitHub REST API requires a `User-Agent` header. Requests without it return empty or 403.
**Fix:** Always include `User-Agent: <app-name>` in GitHub API requests.

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

## 13. Swagger Drift After Any Handler/Model Change

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (swaggo/swag)
**Issue:** ANY change to Go types in swagger-annotated handlers requires regenerating the swagger spec.
**Fix:** Always run `swag init` (or `make swagger`) after modifying handlers/structs. Commit regenerated files alongside Go changes.

## 14. Go Nil Guard: Split Chained Nil Checks Into Separate Blocks

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (all)
**Issue:** `if obj.Field == nil || obj.Field.Sub == 0` with logging that accesses `obj.Field.X` panics when `obj.Field` is nil.
**Fix:** Split into two separate `if` blocks -- check nil first, then check the field.

## 15. Squash-Merged Branches Don't Appear in `git branch --merged`

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Git (all)
**Issue:** After squash-merge, `git branch --merged main` won't list the branch (different hashes).
**Fix:** Use `git branch -D` (force delete). Verify safety with `git remote prune origin` first.

## 16. GitHub `Closes #N` Comma Syntax Only Closes First Issue

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub
**Issue:** `Closes #1, #2, #3` only auto-closes #1. GitHub requires the keyword before each number.
**Fix:** Use `Closes #1, Closes #2, Closes #3` or one per line.

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

**Key scenarios:** (1) `git checkout` destroys other agents' unstaged tracked files. (2) `go build` compiles untracked files from other agents -- stash before pushing. (3) Stash during running agents is unsafe -- commit one agent's files first.

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

## 37. VS Code Locks Workspace Root Directories

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (VS Code)
**Issue:** `rm -rf` fails on directories VS Code has open as workspace roots. File watcher holds handles.
**Fix:** Remove contents first, then reload VS Code with updated workspace config. Or close VS Code first.

## 38. Playwright getByLabel Resolves Multiple Elements with Toggle Buttons

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Playwright (all)
**Issue:** `getByLabel('Password')` matches both the input and companion toggle button.
**Fix:** Use `page.locator('#password')` to target by ID instead.

## 47. PowerShell [Mandatory] Validates Each Element in String Arrays

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** PowerShell 7+
**Issue:** `[Mandatory] [string[]]` validates each element. Empty strings `''` fail validation.
**Fix:** Add `[AllowEmptyString()]` alongside `[Mandatory]`.

## 48. Win32_Processor.VirtualizationFirmwareEnabled False When Hypervisor Running

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (Hyper-V)
**Issue:** Returns `$false` when Hyper-V is already active (hypervisor claimed VT-x).
**Fix:** Use Hyper-V state as fallback: `if ($virtCheck.Met -or $hyperVMet) { # confirmed }`.

## 49. PowerShell Get-ChildItem Misses Dotfiles Without -Force

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** PowerShell (all)
**Issue:** `Get-ChildItem` skips dotfiles (hidden on Windows). Filter `credentials*` won't match `.credentials*`.
**Fix:** Use `-Force` flag AND add separate `.credentials*` filter.

## 50. Winget Installation Gotchas (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (winget / PowerShell / MSYS)

### Exit codes for "already installed"

**Issue:** `winget install` returns `-1978335189` (already installed) or `-1978335184`. Scripts treat as failure.
**Fix:** Check for both exit codes and treat as success.

### PATH staleness after install

**Issue:** Winget-installed tools update registry PATH but current session has old PATH.
**Fix:** Refresh: `$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')`.

## 54. PowerShell param() and CI Ordering (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** PowerShell 7+ / GitHub

### param() must be first executable statement

**Issue:** `Set-StrictMode` before `param()` causes confusing error.
**Fix:** Only comments and `#Requires` before `param()`.

### Branch protection requires pre-existing CI check names

**Issue:** `required_status_checks.contexts` must reference jobs that have already run.
**Fix:** Merge CI workflow first, verify job names in Actions tab, then apply protection.

## 56. Subagent pnpm-lock.yaml Drift When Node.js Unavailable

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (Windows)
**Issue:** Subagent adds deps to `package.json` but can't run `pnpm install`. CI fails with `ERR_PNPM_OUTDATED_LOCKFILE`.
**Fix:** Run `pnpm install` after merging subagent changes to update lockfile.

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

## 65. golangci-lint v2 Config Requirements

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (all)
**Issue:** v1 configs lack `version: "2"` field. v2 exits with "unsupported version" error. Build/test pass fine.
**Fix:** Add `version: "2"` as first field. Update module path to `.../v2/cmd/golangci-lint`. Use devkit template `project-templates/golangci.yml`.

## 66. golangci-lint-action v7 Runs config verify (Schema Enforcement)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub Actions
**Issue:** v7 enforces strict JSON schema. v2.1 config keys fail with v2.10 schema. `linters-settings:` moved under `linters: settings:`. `issues: exclude-rules:` moved to `linters: exclusions: rules:`.
**Fix:** Migrate config to v2.10 schema. Use `@v7` (not `@v6`) for golangci-lint v2. Default binary mode (not `goinstall`).

## 67. Agent-Generated Markdown Tables: Pipes in Cells and Missing Columns

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** All (markdownlint)
**Issue:** Agent markdown tables have MD056 errors: pipes in code spans parsed as separators, or missing columns.
**Fix:** Run `npx markdownlint-cli2` on agent `.md` files. Use `&#124;` for pipes in cells. Verify column counts.

## 72. ESLint react-hooks/set-state-in-effect Cannot Be Inline-Disabled

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** React / ESLint
**Issue:** This rule does NOT support `// eslint-disable-next-line`. Adding it produces "Unused directive".
**Fix:** Config-level override only: `"react-hooks/set-state-in-effect": "warn"` in `eslint.config.js`.

## 73. ESLint 10 Breaks react-hooks Plugin Peer Dependency

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** npm / React
**Issue:** ESLint 10.x breaks `eslint-plugin-react-hooks` which requires `eslint@^9`.
**Fix:** Pin: `npm install --save-dev eslint@^9 @eslint/js@^9`.

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

## 79. GitHub Secrets UI Is Buried Under Expandable Sidebar

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub
**Issue:** Repo secrets are under Settings > Secrets and variables > Actions (expandable submenu).
**Fix:** Use CLI: `gh secret set SECRETNAME`. `gh secret list` to verify.

## 80. PowerShell StrictMode Throws on Nonexistent Property Access

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** PowerShell 7+
**Issue:** Under StrictMode, accessing nonexistent property on PSCustomObject throws -- even in conditionals.
**Fix:** Use `$obj.PSObject.Properties.Match('prop').Count -gt 0`. Does NOT affect hashtables.

## 86. grep -c With || echo "0" Doubles Output on No Match

**Added:** 2026-03-02 | **Source:** DevKit | **Status:** active

**Platform:** Bash (all, especially CI)
**Issue:** `grep -c` outputs "0" AND exits code 1. `$(grep -c ... || echo "0")` captures "0\n0", breaking arithmetic.
**Fix:** Use `|| true` instead of `|| echo "0"`.

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

## 100. Large Input Block Ignored at Task Transition (Variant B Stall)

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Platform:** Claude Code (all)
**Issue:** After completing a multi-step task, CC displays a pasted large input block as text rather than executing it. Context saturation at task boundaries.
**Fix:** Kill session and open fresh. Do NOT attempt multiple `?` prompts -- if it fails twice, session is unrecoverable.
**Prevention:** Keep handoff prompts under 40 lines. Run `/rules-compact` if rules files approach 40k.

## 104. PowerShell Output Capture Gotchas (Consolidated Reference)

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell (all)

### Unused variable warning

**Issue:** `$output = & command 2>&1 | Out-String` where `$output` is never read triggers `PSUseDeclaredVarsMoreThanAssignments`.
**Fix:** Use `$null = & command 2>&1` to explicitly discard output.

### Stderr mixes into parsed output

**Issue:** `& command 2>&1 | Out-String` merges stderr into stdout. Parsing line-by-line produces garbage entries.
**Fix:** Redirect stderr to a temp file: `$out = & command 2>$tmpErr | Out-String`. Check `$LASTEXITCODE` and read `$tmpErr` on failure.

## 107. gh CLI Parameter Gotchas (Consolidated Reference)

**Added:** 2026-03-08 | **Source:** Samverk | **Status:** active

**Platform:** GitHub CLI (all)

### -f flags default to POST

**Issue:** `-f field=value` with `gh api` sets HTTP method to POST. GET requests fail with 422.
**Fix:** Embed params as URL query string: `gh api "repos/{owner}/{repo}/issues?milestone=5&state=open"`.

### --milestone takes title, not number

**Issue:** `gh issue create --milestone 5` fails -- CLI expects the milestone TITLE, not its number.
**Fix:** Pass title directly: `gh issue create --milestone "Gitea Migration"`. Note: REST API (`-F milestone=5`) does accept numbers.

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

## 112. Invoke-ScriptAnalyzer Has No -Include Parameter

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell / PSScriptAnalyzer
**Issue:** `-Include` parameter does not exist. Copilot and LLMs commonly generate this invalid syntax.
**Fix:** Use `Get-ChildItem -Recurse -Filter '*.ps1'` to collect files, then pipe each to `Invoke-ScriptAnalyzer`.

## 113. PowerShell $args Is an Automatic Variable

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell (all)
**Issue:** `$args` is a PowerShell automatic variable containing the unbound parameters for the current function or script. Using it as a local variable name (e.g., `$args = @('label', 'create', ...)`) triggers `PSAvoidAssignmentToAutomaticVariable`. PSScriptAnalyzer flags it as an error.
**Fix:** Rename to `$cmdArgs`, `$labelArgs`, `$cliArgs`, or any non-reserved name. Full list of automatic variables: `$args`, `$error`, `$input`, `$matches`, `$myinvocation`, `$ofs`, `$profile`, `$psboundparameters`, `$pscmdlet`, `$psscriptroot`, etc.
**See also:** KG#104 (PSUseDeclaredVarsMoreThanAssignments -- related PSScriptAnalyzer surface)

## 114. Set-StrictMode in Dot-Sourced PS Lib Pollutes Caller Scope

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell (all)
**Issue:** `Set-StrictMode -Version Latest` at the top level of a dot-sourced `.ps1` lib file (`. "$PSScriptRoot\lib\foo.ps1"`) propagates to the calling script's scope and all subsequently dot-sourced files. This silently tightens rules in callers that didn't opt in and can cause unexpected runtime errors.
**Fix:** Do NOT put `Set-StrictMode` in dot-sourced library files. Set it only in the entry-point script (`setup.ps1`, `new-project.ps1`, etc.) that owns its own execution context.

## 115. TypeScript API Interface Phantom Field Drift from Go Backend

**Added:** 2026-03-09 | **Source:** Samverk | **Status:** active

**Platform:** TypeScript / Go (full-stack)
**Issue:** TypeScript API interfaces accumulate phantom fields the Go backend never sends. Causes `undefined` React keys and silent failures.
**Fix:** Verify TS interfaces against actual Go JSON output (`curl` the endpoint). Grep for TS uses when changing Go JSON field names. See AP#79.
