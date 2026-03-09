---
description: Known gotchas and platform-specific issues. Read when debugging unexpected behavior.
tier: 2
entry_count: 94
last_updated: "2026-03-09"
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
**Issue:** When branch protection requires PR reviews or status checks, `gh pr merge` fails if you're the only maintainer.
**Fix:** Use `gh pr merge --admin` to bypass (only for repo admins).

## 3. Git Stash Before PR Merge

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Git
**Issue:** `gh pr merge` can fail if there are uncommitted local changes, even if unrelated.
**Fix:** `git stash` before merging, `git stash pop` after.

## 4. Force Push to Already-Merged Branch Creates Orphan

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub
**Issue:** `git push --force` to a merged PR branch creates a new orphaned remote branch.
**Fix:** Check PR state first: `gh pr view <number> --json state`. Clean up: `git push origin --delete <branch-name>`.

## 5. Incomplete Range Variable Replacement in Loop Refactoring

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (all)
**Issue:** Changing `for _, v := range slice` to `for i := range slice` -- easy to miss `v` references deeper in the loop body.
**Fix:** Search the entire loop body for the old variable name. Replace ALL occurrences with `slice[i]`.

## 6. React Compiler Lint: Refs During Render (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#114 (archived)

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
**Issue:** `python3`/`python`/`py` resolve to Windows Store alias stubs that prompt for install instead of running Python. `command -v` reports them as found.
**Fix:** Check with `"$p" --version` (not `command -v`) and include explicit Windows paths in the search loop.

## 9. jq Not Available on Windows MSYS by Default

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** `jq` is not in Git for Windows / MSYS2 by default.
**Fix:** Use Python's `json` module instead (once you work around gotcha #8).

## 10. UserPromptSubmit Hooks Block Slash Commands and Menu Selections

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (all)
**Issue:** `UserPromptSubmit` hooks with `type: "prompt"` block slash commands and bare numeric menu selections.
**Fix:** Add `matcher` regex: `"^(?!/)(?!\\d{1,2}$)"` to skip slash commands and 1-2 digit numbers.

## 11. GitHub API Returns Empty Without User-Agent Header

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** All (curl, fetch)
**Issue:** GitHub REST API requires a `User-Agent` header. Requests without it return empty or 403.
**Fix:** Always include `User-Agent: <app-name>` in GitHub API requests.

## 12. Swagger Cross-Platform Drift (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active
**Consolidates:** KG#57, KG#59 (archived)
**See also:** AP#17

**Platform:** Go (swaggo/swag, cross-platform)

### time.Duration enum drift

**Issue:** `swag init` generates platform-specific `time.Duration` enum values. Linux CI differs from Windows.
**Fix:** Add `swaggertype:"integer"` struct tag to all `time.Duration` fields in swagger-annotated handlers.

### x-enum-descriptions drift

**Issue:** Windows `swag init` generates `x-enum-descriptions` blocks; Linux omits them.
**Fix:** After `swag init` on Windows, remove all `x-enum-descriptions` blocks: `grep -c "x-enum-descriptions" api/swagger/*` should be 0.

### Perl regex corrupts YAML

**Issue:** Perl regex stripping `x-enum-descriptions` from `swagger.yaml` can join adjacent lines.
**Fix:** After stripping, verify YAML integrity. Consider using yq instead of regex.

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
**Consolidates:** KG#19 (archived)

**Platform:** Windows (PowerShell)

### Start-Process gives child real console

**Issue:** `Start-Process` gives child `ModeCharDevice=true` even with `-WindowStyle Hidden`. Go terminal-detection code still prompts on stdin.
**Fix:** Set environment variables before `Start-Process` to bypass interactive prompts.

### ConvertFrom-Json drops empty arrays (PS 5.1)

**Issue:** `ConvertFrom-Json` on `[]` returns `$null` instead of `@()`.
**Fix:** Use `Invoke-WebRequest` and check `$resp.StatusCode` instead of parsing JSON.

## 20. Stacked PR Rebase After Squash-Merge Requires Skip

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Git / GitHub
**Issue:** After squash-merge, downstream stacked branches have different hashes. `git rebase origin/main` produces conflicts.
**Fix:** Use `git rebase --skip` for each already-merged commit, or `git rebase --onto origin/main <old-base> <branch>`.

## 22. Project Renames Create Competitive Research Blind Spots

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub / All
**Issue:** GitHub project renames make keyword searches miss established competitors. Docker Hub retains old names.
**Fix:** Search by function not product name. Check Docker Hub, GitHub topics/tags, star counts. Re-scan monthly.

## 23. GitHub Rulesets and Protection (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** KG#98, KG#99 (archived)

**Platform:** GitHub

- **404 on protection API:** Repos using rulesets return 404 from branch protection API. Check rulesets: `gh api repos/{owner}/{repo}/rulesets --jq '.[] | {id, name, enforcement}'`.
- **Review conflict:** Both rulesets and branch protection requiring reviews doubles the requirement. Use rulesets for reviews; branch protection only for CI status checks.
- **Split rulesets break Copilot:** Separate PR review and Copilot rulesets cause COMMENTED not APPROVED. Use single combined ruleset. Template: `project-templates/copilot-ruleset.json`. See `claude/rules/review-policy.md`.

## 24. cla-assistant.io Blocks Dependabot PRs

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub
**Issue:** cla-assistant.io creates a permanently "pending" `license/cla` check on Dependabot PRs.
**Fix:** Remove cla-assistant.io (redundant with Actions CLA workflow) or add `dependabot[bot]` to allowlist.

## 25. Parallel Background Agents Share Working Tree (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** KG#76 (archived)

**Platform:** Claude Code (all)

All parallel agents write to the same working directory. Changes mix as unstaged modifications. Sort into branches via stage/stash/pop after agents complete.

**Key scenarios:** (1) Agent autonomous commit runs `git checkout`, destroying other agents' unstaged tracked files -- restrict agents from committing or re-apply from summary. (2) `go build` compiles untracked files from other agents -- stash them before pushing. (3) Stash during running agents is unsafe -- agents keep writing, pop fails. Recovery: commit one agent's files, extract other's via `git diff stash@{0} -- <file>`.

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
**Fix:** Use `TooltipContentProps<number, string>`. For JSX element form, use `Partial<TooltipContentProps<...>>`. See AP#63.

## 29. Build-Tag Files Invisible to Local Lint on Different OS

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (cross-platform)
**Issue:** `//go:build !windows` files are excluded from `golangci-lint` on Windows. Lint errors only appear in Linux CI.
**Fix:** Mentally check for `filepathJoin`, `G115`, `paramTypeCombine`, `prealloc` in platform-specific files. Consider `GOOS=linux golangci-lint run`.

## 30. Background Agents Can't Prompt for Tool Permissions

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Background agents inherit tool permissions. Unapproved tools are silently denied.
**Fix:** Ensure tools are approved before launching background agents. Prefer `subagent_type=Bash` with `gh api`.

## 31. Reddit Blocks WebFetch but gh api Works

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** All (Claude Code)
**Issue:** Reddit blocks WebFetch. Web search with reddit domains returns nothing.
**Fix:** Append `.json` to any Reddit URL and use `gh api -X GET "$URL.json"`. Extract with `--jq`.

## 32. SessionStart Hook: Use `type: "command"` Not `type: "prompt"`

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (all)
**Issue:** `SessionStart` with `type: "prompt"` sends to a small model that can't process instructions.
**Fix:** Use `type: "command"` with `echo` to inject system reminders.

## 33. Claude Code Hooks Cannot Initiate Conversation

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Hooks inject context as system reminders but cannot make Claude proactively start a conversation. User must type something first.
**Fix:** Accept two-step startup. Pair with VS Code `runOn: folderOpen` task for orientation.

## 34. Chrome Ignores autocomplete="off" on Form Fields

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** All browsers
**Issue:** `autocomplete="off"` is ignored. Non-standard `name` attributes cause autofill to overwrite wrong fields.
**Fix:** Use standard `name` + `autocomplete` values: `username`, `email`, `new-password`, `current-password`.

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

## 39. Docker Extension `update` Fails After Image Rebuild

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Docker Desktop Extensions
**Issue:** `docker extension update` returns "not installed" after rebuilding (tracks by image digest, not tag).
**Fix:** Use `docker extension install` instead of `update` when image has been rebuilt.

## 41. .claude/settings.local.json Should Be Gitignored

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (all)
**Issue:** `.claude/settings.local.json` contains local tool permissions. Can be accidentally committed.
**Fix:** Add `.claude/` to `.gitignore`. If committed, `git rm --cached .claude/settings.local.json`.

## 42. BMAD Method Generates 42 Slash Commands

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (all)
**Issue:** `npx bmad-method install` generates 42 slash commands, overwhelming the namespace.
**Fix:** Install in a separate directory, or selectively delete unused `/bmad-bmm-*` command files.

## 43. Spec Kit `specify init` Hangs on Windows MSYS

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (MSYS_NT) / Python Rich library
**Issue:** `specify init` hangs at interactive prompt. Rich library blocks even with piping/redirection.
**Fix:** Skip CLI. Fetch templates via `gh api repos/github/spec-kit/contents/templates/commands --jq '.[].name'`.

## 44. BMAD npm Package Name Is Not Obvious

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** npm / Node.js
**Issue:** Package is `bmad-method`. Common wrong guesses: `bmad-cli`, `@bmadcode/bmad`.
**Fix:** `npx -y bmad-method install --modules bmm --tools claude-code --directory <path> -y`.

## 45. markdownlint-cli2 Config Must Be at Repo Root for CI

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub Actions / markdownlint-cli2
**Issue:** `config` parameter doesn't reliably override lookup. Config in subdirectory only won't be found by CI.
**Fix:** Place `.markdownlint.json` at repo root. Remove `config` parameter from the action.

## 46. markdownlint MD060 Auto-Enabled by Default: True

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** markdownlint v0.40.0+
**Issue:** MD060 (table-column-style) auto-enables with `"default": true`. Appears after version upgrade.
**Fix:** Add `"MD060": false` to config, or fix table pipe spacing consistency.

## 47. PowerShell [Mandatory] Validates Each Element in String Arrays

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** PowerShell 7+
**Issue:** `[Mandatory] [string[]]` validates each element. Empty strings `''` fail validation.
**Fix:** Add `[AllowEmptyString()]` alongside `[Mandatory]`.

## 48. Win32_Processor.VirtualizationFirmwareEnabled False When Hypervisor Running

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (Hyper-V)
**Issue:** `VirtualizationFirmwareEnabled` returns `$false` when Hyper-V is already active (hypervisor claimed VT-x).
**Fix:** Use Hyper-V state as fallback: `if ($virtCheck.Met -or $hyperVMet) { # confirmed }`.

## 49. PowerShell Get-ChildItem Misses Dotfiles Without -Force

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** PowerShell (all)
**Issue:** `Get-ChildItem` skips dotfiles (hidden on Windows). Filter `credentials*` won't match `.credentials*`.
**Fix:** Use `-Force` flag AND add separate `.credentials*` filter.

## 50. Winget Exit Code -1978335189 Means Already Installed

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (winget)
**Issue:** `winget install` returns `-1978335189` when already installed. Scripts treat it as failure.
**Fix:** Check for exit codes `-1978335189` and `-1978335184` and treat as success.

## 51. Winget Installs Update Registry PATH but Current Session Is Stale

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (PowerShell / MSYS)
**Issue:** Winget-installed tools update registry PATH but current session has old PATH.
**Fix:** Refresh: `$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')`.

## 54. PowerShell param() and CI Ordering (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active
**Consolidates:** KG#75 (archived)

**Platform:** PowerShell 7+ / GitHub

### param() must be first executable statement

**Issue:** `Set-StrictMode` before `param()` causes confusing error.
**Fix:** Only comments and `#Requires` before `param()`. Everything else after.

### Branch protection requires pre-existing CI check names

**Issue:** `required_status_checks.contexts` must reference jobs that have already run. Setting protection before CI workflow ships blocks all PRs.
**Fix:** Merge CI workflow first, verify job names in Actions tab, then apply protection.

## 55. VS 2022 Bundled Node.js as Fallback for Frontend Builds

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** Node.js/npm/pnpm may not be on PATH, but VS 2022 bundles Node.js at a known path.
**Fix:** Write a temp `.ps1` file with PATH prepended, execute with `powershell.exe -NoProfile -File`. See AP#76.

## 56. Subagent pnpm-lock.yaml Drift When Node.js Unavailable

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (Windows)
**Issue:** Subagent adds deps to `package.json` but can't run `pnpm install`. CI fails with `ERR_PNPM_OUTDATED_LOCKFILE`.
**Fix:** Run `pnpm install` after merging subagent changes to update lockfile.

## 58. Local Main Diverges After Squash-Merge When Merge Commits Exist

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Git (all)
**Issue:** Local merge commits cause `git pull --ff-only` to fail after squash-merge.
**Fix:** `git reset --hard origin/main` when local main has no uncommitted work. Prevent with `git config pull.ff only`.

## 60. Go Binary Permission Denied on MSYS -- Use go run Instead

**Added:** 2026-02-24 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** Go binaries in `~/go/bin/` get "permission denied" on MSYS despite execute bits.
**Fix:** Use `go run github.com/.../tool@vX.Y.Z` instead of local binary. Works for swag, golangci-lint, etc.

## 61. Claude Code settings.local.json Does NOT Cascade from Parent Directories

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Settings do NOT cascade from parent directories. Each project is independent. Hierarchy: user (`~/.claude/`) > project (`.claude/`) > local.
**Fix:** Put broad wildcards in `~/.claude/settings.json`. Copy `project-templates/settings.json` for new projects. See AP#86.

## 62. Windows CRLF Breaks Bash grep Value Extraction in CI

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** GitHub Actions (Ubuntu) / Windows-committed files
**Issue:** `\r\n` line endings cause trailing `\r` in grep output, breaking string comparisons and arithmetic.
**Fix:** Pre-process with `tr -d '\r' < "$file" > "$clean_file"` before parsing.

## 63. Lipgloss Emoji Variation Selector Width Mismatch

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (charmbracelet/lipgloss)
**Issue:** Emoji with U+FE0F renders as 2 cells but lipgloss counts as 1, causing border misalignment.
**Fix:** Use emoji in U+1Fxxx range (consistent 2-cell width). Avoid variation selectors in TUI content.

## 64. lipgloss.Place Output Is Not Safely ANSI-Strippable

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (charmbracelet/lipgloss)
**Issue:** Stripping ANSI from lipgloss output for position computation fails due to width calculation mismatches.
**Fix:** Create a dedicated plain-text renderer method sharing layout logic, not strip ANSI from styled output.

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
**Consolidates:** KG#78, KG#81, KG#82, KG#83, KG#84, KG#85 (archived)

**Platform:** Docker Desktop Extensions

- **Marketplace:** Images show as regular containers on Docker Hub. Submit via [docker/extensions-submissions](https://github.com/docker/extensions-submissions). Run `docker extension validate` first.
- **hadolint:** DL3048/DL3045 are false positives. Add `.hadolint.yaml` with `ignored: [DL3048, DL3045]`.
- **Vitest:** `@docker/extension-api-client` CJS/ESM mismatch. Add `resolve.alias` -> mock file. See KG#87.
- **Version drift:** Designate one source of truth (`VERSION` or `package.json`). CI overrides Dockerfile ARG via `--build-arg`.
- **Labels:** Screenshots (JSON array, min 3, 2400x1600px), changelog (HTML), additional-urls (JSON), icon (local file). Escaped quotes. See [docs](https://docs.docker.com/extensions/extensions-sdk/extensions/labels/).
- **Multi-arch:** Must build `linux/amd64` + `linux/arm64` via `docker buildx`.
- **MUI v5:** `@docker/docker-mui-theme` pins v5. Use `InputProps` not `slotProps.input`. Reference v5 docs only.
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
**Fix:** Use `$obj.PSObject.Properties.Match('prop').Count -gt 0` for existence checks. Does NOT affect hashtables.

## 86. grep -c With || echo "0" Doubles Output on No Match

**Added:** 2026-03-02 | **Source:** DevKit | **Status:** active

**Platform:** Bash (all, especially CI)
**Issue:** `grep -c` outputs "0" AND exits code 1. `$(grep -c ... || echo "0")` captures "0\n0", breaking arithmetic.
**Fix:** Use `|| true` instead of `|| echo "0"`. See also KG#62 (CRLF grep issues).

## 87. Vitest Cannot Resolve Browser-Only npm Package Exports

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** active

**Platform:** Vitest / Node.js
**Issue:** Packages with only `browser` field (no `main`/`exports`) fail in Vitest's Node.js resolution.
**Fix:** Add `resolve.alias` in `vitest.config.ts` pointing to the package's dist entry file. See also KG#77 (Docker extension-specific case).

## 88. .NET WPF Projects Fail dotnet restore on Linux CI

**Added:** 2026-03-02 | **Source:** IPScan | **Status:** active

**Platform:** .NET / GitHub Actions (Ubuntu)
**Issue:** `dotnet restore` on solution with WPF projects fails on Ubuntu with `NETSDK1100`.
**Fix:** Scope `dotnet restore` and `dotnet test` to individual cross-platform .csproj files instead of the solution.

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

## 93. Git Init Template CLAUDE.md Breaks Markdownlint

**Added:** 2026-03-05 | **Source:** DigitalRain | **Status:** active

**Platform:** Git (all) / markdownlint-cli2
**Issue:** `git init.templateDir` copies CLAUDE.md into `.git/`. Markdownlint's `**/*.md` picks it up.
**Fix:** Add `"#.git"` to all markdownlint exclusion patterns.

## 94. GITHUB_TOKEN-Created Tags Don't Trigger Push Events

**Added:** 2026-03-05 | **Source:** Runbooks | **Status:** active
**Last relevant:** 2026-03-08

**Platform:** GitHub Actions
**Issue:** Tags created by `GITHUB_TOKEN` don't trigger `on: push: tags:` in other workflows (anti-recursion safeguard).
**Fix:** Chain publish job in same workflow using `release_created` output. Or use `on: release: types: [published]` in separate workflow. For release-please specifically, use `RELEASE_PLEASE_TOKEN` (a PAT) instead of `GITHUB_TOKEN` -- see AP#120.

## 95. Release-Please Branch Updates Don't Always Trigger CI

**Added:** 2026-03-05 | **Source:** Runbooks | **Status:** active

**Platform:** GitHub Actions
**Issue:** `pull_request: synchronize` sometimes doesn't fire for release-please commits. PR gets stale checks.
**Fix:** Deploy `retrigger-ci.yml` workflow. Manual: `gh pr close N && sleep 2 && gh pr reopen N`. Template: `project-templates/retrigger-ci.yml`.

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
**Issue:** Rules files in `claude/rules/` load into every Claude Code session as system context. Files over 40k cause large input blocks to be ignored at task transitions (Variant B stall pattern). The session appears to work normally but silently drops context from oversized rules, leading to repeated mistakes and missed patterns.
**Symptom:** Agent ignores known patterns documented in rules files. Task transitions (switching between plan/code/verify phases) lose context from rules that should apply. Rules files that were 2.5x over the 40k threshold caused measurable degradation.
**Fix:** Run `/rules-compact` to archive stale entries, deduplicate same-root-cause patterns, and consolidate related entries below 35k per file.
**Prevention:** The conformance-audit checklist (check #17) flags any rules file over 40k. Run `/conformance-audit` periodically to catch growth before it hits the limit. Target 35k per file to leave headroom.

## 99. Copilot Cannot Approve PRs -- Review Is Informational Only

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active
**Last relevant:** 2026-03-09

**Platform:** GitHub
**Issue:** Copilot code review can only COMMENT on PRs, never APPROVE. Setting `required_approving_review_count: 1` in a ruleset creates a gate that can never be satisfied without `--admin` bypass. Previous configurations attempted workarounds (combined rulesets, split rulesets) but none solve the fundamental constraint: Copilot cannot approve.
**Fix:** Set `required_approving_review_count: 0`. Keep `copilot_code_review` with `review_on_push: true` for informational comments. CI is the only merge gate. Claude Code reads Copilot comments after CI passes, implements valid ones, and merges without waiting for re-review. Use `--admin` only for CI infrastructure failures, never to skip Copilot feedback. Template: `project-templates/copilot-ruleset.json`. Audit: `scripts/copilot-review-setup.sh audit OWNER/REPO`.

## 100. Large Input Block Ignored at Task Transition (Variant B Stall)

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Platform:** Claude Code (sidebar extension and terminal)
**Issue:** After completing a multi-step task, CC displays a newly pasted large input block as text rather than executing it. The session appears frozen. This is distinct from Variant A (skill menu blocking) -- there is no menu, no prompt, CC simply does not act on the input.
**Root cause:** Context saturation at task boundaries. CC has processed a full implementation session and the accumulated context leaves insufficient headroom to treat the new input as a fresh task instruction.
**Symptoms:** Large handoff prompt pasted after task completion. CC shows the text in the chat panel. No bash commands run. `?` button appears at bottom. Sending `?` or `continue` may or may not unstick it -- success rate is low on third or subsequent attempts.
**Fix:** Kill the session and open a fresh one (`+` in sidebar, `Ctrl+C` then `claude` in terminal). Paste the handoff into the new session. Do NOT attempt to recover a saturated session with multiple `?` prompts -- each attempt consumes more context.
**Prevention:** Keep handoff prompts under 40 lines. Split multi-part handoffs into separate sessions. Run `/rules-compact` if rules files approach 40k -- oversized rules files accelerate context saturation on load.
**Recovery escalation:** If `?` fails twice, the session is unrecoverable. Open fresh immediately.

## 101. Claude Code Edit Tool CRLF Matching Failure on Windows

**Added:** 2026-03-07 | **Source:** Samverk | **Status:** active

**Platform:** Windows (MSYS_NT) / Claude Code
**Issue:** The Edit tool's `old_string` matching fails silently on files with Windows CRLF (`\r\n`) line endings. The `\r` characters are invisible but prevent exact string matching. Affects every Edit call on CRLF files.
**Workarounds:**

- Use Python binary-mode scripts: `open('file', 'rb')` / `open('file', 'wb')` with explicit `\r\n` in replacement strings
- Use the Write tool to create new files instead of appending to large existing CRLF files
- `sed` is also unreliable on MSYS (literal `t` instead of tab with `\t` escapes)

- When parsing GitHub API issue bodies in Python, always normalize first:
  `body = body.replace("\r\n", "\n")` before any regex matching

**See also:** KG#62 (CRLF breaks bash grep in CI -- same root cause, different tool);
KG#109 (GitHub API response CRLF -- same root cause, third surface)

## 102. Samverk Dispatcher False-Positive on Issues Without Frontmatter

**Added:** 2026-03-07 | **Source:** Samverk | **Status:** active

**Platform:** Samverk dispatcher
**Issue:** The dispatcher's `classify` path requires YAML frontmatter in issue bodies. Issues that are valid but have no frontmatter (e.g., plain prose issues, Copilot-generated issues) trigger `invalid_frontmatter` escalation, which applies `status:needs-human` and halts routing. The issue is not actually blocked -- the label is a false positive.
**Symptom:** Valid issue receives `status:needs-human` label immediately after creation or assignment. Dispatcher comment reads: `ESCALATE [dispatcher] trigger: invalid_frontmatter details: classify issue ... no frontmatter found`.
**Workaround:** Remove the `status:needs-human` label manually. The issue is valid; proceed normally.
**Fix needed:** Dispatcher should treat `invalid_frontmatter` as a soft warning, not a hard escalation. Options: (1) skip frontmatter requirement for issues created by Copilot or external agents, (2) route to a fallback classify path using title/label heuristics, (3) only escalate if frontmatter is present but malformed. See Samverk issue #180.
**See also:** KG#99 (Copilot review is informational -- same "Copilot-as-actor" surface area)

## 103. Copilot Sub-PRs Target Feature Branch, Not Main

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Platform:** GitHub (Copilot coding agent)
**Issue:** Copilot's auto-generated sub-PRs (follow-up fix suggestions) target the feature branch that triggered the review, not `main`. When that feature branch is squash-merged and closed, the Copilot sub-PRs still point to the now-dead branch. Merging them (even with `--admin`) lands commits on the dead branch, not `main`. Changes are silently lost.
**Symptom:** `gh pr merge <copilot-pr> --admin` succeeds but the fixes never appear on `main`.
**Fix:** Before merging any Copilot sub-PR, check its target: `gh pr view <number> --json baseRefName,state`. If `baseRefName` is not `main` and the original PR is already merged, apply the fixes manually on a new branch from `main`.
**See also:** KG#99 (Copilot review is informational -- same Copilot-as-actor surface area)

## 104. PowerShell Unused Variable Triggers PSScriptAnalyzer Warning

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell (PSScriptAnalyzer)
**Issue:** `PSUseDeclaredVarsMoreThanAssignments` fires when command output is captured into a variable that is never read: `$output = & command 2>&1 | Out-String`. If `$output` is only assigned and never referenced, the analyser warns. Caught by local PostToolUse hook; NOT caught by DevKit CI (issue #243 tracks adding PS lint to CI).
**Fix:** Use `$null = & command 2>&1` to explicitly discard output. Drop `Out-String` — allocation is wasted if the result isn't used.

## 105. PowerShell 2>&1 Mixes Stderr Into Parsed Output

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell (all)
**Issue:** `& command 2>&1 | Out-String` merges stderr into the stdout string. When the output is parsed line-by-line for data (e.g. repo names from `gh api`), any error message from the command appears as a fake data record. Splitting on newlines produces garbage entries.
**Fix:** Redirect stderr to a temp file to isolate it:

```powershell
$tmpErr = [System.IO.Path]::GetTempFileName()
try {
    $out = & command 2>$tmpErr | Out-String
    if ($LASTEXITCODE -ne 0) {
        $err = Get-Content $tmpErr -Raw -ErrorAction SilentlyContinue
        Write-Error "command failed: $err"
        exit 1
    }
} finally {
    Remove-Item $tmpErr -ErrorAction SilentlyContinue
}
```

**See also:** AP#76 (temp-file pattern for MSYS→PowerShell), KG#104 (unused var warning from the same code path)

## 106. Inserting into Numbered Markdown List Requires Full Renumbering

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Platform:** All (markdownlint MD029)
**Issue:** When inserting a new item mid-way into a numbered markdown list, every subsequent item must be renumbered in the same edit. Forgetting to renumber creates duplicate numbers and triggers MD029: "Expected: N; Actual: M; Style: 1/2/3".
**Fix:** Before inserting, count the total items. After inserting, update every item number from the insertion point to the end. When in doubt, read the list with line numbers first (`Read` tool with limit), then make all numbering changes in a single Edit call.

## 107. gh api -f Flags Default to POST — Use URL Query Params for GET

**Added:** 2026-03-08 | **Source:** Samverk | **Status:** active

**Platform:** GitHub CLI (all)
**Issue:** Using `-f field=value` with `gh api` automatically sets the HTTP method
to POST. For GET requests (listing issues, milestones, etc.) passing `-f milestone=5`
causes HTTP 422 "title wasn't supplied" because GitHub interprets it as a create call.
**Fix:** Embed params as URL query string instead:

```bash
gh api "repos/{owner}/{repo}/issues?milestone=5&state=open&per_page=100" --paginate
```

**See also:** KG#108 (gh issue create --milestone takes title, not number)

## 108. gh issue create --milestone Takes Title, Not Number

**Added:** 2026-03-08 | **Source:** Samverk | **Status:** active

**Platform:** GitHub CLI (all)
**Issue:** `gh issue create --milestone` accepts the milestone TITLE as a string.
If you resolve a title to its number (e.g., 5) and pass `--milestone 5`, gh CLI
searches for a milestone titled "5" and fails with "could not add to milestone
'5': '5' not found".
**Symptom:**

```bash
MILESTONE_NUM=$(resolve_milestone "$MILESTONE_TITLE")  # returns 5
gh issue create --milestone "$MILESTONE_NUM"            # fails: '5' not found
```

**Fix:** Pass the title directly:

```bash
gh issue create --milestone "Gitea Migration"   # correct
gh issue create --milestone "$MILESTONE_NUM"    # wrong -- number is not a title
```

Note: `gh api PATCH /repos/{owner}/{repo}/issues/{n}` with `-F milestone=5` does
accept the number (REST API level). The discrepancy is in the `gh` CLI layer.
**See also:** KG#107 (gh api -f flag POST/GET issue)

## 109. GitHub REST API Returns CRLF in Issue Body Text Fields

**Added:** 2026-03-09 | **Source:** Samverk | **Status:** active

**Platform:** Windows / GitHub REST API (gh api)
**Issue:** When fetching issue bodies via `gh api`, the `body` field contains `\r\n` (CRLF) line endings on Windows. Python regex patterns that match `\n` fail silently — for example, `FRONTMATTER_RE.search(body)` returns `None` even when the body starts with `---`, because the actual content is `---\r\n`.
**Fix:** Normalize line endings before any regex or string parsing:

```python
body = body.replace("\r\n", "\n")
```

**See also:** KG#62 (CRLF breaks bash grep in CI); KG#101 (Edit tool CRLF matching failure -- same root cause, different surface)

## 110. GitHub Actions New CI Job Uses Base Branch Workflow, Not PR Branch

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** GitHub Actions
**Issue:** When a PR introduces a new CI job for the first time, GitHub Actions runs the workflow from the BASE branch (usually `main`), not the PR branch. The new job doesn't exist on `main` yet, so it is silently absent from the CI run. The PR passes CI (the new job never runs), then ALL subsequent PRs fail because the job now exists on `main` and is broken.
**Fix:** Before merging a PR that adds a new CI job, verify the job ran in the CI check list. If the new job name is absent from the check list, the workflow was evaluated from `main`. To test the new job, merge a trivially correct version first, then fix issues in follow-up PRs.
**See also:** KG#66 (golangci-lint-action v7 schema enforcement -- same CI surprise pattern)

## 111. markdownlint 3-Backtick Outer Fence Broken by Inner Backtick Blocks

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** All (markdownlint-cli2)
**Issue:** A fenced code block using ` ```language ` as the outer fence is terminated by the first inner ` ``` ` block it contains. Everything after the inner block is treated as regular markdown, triggering MD029, MD031, MD033, MD040, and other rules on content that was supposed to be inside the fence.
**Fix:** When a code block's content contains triple-backtick fences (e.g., a markdown template or documentation showing code examples), use a 4-backtick outer fence:

`````markdown
````markdown
...content with inner ```bash blocks...
````
`````

Verify locally with `npx markdownlint-cli2 "path/to/file.md"` before pushing.

## 112. Invoke-ScriptAnalyzer Has No -Include Parameter

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Platform:** PowerShell / PSScriptAnalyzer
**Issue:** `Invoke-ScriptAnalyzer -Path . -Include '*.ps1'` throws "A parameter cannot be found that matches parameter name 'Include'". The `-Include` parameter does not exist on `Invoke-ScriptAnalyzer`. Copilot and LLMs commonly generate this invalid syntax.
**Fix:** Use `Get-ChildItem` to collect files, then pipe each to `Invoke-ScriptAnalyzer`:

```powershell
$files = Get-ChildItem -Path . -Recurse -Filter '*.ps1'
$results = $files | ForEach-Object {
    Invoke-ScriptAnalyzer -Path $_.FullName -Severity Warning,Error
}
```

To scan only specific subdirectories, scope `Get-ChildItem -Path setup,scripts`.

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
