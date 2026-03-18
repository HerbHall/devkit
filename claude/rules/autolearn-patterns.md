---
description: Learned patterns from past sessions. Read when encountering similar situations.
tier: 2
entry_count: 66
last_updated: "2026-03-18"
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
**Fix:** Use `--onto` to replay only the feature commits:

```bash
# Find the last GitHub main commit the branch was based on
git log --oneline main | head -5  # e.g. d96284e

# Replay only commits after that point onto Gitea main
git rebase --onto gitea/main d96284e feat/branch

# Fetch first (KG#123: Gitea rejects force-push with stale info)
git fetch gitea feat/branch
git push --force-with-lease gitea feat/branch
```

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

## 74. Iterative Bootstrap Debugging on New Machines

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** workflow-pattern
**Context:** First-time bootstrap surfaces cascading issues. Each phase may expose issues invisible until prior phases complete.
**Fix:** Run end-to-end, capture full output, fix ALL failures in single pass. Multiple failures may share root cause (e.g., PATH staleness).

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

## 88. Agent-Generated Markdown Needs MD038 Check

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Category:** correction
**Fix:** Subagents produce code spans with trailing spaces triggering MD038. Run `npx markdownlint-cli2 file.md` on agent-generated markdown before committing.

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

## 110. Docker Desktop Extension Marketplace Submission Checklist

**Added:** 2026-03-02 | **Source:** Runbooks, RunNotes | **Status:** active

**Category:** process-pattern
**Context:** Marketplace submission has multiple prerequisites. Missing any causes rejection.
**Fix:** Checklist: (1) Dockerfile labels (screenshots JSON, changelog HTML, additional-urls), (2) .hadolint.yaml ignores DL3048/DL3045, (3) multi-arch (amd64+arm64), (4) `docker extension validate`, (5) submit via docker/extensions-submissions.
**See also:** KG#77

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

## 120. Secrets Block in ~/.devkit-config.json for PAT Distribution

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Category:** scaffolding-pattern
**Context:** New repos need PATs (e.g., `RELEASE_PLEASE_TOKEN`) as GitHub Actions secrets.
**Fix:** Store in `~/.devkit-config.json` under `.Secrets`. `new-project.ps1` auto-sets them. Use `Set-DevkitSecrets.ps1` to backfill. See KG#94.

## 121. Periodic Project Audit via Explore Subagent

**Added:** 2026-03-08 | **Source:** DevKit | **Status:** active

**Category:** process-pattern
**Context:** Documentation, skill lists, CI coverage, and setup scripts drift from reality without automated validation.
**Fix:** Run structured Explore subagent audit periodically covering 10 dimensions: docs accuracy, skill routing, agent templates, rules metadata, CI jobs, setup scripts, project templates, hooks, sync manifest, cross-references.
**See also:** AP#47, AP#83, AP#85

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

## 126. Cloudflare Email Routing Replaces MailChannels for Workers

**Added:** 2026-03-14 | **Source:** herbhall.net | **Status:** active

**Category:** pattern
**Context:** MailChannels shut down free Cloudflare Workers integration. Replacement is Cloudflare Email Routing `send_email` binding.
**Fix:** Enable Email Routing on zone, add `[[send_email]]` binding in wrangler.toml with `destination_address`, use `EmailMessage` from `cloudflare:email` + `mimetext` for MIME. Requires `nodejs_compat` flag. Note: mimetext `setHeader('Reply-To', ...)` is broken -- inject into raw MIME directly.

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

## 132. Exclude Release-Please CHANGELOG From Markdownlint

**Added:** 2026-03-17 | **Source:** DevKit | **Status:** active

**Category:** ci-config
**Context:** Release-please generates CHANGELOG.md with asterisk list markers (`*`) and double blank lines. These violate MD004 and MD012 but cannot be fixed -- the file is regenerated on each release.
**Fix:** Add `"CHANGELOG.md"` to the `ignores` array in `.markdownlint-cli2.jsonc`. Do not attempt `replace_all` on asterisk-space -- it corrupts bold markers (`**text:**`) inside list items.

## 133. Prefer Dynamic MCP Discovery Over Static Prompt Files

**Added:** 2026-03-17 | **Source:** Samverk | **Status:** active

**Category:** process-pattern
**Context:** Hand-written `.samverk/prompts/*.md` files listed issues as critical that were already implemented. MCP calls (`get_digest`, `list_open_prs`) at session start already provide live state. Static prompts duplicate and contradict.
**Fix:** Use dynamic MCP discovery for session orientation. If static prompts are used, they should be generated (not hand-written) and include a staleness warning with a generation timestamp.
**See also:** AP#85 (roadmap drift)

## 134. Issue Specs Must Reference Verified Exported API

**Added:** 2026-03-17 | **Source:** Samverk | **Status:** active

**Category:** process-pattern
**Context:** Issue spec said "call into existing `dispatcher.Claim()`" but no such public method existed, and the caller and callee were in separate processes. A 2-minute codebase check would have caught both problems.
**Fix:** Before writing implementation specs that reference internal methods, verify: (1) the method exists and is exported, (2) the caller and callee are in the same process. Extends AP#47 (check existing assets before scoping) and AP#83 (sprint scope reduction via exploration).

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
