---
description: Learned patterns from past sessions. Read when encountering similar situations.
tier: 2
entry_count: 68
last_updated: "2026-03-22"
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

- **rangeValCopy**: `for _, v := range slice` copies large structs -> use `for i := range slice` with `slice[i]`
- **builtinShadow**: params named `new`, `make`, `len`, `cap`, etc. -> rename to `n`, `count`, `limit`, `val`
- **httpNoBody**: `http.NewRequestWithContext(..., nil)` for GET -> use `http.NoBody`
- **commentedOutCode**: math-heavy comments look like code -> rephrase to natural language
- **unnamedResult**: `(float64, string)` without names -> add names, change `:=` to `=`, remove redundant `var`
- **appendCombine**: two consecutive `append()` to same slice -> combine into single call
- **paramTypeCombine**: `(a int, b int)` -> `(a, b int)` for adjacent same-type params
- **dupBranchBody**: identical if/else branches -> remove conditional, keep body
- **emptyStringTest**: `len(s) > 0` -> use `s != ""`
- **sloppyReassign**: `if err = f(); err != nil` overwrites named return -> use `:=` to shadow
- **preferFprint**: `b.WriteString(fmt.Sprintf(...))` -> use `fmt.Fprintf(&b, ...)`

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

## 16. Remove Heavy Dependencies for Unfixable Vulnerabilities

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** architecture-pattern
**Context:** When a Go dependency has an unfixable vulnerability and the API surface is small, rewriting with `net/http` is faster than waiting for upstream.
**Fix:** Replace with raw HTTP calls. A thin `net/http` + `encoding/json` wrapper is typically under 200 lines and reduces transitive deps.

## 17. Swagger Platform-Specific Issues (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** ci-fix
**Context:** Swagger cross-platform drift (enum definitions, x-enum-descriptions, go mod download for CI).
**Fix:** See KG#12 for full consolidated reference. Key fix: add `swaggertype:"integer"` to `time.Duration` fields, run `go mod download` before `swag init` in CI.

## 18. DevKit Governance and Validation Pipeline (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#92, AP#93, AP#94, AP#95, AP#108 (archived)

**Category:** process-pattern

### Documentation drift audit

After PR bursts, audit: list merged PRs since last doc update, cross-reference with roadmap, check README claims against actual capabilities, fix aspirational language.

### Executable templates in scaffolding

Profiles describing WHAT but no HOW leads to manual CI creation. Include ready-to-copy templates: pre-push hook, golangci-lint config, Makefile, CI workflow.

### Enforcement over advisory rules

Advisory-only rules are skipped under pressure. Use enforcement tiers (Tier 0 immutable, Tier 1 governed, Tier 2 learned). Pre-commit verification must be mandatory ("must" not "should").

### Autolearn validation pipeline

Five-stage pipeline before writing rules: evidence check, core principle alignment, best practices review, conflict check, risk classification. Dangerous patterns ("skip", "bypass", "suppress") always trigger human review.

### Fix-forward replaces pre-existing classification

Fix-forward: (1) fix inline <5 min, (2) can't fix? file GitHub issue, (3) systemic? update DevKit gap. Never acceptable: "noted as pre-existing, moving on."

### Research-gate workflow for new projects

Structure as: Research issues -> Implementation issues -> Gate issue (checklist). Forces thinking before coding at every stage.

## 19. golangci-lint Rules (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#102, AP#103, AP#104 (archived)

**Category:** lint-fix

- **nilerr**: function receives non-nil error but returns `nil` -> return wrapped error: `fmt.Errorf("op: %w", e)`
- **noctx**: `db.Exec()` without context -> use `ExecContext`, `QueryContext`, `QueryRowContext`
- **errcheck** (resp.Body.Close): direct `_ = resp.Body.Close()`, deferred `defer func() { _ = resp.Body.Close() }()`
- **gosec G704** (SSRF): trusted-base-URL clients -> `//nolint:gosec // G704: URL is from trusted baseURL config`
- **gosec G202** (SQL concat): parameterized WHERE builders with static clauses flagged -> `//nolint:gosec // G202: clauses are static, user input is parameterized`
- **gosec G115** (integer overflow): `uint64(stat.Bsize)` on syscall.Statfs_t flagged -> extract to named var with `//nolint:gosec // G115: Bsize is always positive`

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

### Dual-forge rebase requires --onto to replay only feature commits

**Context:** Projects using two forges (e.g., GitHub as `origin` + Gitea as `gitea` remote) have the same logical history but different commit SHAs (squash-merged separately into each). A feature branch based on GitHub `main` cannot fast-forward onto Gitea `main`. Naive `git rebase gitea/main feat/branch` replays 80+ commits from the divergence point, producing conflicts on already-merged unrelated commits.
**Fix:** `git rebase --onto gitea/main <last-github-main-commit> feat/branch` replays only feature commits. Find the fork point with `git log --oneline main | head -5`. Then `git fetch gitea feat/branch && git push --force-with-lease gitea feat/branch`.
**See also:** KG#123 (Gitea force-push requires fetch first)

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

## 36. Merge and PR Ordering (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#53, AP#98, AP#99 (archived)

**Category:** process-pattern

### Dependabot PR CI fix ordering

Cannot fix CI on Dependabot branches. Fix CI on separate branch, merge to main, then `gh pr update-branch`.

### Dependency PR merge ordering

Merge the PR with new `go.mod` dependency FIRST, then rebase stdlib-only PR.

### Multi-PR contributor config rollout

4-PR chain: (1) health files, (2) linting, (3) CI, (4) branch protection. Protection API call after last PR merges.

### Dependabot triage workflow

Check CI on ALL PRs first. Merge green sequentially (rebase between each). Close failing with comment.

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

## 68. E2E Tests: Assert Core Structure, Not Specific Widget Names

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** testing-pattern
**Context:** E2E tests asserting specific widget names or exact data values break when UI changes labels or seed data differs.
**Fix:** Assert stable structural elements: page headings, primary action buttons, navigation links, generic data labels. Avoid exact numeric values or feature-specific section names.

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

## 73. Windows Shell Interop Workarounds (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active
**Consolidates:** AP#75, AP#76 (archived)

**Category:** platform-workaround

### Three-stream redirect for VS Code CLI

`code --list-extensions` in PowerShell opens `code-stdin-*` tabs. Redirect ALL THREE streams -- `-RedirectStandardInput` to empty temp file feeds EOF immediately, preventing VS Code from reading parent stdin.

### Start-Job timeout for hanging commands

Windows Store Python aliases hang forever. `command -v` resolves them as valid but `& py --version` blocks. Wrap in `Start-Job` + `Wait-Job -Timeout 5`. Stop and remove job if timeout.

### PowerShell temp file from MSYS bash

Inline PowerShell from MSYS bash breaks with `$env:PATH`, special chars. Write temp `.ps1` file using single-quoted heredoc (`'PSEOF'`), execute with `powershell.exe -NoProfile -File /tmp/cmd.ps1 2>&1`.

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

## 84. Lint Enforcement Language Must Be Mandatory, Not Advisory (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** correction

### Subagents skip lint when phrasing is advisory (was AP#84)

**Context:** "Watch for" phrasing in CI checklists is advisory. Agents skip `golangci-lint` and ship violations.
**Fix:** Require running `golangci-lint run ./path/...` as a mandatory numbered step, not a "watch for" pattern.

### Mandatory language eliminates fix-push cycles (was AP#106)

**Context:** "Self-check" phrasing in CI checklist treated as advisory. Agents skip golangci-lint.
**Fix:** "Step 4, NOT optional, fix ALL" language. Agent compliance depends on enforcement language, not just rule presence.

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

## 90. golangci-lint v2 Migration (Consolidated Reference)

**Added:** 2026-02-17 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#115, AP#116 (archived)

**Category:** ci-config

- **version field**: v2 requires `version: "2"` as first field. Module path: `.../golangci-lint/v2/cmd/golangci-lint`.
- **formatters**: v2 moved `gofmt`/`goimports` from `linters:` to `formatters: enable:` top-level key.
- **gosimple**: merged into `staticcheck` in v2. Remove from linters list.

**See also:** KG#65 (config requirements + v7 schema enforcement).

## 91. go run for Pinned Tool Versions

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** `go install ...@latest` creates version drift, PATH issues on Windows MSYS, and risks surprise breakage.
**Fix:** Use `go run github.com/.../tool@vX.Y.Z` in Makefiles and hooks. Exact version, no install, no PATH issues.

## 96. Interactive Q&A Then Background Agent for Human-Dependent Issues

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** `agent:human` issues need design decisions before implementation. One at a time wastes attention.
**Fix:** Batch into single interactive pass with focused questions, capture decisions, launch background agents in parallel.

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

## 111. React Compiler and MUI Interaction Patterns (Consolidated Reference)

**Added:** 2026-03-02 | **Source:** Multiple | **Status:** active
**Consolidates:** AP#112, AP#114 (archived)

**Category:** frontend-pattern

### MUI Tooltip on disabled elements

MUI `<Tooltip>` on disabled `<IconButton>` never shows -- disabled elements don't fire mouse events. Wrap disabled button in `<span>`. Applies to any disabled interactive element inside Tooltip.

### useRef guard for useEffect loops

useEffect detecting stale data triggers state updates, which re-trigger the same effect infinitely. Use `useRef(false)` flag. Set `true` after first run. Reset only on intentional user actions.

### Callback ref for Popper anchors

MUI Popper needs `anchorEl` during render. `useRef` + `ref.current` triggers React Compiler's refs rule. Use callback ref with `useState`: `const [anchorEl, setAnchorEl] = useState(null)` then `<Button ref={setAnchorEl}>`. See also KG#6.

## 117. Cross-Project Compliance Audit via Parallel Independent-Repo Agents

**Added:** 2026-03-02 | **Source:** DevKit | **Status:** active

**Category:** workflow-pattern
**Context:** Cross-project compliance can be parallelized across independent repos with zero conflict (unlike KG#25 same-repo agents).
**Fix:** One agent per repo with full git autonomy: DevKit templates, customization instructions, CI checklist. Main context handles orchestration only.
**See also:** KG#25

## 118. Skill Routing Must Have Explicit Cancel for Skip/Dismiss Intake

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Category:** process-pattern
**Context:** Without a cancel route, "skip"/"dismiss" inputs fall through to default and trigger unintended work.
**Fix:** Any skill with optional steps must have an explicit cancel entry in its SKILL.md routing table.

## 119. Known-Gotchas Frontmatter Must Update With New Entries

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Category:** process-pattern
**Fix:** Always update `entry_count` and `last_updated` in YAML frontmatter when adding or removing entries from `known-gotchas.md` or `autolearn-patterns.md`.

## 122. Python UTF-8 I/O on Windows for Unicode-Heavy Scripts

**Added:** 2026-03-09 | **Source:** Samverk | **Status:** active
**Consolidates:** AP#11, AP#109 (archived)

**Category:** platform-workaround
**Context:** Python on Windows defaults to cp1252 encoding. Scripts processing Unicode (em-dashes, smart quotes) crash with `UnicodeEncodeError`. Use Python `json` + `urllib.request` instead of `jq` on Windows MSYS. For regex-heavy scripts, write standalone `.py` file called from bash wrapper.
**Fix:** Three-layer fix (all required): (1) bash: `export PYTHONIOENCODING=utf-8`, (2) Python top: `if hasattr(sys.stdout, "reconfigure"): sys.stdout.reconfigure(encoding="utf-8")`, (3) every `subprocess.run`: pass `encoding="utf-8"`. Each layer covers a different stream surface.

## 123. PSScriptAnalyzer Brownfield Onboarding -- Audit Before First CI Run

**Added:** 2026-03-09 | **Source:** DevKit | **Status:** active

**Category:** ci-config
**Context:** Adding PSScriptAnalyzer CI to an existing repo surfaces pre-existing violations iteratively.
**Fix:** Run PSScriptAnalyzer locally against ALL scripts, resolve or exclude violations in a single pass before pushing CI. Create `PSScriptAnalyzerSettings.psd1` with justified exclusions.
**See also:** KG#104 (PowerShell tool gotchas), AP#84

## 124. Pre-Sprint Human-Label Audit for Mislabeled Issues

**Added:** 2026-03-09 | **Source:** Samverk | **Status:** active

**Category:** process-pattern
**Context:** Issues labeled `agent:human` may be mislabeled as requiring human intervention when automatable.
**Fix:** Audit human-labeled issues before sprint: (1) automatable via API/scripts -- relabel, (2) already implemented -- close, (3) genuinely human -- keep. List both closed and open issues for true remaining scope.
**See also:** AP#83, AP#47

## 125. Copilot Post-Merge Review Followup Workflow

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Category:** process-pattern
**Context:** Copilot adds NEW review comments to already-merged PRs, days after merge. These need a second pass.
**Fix:** Fetch via `gh api repos/{o}/{r}/pulls/{n}/comments`, filter by `created_at` post-merge. Implement clear fixes on a followup branch referencing the original PR number. Flag questionable changes for user decision.

## 127. Worktree Isolation for Parallel Code-Gen Agents

**Added:** 2026-03-14 | **Source:** Synapset | **Status:** active

**Category:** workflow-pattern
**Context:** Using `isolation: "worktree"` in Agent tool calls gives each parallel agent a fully isolated git copy. No shared working tree conflicts (solves KG#25). Each agent commits to its own branch in its own worktree.
**Fix:** Use `isolation: "worktree"` for parallel code-gen agents. Merge via API after all complete. Proven: 3 waves x 2 agents = 7 total agents, all CI-clean first pass. Supersedes stash/pop workflow from AP#48 for new work.
**See also:** KG#25 (parallel agents share working tree)

### Merge interface-changing PRs first to avoid cascading conflicts (was AP#131)

**Context:** Parallel PRs modifying a shared Go interface create cascading conflicts in mock implementations. Automated conflict scripts cannot resolve these correctly.
**Fix:** Merge the interface-changing PR first, then rebase dependent PRs onto updated main. When conflicts arise on pushed PRs, spawn a fresh worktree agent to rebuild on current main.
**See also:** AP#82 (rebase conflict resolution)

### Sequential merge for parallel agents modifying the same file (was AP#135)

**Context:** Parallel worktree agents both modifying the same file create merge conflicts if both branches merge independently.
**Fix:** Merge the first branch to main via fast-forward, then rebase the second branch onto updated main before merging. Both merges stay fast-forward with zero conflicts.

### Stacked worktree commits: rebase --onto to separate agent branches

**Context:** When parallel worktree agents all end up committing to the main worktree (instead of their isolated worktrees), commits become stacked on a single branch. For example, `feat/issue-102` ends up with commits for issues 103, 104, AND 102 stacked on top of each other -- only 102 should be there.
**Fix:** Use `git rebase --onto origin/main <parent-commit> <branch>` to replay only the target commit onto main. The parent-commit is the hash of the commit just below your target in `git log --oneline <branch>`. Run this for each affected branch separately.
**See also:** KG#25

### Sequential worktrees for issues sharing central files

**Context:** When a wave of code-gen issues all touch the same central files (e.g., `tools.go` + `search.go`), parallel worktree agents produce merge conflicts requiring manual combination. Sequential execution eliminates this entirely.
**Fix:** Sequential wave pattern: run agent A -> merge PR A -> `git pull main` -> run agent B -> merge PR B -> repeat. Result: zero conflicts, zero manual resolution. Use parallel only when issues have non-overlapping file sets. Check each issue's acceptance criteria to identify which files will be touched before deciding parallel vs sequential.

### Check worktree for partial progress before re-running truncated agent

**Context:** When a worktree agent returns a truncated response (mid-sentence, no PR created), do NOT re-run from scratch. The agent may have completed all code changes and only failed at the final summary/PR step.
**Fix:** First inspect the worktree directory at `.claude/worktrees/agent-*/`. Review what files were changed with `git diff main...HEAD` inside the worktree. If substantial work exists, continue via `SendMessage` to the same agent or run a targeted agent for only the missing piece. This can save 70k+ tokens compared to a full re-run.

### Identify hot files before launching a parallel wave

**Context:** Parallel worktree agents work in isolation and cannot see each other's changes. When two agents both encounter the same pre-existing bug (e.g., a failing test) in the same file, both fix it independently. When the first PR merges, the second becomes CONFLICTING on that file. Discovered in samverk: two agents both added `-buildvcs=false` to `validator.go`.
**Fix:** Before launching N agents in parallel, do a pre-launch hot-file audit:

```bash
# For each issue being paralleled, predict which files it will touch
# (read the issue body / acceptance criteria)
# Find overlaps -- those are hot files

# List files each branch would realistically modify
# If a file appears in 2+ agents' expected changes: it's hot
```

Pass the `[HOT-FILES]` block from `subagent-ci-checklist.md` to ALL agents in the wave, listing the hot files. Agents that encounter bugs in hot files should report but not fix them. After all PRs merge sequentially, check that the hot file fix landed exactly once.

Also check for known pre-existing bugs before launching: run `go test ./...` or `pnpm test` on current main and note any failing tests. Tell all agents: "The following tests are already failing on main: [...]. Do not attempt to fix them -- they are pre-existing." This prevents multiple agents from independently applying the same fix.

### Prune stale worktrees after parallel wave before any git push

**Context:** Agent tool calls with `isolation: "worktree"` leave worktree directories behind after the agent finishes. These stale entries appear in `git worktree list`. Pre-push hooks that run `go test ./...` or `go build` may traverse into these non-git temp directories and fail with "error obtaining VCS status: exit status 128".
**Fix:** After any parallel agent wave completes and before any `git push`:

```bash
git worktree list           # identify stale entries
git worktree remove <path> --force   # for each stale worktree
git worktree prune          # remove stale administrative files
```

Make this a standard post-wave step in wave orchestration. All agent-created worktrees should be removed before the first push of the merging sequence.

## 132. Exclude Release-Please CHANGELOG From Markdownlint

**Added:** 2026-03-17 | **Source:** DevKit | **Status:** active

**Category:** ci-config
**Context:** Release-please generates CHANGELOG.md with asterisk list markers (`*`) and double blank lines. These violate MD004 and MD012 but cannot be fixed -- the file is regenerated on each release.
**Fix:** Add `"CHANGELOG.md"` to the `ignores` array in `.markdownlint-cli2.jsonc`. Do not attempt `replace_all` on asterisk-space -- it corrupts bold markers (`**text:**`) inside list items.

## 136. Go Interface Extension Requires Updating All Test Mocks

**Added:** 2026-03-17 | **Source:** Samverk | **Status:** active

**Category:** correction
**Context:** Adding a method to a Go interface requires updating ALL structs implementing it, including private test mocks. The compiler catches missing methods, but if a mock adds the new method stub without calling it in any test, golangci-lint's `unused` linter fails.
**Fix:** Before submitting a PR that extends a Go interface, grep for all types implementing it. Ensure every mock (1) adds the new method and (2) exercises it in at least one test case.

## 137. Hardcoded Count Assertions Break When Adding Features

**Added:** 2026-03-17 | **Source:** Samverk | **Status:** active

**Category:** gotcha
**Context:** Tests asserting exact counts (e.g., `len(tools) != 41`) fail whenever a new item is added. Common in tool-discovery tests, route-registration tests, and enum exhaustiveness checks.
**Fix:** Before creating a PR that adds tools/routes/handlers, search for `len(...) != N` or `assert.Equal(t, N, len(...))` patterns and update the expected count. For non-correctness counts, prefer `>= N` over exact equality.

## 141. Go restartCh Channel Pattern for Goroutine Slice Ownership

**Added:** 2026-03-20 | **Source:** Samverk | **Status:** active

**Category:** pattern
**Context:** When a background timer goroutine calls a closure that writes to a local slice (e.g., `watchers[idx].cancel = wcancel`), and the main select loop also reads that slice, the race detector flags a concurrent read/write. This failure mode is flaky -- passes without `-race` and may pass sporadically in CI.
**Fix:** Add `restartCh chan int`. Timer goroutine sends `restartCh <- idx` instead of writing to the slice directly. Main select loop adds `case idx := <-restartCh: startWatcher(idx)` — all slice writes stay on one goroutine. Use channels for goroutine ownership transfer rather than mutexes for shared local slice access.

## 142. strace FD-Level Diagnosis for Process Hang vs Output Buffering

**Added:** 2026-03-20 | **Source:** Samverk | **Status:** active

**Category:** debugging-pattern
**Context:** When a subprocess appears hung (no stdout output, `output_bytes=0`) but the process is alive, it may be buffering output rather than truly stuck.
**Fix:** Use `strace` FD-level tracing to distinguish buffering from stuck:

```bash
strace -p PID -e trace=read,write,recvfrom
```

Active `recvfrom` calls on a network FD confirm the process is receiving data. Zero writes to stdout (FD 1) with active network reads = process is buffering output, not hung. Change the fix from "kill process" to "increase timeout". Discovered while diagnosing `claude --print` processes: `--print` mode buffers ALL output until the entire agentic session ends.

## 143. React ErrorBoundary at Router Level -- Standard Pattern

**Added:** 2026-03-20 | **Source:** Samverk | **Status:** active

**Category:** frontend-pattern
**Context:** React apps without an ErrorBoundary show a silent black screen when any render error occurs -- React unmounts the entire tree with no visible error or crash dialog. Looks identical to a hang or network failure. Standard practice for all React dashboards.
**Fix:** Add `ErrorBoundary` in `App.tsx` wrapping all routes:

```tsx
class ErrorBoundary extends React.Component<{children: React.ReactNode}, {error: Error | null}> {
  state = { error: null }
  static getDerivedStateFromError(error: Error) { return { error } }
  componentDidCatch(error: Error) { console.error('App crashed:', error) }
  render() {
    if (this.state.error) return <div style={{padding:'2rem',color:'red'}}>Error: {(this.state.error as Error).message}</div>
    return this.props.children
  }
}
```

Wrap at router level: `<ErrorBoundary><Routes>...</Routes></ErrorBoundary>`.
**See also:** AP#111 (React Compiler and MUI patterns)

## 144. Tauri 2 Multi-Window Label Routing Pattern

**Added:** 2026-03-21 | **Source:** claude-token-stats | **Status:** active

**Category:** frontend-pattern
**Context:** Tauri 2 apps with multiple windows sharing one frontend bundle need to render different root components per window without React Router or URL-based routing.
**Fix:** Detect window identity at the entry point via `getCurrentWindow().label` (synchronous), then conditionally render root components:

```tsx
// main.tsx
import { getCurrentWindow } from '@tauri-apps/api/window';

const windowLabel = getCurrentWindow().label;
ReactDOM.createRoot(document.getElementById('root')!).render(
  windowLabel === 'dashboard' ? <Dashboard /> : <App />
);
```

Each window gets the correct UI with zero navigation overhead. Typical window config:

- Popup (`main`): 380×500, `decorations: false`, `visible: false`, `skipTaskbar: true`
- Dashboard (`dashboard`): 1100×700, `decorations: true`, `visible: false`, `skipTaskbar: false`

Backend opens a named window: `app.get_webview_window("dashboard").show()`
**See also:** KG#176 (Tauri 2 API gotchas — getCurrentWindow import path)

## 145. Use WIP Branch Instead of Stash for Branch-Switching Work

**Added:** 2026-03-22 | **Source:** samverk | **Status:** active

**Category:** workflow-pattern
**Context:** When in-progress work exists and a multi-step task requires switching between multiple branches (e.g., rebasing, merging, resolving stacked PRs), `git stash` carries risk: `git stash drop` is irreversible and easy to run accidentally during cleanup. A WIP branch is safer — it survives branch switches, can be inspected later, and is trivially recoverable.
**Fix:** Before any multi-branch operation when uncommitted work exists:

```bash
# Instead of: git stash push -m "..."
git add -A
git commit -m "wip: [description] -- branch-switching work in progress"
# Do your multi-branch work
# Afterwards, soft-reset to un-commit and restore working state:
git reset HEAD~1
```

If you must use stash, inspect before dropping:

```bash
git stash show -p stash@{0}   # always inspect before dropping
# prefer git stash pop over git stash drop
```

**Why:** `git stash drop` permanently deletes staged and tracked-but-modified files with no recovery path. In the samverk migration session, AGENTS.md and CLAUDE.md edits were permanently lost this way.

## 146. Cherry-Pick Only Unique Commits for Stacked PRs

**Added:** 2026-03-22 | **Source:** samverk | **Status:** active

**Category:** workflow-pattern
**Context:** When parallel feature branches are stacked (branch B was created on top of branch A, so B contains A's commit plus its own), simple rebase fails after A is squash-merged to main. Git cannot recognize the squashed version of A as equivalent to the original commit, causing conflicts.
**Fix:**

```bash
# 1. Identify the unique commit in branch B (first line is unique, second is A's)
git log --oneline origin/feature/B | head -2

# 2. Reset branch B to current main and replay only the unique commit
git checkout --track origin/feature/B -B feature/B
git reset --hard origin/main
git cherry-pick <tip-commit-of-B>

# 3. Push and enable auto-merge
git push --force origin feature/B
gh pr merge N --squash --auto
```

If the cherry-pick still conflicts (A and B both touched the same file), resolve as additive — keep both sides. Conflicts from stacked PRs are always additive, never destructive.

## 147. Sequential Auto-Merge Requires Manual Branch Updates Between Merges

**Added:** 2026-03-22 | **Source:** samverk | **Status:** active

**Category:** workflow-pattern
**Context:** When N PRs all have auto-merge enabled and one merges, the remaining N-1 PRs enter "BEHIND" state. GitHub's auto-merge does NOT auto-update behind branches — it waits indefinitely even if all CI checks passed on the most recent push.
**Fix:** After each merge in a batch, manually update remaining behind PRs:

```bash
# After PR N merges:
gh pr update-branch <remaining-pr-1>
gh pr update-branch <remaining-pr-2>
# ...
```

This triggers new CI runs via merge commits; auto-merge fires once CI passes. For N sequential PRs, expect O(N²/2) total update-branch calls. If running many PRs, consider a workflow that auto-updates behind branches on push to main.

## 148. Go Multi-Project API Aggregation Pattern

**Added:** 2026-03-22 | **Source:** Samverk | **Status:** active

**Category:** pattern
**Context:** Go REST API handlers that aggregate results from multiple backends (e.g., multiple forge trackers registered in a project registry) need concurrent fetching with correct linter compliance. Fetching from a single tracker silently ignores all other registered projects.
**Fix:** Use WaitGroup + fixed-size results slice indexed by backend position (avoids mutex on append). Pre-compute total capacity before flattening (satisfies prealloc linter). Apply pagination AFTER aggregation — per-backend pagination is meaningless across backends. Fetch up to `maxLimit` per backend to bound memory.

```go
results := make([]result, len(projects))
var wg sync.WaitGroup
for i, p := range projects {
    wg.Add(1)
    go func(idx int, proj *Project) {
        defer wg.Done()
        items, err := proj.Tracker.List(ctx, opts)
        if err != nil { return }
        results[idx] = result{items: items}
    }(i, p)
}
wg.Wait()

// Pre-compute capacity (satisfies prealloc linter)
totalCount := 0
for i := range results { totalCount += len(results[i].items) }
all := make([]responseType, 0, totalCount)
for i := range results { all = append(all, results[i].items...) }
// Apply pagination to all[offset:end]
```

Use for-index-range (not for-val-range) when iterating results to avoid rangeValCopy on large structs. Discovered when fixing `handleListIssues()` which only queried `a.tracker` even when `a.projectRegistry` had 3 projects registered.

## 149. Agent-Facing Outputs Must Be Data-Driven

**Added:** 2026-03-22 | **Source:** Samverk | **Status:** active

**Category:** architecture-pattern

**Context:** Any function that generates text consumed directly by an agent (prompt templates, issue URLs, CLI commands, file paths, forge slugs) is infrastructure — not UI copy. Hardcoded project names, repo slugs, or paths in these functions produce wrong output as soon as multi-project support is added.

**Real example:** `buildAgentPrompt()` in `MyQueue.tsx` hardcoded the project name, GitHub URL, and `gh` commands. When devkit and synapset issues appeared in My Queue, agents received prompts pointing to the wrong project directory and running `gh` against a repo with issues disabled.

**Fix:** Pull project name, forge URL, and repo slug from the issue/project object at runtime. Build URLs from `project.forgeURL + issue.number`. Pass forge type to generate the correct CLI command (`gh` vs Gitea API vs Samverk MCP).

**How to apply:** Before adding any hardcoded project/repo/URL string to an agent-facing output function, ask "what happens when this runs for a different project?" If the answer is "wrong output," parameterize it.

## 150. go build -buildvcs=false in Non-Git Temp Dirs

**Added:** 2026-03-22 | **Source:** Samverk | **Status:** active

**Category:** gotcha
**Context:** `go build ./...` fails with "error obtaining VCS status: exit status 128 / Use -buildvcs=false to disable VCS stamping" when run inside a directory that is not part of a git repository. Affects agent validator subprocesses, worktree temp dirs, and any subprocess running `go build` in an isolated temp dir.
**Fix:** Add `-buildvcs=false` to `go build` calls in non-repo contexts:

```go
buildOut, buildErr := runInDir(ctx, workDir, "go", "build", "-buildvcs=false", "./...")
```

The flag is harmless in normal git repos — it only skips embedding VCS metadata (commit hash, dirty flag) into the binary. Safe to always use in test/validation contexts.

## 151. sync.Mutex to sync.RWMutex Is a Drop-In Fix for Read-Heavy Race

**Added:** 2026-03-22 | **Source:** Samverk | **Status:** active

**Category:** pattern
**Context:** When `-race` detects that a shared-state method reads without holding a lock while writes always hold `mu.Lock()`, the minimal correct fix is to upgrade to `sync.RWMutex` and add `RLock/RUnlock` on readers. This is a drop-in replacement — all existing `Lock()/Unlock()` calls still compile unchanged.

**Diagnostic pattern:** (1) check if ALL write callers already hold `Lock()`, (2) check if ALL read callers hold nothing. If so, `sync.Mutex → sync.RWMutex + RLock on readers` is the minimal correct fix with zero behavior change.

```go
// Before:
mu sync.Mutex

// After (drop-in: all existing Lock/Unlock calls still compile):
mu sync.RWMutex

// In read-only methods:
func (d *Dispatcher) trackerFor(...) forge.IssueTracker {
    d.mu.RLock()
    defer d.mu.RUnlock()
    // ...
}
```

## 152. Forge Detection and Tool-Selection Hierarchy

**Added:** 2026-03-22 | **Source:** DevKit | **Status:** active

**Category:** workflow-pattern

### Detection algorithm (run before any forge operation)

1. If `.samverk/project.yaml` exists in repo root → read `forge` and `repo` fields
2. Otherwise → parse `git remote get-url origin`:
   - `github.com` in URL → GitHub forge
   - `192.168.1.160` or `gitea.herbhall.net` in URL → Gitea forge

### Tool-selection hierarchy

| Forge | Primary | Fallback | Never |
|-------|---------|----------|-------|
| **Gitea** (Samverk-managed) | Samverk MCP (`list_issues`, `create_pr`, `get_diff`, etc.) | Gitea REST API (`http://192.168.1.160:3000/api/v1/` or `https://gitea.herbhall.net/api/v1/`) | `gh` CLI |
| **GitHub** | `gh` CLI | GitHub REST API | Samverk MCP |

**`gh` CLI is GitHub-only.** Using `gh pr list --repo HerbHall/devkit` on a Gitea project silently queries the read-only GitHub mirror, not the active Gitea forge. This caused a regression in session 2026-03-18.

### Applies to

All forge operations: PR list, issue list, PR create, issue create, CI status, labels, milestones.

## 153. Every Project Needs a Non-Release PR Auto-Merge Trigger

**Added:** 2026-03-22 | **Source:** DevKit | **Status:** active

**Category:** ci-config

**Context:** `release-gate.yml` only auto-merges PRs with the `autorelease: pending` label (release-please PRs only). Agent-created PRs (`feat:`, `fix:`, `chore:`) have no automated merge path and sit open indefinitely even after CI passes.

**Fix by forge:**

- **GitHub:** Add `.github/workflows/auto-merge.yml` — on PR open with conventional title, run `gh pr merge --auto --squash`. Skip `release-please--` branches.
- **Gitea:** Add a `merge` job to CI workflow with `needs: [all-ci-jobs]` — after all checks pass, call `POST /api/v1/repos/{owner}/{repo}/pulls/{n}/merge` with `Do: squash`. HTTP 200/204 = merged, 405 = already merged (both are success).

**How to apply:** When setting up CI for any new project, verify there is a merge trigger for non-release PRs, not just for release-please.

## 154. Dual-Forge Auto-Merge Cannot Share Implementation

**Added:** 2026-03-22 | **Source:** DevKit | **Status:** active

**Category:** ci-config

**Context:** Projects mirrored across GitHub and Gitea need separate auto-merge implementations for each forge because the APIs and trigger mechanisms differ.

| Forge | Mechanism | Notes |
|-------|-----------|-------|
| GitHub | `gh pr merge --auto --squash` on PR open | Fire-and-forget; merges when branch protection checks pass |
| Gitea | `merge` job in CI with `needs: [all-jobs]` | Calls `POST /api/v1/repos/{repo}/pulls/{n}/merge` with `Do:squash` |

**Gitea merge API:** HTTP 200/204 = merged, 405 = already merged — both success states. Use `CI_GITEA_TOKEN` (NOT `GITEA_TOKEN` — reserved prefix, silently empty at runtime; see KG#123).

**Side effect:** Squash-merge on GitHub with dual-push `origin` causes local `git pull` to produce a merge commit instead of fast-forward. Expected; use `git pull --rebase` locally if preferred.
