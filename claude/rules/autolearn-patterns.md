---
description: Learned patterns from past sessions. Read when encountering similar situations.
tier: 2
entry_count: 74
last_updated: "2026-03-09"
---

# Learned Patterns

Patterns discovered through past sessions. Each entry includes the pattern, context, and fix/approach.

## 1. gosec G101 False Positive on Constants Near Credential Code

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** lint-fix
**Context:** gosec G101 flags constants as "hardcoded credentials" when their name contains "credential", "password", "secret", "token", or "passphrase", OR when their value contains sensitive-looking strings. Expect 5-10+ false positives in vault/credential modules.
**Fix:** Add `//nolint:gosec // G101: <reason>` on each flagged line. Proactively annotate ALL credential-adjacent constants in a single pass.

## 2. gocritic Lint Patterns (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#14, AP#15, AP#59, AP#61, AP#62, AP#64, AP#65, AP#66, AP#105, AP#113 (archived)

**Category:** lint-fix

Comprehensive reference for gocritic lint rules encountered across projects.

### rangeValCopy

**Context:** `for _, v := range slice` copies structs >64 bytes each iteration.
**Fix:** Use `for i := range slice` with `slice[i].Field`. Replace ALL loop body references.

### builtinShadow

**Context:** Parameters named `new`, `make`, `len`, `cap`, `close`, `delete`, `copy`, `append`, `min`, `max`, `clear` shadow Go builtins.
**Fix:** Rename to `n`, `count`, `limit`, `val`, `updated`, etc.

### httpNoBody

**Context:** `http.NewRequestWithContext(ctx, http.MethodGet, url, nil)` -- nil body is ambiguous.
**Fix:** Use `http.NoBody` instead of `nil` for GET/HEAD/DELETE requests.

### commentedOutCode

**Context:** Math-heavy comments like `// OUI(15) + Port(15) = 30` look like code.
**Fix:** Rephrase to natural language: `// Expected: OUI weight + Port weight`.

### unnamedResult

**Context:** Functions returning `(float64, string)` without named returns.
**Fix:** Add names, then change `:=` to `=` for those variables and remove redundant `var` declarations.

### appendCombine

**Context:** Two consecutive `append()` calls to the same slice.
**Fix:** Combine into single `append` with multiple elements.

### paramTypeCombine

**Context:** `(a int, b int)` -- consecutive same-type params.
**Fix:** Combine: `(a, b int)`. Only applies to adjacent params.

### dupBranchBody

**Context:** Identical `if/else` branch bodies.
**Fix:** Remove the conditional, keep just the body.

### emptyStringTest

**Context:** `len(s) > 0` for string emptiness.
**Fix:** Use `s != ""` (or `s == ""`).

### sloppyReassign

**Context:** `if err = f(); err != nil` overwrites named return `err`.
**Fix:** Use `:=` to shadow: `if err := f(); err != nil { return err }`.

### preferFprint

**Context:** `b.WriteString(fmt.Sprintf(...))` allocates intermediate string.
**Fix:** Use `fmt.Fprintf(&b, ...)` to write directly to builder.

## 3. golangci-lint install-mode for CI

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** ci-config
**Context:** Pre-built golangci-lint binaries may be compiled with an older Go version than the project requires.
**Fix:** Use `install-mode: goinstall` in the GitHub Action to build from source with the project's Go version.

## 4. go-licenses Blocked License Check

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** ci-config
**Context:** `go-licenses check --allowed_licenses` strict allowlist fails on non-standard license locations or unrecognized licenses (BSL 1.1).
**Fix:** Use grep-based blocked-license approach:

```bash
go-licenses check ./... 2>&1 | grep -E "GPL|AGPL|LGPL|SSPL" && exit 1 || echo "No blocked licenses found"
```

## 6. GoReleaser Release Workflow Prerequisites

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** ci-config
**Context:** GoReleaser v2 with Docker and SBOM support requires explicit setup steps not included automatically.
**Fix:** Add before `goreleaser/goreleaser-action`: (1) `docker/setup-buildx-action@v3`, (2) `docker/login-action@v3`, (3) `anchore/sbom-action/download-syft@v0`. Add `packages: write` and `id-token: write` permissions.

## 8. Dockerfile ldflags Must Match Go Variable Names

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** ci-config
**Context:** Dockerfile ARG names for `-ldflags -X` must exactly match Go `var` names in version.go. Mismatch causes "unknown" version info.
**Fix:** Cross-reference Dockerfile ldflags with version.go. Common mismatch: `version.Commit` vs `version.GitCommit`.

## 11. Python as jq Replacement on Windows MSYS

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** platform-workaround
**Context:** `jq` unavailable on Windows MSYS. Python's `json` + `urllib.request` modules provide equivalent functionality.
**Fix:** Use inline Python for JSON operations. Combine with Windows Python path
detection (KG#8). Always set UTF-8 I/O to prevent cp1252 crashes on Unicode content
(issue bodies with →, em-dashes, etc.):

1. In the calling bash script: `export PYTHONIOENCODING=utf-8`
2. At the top of the Python script:
   `if hasattr(sys.stdout, "reconfigure"): sys.stdout.reconfigure(encoding="utf-8")`
3. In all `subprocess.run` calls: pass `encoding="utf-8"` explicitly

Without this, any Unicode character in output causes `UnicodeEncodeError: 'charmap'
codec can't encode character`. The two-layer fix (env var + reconfigure) is needed
because the env var only covers the outer process; subprocess.run needs its own arg.
**See also:** AP#122 (standalone entry for the broader encoding pattern beyond jq use)

## 16. Remove Heavy Dependencies for Unfixable Vulnerabilities

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** architecture-pattern
**Context:** When a Go dependency has an unfixable vulnerability and the API surface is small, rewriting with `net/http` is faster than waiting for upstream.
**Fix:** Replace with raw HTTP calls. A thin `net/http` + `encoding/json` wrapper is typically under 200 lines and reduces transitive deps.

## 17. Swagger Platform-Specific Issues (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active
**See also:** KG#12

**Category:** ci-fix

### swaggertype tags for type enums

**Context:** swag introspects `time.Duration` and generates platform-specific enum definitions that differ between Linux and Windows.
**Fix:** Add `swaggertype:"integer"` struct tag to override introspection. Pin swag version in CI.

### CI swagger job needs go mod download

**Context:** Dependabot bumps change `go.sum` cache key. Without explicit download, `swag init --parseDependency` fails.
**Fix:** Add `go mod download` step before `swag init` in CI.

## 18. Documentation Drift Audit After PR Bursts

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** process-pattern
**Context:** After merging many PRs in a burst, roadmap checklists, README claims, and architecture docs drift from reality.
**Fix:** Audit: (1) list merged PRs since last doc update, (2) cross-reference with roadmap, (3) check README claims against actual capabilities, (4) fix aspirational language.

## 19. golangci-lint Rules (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#102, AP#103, AP#104 (archived)

**Category:** lint-fix

### nilerr

**Context:** Function receives non-nil error but returns `(result, nil)` instead of propagating.
**Fix:** Return both result AND wrapped error: `return &Result{Err: e.Error()}, fmt.Errorf("op: %w", e)`.

### noctx

**Context:** `db.Exec()`, `db.Query()`, `db.QueryRow()` without context.
**Fix:** Use `ExecContext`, `QueryContext`, `QueryRowContext`. For init code, use `context.Background()`.

### errcheck (resp.Body.Close)

**Context:** `errcheck` flags both direct and deferred `resp.Body.Close()`.
**Fix:** Direct: `_ = resp.Body.Close()`. Deferred: `defer func() { _ = resp.Body.Close() }()`.

### gosec G704 (SSRF)

**Context:** `httpClient.Do(req)` flagged as SSRF in trusted-base-URL clients.
**Fix:** Add `//nolint:gosec // G704: URL is from trusted baseURL config`.

## 20. staticcheck SA4023: Concrete Type Assigned to Interface Is Never Nil

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** lint-fix
**Context:** Assigning a concrete pointer to an interface, then checking `if iface == nil` is always false (dead code).
**Fix:** Remove the nil check, or use compile-time guard: `var _ Checker = (*ICMPChecker)(nil)`.

## 22. Git Stash and Branch Workflows (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#37, AP#107 (archived)

**Category:** workflow

### Stash before branch switch

**Context:** Uncommitted working tree changes carry across `git checkout`, leaking changes between feature branches.
**Fix:** Always `git stash` (or commit) before switching branches during parallel feature work.

### Rebase --onto for stacked PR cleanup

**Context:** After squash-merge, downstream branches contain pre-squash commits. `git rebase origin/main` requires repeated `--skip`.
**Fix:** `git rebase --onto origin/main <old-base-commit> <branch>` replays only unique commits in one operation.

### Stash untracked files before cross-branch push

**Context:** `go build` in pre-push hook compiles untracked files from other agents, failing with "undefined" errors.
**Fix:** `git stash push -u -m "other-files" -- path/to/other/*.go` before pushing, then `git stash pop` after.

## 23. Go Slice Assignment Creates Alias, Not Copy

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** correction
**Context:** `oldSlice := someStruct.slice` creates a new header pointing to the SAME backing array. Zeroing the original zeroes the "copy" too.
**Fix:** Use `make` + `copy` for true deep copies:

```go
oldKEK := make([]byte, len(km.kek))
copy(oldKEK, km.kek)
```

## 24. Name Parameters You Might Reference Later

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** correction
**Context:** `func handler(w http.ResponseWriter, _ *http.Request)` causes "undefined: r" when you later add `r.Context()`.
**Fix:** Always name handler parameters, even if currently unused. Compiler allows named-but-unused params.

## 27. golangci-lint bodyclose with websocket.Dial

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** superseded-by-KG17

Archived to `claude/rules/archive/autolearn-patterns.md`. See KG#17 for the consolidated entry.

## 28. Go 1.22+ ServeMux Ambiguous Route Pattern Panic

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** gotcha
**Context:** Go 1.22+ ServeMux panics at registration when two patterns both match some paths (e.g., `/credentials/{id}/data` and `/credentials/device/{device_id}`).
**Fix:** Restructure routes: move sub-resource to different prefix, add distinguishing literal, or use query params. When using `{id}` wildcards, ensure no sibling literals at the same depth.

## 31. ESLint Catches Unused Imports That TypeScript Misses

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** ci-fix
**Context:** `npx tsc --noEmit` passes but ESLint's `@typescript-eslint/no-unused-vars` catches unused named imports. TypeScript doesn't flag unused imports unless `noUnusedLocals` is enabled.
**Fix:** Run `pnpm run lint` locally before pushing. Verify every named import is referenced.

## 32. gosimple S1016: Use Type Conversion for Identical Structs

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** lint-fix
**Context:** Constructing target struct with literal when source/target have identical fields triggers S1016.
**Fix:** Use type conversion: `TargetType(sourceValue)`.

## 33. Research Methodology (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#34, AP#42, AP#45, AP#46 (archived)

**Category:** research-methodology

### Search GitHub before claiming "no competitors"

Search by function ("network topology visualization"), not product names. Check GitHub, Docker Hub, Product Hunt, HN. Re-scan monthly. Project renames create blind spots.

### Deep competitive analysis via gh CLI

Key commands: `gh api repos/{o}/{r}/contents/`, `gh issue list --state open --json title,comments,labels` (sort by comment count = highest friction), `gh release list`, `gh api repos/{o}/{r}/contributors`. Issues sorted by reactions reveal demand; Discussions API reveals UX pain.

### Gap exploitation report structure

Structure: Updated Metrics, Exploitable Weaknesses (backed by issue #s), Feature Request Gaps, Discussion Intelligence, Strategic Action Items, Competitive Moat, Risk Analysis. Every claim must link to evidence.

### Blog aggregation for blocked platforms

Reddit blocks WebFetch. Search "best X tools reddit 2025" on aggregator sites (elest.io, betterstack, etc.). For specific Reddit threads: `gh api -X GET "https://www.reddit.com/r/{sub}/comments/{id}/.json"`.

### Curated list ecosystem mapping

Analyze awesome-selfhosted category structure for gaps. Empty categories = underserved segments. Check listing requirements and license classification before submission.

## 36. Merge and PR Ordering (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#53, AP#98, AP#99 (archived)

**Category:** process-pattern

### Dependabot PR CI fix ordering

Cannot fix CI on Dependabot branches. Fix CI on separate branch, merge to main, then `gh pr update-branch <number>`.

### Dependency PR merge ordering

Merge the PR with new `go.mod` dependency FIRST, then rebase stdlib-only PR. Go.mod/go.sum changes don't overlap.

### Multi-PR contributor config rollout

Dependency chain: (1) Community health files, (2) ESLint/linting (parallel with 1), (3) CI enhancements (needs 2), (4) Repo settings + branch protection (needs 3). Protection API call goes AFTER PR 4 merges.

### Dependabot triage workflow

Check CI on ALL PRs first. Merge green ones sequentially (rebase between each). Close failing ones with comment. Order: Actions bumps first, then build tools, then framework deps.

## 38. Gitignored Generated Files Break CI Compilation

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** ci-fix
**Context:** Generated files (e.g., `*.pb.go`) in `.gitignore` won't exist in CI, causing build failures.
**Fix:** Either commit generated files or add CI step to regenerate. Decide upfront: commit artifacts or regenerate in CI.

## 47. Check Existing Assets Before Scoping "Create X" Issues

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** pattern
**Context:** "Create X" issues may already have deliverables in the codebase. Planning without checking leads to overscoped work.
**Fix:** Search codebase first: `grep -r "<keyword>" --include="*.svg" --include="*.md" .` Can reduce scope by 90%.

## 48. Parallel Agent Orchestration (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#41, AP#52, AP#67 (archived)

**Category:** workflow-pattern

### Self-recovery from shared working tree

Agents detect leaked files via `git status`, clean with `git checkout -- <leaked>`. Wrong-branch agents recover with `git stash && git checkout <correct> && git stash pop`. Key: prompts must specify target branch, exact files, and `git checkout <branch>` as first step.

### Main.go split for parallel branches

When 2+ agents modify same file: (1) Read combined diff FIRST, (2) stash all, (3) checkout branch-A, pop, remove B's changes, commit, (4) stash remaining, (5) checkout branch-B, pop, re-apply B's changes, commit.

### Autonomous commit disrupts parallel work

Agent running `git checkout <branch>` discards other agents' unstaged tracked-file changes. Untracked files survive. Two approaches: restrict agents from committing (safer) or accept loss and re-apply from output summary (faster).

### Subagent recovery after session break

On resume: `git status`, `git diff --stat`, `go build ./...`, then commit. Subagent work persists in working tree even if main context was interrupted.

## 50. VS Code Auto-Open File on Workspace Start

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** tooling
**Context:** Auto-open a file when VS Code loads a workspace without an extension.
**Fix:** Create `.vscode/tasks.json` with `runOn: folderOpen` task. First open prompts "Allow?" -- permanent after that.

## 51. Two-Tier Session Startup: Static File + Interactive Hook

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Need both IDE and Claude Code oriented on project state at startup.
**Fix:** Combine: (1) VS Code task (`runOn: folderOpen`) auto-opens DASHBOARD.md, (2) Claude Code SessionStart hook injects `/dashboard` instruction. Static file orients human; hook provides live routing.

## 57. JSX Short-Circuit with `unknown` Type Is Not ReactNode

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** typescript-fix
**Context:** `{expanded && entry.details && (<div/>)}` evaluates to `entry.details` (typed `unknown`) when truthy. TS error: "unknown not assignable to ReactNode".
**Fix:** Use `entry.details != null &&` which evaluates to `boolean`.

## 60. Sequential Agents for Dependent Issues in Same Module

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Two issues modifying same files where one depends on the other's types -- parallel agents fail because second can't compile.
**Fix:** Run sequentially. If urgent, rebase #2 onto #1's branch (not main), then rebase onto main after #1 merges.

## 63. Recharts Custom Tooltip Needs Partial Props

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** frontend-pattern
**Context:** Passing `<Tooltip content={<CustomTooltip />} />` -- component initially receives empty `{}` props. Using `TooltipContentProps` directly causes TS error.
**Fix:** Use `Partial<TooltipContentProps<number, string>>` for the function signature. See also KG#28.

## 68. E2E Tests: Assert Core Structure, Not Specific Widget Names

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** testing-pattern
**Context:** E2E tests asserting specific widget names or exact data values break when UI changes labels or seed data differs.
**Fix:** Assert stable structural elements: page headings, primary action buttons, navigation links, generic data labels. Avoid exact numeric values or feature-specific section names.

## 69. GitHub API as CLI Template Fallback

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** tooling-workaround
**Context:** CLI scaffold/init commands fail on Windows MSYS (hanging prompts, Unicode crashes).
**Fix:** Fetch templates via `gh api repos/{owner}/{repo}/contents/{path} --jq '.content' | base64 -d`.

## 70. SDD Tool Abstraction Level Check Before Integration

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** research-methodology
**Context:** Two SDD tools at different abstraction levels (product vs feature vs task) can't pipe directly.
**Fix:** Map each tool's level first. If different, identify a bridge artifact. Direct piping between levels requires manual decomposition.

## 71. Scope CI Lint to Maintained Files on First Introduction

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** ci-config
**Context:** Adding CI linting to a repo with many pre-existing files produces hundreds of violations.
**Fix:** Scope the CI lint glob to actively maintained files. Fix pre-existing violations incrementally.

## 72. Three-Layer Project Initialization Chain

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Ensuring every new project gets CLAUDE.md requires multiple safety nets.
**Fix:** Three layers: (1) `git init.templateDir` auto-copies starter, (2) shell helper for intentional workflow, (3) SessionStart hook detects missing CLAUDE.md.

## 73. Three-Stream Redirect for VS Code CLI in PowerShell Scripts

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** platform-workaround
**Context:** `code --list-extensions` in PowerShell opens `code-stdin-*` tabs. Redirecting only stdout/stderr is NOT sufficient.
**Fix:** Redirect ALL THREE streams. `-RedirectStandardInput` to empty temp file feeds EOF immediately, preventing VS Code from reading parent stdin.

## 74. Iterative Bootstrap Debugging on New Machines

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** First-time bootstrap surfaces cascading issues. Each phase may expose issues invisible until prior phases complete.
**Fix:** Run end-to-end, capture full output, fix ALL failures in single pass. Multiple failures may share root cause (e.g., PATH staleness).

## 75. Start-Job Timeout for Commands That Might Hang

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** platform-workaround
**Context:** Windows Store Python aliases hang forever. `command -v` resolves them as valid but `& py --version` blocks.
**Fix:** Wrap in `Start-Job` + `Wait-Job -Timeout 5`. Stop and remove job if timeout. 5s catches hangs while allowing slow tools.

## 76. PowerShell Temp File for Complex Commands from MSYS Bash

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** platform-workaround
**Context:** Inline PowerShell from MSYS bash breaks with `$env:PATH`, special chars. `cmd.exe /c` swallows output.
**Fix:** Write temp `.ps1` file using single-quoted heredoc (`'PSEOF'`), execute with `powershell.exe -NoProfile -File /tmp/cmd.ps1 2>&1`.

## 77. Small Wave Without Subagent for Focused Changes

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Subagent overhead exceeds benefit for single-file, well-understood changes.
**Fix:** If task modifies 1-2 files with <50 lines and main context already has file loaded, skip subagent.

## 78. golangci-lint exhaustive: List All Enum Cases in Switch

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** lint-fix
**Context:** `exhaustive` requires every enum value in a `switch`, even with `default`. Common in helpers where only 4 of 15 values return `true`.
**Fix:** Explicitly list all remaining values in a second `case` block. Keep final `return` after switch as safety net.

## 79. Cross-Language Enum Exhaustiveness Audit

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** pattern
**Context:** Shared enums (e.g., `DeviceType`) in Go and TypeScript need updates in BOTH when adding values.
**Fix:** Grep for all switch statements (Go) and Record maps (TypeScript). Add new values everywhere.

## 80. E2E getByText Regex Matches Multiple UI Elements

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** gotcha
**Context:** `getByText(/\d+ devices?/)` breaks after adding per-group counts. Strict mode: "resolved to 3 elements."
**Fix:** Use `.first()` for aggregate assertions, or use scoped locators / `data-testid`.

## 81. Union Return Type Requires Type Guard at ALL Call Sites

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** correction
**Context:** Changing return type to a union requires narrowing at every call site and in every mock.
**Fix:** Grep for ALL call sites and ALL mocks. Add type guard narrowing and export the guard in mocks.

## 82. Rebase Conflict Resolution: Keep Both Features' Additions

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Two PRs adding to same file -- rebasing second produces multiple conflict blocks.
**Fix:** At each block, keep BOTH sides by concatenating. These look complex but are mechanically simple.

## 83. Sprint Scope Reduction via Codebase Exploration

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Planned items may already be implemented. Planning without exploring leads to overscoped sprints.
**Fix:** Launch Explore agent to check each deliverable against actual codebase before executing. Extends AP#47.

## 84. Subagents Skip Lint Despite CI Checklist Warnings

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** correction
**Context:** "Watch for" phrasing in CI checklists is advisory. Agents skip `golangci-lint` and ship violations.
**Fix:** Require running `golangci-lint run ./path/...` as mandatory numbered step, not "watch for" patterns.

## 85. Roadmap Drift: Verify Claims Against Source Code

**Added:** 2026-02-24 | **Source:** SubNetree | **Status:** active

**Category:** process-pattern
**Context:** Roadmap checklists drift both ways: items done but unchecked, items listed but already complete.
**Fix:** Cross-reference each unchecked item against codebase. Search for implementations, check if files exist.

## 86. Two-Layer Permission Strategy for Claude Code Projects

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Claude Code settings don't cascade from parent directories. Interactive approvals accumulate hundreds of specific entries.
**Fix:** User-level (`~/.claude/settings.json`): broad wildcards (`"Bash"`, `"Read"`, `"Edit"`, etc.). Project-level: tool-specific wildcards committed to repo. Periodically clean accumulated specific approvals.

## 87. Linter/Hook Leaks Cross-Branch Changes in Parallel Agent Work

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Parallel agents modifying same file + linter/hook can merge both changes. Committing includes other agent's additions.
**Fix:** After stash/pop sorting, diff shared file against main. Remove cross-branch additions before committing.

## 88. Agent-Generated Markdown Needs MD038 Check

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** correction
**Context:** Subagents produce code spans with trailing spaces triggering MD038.
**Fix:** Run `npx markdownlint-cli2 file.md` on agent-generated markdown before committing.

## 90. golangci-lint v2 Migration (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#115, AP#116 (archived)

**Category:** ci-config

### version field required

**Context:** v2 requires `version: "2"` as first field. Without it: `unsupported version of the configuration: ""`.
**Fix:** Add `version: "2"`. Module path changed to `.../golangci-lint/v2/cmd/golangci-lint`.

### Formatters are separate top-level section

**Context:** v2 moved `gofmt`/`goimports` from `linters:` to `formatters:`. "Unknown linters" error.
**Fix:** Move to `formatters: enable:` top-level key.

### gosimple absorbed into staticcheck

**Context:** `gosimple` merged into `staticcheck` in v2. Listing separately causes "unknown linter".
**Fix:** Remove `gosimple`. All S1xxx rules covered by `staticcheck` automatically.

**See also:** KG#65 (silent config failure), KG#66 (v7 action schema enforcement).

## 91. go run for Pinned Tool Versions

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** `go install ...@latest` creates version drift, PATH issues on Windows MSYS, and risks surprise breakage.
**Fix:** Use `go run github.com/.../tool@vX.Y.Z` in Makefiles and hooks. Exact version, no install, no PATH issues.

## 92. DevKit Scaffolding Must Include Executable Templates

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** process-pattern
**Context:** Profiles describing WHAT but no HOW scaffolding leads to manual CI infrastructure creation and preventable failures.
**Fix:** Include ready-to-copy templates: pre-push hook, golangci-lint config, Makefile, CI workflow.

## 93. Advisory Rules Without Enforcement Are Ignored Under Pressure

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** process-pattern
**Context:** Advisory-only rules are skipped under time pressure. Agents repeat known mistakes.
**Fix:** Enforcement tiers: Tier 0 immutable, Tier 1 governed, Tier 2 learned with periodic review. Pre-commit verification must be mandatory ("must" not "should").

## 94. Autolearn Must Validate Before Writing Rules

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** process-pattern
**Context:** Unvalidated learnings become permanent rules cascading to all projects. A workaround could weaken guardrails.
**Fix:** Five-stage pipeline: evidence check, core principle alignment, best practices review, conflict check, risk classification. Dangerous patterns ("skip", "bypass", "suppress") always trigger human review.

## 95. Fix-Forward Replaces Pre-Existing Error Classification

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** process-pattern
**Context:** "Pre-existing" classification had no follow-through. Errors noted and ignored indefinitely.
**Fix:** Fix-forward: (1) fix inline <5 min, (2) can't fix? file GitHub issue, (3) systemic? update DevKit gap. Never acceptable: "noted as pre-existing, moving on."

## 96. Interactive Q&A Then Background Agent for Human-Dependent Issues

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** `agent:human` issues need design decisions before implementation. One at a time wastes attention.
**Fix:** Batch into single interactive pass with focused questions, capture decisions, launch background agents in parallel.

## 97. Combine Complementary Issues Into Single PR

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Two issues where one's research feeds the other's requirements.
**Fix:** Single PR with both deliverables. Use `Closes #X, Closes #Y`. Reduces CI runs and merge conflict risk.

## 100. Vitest Setup for React + Vite Projects

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** testing-pattern
**Context:** Setting up unit tests for React + MUI + Vite with TypeScript strict mode.
**Fix:** Use `mergeConfig(viteConfig, defineConfig({test: {environment: 'jsdom', globals: true, setupFiles: './src/test-setup.ts'}}))`. `mergeConfig` is required to inherit Vite config.

## 101. Zero-Rework Sprint via Subagent CI Checklists

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** Sprint achieved zero rework (all CI-green first pass) vs previous 1-3 fix-push cycles per PR.
**Fix:** Key factors: (1) specific CI commands in prompts, (2) wave ordering respects deps, (3) read-before-write requirement, (4) single responsibility per agent.

## 106. Mandatory Lint Step Language Eliminates Fix-Push Cycles

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** "Self-check" phrasing in CI checklist treated as advisory. Agents skip golangci-lint.
**Fix:** "Step 4, NOT optional, fix ALL" language. Agent compliance depends on enforcement language, not just rule presence.

## 108. Phased Research-Gate Workflow for New Projects

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** process-pattern
**Context:** Flat issue backlogs lead to underresearched designs and no validation checkpoints.
**Fix:** Structure as: Research issues -> Implementation issues -> Gate issue (checklist). Forces thinking before coding at every stage.

## 109. Standalone Python File for Regex-Heavy Bash Scripts

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** active

**Category:** correction
**Context:** Python with complex regex inside bash heredocs fails due to three-layer escaping conflicts.
**Fix:** Write standalone `.py` file, call from thin bash wrapper. Eliminates all escaping layers. Extends AP#11.

## 110. Docker Desktop Extension Marketplace Submission Checklist

**Added:** 2026-03-02 | **Source:** Runbooks, RunNotes | **Status:** active

**Category:** process-pattern
**Context:** Marketplace submission has multiple prerequisites. Missing any causes rejection.
**Fix:** Checklist: (1) Dockerfile labels (screenshots JSON, changelog HTML, additional-urls), (2) .hadolint.yaml ignores DL3048/DL3045, (3) multi-arch (amd64+arm64), (4) `docker extension validate`, (5) submit via docker/extensions-submissions.
**See also:** KG#77

## 111. MUI Tooltip Requires Span Wrapper for Disabled Buttons

**Added:** 2026-03-02 | **Source:** RunNotes | **Status:** active

**Category:** frontend-pattern
**Context:** MUI `<Tooltip>` on disabled `<IconButton>` never shows -- disabled elements don't fire mouse events.
**Fix:** Wrap disabled button in `<span>`. Applies to any disabled interactive element inside Tooltip.

## 112. useRef Guard to Prevent useEffect Re-Trigger Loops

**Added:** 2026-03-02 | **Source:** RunNotes | **Status:** active

**Category:** frontend-pattern
**Context:** useEffect detecting stale data triggers state updates, which re-trigger the same effect infinitely.
**Fix:** Use `useRef(false)` flag. Set `true` after first run. Reset only on intentional user actions (e.g., manual refresh).

## 114. React Callback Ref for MUI Popper Anchors (React Compiler Compliance)

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** active

**Category:** frontend-pattern
**Context:** MUI Popper needs `anchorEl` during render. `useRef` + `ref.current` triggers React Compiler's refs rule.
**Fix:** Use callback ref with `useState`: `const [anchorEl, setAnchorEl] = useState(null)` then `<Button ref={setAnchorEl}>`. See also KG#6.

## 117. Cross-Project Compliance Audit via Parallel Independent-Repo Agents

**Added:** 2026-03-02 | **Source:** DevKit | **Status:** active

**Category:** workflow-pattern
**Context:** Cross-project compliance can be parallelized across independent repos with zero conflict (unlike KG#25 same-repo agents).
**Fix:** One agent per repo with full git autonomy: DevKit templates, customization instructions, CI checklist. Main context handles orchestration only.
**See also:** KG#25, AP#48

## 118. Skill Routing Must Have Explicit Cancel for Skip/Dismiss Intake

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Category:** process-pattern
**Context:** If a skill's intake prompt mentions "skip" or "dismiss", users will try it. Without a routing table entry for cancel/skip, the input falls through to the default route and triggers unintended work.
**Fix:** Any skill with optional steps or confirmations must have an explicit cancel entry in its SKILL.md routing table that exits cleanly.

## 119. Known-Gotchas Frontmatter Must Update With New Entries

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Category:** process-pattern
**Context:** Adding a KG entry without updating `entry_count` and `last_updated` in the YAML frontmatter causes drift between metadata and actual content.
**Fix:** Always update `entry_count` and `last_updated` in the same commit that adds or removes entries. Applies to both `known-gotchas.md` and `autolearn-patterns.md`.

## 120. Secrets Block in ~/.devkit-config.json for PAT Distribution

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Category:** scaffolding-pattern
**Context:** New repos need long-lived PATs (e.g., `RELEASE_PLEASE_TOKEN`) set as GitHub Actions secrets. Prompting users each time is fragile; env vars don't survive across sessions.
**Fix:** Store PATs in `~/.devkit-config.json` under `.Secrets`. New-project.ps1 reads and sets them automatically (section 2.7). Use `scripts/Set-DevkitSecrets.ps1` to backfill existing repos (`-Repo HerbHall/foo` for one, no args for all). File is local-only, never committed. See KG#94 for why `GITHUB_TOKEN` is insufficient for release-please.

## 121. Periodic Project Audit via Explore Subagent

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Category:** process-pattern
**Context:** Documentation, skill lists, CI coverage, and setup scripts drift from reality over time without automated validation. Stale counts, missing checklist blocks, and undocumented CI gaps accumulate invisibly.
**Fix:** Run a structured Explore subagent audit periodically. The prompt should cover 10 dimensions: (1) docs-vs-reality count claims, (2) skill routing table completeness, (3) agent template coverage, (4) rules file metadata accuracy, (5) CI job gap analysis, (6) setup script completeness, (7) project template freshness, (8) hook coverage, (9) sync manifest integrity, (10) cross-reference completeness. Results from one DevKit audit: found stale README counts, 3 missing skills in verify.sh, absent `node` check, missing RUST-CI/DOTNET-CI checklists, no PSScriptAnalyzer in CI -- all actionable in the same session.
**See also:** AP#47 (check existing assets before scoping issues), AP#83 (sprint scope reduction via exploration), AP#85 (roadmap drift)

## 122. Python UTF-8 I/O on Windows for Unicode-Heavy Scripts

**Added:** 2026-03-09 | **Source:** Samverk | **Status:** active

**Category:** platform-workaround
**Context:** Python on Windows defaults to cp1252 encoding. Any script that processes
Unicode content (GitHub issue bodies with →, em-dashes, smart quotes, etc.) crashes
with `UnicodeEncodeError: 'charmap' codec can't encode character '\uXXXX'`. This
applies to any Python script, not just jq replacements.
**Fix:** Apply a three-layer fix -- all three layers are required:

1. In the calling bash script: `export PYTHONIOENCODING=utf-8`
2. At the top of the Python script:
   `if hasattr(sys.stdout, "reconfigure"): sys.stdout.reconfigure(encoding="utf-8")`
3. In every `subprocess.run` call: pass `encoding="utf-8"` explicitly

The env var (layer 1) covers the outer process stdout/stderr. The reconfigure call
(layer 2) is the preferred way to switch an already-open stream; the `hasattr` guard
keeps it safe on Python < 3.7. `subprocess.run` (layer 3) opens a new stream and
ignores PYTHONIOENCODING, so it needs its own `encoding=` argument.
**See also:** AP#11 (jq-replacement context where this pattern was first documented)

## 123. PSScriptAnalyzer Brownfield Onboarding — Audit Before First CI Run

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Category:** ci-config
**Context:** Adding PSScriptAnalyzer CI to an existing repo with many PowerShell scripts surfaces pre-existing violations iteratively across multiple CI cycles (each 2-minute windows-latest run reveals a different set of failures). On DevKit: first run surfaced PSReviewUnusedParameter/PSUseSingularNouns, second run surfaced PSUseUsingScopeModifierInNewRunspaces/PSAvoidUsingPlainTextForPassword, third run surfaced PSUseBOMForUnicodeEncodedFile.
**Fix:** Before pushing CI integration, run PSScriptAnalyzer locally against all scripts and resolve or exclude ALL violations in a single pass:

```powershell
$files = Get-ChildItem -Path setup,scripts -Recurse -Filter '*.ps1'
$results = $files | ForEach-Object {
    Invoke-ScriptAnalyzer -Path $_.FullName -Severity Warning,Error
}
$results | Format-Table -AutoSize
```

Create `PSScriptAnalyzerSettings.psd1` with justified exclusions before the first CI run. Common brownfield exclusions for DevKit-style repos: `PSAvoidUsingWriteHost`, `PSUseShouldProcessForStateChangingFunctions`, `PSReviewUnusedParameter` (ParameterSetName dispatch), `PSUseSingularNouns` (internal helpers), `PSAvoidAssignmentToAutomaticVariable` (loop vars named `$profile`), `PSUseUsingScopeModifierInNewRunspaces` (Start-Job with ArgumentList), `PSAvoidUsingPlainTextForPassword` ([object[]]$Credentials false positive), `PSUseBOMForUnicodeEncodedFile` (cross-platform git strips BOM).
**See also:** KG#112 (Invoke-ScriptAnalyzer -Include invalid parameter), AP#84 (mandatory lint step language)

## 124. Pre-Sprint Human-Label Audit for Mislabeled Issues

**Added:** 2026-03-09 | **Source:** Samverk | **Status:** active

**Category:** process-pattern
**Context:** Issues labeled `agent:human` (or `agent:qc`, `agent:test`) may be mislabeled as requiring human intervention when they are actually automatable. Planning without auditing labels leads to false blockers and overscoped sprints.
**Fix:** Before starting sprint or milestone work, audit all human-labeled issues against three categories: (1) automatable via API/scripts -- relabel to correct agent type, (2) already implemented but never closed -- close immediately, (3) genuinely human (GUI, time-based, quality judgment) -- keep label. Also list BOTH closed AND open issues for a milestone to understand true remaining scope. In one Samverk audit: 2 closed immediately, 9 relabeled automatable, 4 correctly kept human.
**See also:** AP#83 (sprint scope reduction via exploration), AP#47 (check existing assets before scoping issues)
