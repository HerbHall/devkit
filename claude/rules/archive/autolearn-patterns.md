# Archived Autolearn Patterns

Deprecated and superseded entries from `../autolearn-patterns.md`.

## 27. golangci-lint bodyclose with websocket.Dial

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** superseded-by-KG17

**Category:** lint-fix
**Context:** The `coder/websocket` library's `websocket.Dial()` returns `(conn, *http.Response, error)`. The golangci-lint `bodyclose` linter requires that the `*http.Response` body is always closed, even in test code where the response is typically discarded with `_, _, err := websocket.Dial(...)`.
**Mistake:** First fix only addressing some call sites, or using `replace_all` blindly which creates variable name collisions with other uses of `_` in the same scope (e.g., a `conn.Read()` return variable also named `resp`).
**Fix:** For each `websocket.Dial` call, change to:

```go
conn, resp, err := websocket.Dial(ctx, wsURL, nil)
if resp != nil && resp.Body != nil {
    resp.Body.Close()
}
if err != nil {
    t.Fatalf("websocket dial: %v", err)
}
```

**Lesson:** When fixing a lint issue across multiple call sites, ALWAYS grep for ALL occurrences first before making partial fixes. Check for variable name collisions in the surrounding scope before using `replace_all`.

## Archived 2026-03-07: Rules compaction (below 35k threshold)

### Project-specific entries (SubNetree/CLI-Play internals, not transferable)

## 5. WebSocket Auth: JWT via Query Parameter

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** architecture-pattern
**Context:** Browser WebSocket API doesn't support custom headers (`Authorization: Bearer ...`). Standard auth middleware can't validate WS connections.
**Fix:** Pass JWT as `?token=xxx` query parameter. Skip WS paths in auth middleware with prefix check, then validate token manually in the WS handler before calling `websocket.Accept()`.

## 9. React Flow Test Mocking Pattern

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** testing
**Context:** `@xyflow/react` components require DOM measurements and `ReactFlowProvider`. Unit tests fail without comprehensive mocking.
**Fix:** Use `vi.mock('@xyflow/react')` that stubs: `ReactFlow` as a div, `Handle` as null, `Position`/`MarkerType` as objects, `useReactFlow` returning mock functions, and `useNodesState`/`useEdgesState` returning `[initialValue, vi.fn(), vi.fn()]`.

## 10. Slash Command / Skill Overlap Prevention

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** tooling
**Context:** Creating a slash command (`commands/foo.md`) that overlaps with an existing skill (`skills/foo/SKILL.md`) causes duplicate entries.
**Fix:** Always check existing skills before creating a new command. Skills are the preferred format for complex functionality.

## 12. Astro Image Optimization: src/assets vs public/

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** framework-pattern
**Context:** Astro's `<Image />` component only optimizes images imported from `src/assets/`. Images in `public/` served as-is.
**Fix:** Place images in `src/assets/` and import them. Astro converts to WebP at build time.

## 13. Astro Static on Cloudflare Pages (No Adapter)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** framework-pattern
**Context:** Astro v5 with `output: 'static'` produces plain HTML/CSS/JS. Cloudflare Pages serves static files natively.
**Fix:** No Cloudflare adapter needed for static-only Astro sites. Only add `@astrojs/cloudflare` for SSR.

## 21. Don't Start() Modules in Tests That Only Query the Store

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** testing
**Context:** Tests for query-only methods don't need `Start()`. It launches background goroutines that race with tests.
**Fix:** Only call `Start()`/`Stop()` when testing behavior that depends on background workers.

## 25. Consumer-Side Adapter for Cross-Internal Imports

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** architecture-pattern
**Context:** Plugin in `internal/X` needs functionality from `internal/Y`. Direct import creates coupling.
**Fix:** Define consumer-side interface in consuming package. Create thin adapter in `cmd/main.go` (composition root).

## 26. WebSocket Plugin Routes Need SimpleRouteRegistrar

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** architecture-pattern
**Context:** Plugin `Routes()` mounts under `/api/v1/{plugin}/` with auth middleware. WebSocket endpoints need different auth path.
**Fix:** Create separate struct implementing `server.SimpleRouteRegistrar`. Register WS route under `/api/v1/ws/{plugin}/...`.

## 40. Go-Side Time-Bucket Aggregation Over SQL

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** architecture-pattern
**Context:** SQLite's `strftime` fails on RFC3339Nano timestamps. SQL-side bucketing unreliable.
**Fix:** Query raw points with `WHERE timestamp BETWEEN ? AND ?`, aggregate in Go using `time.Truncate`.

## 43. Viper Nested Mapstructure Keys Must Match Struct Hierarchy

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** correction
**Context:** `viper.Set()` calls must use full dotted paths matching struct nesting. Flat keys break silently on refactor.
**Fix:** Use dotted paths: `v.Set("ollama.url", ...)` not `v.Set("url", ...)`.

## 44. React Nullable Local Override for Server State Sync

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** pattern
**Context:** React `set-state-in-effect` lint rule rejects `useEffect(() => setState(serverData), [serverData])`.
**Fix:** Nullable local override: `const [localOverride, setLocalOverride] = useState(null)` with `displayValue = localOverride ?? serverConfig?.value ?? default`.

## 89. Parallel Plain-Text Renderer for TUI Transition Animations

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Category:** architecture-pattern
**Context:** Bubbletea TUI needs plain text for transition animation. Stripping ANSI from lipgloss output fails due to width mismatches.
**Fix:** Create `TransitionText()` method mirroring `View()` logic but outputting plain text. Share responsive logic between both.

### Consolidation victims: gocritic cluster (merged into AP#2)

## 14. gocritic builtinShadow for Go Builtins

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** Go builtins (`new`, `make`, `len`, `cap`, `close`, `delete`, `copy`, `append`, `min`, `max`, `clear`) trigger `builtinShadow` when used as param/var names.
**Fix:** Rename to `n`, `count`, `limit`, `val`, `updated`, etc.

## 15. gocritic httpNoBody for GET/HEAD Requests

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** `http.NewRequestWithContext(ctx, http.MethodGet, url, nil)` triggers httpNoBody.
**Fix:** Use `http.NoBody` instead of `nil`.

## 59. gocritic commentedOutCode on Math-Like Comments

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** Math-heavy comments trigger `commentedOutCode`.
**Fix:** Rephrase to natural language.

## 61. gocritic unnamedResult: Named Returns Require = Not :=

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** After adding named returns, `:=` becomes redeclaration error.
**Fix:** Change `:=` to `=`, remove redundant `var` declarations.

## 62. gocritic appendCombine: Merge Consecutive Appends

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** Two consecutive `append()` calls to same slice.
**Fix:** Combine into single `append` with multiple elements.

## 64. gocritic paramTypeCombine: Consecutive Same-Type Params

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** `(a int, b int)` -- consecutive same-type params.
**Fix:** Combine: `(a, b int)`.

## 65. gocritic dupBranchBody: Identical If/Else Branches

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** Identical if/else branch bodies.
**Fix:** Remove conditional, keep just the body.

## 66. gocritic emptyStringTest: Prefer != "" Over len() > 0

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** `len(s) > 0` for string emptiness.
**Fix:** Use `s != ""`.

## 105. gocritic sloppyReassign: Named Return Shadow in If Statement

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** `if err = f(); err != nil` overwrites named return.
**Fix:** Use `:=` to shadow with new scope.

## 113. gocritic preferFprint: Use fmt.Fprintf Over WriteString+Sprintf

**Added:** 2026-03-02 | **Source:** Samverk | **Status:** consolidated-into-AP2

**Category:** lint-fix
**Context:** `b.WriteString(fmt.Sprintf(...))` allocates intermediate string.
**Fix:** Use `fmt.Fprintf(&b, ...)`.

### Consolidation victims: golangci-lint v2 migration (merged into AP#90)

## 115. golangci-lint v2 Formatters Are a Separate Top-Level Section

**Added:** 2026-03-02 | **Source:** CLI-Play | **Status:** consolidated-into-AP90

**Category:** ci-config
**Context:** v2 moved `gofmt`/`goimports` to `formatters:` top-level section.
**Fix:** Move from `linters: enable:` to `formatters: enable:`.

## 116. golangci-lint v2 Absorbs gosimple Into staticcheck

**Added:** 2026-03-02 | **Source:** CLI-Play | **Status:** consolidated-into-AP90

**Category:** ci-config
**Context:** `gosimple` merged into `staticcheck` in v2.
**Fix:** Remove `gosimple` from linters list.

### Consolidation victims: golangci-lint rules (merged into AP#19)

## 102. noctx: Database Operations Must Use Context-Aware Variants

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP19

**Category:** lint-fix
**Context:** `db.Exec()`, `db.Query()`, `db.QueryRow()` without context flagged by noctx.
**Fix:** Use `ExecContext`, `QueryContext`, `QueryRowContext`.

## 103. errcheck: resp.Body.Close Requires Explicit Error Discard

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP19

**Category:** lint-fix
**Context:** `errcheck` flags `resp.Body.Close()`.
**Fix:** Direct: `_ = resp.Body.Close()`. Deferred: `defer func() { _ = resp.Body.Close() }()`.

## 104. gosec G704: SSRF Nolint for Trusted Base URL Clients

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP19

**Category:** lint-fix
**Context:** `httpClient.Do(req)` flagged as SSRF in trusted clients.
**Fix:** `//nolint:gosec // G704: URL is from trusted baseURL config`.

### Consolidation victims: Swagger cluster (merged into AP#17)

## 35. Swagger CI Job Needs Explicit go mod download

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP17
**See also:** AP#17, KG#12, KG#57, KG#59

**Category:** ci-fix
**Context:** Dependabot bumps change cache key. `swag init --parseDependency` fails without modules.
**Fix:** Add `go mod download` step before `swag init`.

### Consolidation victims: Parallel agent orchestration (merged into AP#48)

## 41. Subagent Recovery After Rate Limit or Session Break

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP48

**Category:** workflow
**Context:** Main context hits rate limit after subagent completes. Orchestrator loses track.
**Fix:** On resume: `git status`, `git diff --stat`, `go build`, then commit. Work persists in working tree.

## 52. Main.go Split for Parallel Agent Branches

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP48

**Category:** workflow-pattern
**Context:** 2+ parallel agents both modify main.go. Changes land in same working tree.
**Fix:** Read combined diff first, then stash/pop/edit to sort each agent's changes into correct branch.

## 67. Agent Autonomous Commit Disrupts Parallel Agent Work

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP48

**Category:** workflow-pattern
**Context:** Agent running `git checkout <branch>` discards other agents' unstaged tracked-file changes.
**Fix:** Restrict agents from committing (safer) or accept loss and re-apply from output summary (faster).

### Consolidation victims: Git stash workflows (merged into AP#22)

## 37. git rebase --onto for Precise Stacked PR Cleanup

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP22

**Category:** workflow
**Context:** After squash-merge, downstream branches need rebase. `git rebase origin/main` requires repeated `--skip`.
**Fix:** `git rebase --onto origin/main <old-base-commit> <branch>` replays only unique commits.

## 107. Stash Untracked Files Before Cross-Branch Push

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP22

**Category:** workflow-pattern
**Context:** Pre-push hook compiles untracked files from other agents, failing with "undefined" errors.
**Fix:** `git stash push -u -m "other-files" -- path/to/*.go` before push, `git stash pop` after.

### Consolidation victims: Merge sequencing (merged into AP#36)

## 53. Dependency PR Merge Ordering in Parallel Waves

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP36

**Category:** workflow-pattern
**Context:** Parallel PRs where one adds go.mod dependency, other uses stdlib. Merge order matters.
**Fix:** Merge dependency PR first, then rebase stdlib-only PR.

## 98. 4-PR Contributor Config Rollout Sequence

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP36

**Category:** workflow-pattern
**Context:** Contributor setup requires dependency-ordered PRs: health files, linting, CI, branch protection.
**Fix:** 4-PR chain with explicit dependency ordering. Protection API call after last PR merges.

## 99. Dependabot Triage: Batch Check, Merge Green, Close Failing

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP36

**Category:** workflow-pattern
**Context:** Dependabot creates multiple PRs. Some pass CI, others fail.
**Fix:** Check all CI first. Merge green sequentially with rebase between each. Close failing with comment.

### Consolidation victims: Competitive research (merged into AP#33)

## 34. Deep Competitive Analysis via gh CLI

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP33

**Category:** research-pattern
**Context:** Comprehensive competitor analysis via `gh` CLI.
**Fix:** Key commands for repo structure, release timeline, user pain points (issues by comment count), contributor analysis.

## 42. Gap Exploitation Report Structure for Competitive Research

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP33

**Category:** research-methodology
**Context:** Structuring competitive weakness analysis.
**Fix:** 7-section structure: metrics, weaknesses (backed by evidence), feature gaps, discussion intelligence, action items, moat assessment, risk analysis.

## 45. Blog Aggregation for Blocked Community Platforms

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP33

**Category:** research-methodology
**Context:** Reddit blocks WebFetch. Discord requires auth.
**Fix:** Search "best X tools reddit 2025" on aggregator sites. For specific threads: `gh api -X GET "reddit.com/.../.json"`.

## 46. Curated List Ecosystem Mapping for Market Positioning

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP33

**Category:** research-methodology
**Context:** Awesome-lists as discovery channels. Category structure reveals gaps.
**Fix:** Analyze empty/redirected sections, check listing requirements, identify integration targets.

## Archived 2026-03-14: Rules compaction (below 35k threshold)

### Superseded entries

## 63. Recharts Custom Tooltip Needs Partial Props (archived 2026-03-14)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** superseded-by-KG28

**Category:** frontend-pattern
**Context:** Passing `<Tooltip content={<CustomTooltip />} />` -- component initially receives empty `{}` props.
**Fix:** Use `Partial<TooltipContentProps<number, string>>`. See KG#28 for consolidated entry.

### Obsolete entries

## 70. SDD Tool Abstraction Level Check Before Integration (archived 2026-03-14)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-obsolete

**Category:** research-methodology
**Context:** Two SDD tools at different abstraction levels (product vs feature vs task) can't pipe directly.
**Fix:** Map each tool's level first. If different, identify a bridge artifact.

## 109. Standalone Python File for Regex-Heavy Bash Scripts (archived 2026-03-14)

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** consolidated-into-AP122

**Category:** correction
**Context:** Python with complex regex inside bash heredocs fails due to three-layer escaping conflicts.
**Fix:** Write standalone `.py` file, call from thin bash wrapper. Core insight folded into AP#122.

### Consolidation victims: Python UTF-8 (merged into AP#122)

## 11. Python as jq Replacement on Windows MSYS (archived 2026-03-14)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP122

**Category:** platform-workaround
**Context:** `jq` unavailable on Windows MSYS. Python's `json` + `urllib.request` modules provide equivalent functionality.
**Fix:** Use inline Python for JSON operations. Combine with Windows Python path detection (KG#8). UTF-8 I/O fix now documented in AP#122.

## Archived 2026-03-15: Rules compaction (governance + React + Windows consolidation)

### Superseded entry

## 27. golangci-lint bodyclose with websocket.Dial (removed from active 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** superseded-by-KG17

Previously retained as stub in active file. Fully removed. See KG#17 for the consolidated entry.

### Consolidation victims: DevKit governance pipeline (merged into AP#18)

## 92. DevKit Scaffolding Must Include Executable Templates

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP18

**Category:** process-pattern
**Context:** Profiles describing WHAT but no HOW scaffolding leads to manual CI infrastructure creation and preventable failures.
**Fix:** Include ready-to-copy templates: pre-push hook, golangci-lint config, Makefile, CI workflow.

## 93. Advisory Rules Without Enforcement Are Ignored Under Pressure

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP18

**Category:** process-pattern
**Context:** Advisory-only rules are skipped under time pressure. Agents repeat known mistakes.
**Fix:** Enforcement tiers: Tier 0 immutable, Tier 1 governed, Tier 2 learned with periodic review. Pre-commit verification must be mandatory ("must" not "should").

## 94. Autolearn Must Validate Before Writing Rules

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP18

**Category:** process-pattern
**Context:** Unvalidated learnings become permanent rules cascading to all projects. A workaround could weaken guardrails.
**Fix:** Five-stage pipeline: evidence check, core principle alignment, best practices review, conflict check, risk classification. Dangerous patterns ("skip", "bypass", "suppress") always trigger human review.

## 95. Fix-Forward Replaces Pre-Existing Error Classification

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP18

**Category:** process-pattern
**Context:** "Pre-existing" classification had no follow-through. Errors noted and ignored indefinitely.
**Fix:** Fix-forward: (1) fix inline <5 min, (2) can't fix? file GitHub issue, (3) systemic? update DevKit gap. Never acceptable: "noted as pre-existing, moving on."

## 108. Phased Research-Gate Workflow for New Projects

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP18

**Category:** process-pattern
**Context:** Flat issue backlogs lead to underresearched designs and no validation checkpoints.
**Fix:** Structure as: Research issues -> Implementation issues -> Gate issue (checklist). Forces thinking before coding at every stage.

### Consolidation victims: React Compiler and MUI patterns (merged into AP#111)

## 112. useRef Guard to Prevent useEffect Re-Trigger Loops

**Added:** 2026-03-02 | **Source:** RunNotes | **Status:** consolidated-into-AP111

**Category:** frontend-pattern
**Context:** useEffect detecting stale data triggers state updates, which re-trigger the same effect infinitely.
**Fix:** Use `useRef(false)` flag. Set `true` after first run. Reset only on intentional user actions (e.g., manual refresh).

## 114. React Callback Ref for MUI Popper Anchors (React Compiler Compliance)

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** consolidated-into-AP111

**Category:** frontend-pattern
**Context:** MUI Popper needs `anchorEl` during render. `useRef` + `ref.current` triggers React Compiler's refs rule.
**Fix:** Use callback ref with `useState`: `const [anchorEl, setAnchorEl] = useState(null)` then `<Button ref={setAnchorEl}>`. See also KG#6.

### Consolidation victims: Windows shell interop (merged into AP#73)

## 75. Start-Job Timeout for Commands That Might Hang

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP73

**Category:** platform-workaround
**Context:** Windows Store Python aliases hang forever. `command -v` resolves them as valid but `& py --version` blocks.
**Fix:** Wrap in `Start-Job` + `Wait-Job -Timeout 5`. Stop and remove job if timeout. 5s catches hangs while allowing slow tools.

## 76. PowerShell Temp File for Complex Commands from MSYS Bash

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** consolidated-into-AP73

**Category:** platform-workaround
**Context:** Inline PowerShell from MSYS bash breaks with `$env:PATH`, special chars. `cmd.exe /c` swallows output.
**Fix:** Write temp `.ps1` file using single-quoted heredoc (`'PSEOF'`), execute with `powershell.exe -NoProfile -File /tmp/cmd.ps1 2>&1`.
