---
description: Known gotchas and platform-specific issues. Read when debugging unexpected behavior.
tier: 2
entry_count: 89
last_updated: "2026-03-02"
---

# Known Gotchas

Platform-specific issues, tool quirks, and surprising behaviors discovered through past sessions.

## 1. Windows MSYS Bash Path Translation

**Added:** 2026-02-17 | **Source:** global | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** MSYS bash auto-translates Unix-style paths to Windows paths in some contexts. Paths starting with `/c/` become `C:\`.
**Workaround:** Use `MSYS_NO_PATHCONV=1` prefix for commands where path translation causes problems, or use double-slash `//` to prevent translation.

## 2. GitHub Branch Protection Requires --admin for Merge

**Platform:** GitHub
**Issue:** When branch protection rules require PR reviews or status checks, `gh pr merge` fails even when all checks pass if you're the only maintainer.
**Workaround:** Use `gh pr merge --admin` to bypass branch protection (only for repo admins).
**Note:** This is expected behavior. Consider configuring branch protection to allow admin bypass.

## 3. Git Stash Before PR Merge

**Platform:** Git
**Issue:** `gh pr merge` with `--merge` or `--squash` can fail if there are uncommitted local changes, even if they're unrelated to the PR.
**Workaround:** `git stash` before merging, `git stash pop` after.

## 4. Force Push to Already-Merged Branch Creates Orphan

**Platform:** GitHub
**Issue:** If a PR branch was already merged and you `git push --force` to it, GitHub creates a new remote branch (orphaned from the PR). The PR remains merged.
**Workaround:** Always check PR state before rebasing/pushing: `gh pr view <number> --json state`.
**Cleanup:** `git push origin --delete <branch-name>` to remove the orphan.

## 5. Incomplete Range Variable Replacement in Loop Refactoring

**Platform:** Go (all)
**Issue:** When changing `for _, v := range slice` to `for i := range slice`, it's easy to miss references to `v` deeper in the loop body. The compiler will catch `undefined: v` but only if you try to build.
**Fix:** After changing the range declaration, search the entire loop body for the old variable name. Replace ALL occurrences with `slice[i]`.

## 6. React Compiler Lint: Cannot Access Refs During Render

**Platform:** React 19+ / ESLint react-hooks/refs rule
**Issue:** Mutating `ref.current` at the top level of a custom hook (during render) is flagged by the React compiler ESLint plugin. Common pattern `onMessageRef.current = onMessage` triggers "Cannot update ref during render". Also applies to storing function implementations in refs.
**Fix:** Wrap all ref assignments in `useEffect`:

```tsx
// BAD: ref mutation during render
onMessageRef.current = onMessage

// GOOD: ref mutation in effect
useEffect(() => { onMessageRef.current = onMessage }, [onMessage])
```

## 7. React Compiler Lint: Recursive useCallback Self-Reference

**Platform:** React 19+ / ESLint react-hooks/immutability rule
**Issue:** A `useCallback` function that calls itself recursively (e.g., a `connect()` function calling `connect()` inside an `onclose` handler) triggers "Cannot access variable before it is declared". The linter sees the variable used before its `const` declaration completes.
**Fix:** Store the function in a ref and call `ref.current?.()` for the recursive invocation:

```tsx
const connectRef = useRef<() => void>()
useEffect(() => {
  connectRef.current = () => {
    // ... ws.onclose = () => { connectRef.current?.() }
  }
}, [deps])
```

## 8. Windows Python Aliases Shadow Real Python

**Platform:** Windows (MSYS_NT)
**Issue:** `python3`, `python`, and `py` all resolve to Windows Store alias stubs (at `~/AppData/Local/Microsoft/WindowsApps/python*.exe`) that just prompt "Install from Microsoft Store" instead of running Python. `command -v` reports them as found, but they don't actually work.
**Diagnosis:** `python --version` outputs "Python was not found; run without arguments to install from the Microsoft Store" and exits non-zero.
**Fix:** Check candidates with `"$p" --version` (not `command -v`) and include explicit Windows paths in the search loop:

```bash
for p in python3 python py "/c/Program Files/Python39/python" "/c/Program Files/Python312/python"; do
    if "$p" --version &>/dev/null 2>&1; then PYTHON="$p"; break; fi
done
```

## 9. jq Not Available on Windows MSYS by Default

**Platform:** Windows (MSYS_NT)
**Issue:** `jq` is not included in Git for Windows / MSYS2 by default. Scripts that use `jq` for JSON processing fail with "command not found".
**Fix:** Use Python's `json` module instead of `jq` for bash scripts that need JSON escaping/parsing. Python is more commonly available (once you work around gotcha #8).

## 10. UserPromptSubmit Hooks Block Slash Commands and Menu Selections

**Platform:** Claude Code (all platforms)
**Issue:** `UserPromptSubmit` hooks with `type: "prompt"` block slash commands (`/reflect`, `/whats-next`, etc.) and bare numeric inputs (`1`, `7`, `12`) used as menu selections. The small model evaluating the hook prompt interprets these as "not a valid or actionable request" and generates refusal messages.
**Diagnosis:** Slash commands fail with "the user prompt '/foo' is a slash command, not a regular prompt." Numeric menu selections fail with "does not represent a valid or actionable request for evaluation."
**Fix:** Add a `matcher` regex to skip slash commands AND bare numeric menu selections:

```json
{
  "matcher": "^(?!/)(?!\\d{1,2}$)",
  "hooks": [{ "type": "prompt", "prompt": "..." }]
}
```

- `^(?!/)` skips slash commands
- `(?!\\d{1,2}$)` skips bare 1-2 digit numbers (menu selections like `0`-`14`)

Regular prompts containing numbers still fire normally (e.g., "fix issue #297").

## 11. GitHub API Returns Empty Without User-Agent Header

**Platform:** All (curl, fetch)
**Issue:** GitHub REST API requires a `User-Agent` header. Requests without it return empty or 403 responses. Curl on some platforms sends a User-Agent by default; others don't.
**Fix:** Always include `User-Agent: <app-name>` in GitHub API requests. In Node.js fetch: `headers: { 'User-Agent': 'app-name', 'Accept': 'application/vnd.github.v3+json' }`.

## 12. swag Generates Platform-Specific time.Duration Enums

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active
**See also:** AP#17, AP#35, KG#57, KG#59

**Platform:** Go (cross-platform)
**Issue:** `swag init` with `--parseDependency --parseInternal` introspects `time.Duration` and generates an enum definition. The exact enum values differ across Go versions and platforms -- Linux CI may include `minDuration`/`maxDuration` while Windows local doesn't (or vice versa). Even with the same swag version pinned (`v1.16.4`), the Go toolchain version affects the output.
**Diagnosis:** Swagger drift check fails in CI. The diff shows `minDuration`/`maxDuration` being added or removed from the `time.Duration` enum.
**Fix:** Add `swaggertype:"integer"` struct tag to all `time.Duration` fields exposed in swagger-annotated handlers. This tells swag to use a plain integer type instead of introspecting Duration, completely eliminating the platform-specific enum block.

```go
TimeToThreshold *time.Duration `json:"time_to_threshold,omitempty" swaggertype:"integer"`
```

## 13. Swagger Drift After Any Handler/Model Change

**Platform:** Go (swaggo/swag)
**Issue:** ANY change to Go types referenced in swagger-annotated handlers requires regenerating the swagger spec. This includes: adding new types (e.g., `ThemeLayer`), adding/removing fields on existing structs (e.g., `Layers` on `ThemeDefinition`), changing response types, or removing routes. The CI Swagger Drift Check catches stale specs but costs a round-trip.
**Fix:** Always run `swag init -g cmd/subnetree/main.go -o api/swagger --parseDependency --parseInternal` (or `make swagger`) after modifying any handler, request/response struct, or type used in swagger annotations. Commit the regenerated files alongside the Go changes.

## 14. Go Nil Guard: Split Chained Nil Checks Into Separate Blocks

**Platform:** Go (all)
**Issue:** When guarding against nil with `if obj.Field == nil || obj.Field.Sub == 0`, any code in the same block that accesses `obj.Field.X` (e.g., logging) will panic when `obj.Field` is nil. The `||` short-circuits the condition, but the log statement still executes before the return.
**Fix:** Split into two separate `if` blocks:

```go
// BAD: logging panics when de.Device is nil
if de.Device == nil || len(de.Device.IPAddresses) == 0 {
    log.Debug("no IPs", zap.String("id", de.Device.ID)) // PANIC
    return
}

// GOOD: separate guards
if de.Device == nil {
    log.Debug("nil device")
    return
}
if len(de.Device.IPAddresses) == 0 {
    log.Debug("no IPs", zap.String("id", de.Device.ID)) // safe
    return
}
```

## 15. Squash-Merged Branches Don't Appear in `git branch --merged`

**Platform:** Git (all)
**Issue:** After squash-merging a PR, the local branch tip and the squash commit on main have different hashes. `git branch --merged main` won't list the branch because the original commits aren't ancestors of main.
**Fix:** Use `git branch -D` (force delete) instead of `git branch -d` for cleanup. Verify safety by checking that the remote tracking ref was already pruned (`git remote prune origin` first), confirming the PR was merged and the remote branch was deleted.

## 16. GitHub `Closes #N` Comma Syntax Only Closes First Issue

**Platform:** GitHub
**Issue:** `Closes #1, #2, #3` in a PR body only auto-closes #1. GitHub requires the keyword before **each** issue number. The comma-separated list without repeated keywords is silently ignored for all but the first reference.
**Diagnosis:** PR merged successfully, first issue closed, remaining issues still open. Easy to miss since GitHub doesn't warn about the syntax.
**Fix:** Use the keyword before each issue number: `Closes #1, Closes #2, Closes #3` or put each on a separate line:

```text
Closes #1
Closes #2
Closes #3
```

If you miss some, close manually: `gh issue close N --comment "Shipped in PR #X"`.
**Example:** PR #270 body had `Closes #226, #251, #259, #254, #249` -- only #226 was auto-closed. The other 4 required manual closure.

## 17. websocket.Dial Response Body Must Be Closed

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Go (all) / coder/websocket library
**Issue:** `websocket.Dial(ctx, url, nil)` returns `(*websocket.Conn, *http.Response, error)`. Even though you typically only care about the connection, the golangci-lint `bodyclose` linter requires that the `*http.Response` body is always closed. Ignoring the response with `_, _, err := websocket.Dial(...)` triggers lint errors.
**Diagnosis:** `golangci-lint run` reports "response body must be closed" on all `websocket.Dial` call sites, including tests.
**Fix:** Always capture the response and close the body:

```go
conn, resp, err := websocket.Dial(ctx, wsURL, nil)
if resp != nil && resp.Body != nil {
    resp.Body.Close()
}
if err != nil {
    // handle error
}
```

**Gotcha:** When fixing multiple call sites, grep for ALL occurrences first. Using `replace_all` to rename `_` to `resp` can create collisions if `resp` is already used elsewhere in the same function (e.g., a variable from `conn.Read()`). Fix each occurrence individually or verify no collisions exist.

## 18. Windows Start-Process Gives Child a Real Console (ModeCharDevice)

**Platform:** Windows (PowerShell)
**Issue:** `Start-Process` in PowerShell gives the child process a real console, even with `-WindowStyle Hidden` and `-RedirectStandardOutput/-StandardError`. Go's `os.Stdin.Stat()` returns `ModeCharDevice=true`, so code that checks for an interactive terminal (e.g., vault passphrase prompt) will still prompt on stdin, blocking the process.
**Contrast:** On Linux, backgrounding with `&` or piping stdin makes `ModeCharDevice=false`, so terminal-detection code correctly skips interactive prompts.
**Fix:** Set environment variables before `Start-Process` to bypass interactive prompts:

```powershell
$env:SUBNETREE_VAULT_PASSPHRASE = "passphrase"
$proc = Start-Process -FilePath $binary -ArgumentList $args -PassThru -WindowStyle Hidden
```

For bash scripts, `export VAR=value` before backgrounding the process achieves the same effect.

## 19. PowerShell 5.1 ConvertFrom-Json Drops Empty Arrays

**Platform:** Windows (PowerShell 5.1)
**Issue:** `ConvertFrom-Json` on an empty JSON array `[]` returns `$null` instead of an empty PowerShell array `@()`. This means `$null -ne $result` evaluates to `$false` even when the API returned HTTP 200 with a valid empty response.
**Diagnosis:** API endpoints that return `[]` (e.g., Pulse alerts, Insight anomalies when none exist) appear to "fail" in verification scripts.
**Fix:** For endpoints where you only need to confirm "responds 200", use `Invoke-WebRequest` directly and check `$resp.StatusCode` instead of parsing JSON:

```powershell
# BAD: empty array becomes $null
$alerts = Invoke-Api -Uri "$url/api/v1/pulse/alerts" -Token $token
if ($null -ne $alerts) { ... }  # false negative on []

# GOOD: check HTTP status code
$resp = Invoke-WebRequest -Uri "$url/api/v1/pulse/alerts" -Headers @{ "Authorization" = "Bearer $token" } -UseBasicParsing
if ($resp.StatusCode -eq 200) { ... }  # always works
```

## 20. Stacked PR Rebase After Squash-Merge Requires Skip

**Platform:** Git / GitHub
**Issue:** When squash-merging a base PR (e.g., PR #143) to main, downstream stacked branches (e.g., PR #144, #145) still contain the original pre-squash commits. Running `git rebase origin/main` on the downstream branch produces conflicts for every already-merged commit because the squash commit hash differs from the original commits.
**Fix:** Use `git rebase --skip` for each conflicting commit that was part of the squash-merged PR. Git will drop the already-applied commits and keep only the unique downstream commits. For a 3-PR stack (A->B->C) merged bottom-up:

1. Squash-merge A to main
2. On B's branch: `git rebase origin/main`, then `--skip` for each of A's commits
3. Force push B, merge B to main
4. On C's branch: `git rebase origin/main`, then `--skip` for A's and B's commits

**Prevention:** Consider using `git rebase --onto origin/main <old-base> <branch>` to skip known-merged commits in one step.

## 21. VS Code YAML Extension Conflict: jumpToSchema

**Platform:** VS Code (all)
**Issue:** Codecov VS Code extension (v0.1.1) and Red Hat YAML both bundle `yaml-language-server` internally. Both try to register the `jumpToSchema` command at startup. The second to load crashes with `command 'jumpToSchema' already exists`, preventing the Codecov extension from initializing.
**Diagnosis:** Error in Codecov Extension output channel: `Server initialization failed. Error: command 'jumpToSchema' already exists`.
**Fix:** Remove the Codecov extension. Red Hat YAML covers YAML schema validation comprehensively (including Codecov schemas via SchemaStore). Also remove redundant `yamllint-ts` and `yamllint-fix` extensions if installed -- one YAML language server is sufficient.
**General rule:** Avoid multiple extensions that embed the same language server. Prefer one comprehensive extension over several specialized ones for the same language.

## 22. Project Renames Create Competitive Research Blind Spots

**Platform:** GitHub / All
**Issue:** When GitHub projects rename (often for trademark reasons), searches for the OLD name return nothing and searches for the NEW name miss historical context. Docker Hub images, Proxmox community scripts, and Unraid app listings may retain old names for months. Example: Scanopy was "NetVisor" (mayanayza/netvisor) from Sep-Dec 2025, renamed to scanopy/scanopy on Dec 15, 2025. Docker images still show `mayanayza/netvisor-server`.
**Impact:** Competitive research using keyword searches misses renamed projects entirely. Our research concluded "no competitors" while Scanopy had 3k+ stars.
**Fix:** When researching a competitive space: (1) Search by function, not product name ("network topology visualization self-hosted" not "NetVisor"), (2) Check Docker Hub for related images (old names persist), (3) Look at GitHub topics/tags, (4) Check star counts on GitHub search results to find established projects, (5) Re-scan monthly.

## 23. GitHub Rulesets Return 404 on Branch Protection API

**Platform:** GitHub
**Issue:** Repos using GitHub **rulesets** (Settings > Rules > Rulesets) instead of classic **branch protection** (Settings > Branches) return 404 from `gh api repos/{owner}/{repo}/branches/main/protection`. This makes it look like there's no protection when there actually is. Rulesets are the newer system and repos may have been migrated without the maintainer realizing.
**Diagnosis:** `gh pr merge` fails with "base branch policy prohibits the merge" but branch protection API returns 404.
**Fix:** Check rulesets instead: `gh api repos/{owner}/{repo}/rulesets --jq '.[] | {id, name, enforcement}'`. Get details with `gh api repos/{owner}/{repo}/rulesets/{id}`. The `--admin` flag on `gh pr merge` works for ruleset bypass when the admin role is in the bypass list.
**Related:** Required review count is nested under "Require a pull request before merging" > "Show additional settings" in the ruleset UI -- easy to miss.

## 24. cla-assistant.io Blocks Dependabot PRs

**Platform:** GitHub
**Issue:** The external cla-assistant.io integration creates a `license/cla` status check that stays permanently "pending" on Dependabot PRs because `dependabot[bot]` cannot sign a CLA. This is separate from a GitHub Actions CLA workflow (`cla.yml`) which can allowlist bots. Having both creates duplicate CLA checks with different results.
**Diagnosis:** PR shows `license/cla: pending -- Contributor License Agreement is not signed yet` alongside `cla: pass`.
**Fix:** Remove the cla-assistant.io integration (redundant if you have a GitHub Actions CLA workflow) or add `dependabot[bot]` to its allowlist. The Actions-based CLA workflow is more configurable and handles bot authors correctly.

## 25. Parallel Background Agents Share Working Tree

**Added:** 2026-02-17 | **Source:** global | **Status:** active

**Platform:** Claude Code (all)
**Issue:** When launching multiple background agents (`Task` tool) in parallel that modify files, ALL agents write to the currently checked-out git branch. The agents don't create or switch branches -- they just write files to the working directory. After both complete, all changes are mixed together as unstaged modifications on whichever branch was checked out.
**Diagnosis:** `git status` shows files from multiple unrelated features as modified. `git diff` shows changes meant for different branches interleaved.
**Fix:** After parallel agents complete, manually sort changes into correct branches:

1. Stage only the files for the current branch's feature: `git add <specific files>`
2. Commit on the current branch
3. Stash remaining files: `git stash push -u -m "other-feature" -- <paths>`
4. Switch to the other branch: `git checkout <other-branch>`
5. Pop stash: `git stash pop`
6. Commit on the other branch

**Prevention:** Accept this as a tradeoff of parallel execution. The time saved by parallel agents outweighs the 2-minute sorting step. Alternatively, run agents sequentially with branch switches between them (slower but cleaner).
**Update (2026-02-15):** Agents can self-recover if given clear branch context in their prompts. Include target branch name and exact file list in the agent prompt. Agents detect leaked files via `git status` and clean them with `git checkout --`. Agents on wrong branches recover with `git stash && git checkout <correct> && git stash pop`. See autolearn-patterns.md #48.
**Update (2026-02-16):** If an agent autonomously commits and pushes (creating a PR), it runs `git checkout <branch>` which changes HEAD and **discards other parallel agents' unstaged tracked-file changes**. Untracked files (new directories) survive. Sprint 2: Agent H committed on `feature/issue-399`, discarding Agent B's unstaged changes to `main.go` and `recon.go`. Fix: Either restrict agents from committing (main context handles all git ops) or accept tracked file loss and re-apply from the agent's output summary.
**Update (2026-03-02):** `git stash` while agents are still running is unsafe. Agents continue writing to the working tree AFTER the stash, so `git stash pop` fails with "Your local changes would be overwritten." Recovery: commit one agent's files directly (already in working tree), extract the other's from stash via `git diff stash@{0} -- <file>` (not `git stash show -p stash@{0} -- <file>`, which fails with "Too many revisions specified"), then apply manually.

## 26. Sequential Same-File PR Merge Requires Rebase Between Each

**Platform:** Git / GitHub
**Issue:** When multiple PRs modify the same file (e.g., README.md), merging one immediately conflicts the others -- even if all had passing CI when created. The second PR's diff is computed against the old main, not the post-merge main.
**Diagnosis:** `gh pr merge` fails with "Pull Request is not mergeable" after a sibling PR was just merged.
**Fix:** Merge one at a time. After each merge:

1. `git fetch origin && git checkout <next-branch>`
2. Clear dirty tracked files: `git checkout -- .claude/settings.local.json` (always dirty)
3. Stash untracked blockers: `git stash push -u -m "temp" -- <untracked-files>`
4. `git rebase origin/main` -- resolve conflicts manually
5. `git push --force-with-lease`
6. Wait for CI, then merge

**Gotcha within the gotcha:** `GIT_EDITOR=true git rebase --continue` is needed when rebase pauses at a commit with no remaining conflicts (all resolved via `git add`). Without `GIT_EDITOR=true`, git opens an editor for the commit message and hangs in non-interactive shells.

## 27. SQLite strftime Returns NULL for RFC3339Nano Timestamps

**Platform:** SQLite (all)
**Issue:** `strftime('%Y-%m-%dT%H', timestamp_col)` returns NULL when the timestamp column contains RFC3339Nano format (`2026-02-14T10:30:00.123456789Z`). SQLite's strftime only recognizes a subset of ISO 8601 formats -- specifically, it expects `YYYY-MM-DD HH:MM:SS` or `YYYY-MM-DDTHH:MM:SS` without fractional seconds beyond milliseconds.
**Diagnosis:** SQL queries using `GROUP BY strftime(...)` return zero rows even when the table has data. The grouping key is NULL for every row.
**Fix:** Don't use SQLite strftime for time-bucket aggregation on RFC3339Nano timestamps. Instead, do time-bucketing in Go:

```go
bucket := ts.Truncate(interval).UTC().Format(time.RFC3339)
```

Query all points within the time range with a simple `WHERE timestamp BETWEEN ? AND ?` (string comparison works for RFC3339), then aggregate in Go.

## 28. Recharts v3 Uses TooltipContentProps, Not TooltipProps

**Platform:** React / recharts 3.x
**Issue:** In recharts v3 (3.7.0+), the `<Tooltip content={...} />` callback receives `TooltipContentProps`, not `TooltipProps`. Using `TooltipProps` causes TypeScript errors: `Property 'payload' does not exist on type` and same for `label`. The properties `payload`, `label`, `active` are context-provided and only exist on `TooltipContentProps`.
**Fix:** Import and use `TooltipContentProps` instead of `TooltipProps`:

```tsx
import { type TooltipContentProps } from 'recharts'

function CustomTooltip({ active, payload, label }: TooltipContentProps<number, string>) {
  // payload, label, active all exist here
}

<Tooltip content={(props: TooltipContentProps<number, string>) => <CustomTooltip {...props} />} />
```

**Additional gotcha:** Passing a JSX element like `<Tooltip content={<CustomTooltip />} />` renders with empty `{}` props initially. Fix: use `Partial<TooltipContentProps<number, string>>` for the function signature, or use a render function instead of JSX element. See autolearn-patterns.md #63 for full example.

## 29. Build-Tag Files Invisible to Local Lint on Different OS

**Platform:** Go (cross-platform development)
**Issue:** Files with `//go:build !windows` tags are completely excluded from `golangci-lint` when running on Windows (and vice versa). Lint errors in these files -- `gocritic filepathJoin` (absolute paths in `filepath.Join`), `gosec G115` (int->int32 overflow), `gocritic paramTypeCombine`, `prealloc` -- only appear in Linux CI. This caused 2 fix-push cycles on PR #262 (Linux Scout).
**Common errors in `!windows` files caught only by Linux CI:**

- `filepathJoin`: `filepath.Join("/sys/block", name)` -- the absolute path contains a separator. Fix: use string concat `"/sys/block/" + name`
- `G115`: `int32(runtime.NumCPU())` -- safe conversion but needs `//nolint:gosec // G115: fits in int32`
- `paramTypeCombine`: `(model string, physCores int32, logical int32)` should be `(model string, physCores, logical int32)`
- `prealloc`: `var slice []*T` in a loop should be `make([]*T, 0, len(source))`
**Fix:** After writing `!windows` code, mentally check for these patterns since local Windows lint won't catch them. Consider adding `GOOS=linux golangci-lint run ./...` to local workflow (requires Docker or WSL).

## 30. Background Agents Can't Prompt for Tool Permissions

**Platform:** Claude Code (all platforms)
**Issue:** Background agents launched with `Task(run_in_background=true)` inherit the session's current tool permission state. If a tool hasn't been approved yet (user hasn't clicked "allow"), the background agent gets denied silently and cannot prompt the user for approval. The agent burns tool calls futilely trying alternatives.
**Diagnosis:** Agent output shows repeated "Permission to use [tool] has been denied" for WebSearch, WebFetch, Bash, MCP tools, etc. One agent burned 27 tool calls (all denied) before giving up.
**Fix:** Before launching background agents, ensure the tools they need are already approved in the session. For research tasks, prefer `subagent_type=Bash` using `gh api` commands (usually already approved) over `subagent_type=general-purpose` that might need WebSearch/WebFetch.
**Prevention:** Launch a "warm-up" foreground call using each tool type before going parallel. Or accept partial failure by launching redundant agents across different tool types -- if 2 of 3 succeed, you still get actionable data.

## 31. Reddit Blocks WebFetch but gh api Works

**Platform:** All (Claude Code)
**Issue:** Reddit's robots.txt blocks WebFetch and most scraping tools. `WebFetch("https://www.reddit.com/...")` and `WebFetch("https://old.reddit.com/...")` both fail. Web search with `allowed_domains: ["reddit.com"]` also returns nothing.
**Workaround:** Reddit serves JSON when you append `.json` to any URL. Use `gh api` as a raw HTTP client:

```bash
gh api -X GET "https://www.reddit.com/r/selfhosted/comments/v3pjx8/.json" --cache 1h
```

Returns an array of two objects: `[0]` is the post, `[1]` is the comment tree. Extract with `--jq`:

```bash
# Post title and body
gh api -X GET "$URL.json" --jq '.[0].data.children[0].data | {title, selftext}'
# All top-level comments
gh api -X GET "$URL.json" --jq '.[1].data.children[].data | {author, body, score}'
```

**Limitation:** Only works with specific URLs (not search). For broad Reddit research, use blog aggregation (search for "best X tools reddit 2025/2026" on elest.io, xda-developers, betterstack).

## 32. SessionStart Hook: Use `type: "command"` Not `type: "prompt"`

**Platform:** Claude Code (all)
**Issue:** `SessionStart` hooks with `type: "prompt"` send the prompt text to a small model for yes/no evaluation. If the prompt is an instruction ("Run /dashboard to display..."), the small model doesn't know what to do with it and the hook produces no useful output. The hook appears to fire but nothing happens.
**Diagnosis:** No `SessionStart hook success` message appears in system reminders despite the hook being correctly configured in settings.json.
**Fix:** Use `type: "command"` with an echo statement. The command output is injected as a system reminder that Claude sees and acts on:

```json
"SessionStart": [{
  "hooks": [{
    "type": "command",
    "command": "echo 'AUTO_START: Run /dashboard skill to display session control station.'"
  }]
}]
```

**Key insight:** `type: "prompt"` is for conditional logic (should this hook fire?). `type: "command"` is for injecting fixed context. For SessionStart instructions, always use command.

## 33. Claude Code Hooks Cannot Initiate Conversation

**Platform:** Claude Code (all)
**Issue:** Hooks (including `SessionStart`) inject context as system reminders but cannot make Claude proactively start a conversation. Claude only sees hook output when the user sends their first message. This means "auto-run X on startup" requires the user to type something first.
**Workaround:** Accept this as a two-step startup: (1) hook fires silently, (2) user types anything (even "go"), (3) Claude sees the hook output and acts. Pair with a static file that auto-opens (VS Code task with `runOn: folderOpen`) so the user has orientation while the hook waits for input.

## 34. Chrome Ignores autocomplete="off" on Form Fields

**Platform:** All browsers (Chrome since v34, Firefox/Safari similar)
**Issue:** Setting `autocomplete="off"` on form inputs has no effect -- browsers ignore it. Additionally, non-standard `name` attributes (e.g., `name="new-username"`) prevent browsers from correctly identifying form field roles. When Chrome fills a saved password, it looks for a companion username field and picks the nearest text/email input, causing autofill to overwrite the wrong field.
**Diagnosis:** Password autofill overwrites the email field with a saved username. Happens on setup/registration forms where username, email, and password fields are all present.
**Fix:** Use standard `name` + `autocomplete` attribute values that match the field's semantic role:

```html
<!-- Username field -->
<input name="username" autocomplete="username" />

<!-- Email field -->
<input name="email" type="email" autocomplete="email" />

<!-- New password (registration/setup) -->
<input name="new-password" type="password" autocomplete="new-password" />

<!-- Confirm password -->
<input name="confirm-password" type="password" autocomplete="new-password" />
```

**Key insight:** Browsers use `name` and `autocomplete` together to determine field purpose. Standard values (`username`, `email`, `new-password`, `current-password`) let browsers correctly pair fields with saved credentials. Non-standard values cause browsers to guess -- and guess wrong.

## 35. Go Race Detection Requires CGO on Windows MSYS

**Platform:** Windows (MSYS_NT)
**Issue:** `go test -race ./...` fails immediately with `go: -race requires cgo; enable cgo by setting CGO_ENABLED=1`. The race detector is implemented in C and requires CGO, which isn't available in the standard MSYS/Git-for-Windows Go installation.
**Impact:** Local Windows verification cannot include race detection. Race bugs are only caught by CI (Linux runners have CGO enabled).
**Workaround:** Run `go test ./...` locally (without `-race`). Rely on CI's Linux runner for race detection. If race detection is critical locally, use WSL2 or Docker with a Linux Go image.

## 36. Go uint64 Subtraction Wraps Instead of Going Negative

**Platform:** Go (all)
**Issue:** `uint64` subtraction wraps around to a huge positive number when the result would be negative (e.g., `50 - 100` becomes `~2^64 - 50`). A subsequent `float64()` conversion produces a huge positive float, not a negative one. This means `if float64(a - b) < 0` is **always false** for uint64 values -- the check is dead code.
**Diagnosis:** Docker CPU% calculation returned absurd values (like 1.8e+19%) when `TotalUsage` decreased between samples (container restart, counter reset).
**Fix:** Guard with pre-subtraction comparison on the raw uint64 values:

```go
// BAD: float64 check never catches uint64 underflow
cpuDelta := float64(newUsage - oldUsage)
if cpuDelta < 0 { return 0.0 } // dead code!

// GOOD: compare raw uint64 before subtraction
if newUsage < oldUsage { return 0.0 }
cpuDelta := float64(newUsage - oldUsage)
```

**Scope:** Any metric calculation using uint64 counters that can decrease (container restarts, system reboots, counter wraps). Common in Docker stats, network byte counters, and CPU tick counters.

## 37. VS Code Locks Workspace Root Directories

**Platform:** Windows (VS Code)
**Issue:** `rm -rf` on a directory that VS Code has open as a workspace root fails with "Device or resource busy". VS Code's file watcher holds handles on the directory. Individual files inside CAN be removed, but the empty directory shell persists until VS Code reloads with an updated workspace file that no longer references that root.
**Diagnosis:** After updating `subnetree.code-workspace` from 3-root to single-root, the old `.coordination/` directory (previously a workspace root) couldn't be deleted despite all its files being removed.
**Fix:** Remove file contents first (`rm -f dir/*`, `rm -rf dir/.git`), then accept the empty directory will self-clean when VS Code reloads with the new workspace config. Alternatively, close VS Code first, delete the directory, then reopen.
**Prevention:** When restructuring workspaces, plan to reload VS Code between removing directory contents and deleting the directory itself.

## 38. Playwright getByLabel Resolves Multiple Elements with Toggle Buttons

**Platform:** Playwright (all browsers)
**Issue:** `page.getByLabel('Password')` resolves to 2+ elements when a password input has a companion show/hide toggle button whose `aria-label` contains "password" (e.g., "Show password", "Hide password"). Playwright's `getByLabel` matches both the input (via `for=` attribute) and the button (via `aria-label` substring).
**Diagnosis:** Test fails with "strict mode violation: getByLabel('Password') resolved to 2 elements". The elements are the `<input>` and the toggle `<button>`.
**Fix:** Use `page.locator('#password')` to target by ID instead of label. This is unambiguous regardless of companion buttons.
**Prevention:** For any form field with companion buttons (password toggle, clear button, search icon), prefer `locator('#id')` over `getByLabel()`.

## 39. Docker Extension `update` Fails After Image Rebuild

**Platform:** Docker Desktop Extensions (all)
**Issue:** `docker extension update <tag>` returns "the extension is not installed" after rebuilding the Docker image, even if the extension was previously installed with the same tag. This happens because rebuilding replaces the image SHA, and Docker Desktop tracks extensions by image digest, not tag.
**Fix:** Use `docker extension install <tag>` instead of `update` when the image has been rebuilt. The install command works whether or not the extension is currently registered. Pipe `echo "y"` to auto-confirm the prompt in scripts.

## 40. User Manual Commits During Context Compaction Gap

**Platform:** Claude Code (all)
**Issue:** When context compacts and the session is continued, the user may have made manual git commits between the old session ending and the new session starting. The continuation summary says "files need committing" but the working tree is clean -- the user already committed (possibly with a different message or extra files bundled in).
**Diagnosis:** `git status` shows clean, `git add` stages nothing, `git commit` says "nothing to commit". But `git diff --stat main..HEAD` shows all the expected changes.
**Fix:** On any continuation session, run `git log --oneline main..HEAD` and `git diff --stat main..HEAD` BEFORE attempting to commit. If changes are already committed, skip to push/PR creation. Don't try to amend the user's commit unless asked.

## 41. .claude/settings.local.json Should Be Gitignored

**Platform:** Claude Code (all)
**Issue:** `.claude/settings.local.json` contains local Claude Code tool permission settings. If not in `.gitignore`, it can be accidentally committed via `git add -A` or manual commits, exposing local configuration to the repo.
**Fix:** Add `.claude/` to `.gitignore`. If already committed, remove with `git rm --cached .claude/settings.local.json` and add to `.gitignore`.

## 42. BMAD Method Generates 42 Slash Commands in .claude/commands/

**Platform:** Claude Code (all)
**Issue:** `npx bmad-method install --modules bmm --tools claude-code` generates 42 slash commands (all prefixed `bmad-bmm-*` or `bmad-*`) in `.claude/commands/`. This can overwhelm Claude Code's command namespace if the project already has its own commands, making tab-completion and command discovery harder. Spec Kit only generates 9 commands for comparison.
**Diagnosis:** After BMAD install, `/` tab-completion shows a wall of `bmad-bmm-*` entries mixed with project commands.
**Fix:** Install BMAD in a separate directory from the main project if command namespace is a concern. Or selectively delete unused `/bmad-bmm-*` command files after install (keep only Quick Flow, Document Project, and validation commands for brownfield work).
**Note:** BMAD's `/bmad-help` command provides guidance on which workflows to use, but the sheer volume of 42 commands is intimidating for new users.

## 43. Spec Kit `specify init` Hangs on Windows MSYS

**Platform:** Windows (MSYS_NT) / Python Rich library
**Issue:** `specify init <path> --ai claude --no-git --force` hangs indefinitely on Windows MSYS. The Rich library's interactive prompt blocks even with `PYTHONIOENCODING=utf-8 NO_COLOR=1` env vars, `echo "" |` piping, and `2>&1 | cat` redirection. The `specify version` command also crashes with `UnicodeEncodeError` from `legacy_windows_render`.
**Diagnosis:** `specify init` starts but stops at an interactive directory selection prompt that can't be bypassed.
**Fix:** Skip `specify init` entirely. Fetch templates directly from the GitHub repo:

```bash
# List available templates
gh api repos/github/spec-kit/contents/templates/commands --jq '.[].name'

# Fetch a specific template
gh api repos/github/spec-kit/contents/templates/commands/specify.md \
  --jq '.content' | base64 -d
```

This bypasses the CLI entirely and gives you the raw template files. For `specify version`, use `PYTHONIOENCODING=utf-8 NO_COLOR=1 specify version` (works when piped through bash, not in direct terminal).

## 44. BMAD npm Package Name Is Not Obvious

**Platform:** npm / Node.js
**Issue:** The BMAD Method v6 npm package is `bmad-method`. Common wrong guesses: `@anthropics/bmad-cli`, `bmad-cli`, `@bmadcode/bmad`, `bmad-builder`. There are 15+ BMAD-related packages on npm from different authors.
**Fix:** The correct install command is:

```bash
npx -y bmad-method install --modules bmm --tools claude-code \
  --user-name <name> --directory <path> -y
```

Key flag names (easy to get wrong): `install` (not `init`), `--modules` (not `--module`), `--tools` (not `--ide`), `--directory` (not `--dir`). Use `npx -y bmad-method --help` and `npx -y bmad-method install --help` to discover flags.

## 45. markdownlint-cli2 Config Must Be at Repo Root for CI

**Platform:** GitHub Actions / markdownlint-cli2
**Issue:** `DavidAnson/markdownlint-cli2-action@v19` `config` parameter does not reliably override the config file lookup. markdownlint-cli2 discovers `.markdownlint.json` by walking up from each file's directory. If the config is only in a subdirectory (e.g., `devspace/.markdownlint.json`), CI uses default rules instead.
**Diagnosis:** CI fails with MD013 (line-length) errors even though the config has `"MD013": false`. Locally, lint passes because the parent directory's config is found via filesystem walk.
**Fix:** Place `.markdownlint.json` at the repo root. If you also need it in a subdirectory for parent-directory cascading, maintain two copies (repo root for CI, subdirectory for local cascading). Remove the `config` parameter from the action -- auto-discovery from repo root works correctly.

## 46. markdownlint MD060 Auto-Enabled by Default: True

**Platform:** markdownlint v0.40.0+
**Issue:** MD060 (table-column-style) is a newer rule that gets auto-enabled when config has `"default": true`. It flags tables where separator rows use compact style (`|---|`) but content rows use padded style (`| text |`). If your config was written before this rule existed, it will suddenly appear in CI after a markdownlint version upgrade.
**Diagnosis:** CI shows dozens of `MD060/table-column-style` errors on tables that look fine visually. The errors say "Table pipe is missing space to the left/right for style compact".
**Fix:** Add `"MD060": false` to `.markdownlint.json` to disable, or fix all table pipe spacing to be consistent. When using `"default": true`, review release notes after markdownlint upgrades for newly added rules.

## 47. PowerShell [Mandatory] Validates Each Element in String Arrays

**Platform:** PowerShell 7+
**Issue:** `[Parameter(Mandatory)] [string[]]$Param` validates EACH element in the array, not just the array itself. Empty strings `''` used as visual separator lines in instruction arrays fail with "Cannot bind argument to parameter because it is an empty string."
**Diagnosis:** Function call works with non-empty strings but fails when array contains `''` elements as blank lines for display formatting.
**Fix:** Add `[AllowEmptyString()]` alongside `[Mandatory]`:

```powershell
[Parameter(Mandatory)]
[AllowEmptyString()]
[string[]]$Instructions,
```

**Note:** `[AllowNull()]` is different — it allows `$null`, not empty strings. You need `[AllowEmptyString()]` specifically.

## 48. Win32_Processor.VirtualizationFirmwareEnabled False When Hypervisor Running

**Platform:** Windows (Hyper-V)
**Issue:** `(Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled` returns `$false` when Hyper-V (or any hypervisor) is already active. The CPU reports VT-x as "not available" because the hypervisor has already claimed it. This creates a false negative in virtualization readiness checks.
**Diagnosis:** Bootstrap reports "Virtualization FAIL" on a machine where Docker Desktop, WSL2, and Hyper-V are all working correctly.
**Fix:** Use Hyper-V state as a fallback. If Hyper-V is enabled, virtualization must be active regardless of what `Win32_Processor` reports:

```powershell
$virtCheck = Test-Virtualization  # uses Win32_Processor
$hyperVMet = $false
try { $hyperVMet = (Test-HyperV).Met } catch { }
if ($virtCheck.Met -or $hyperVMet) {
    # Virtualization is confirmed
}
```

## 49. PowerShell Get-ChildItem Misses Dotfiles Without -Force

**Platform:** PowerShell (all versions)
**Issue:** `Get-ChildItem -Filter 'credentials*'` does NOT match `.credentials.json` because dotfiles (files starting with `.`) are treated as hidden on Windows. Without `-Force`, they're invisible. Additionally, the filter `credentials*` doesn't match `.credentials*` — the dot prefix is significant.
**Diagnosis:** Claude Code auth check reports "not authenticated" despite `~/.claude/.credentials.json` existing and containing valid tokens.
**Fix:** Use `-Force` flag AND add a separate `.credentials*` filter:

```powershell
$authFiles = Get-ChildItem -Path $dir -Filter 'auth*' -File -Force -ErrorAction SilentlyContinue
$credFiles = Get-ChildItem -Path $dir -Filter 'credentials*' -File -Force -ErrorAction SilentlyContinue
$dotCredFiles = Get-ChildItem -Path $dir -Filter '.credentials*' -File -Force -ErrorAction SilentlyContinue
```

**General rule:** Always use `-Force` when searching for config/credential files that might be dotfiles.

## 50. Winget Exit Code -1978335189 Means Already Installed

**Platform:** Windows (winget)
**Issue:** `winget install <id>` returns exit code `-1978335189` (`0x8A150011` = `APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE`) when the package is already installed and no upgrade is available. Scripts treating non-zero exit codes as failures incorrectly report these as installation failures.
**Diagnosis:** Bootstrap shows "FAIL" for every package that's already up to date. Stderr contains "No available upgrade found."
**Fix:** Check for this specific exit code and treat it as success:

```powershell
$exitCode = $proc.ExitCode
if ($exitCode -eq 0) {
    # Newly installed or upgraded
} elseif ($exitCode -eq -1978335189 -or $exitCode -eq -1978335184) {
    # Already installed, up to date (-1978335184 = no applicable update)
    Write-OK "$Id already installed (up to date)"
    return @{ Success = $true; AlreadyInstalled = $true }
} else {
    # Actual failure
}
```

## 51. Winget Installs Update Registry PATH but Current Session Is Stale

**Platform:** Windows (PowerShell / MSYS)
**Issue:** When winget installs tools (gh, go, rustup, cmake), they add to the registry `PATH` (`HKLM\...\Environment` or `HKCU\...\Environment`). But the current PowerShell or bash session still has the old `$env:PATH` from process start. Newly installed tools appear as "not found" in the same session.
**Diagnosis:** Phase 6 verification reports tools as missing immediately after Phase 2 installed them. Restarting the terminal resolves it.
**Fix:** Refresh PATH from registry before running verification:

```powershell
# PowerShell
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')
```

```bash
# Bash/MSYS -- export the specific tool path
export PATH="/c/Program Files/GitHub CLI:$PATH"
```

**Note:** This is related to gotcha #8 (Windows Python aliases) but affects ALL winget-installed tools, not just Python.

## 52. Physical Drive Migration Preserves Old User SID

**Platform:** Windows 11
**Issue:** Moving a physical drive from one PC to another preserves the old user's SID on all files and directories. Windows shows security warnings about untrusted files. Applications may fail to read/write files they previously owned. Copying files (via network share or Explorer) creates new ownership; moving/migrating the physical drive does not.
**Diagnosis:** Windows security popup says "we can't verify who created this file" on files from the migrated drive.
**Fix:** Take ownership recursively and reset ACLs:

```powershell
# Run as Administrator
takeown /F D:\ /R /A          # Assign ownership to Administrators group
icacls D:\* /reset /T /C /Q   # Reset ACLs to inherited defaults
```

**Gotcha:** `icacls <drive>:\` on the drive root may fail with "un-usable ACL" — use `<drive>:\*` instead to skip the root directory's special system ACLs. Stale symlinks (e.g., old pnpm links) will fail — these are harmless.

## 53. VS Code CLI Opens Editor Tabs When Stdin Not Redirected

**Platform:** Windows (PowerShell)
**Issue:** `Start-Process -FilePath 'code' -RedirectStandardOutput ... -RedirectStandardError ...` (without `-RedirectStandardInput`) still opens `code-stdin-*` editor tabs. VS Code's CLI wrapper inherits the parent process's stdin handle and interprets pending input as a file to open. This happens with `--list-extensions`, `--install-extension`, and any other `code` subcommand.
**Diagnosis:** VS Code opens a tab named `code-stdin-XXX` (random suffix) every time the script calls `code`. The tab contains garbled or empty content.
**Fix:** Always redirect ALL THREE streams when invoking `code` from a script:

```powershell
$tmpIn  = [IO.Path]::GetTempFileName()
$tmpOut = [IO.Path]::GetTempFileName()
$tmpErr = [IO.Path]::GetTempFileName()
$proc = Start-Process -FilePath 'code' `
    -ArgumentList '--list-extensions' `
    -NoNewWindow -PassThru `
    -RedirectStandardInput  $tmpIn `
    -RedirectStandardOutput $tmpOut `
    -RedirectStandardError  $tmpErr
```

**Key insight:** The empty temp file provides immediate EOF on stdin, preventing VS Code from reading anything. This is the ONLY reliable fix — `-NoNewWindow`, `-WindowStyle Hidden`, and pipe redirects (`2>&1`) all fail to prevent the tabs.

## 54. PowerShell param() Must Be First Executable Statement

**Platform:** PowerShell 7+
**Issue:** `Set-StrictMode -Version Latest` placed before `param()` causes: "The function or command was called as if it were a method. Parameters should be separated by spaces." Only comments and `#Requires` directives are allowed before `param()`.
**Diagnosis:** Script fails on first invocation with a confusing error message that doesn't mention `param()` at all.
**Fix:** Always place `param()` as the first executable statement in any script file:

```powershell
#Requires -Version 7.0
# Comments are OK here

param(
    [switch]$List,
    [string]$Install
)

Set-StrictMode -Version Latest  # Must come AFTER param()
```

**Note:** This is a PowerShell language requirement, not a style preference. The parser treats the script block differently when `param()` is not the first statement.

## 55. VS 2022 Bundled Node.js as Fallback for Frontend Builds

**Platform:** Windows (MSYS_NT)
**Issue:** Node.js, npm, and pnpm may not be on the system PATH or MSYS PATH, but Visual Studio 2022 bundles Node.js v20.x at `C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VisualStudio\NodeJs\`. Running commands via `cmd.exe` from MSYS swallows output; `\$env:PATH` escaping breaks in bash heredocs.
**Fix:** Write a temp PowerShell script file and execute it:

```bash
cat > /tmp/frontend-cmd.ps1 << 'PSEOF'
$env:PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VisualStudio\NodeJs;" + $env:PATH
Set-Location "d:\project\web"
& npx pnpm install --no-frozen-lockfile
PSEOF
powershell.exe -NoProfile -File /tmp/frontend-cmd.ps1 2>&1
```

**Key insights:**

- `cmd.exe /c` from MSYS swallows output -- use PowerShell instead
- Inline PowerShell from bash (`powershell.exe -Command "..."`) has escaping issues with `$env:PATH` -- the `\$` needed for bash conflicts with PowerShell syntax
- Writing to a `.ps1` temp file and using `-File` bypasses all escaping issues
- `npx pnpm` downloads pnpm on the fly but pnpm then needs `node` on PATH -- set PATH before the npx call

## 56. Subagent pnpm-lock.yaml Drift When Node.js Unavailable

**Platform:** Claude Code (Windows)
**Issue:** When a subagent adds npm dependencies to `package.json` but cannot run `pnpm install` because Node.js/pnpm aren't on PATH, CI fails with `ERR_PNPM_OUTDATED_LOCKFILE Cannot install with "frozen-lockfile"`. The agent's changes are correct but incomplete.
**Diagnosis:** PR CI shows frontend job failing. `package.json` has new deps but `pnpm-lock.yaml` is stale.
**Fix:** After merging subagent changes, run `pnpm install` (or `npx pnpm install --no-frozen-lockfile` via the VS 2022 Node.js workaround in gotcha #55) to update the lockfile. Commit the updated `pnpm-lock.yaml` and push.
**Prevention:** Include "run `pnpm install` after adding dependencies" in frontend agent prompts. Or accept this as a known post-agent fixup step when Node.js isn't available in the agent's environment.

## 57. Swagger x-enum-descriptions Blocks Differ Between Windows and Linux

**Added:** 2026-02-24 | **Source:** SubNetree | **Status:** active
**See also:** AP#17, AP#35, KG#12, KG#59

**Platform:** Go (swaggo/swag, cross-platform)
**Issue:** Windows `swag init` generates `x-enum-descriptions` array blocks for Go enums with comment annotations. Linux CI's `swag init` (same version) omits these blocks entirely. The `x-enum-comments` map and `x-enum-varnames` array are generated identically on both platforms. This is a sibling of gotcha #12 (time.Duration enums) but affects any enum type with comment-annotated values.
**Diagnosis:** Swagger Drift Check fails in CI. Diff shows `x-enum-descriptions` arrays being removed from swagger files.
**Fix:** After running `swag init` locally on Windows, manually remove all `x-enum-descriptions` blocks from all three swagger files before committing.
**Prevention:** After any `swag init` on Windows, grep for `x-enum-descriptions` in swagger output and remove all matches.

```bash
# Quick check after swag init
grep -c "x-enum-descriptions" api/swagger/*
# Should be 0 for CI compatibility
```

## 58. Local Main Diverges After Squash-Merge When Merge Commits Exist

**Platform:** Git (all)
**Issue:** If local `main` has merge commits (e.g., from `git pull` without `--ff-only`), squash-merging a PR on GitHub creates a new commit on `origin/main` that isn't an ancestor of local `main`. `git pull --ff-only` then fails with "Not possible to fast-forward, aborting" because the histories diverged.
**Diagnosis:** `git log --oneline main` shows a merge commit not present on `origin/main`. `git log --oneline origin/main` shows the squash commit not present locally.
**Fix:** When local main has no uncommitted work:

```bash
git log --oneline main -3        # verify local-only merge commit
git log --oneline origin/main -3 # verify squash commit
git reset --hard origin/main     # safe when no uncommitted work
```

**Prevention:** Always use `git pull --ff-only` (or configure `git config pull.ff only`) to prevent merge commits on main. If local main already has a merge commit from a previous session, clean it up before starting new work.

## 59. Perl Regex for Stripping Swagger YAML Corrupts Line Boundaries

**Added:** 2026-02-24 | **Source:** SubNetree | **Status:** active
**See also:** AP#17, AP#35, KG#12, KG#57

**Platform:** Windows (MSYS_NT) / swaggo/swag
**Issue:** The perl one-liner used to strip `x-enum-descriptions` from `swagger.yaml` can concatenate adjacent lines. When a YAML enum description value is immediately followed by an `x-enum-descriptions` block, the regex removes the block AND the newline, joining the description with the next YAML key on one line. This produces invalid YAML.
**Diagnosis:** Swagger Drift Check passes for JSON but fails for YAML. The diff shows line concatenation rather than missing blocks.
**Fix:** After running the perl strip regex, verify YAML integrity:

```bash
# Strip x-enum-descriptions
perl -0777 -i -pe 's/\n\s*x-enum-descriptions:\n(?:\s+-\s+.*\n)*//g' api/swagger/swagger.yaml

# Verify no corrupted lines (description text joined with x-enum-varnames)
grep "x-enum-varnames" api/swagger/swagger.yaml | grep -v "^\s*x-enum-varnames"
# If any output, those lines are corrupted -- fix manually
```

**Prevention:** Consider switching to a YAML-aware tool (yq) for swagger post-processing instead of regex. Or validate the YAML parses cleanly after stripping.

## 60. Go Binary Permission Denied on MSYS -- Use go run Instead

**Added:** 2026-02-24 | **Source:** SubNetree | **Status:** active

**Platform:** Windows (MSYS_NT)
**Issue:** Go tool binaries installed to `~/go/bin/` (e.g., `swag`, `protoc-gen-go`) may have filesystem permission issues on MSYS bash, returning "permission denied" even when the file exists and is executable.
**Diagnosis:** Running `~/go/bin/swag init ...` fails with "permission denied". `ls -la ~/go/bin/swag` shows the file exists with execute bits.
**Fix:** Use `go run` with the full module path and pinned version instead of the local binary:

```bash
# BAD: permission denied
~/go/bin/swag init -g cmd/app/main.go -o api/swagger

# GOOD: go run bypasses local binary
go run github.com/swaggo/swag/cmd/swag@v1.16.4 init -g cmd/app/main.go -o api/swagger
```

**Key insight:** `go run` downloads the module to a temp cache and executes it directly, bypassing any filesystem permission issues with the `~/go/bin/` directory. Pin the version with `@vX.Y.Z` for reproducibility. Works for any Go tool: `swag`, `protoc-gen-go`, `golangci-lint`, etc.

## 61. Claude Code settings.local.json Does NOT Cascade from Parent Directories

**Platform:** Claude Code (all)
**Issue:** Unlike `.editorconfig` which walks up directories, Claude Code `settings.local.json` and `settings.json` do NOT cascade from parent directories. `D:\DevSpace\.claude\settings.local.json` does NOT apply to `D:\DevSpace\ProjectA\`. Each project is an independent scope.
**Impact:** Every new project requires manually approving every tool use, even when broad permissions exist in a parent directory.
**Settings hierarchy (actual):**

1. User-level: `~/.claude/settings.json` (applies to ALL projects)
2. Project-level: `<project>/.claude/settings.json` (committed, collaborator-shared)
3. Project-local: `<project>/.claude/settings.local.json` (gitignored, session accumulation)

Permission arrays **merge** across scopes. Deny rules take precedence.
**Fix:** Put broad tool permission wildcards in `~/.claude/settings.json` (user-level). These apply as defaults to every project. Use project-level `settings.json` only for project-specific deny rules or overrides. DevKit's user-level template (`claude/settings.template.json`) has the correct broad wildcards -- apply them to `~/.claude/settings.json`. For project-level permissions, use `project-templates/settings.json` copied to `<project>/.claude/settings.json`.
**Prevention:** When scaffolding new projects, copy `project-templates/settings.json` to `<project>/.claude/settings.json`. See DevKit issue #131 and [Settings Strategy](../docs/settings-strategy.md).

## 62. Windows CRLF Breaks Bash grep Value Extraction in CI

**Platform:** GitHub Actions (Ubuntu runners) / Windows-committed files
**Issue:** Files committed from Windows have `\r\n` line endings. When a CI bash script uses `grep -oP` to extract values (e.g., status fields from markdown metadata), the extracted string includes a trailing `\r`. This causes: (1) string comparisons to fail silently (`"active\r" != "active"`), (2) arithmetic expressions to fail with `syntax error in expression (error token is "0")` when `grep -cP` returns `"77\r"`, and (3) `::error` annotations to display split across two lines.
**Diagnosis:** CI job fails with "Invalid status 'active'" where the status looks correct. The `\r` is invisible in most log viewers. Arithmetic errors on `$((var1 - var2))` where vars came from grep output.
**Fix:** Pre-process files through `tr -d '\r'` before parsing. Create a temp clean copy:

```bash
clean_file=$(mktemp)
tr -d '\r' < "$file" > "$clean_file"
# All grep/parsing operations use $clean_file
# Error annotations still reference $file (original path for GitHub links)
rm -f "$clean_file"
```

**Prevention:** Any CI bash script that parses text from repo files committed on Windows should strip `\r` as a first step. This applies to metadata validators, config parsers, and changelog processors.

## 63. Lipgloss Emoji Variation Selector Width Mismatch

**Platform:** Go (charmbracelet/lipgloss, all terminals)
**Issue:** Emoji with variation selector U+FE0F (e.g., U+2328+FE0F `⌨️`) renders as 2 cells wide in terminals, but lipgloss counts U+2328 (Misc Technical block) as 1 cell. This causes a 1-character width discrepancy on any line containing the emoji, pushing content past the border and creating a stray disconnected right border bar.
**Diagnosis:** A vertical `│` appears detached to the right of the panel border, at the same row as the mismatched emoji.
**Fix:** Replace variation-selector emoji with standard 2-cell emoji from the Supplementary Multilingual Plane (U+1Fxxx). These have consistent 2-cell width in both terminals and lipgloss.

```go
// BAD: U+2328+FE0F -- lipgloss counts as 1 cell, terminal renders as 2
{Name: "Skills", Icon: "\u2328\ufe0f"}

// GOOD: U+1F3AF (dart) -- consistent 2-cell width
{Name: "Skills", Icon: "\U0001f3af"}
```

**General rule:** Avoid variation selectors (U+FE0F, U+FE0E) in TUI content rendered by lipgloss. Stick to emoji in the U+1Fxxx range which have unambiguous East Asian Width properties.

## 64. lipgloss.Place Output Is Not Safely ANSI-Strippable

**Platform:** Go (charmbracelet/lipgloss)
**Issue:** `lipgloss.Place(w, h, Center, Center, panel)` produces a full-terminal output with ANSI styling, borders rendered as box-drawing characters, and space-based centering. Stripping ANSI codes from this output to get "plain text positions" fails because: (1) lipgloss's internal width calculations account for styled content widths that change after stripping, (2) border characters become depositable content (not just chrome), and (3) emoji width mismatches compound across styled vs plain rendering.
**Diagnosis:** Transition animation deposits characters (including border chars) at wrong positions. The revealed text doesn't align with the real View() when it takes over.
**Fix:** Never strip ANSI from lipgloss output for position computation. Instead, create a dedicated plain-text renderer method that mirrors the View() logic using shared state (column count, responsive flags) but outputs unstyled text without borders. Let the consumer handle centering.

```go
// BAD: strip ANSI from styled output
menuText := transition.StripANSI(m.menu.View())

// GOOD: dedicated plain-text method with same layout logic
menuText := m.menu.TransitionText()
```

## 65. golangci-lint v2 Silent Config Failure Without version Field

**Platform:** Go (all)
**Issue:** `.golangci.yml` files written for golangci-lint v1 lack the `version: "2"` field required by v2. Running golangci-lint v2 with a v1 config produces `Error: can't load config: unsupported version of the configuration: ""` and exits non-zero. This only manifests when running golangci-lint itself -- `go build` and `go test` pass fine, so the issue isn't caught until CI or a pre-push hook runs linting.
**Diagnosis:** Linting step fails but build and test steps pass. Error message mentions "unsupported version" but doesn't suggest the fix.
**Fix:** Add `version: "2"` as the first field in `.golangci.yml`. Also update the module path in `go run` or `go install` commands from `github.com/golangci/golangci-lint/cmd/golangci-lint` (v1) to `github.com/golangci/golangci-lint/v2/cmd/golangci-lint` (v2).
**Prevention:** Use the devkit template `project-templates/golangci.yml` which includes the version field. Pin the golangci-lint version in CI with `version: v2.10.1` instead of `version: latest`.

## 66. golangci-lint-action v7 Runs config verify (Schema Enforcement)

**Platform:** GitHub Actions (all)
**Issue:** `golangci-lint-action@v7` runs `golangci-lint config verify` before linting, which enforces strict JSON schema on `.golangci.yml`. Action v6 did NOT do this. Config keys that worked with v6 fail with `additional properties '<key>' not allowed` on v7. Known schema changes between v2.1 and v2.10: top-level `linters-settings:` moved under `linters:` as `settings:`, and `issues: exclude-rules:` moved to `linters: exclusions: rules:`.
**Diagnosis:** CI Lint step fails before any actual linting with "additional properties not allowed" errors. Build and Test steps pass.
**Fix:** Migrate config to v2.10 schema:

```yaml
# BAD (v2.1 schema): fails with v7 action + v2.10
linters-settings:
  gosec:
    excludes: [G104]

issues:
  exclude-rules:
    - path: _test\.go
      linters: [gosec]

# GOOD (v2.10 schema): nested under linters
linters:
  settings:
    gosec:
      excludes: [G104]
  exclusions:
    rules:
      - path: _test\.go
        linters: [gosec]
```

**Also:** `golangci-lint-action@v6` explicitly rejects v2.x versions. Must use `@v7` for golangci-lint v2. And `install-mode: goinstall` does NOT work with v2 (constructs v1 module path). Use default binary mode.

## 67. Agent-Generated Markdown Tables: Pipes in Cells and Missing Columns

**Platform:** All (markdownlint)
**Issue:** Subagent-generated markdown tables have two common MD056 (table-column-count) errors: (1) pipe characters `|` inside code spans in table cells are interpreted as column separators, creating extra columns; (2) agents sometimes omit columns when cell content is wide, generating 2-column rows in 3-column tables.
**Diagnosis:** `markdownlint` reports MD056 with "Expected: N columns, found: M columns" on specific table rows.
**Fix:** After receiving agent-generated `.md` files, run `npx markdownlint-cli2 "path/to/file.md"` and check for MD056. For pipes in cells: rewrite content to avoid `|` or use HTML entity `&#124;`. For missing columns: add the missing cells with appropriate content.
**Prevention:** Include in markdown agent checklist: "Verify all table rows have the same number of columns. Do not use pipe characters inside table cells."

## 68. Proxmox Installer Injects noapic Which Blocks IOMMU

**Platform:** Proxmox VE (all versions)
**Issue:** The Proxmox installer writes `noapic` to `/etc/default/grub.d/installer.cfg` which is silently appended to `GRUB_CMDLINE_LINUX`. This blocks IOMMU even when `intel_iommu=on iommu=pt` is correctly set in `/etc/default/grub`. The main grub file looks clean, so you don't suspect a drop-in config.
**Diagnosis:** `find /sys/kernel/iommu_groups/ -type l` returns nothing despite kernel params showing `intel_iommu=on` in `/proc/cmdline`. The `noapic` is also visible in `/proc/cmdline` but easy to miss.
**Fix:** Check and fix the drop-in config:

```bash
cat /etc/default/grub.d/installer.cfg
# If it contains 'noapic', remove it:
sed -i 's/nomodeset noapic/nomodeset/' /etc/default/grub.d/installer.cfg
update-grub && reboot
```

**Also required:** VT-d (Intel) or AMD-Vi must be enabled in BIOS. Check after fixing grub.
**Prevention:** When setting up GPU passthrough on Proxmox, always check ALL grub configs: `cat /etc/default/grub /etc/default/grub.d/*.cfg | grep -E 'noapic|iommu'`

## 69. Proxmox VM Re-Boots Into ISO Installer After Guest OS Install

**Platform:** Proxmox VE (QEMU/KVM)
**Issue:** After a guest OS (Ubuntu, Debian) finishes installing in a Proxmox VM, clicking "Reboot" in the installer boots back into the ISO installer instead of the installed OS. The ISO is still attached to ide2 and has higher boot priority.
**Fix:** Detach the ISO and set boot order to the installed disk:

```bash
qm set <vmid> --ide2 none --boot order=scsi0
qm reboot <vmid>
```

## 70. Ubuntu Point Release URLs 404 When Superseded

**Platform:** Ubuntu / Proxmox ISO downloads
**Issue:** Ubuntu ISO download URLs include the point release version (e.g., `ubuntu-24.04.2-live-server-amd64.iso`). When a newer point release ships (24.04.4), the old URL returns 404. Proxmox `wget` commands referencing the old version fail silently or with a cryptic error.
**Fix:** Check the current filename before downloading:

```bash
curl -s https://releases.ubuntu.com/24.04/ | grep -oP 'ubuntu-24\.04\.\d+-live-server-amd64\.iso' | head -1
```

## 71. NVIDIA Driver Package Names Vary by Ubuntu PPA

**Platform:** Ubuntu (Proxmox VMs)
**Issue:** `apt install nvidia-driver-560` may fail with "package not found" because the exact driver version depends on which PPA is enabled and the Ubuntu release. The `ppa:graphics-drivers/ppa` PPA has newer versions than the default repos.
**Fix:** Add the PPA and search for available versions:

```bash
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt update
apt-cache search nvidia-driver | grep -E '^nvidia-driver-[0-9]' | sort -t- -k3 -n
# Install the latest available (e.g., nvidia-driver-590)
```

## 72. ESLint react-hooks/set-state-in-effect Cannot Be Inline-Disabled

**Platform:** React / ESLint (eslint-plugin-react-hooks v7+)
**Issue:** The `react-hooks/set-state-in-effect` rule does NOT support `// eslint-disable-next-line` inline comments. Adding the directive produces "Unused eslint-disable directive" while the underlying error persists. This is unusual -- most ESLint rules support inline disable.
**Diagnosis:** Error persists after adding inline disable comment. A second warning appears about the unused directive.
**Fix:** Must use config-level override in `eslint.config.js`:

```javascript
rules: {
  "react-hooks/set-state-in-effect": "warn",  // cannot inline-disable, config only
}
```

**Context:** Dialog form initialization from props via `useEffect(() => setState(prop), [prop])` is a legitimate pattern that triggers this rule. Downgrading to "warn" is acceptable.

## 73. ESLint 10 Breaks react-hooks Plugin Peer Dependency

**Platform:** npm / React ecosystem
**Issue:** Running `npm install eslint` without version pinning pulls ESLint 10.x. `eslint-plugin-react-hooks` (v7.x as of 2026-02) requires `eslint@^9` as a peer dependency. The install succeeds but lint commands fail with peer dependency warnings or crashes.
**Fix:** Pin ESLint to v9: `npm install --save-dev eslint@^9 @eslint/js@^9`. Check peer requirements of all ESLint plugins before installing.

## 74. gh repo edit Lacks --disable-* Flags

**Platform:** GitHub CLI (gh)
**Issue:** `gh repo edit` has `--enable-squash-merge`, `--enable-discussions`, etc. but does NOT have `--disable-merge-commit`, `--disable-rebase-merge`, or `--disable-wiki`. Running with `--disable-*` flags gives "unknown flag" errors.
**Fix:** Use `gh api` with PATCH for disabling settings:

```bash
gh api repos/{owner}/{repo} -X PATCH \
  -f allow_merge_commit=false \
  -f allow_rebase_merge=false \
  -f has_wiki=false
```

Also use `gh api` for features not exposed in `gh repo edit`:

```bash
# Enable private vulnerability reporting
gh api repos/{owner}/{repo}/private-vulnerability-reporting -X PUT
```

## 75. Branch Protection Requires Pre-Existing CI Check Names

**Platform:** GitHub
**Issue:** `required_status_checks.contexts` in branch protection must reference job names that have already appeared in at least one CI run on the repo. Setting protection before the CI workflow runs with those job names causes all PRs to be blocked with "Expected — Waiting for status to be reported."
**Fix:** Merge the CI workflow PR first, verify the job names appear in the Actions tab, THEN apply branch protection. This creates a dependency ordering: CI config must ship before protection can reference it.

## 76. go build Compiles Untracked Files in Working Tree

**Platform:** Go (all)
**Issue:** `go build ./...` compiles ALL `.go` files in the module directory tree, including untracked files. When parallel agents create files for different branches (gotcha #25), untracked files from Agent B can reference symbols that only exist on Agent A's branch. Pre-push hooks running `go build` fail with "undefined" errors even though the committed code on the current branch is correct.
**Diagnosis:** `git push` triggers pre-push hook, which runs `go build ./...`. Build fails with `undefined: models.ParseFrontmatter` (or similar) pointing to untracked files from another agent's work.
**Fix:** Before pushing a branch, stash untracked files belonging to other agents:

```bash
git stash push -u -m "other-agent-files" -- internal/dispatcher/*.go
git push -u origin feature/profile-store
git stash pop
```

**Prevention:** When sorting parallel agent output into branches, push the branch with no cross-dependencies first. Or `git restore` deleted tracked files and stash untracked ones before each push.

## 77. Docker Hub Shows Extension Images as Regular Containers

**Platform:** Docker Hub / Docker Desktop
**Issue:** Pushing a Docker Desktop Extension image to Docker Hub with correct labels (`com.docker.desktop.extension.api.version`, etc.) does NOT make it appear as an extension on Docker Hub. It shows as a regular container image. Users who `docker pull` or `docker run` it get a container, not an extension.
**Fix:** The image is correct for `docker extension install` from CLI. To appear in the Docker Desktop Extensions Marketplace, submit via [docker/extensions-submissions](https://github.com/docker/extensions-submissions) repo (open an issue with the automatic_review template). Automated validation runs `docker extension validate`. If it passes, the extension appears in the marketplace within hours (12h cache).
**Pre-submit:** Run `docker extension validate <image:tag>` locally first. Test light/dark mode, cross-platform. Manual review by Docker is currently paused.

## 78. hadolint False Positives on Docker Desktop Extension Dockerfiles

**Platform:** Docker / hadolint
**Issue:** Docker Desktop extension Dockerfiles use vendor-specific labels (`com.docker.desktop.extension.*`, `com.docker.extension.*`) and `COPY` without `WORKDIR` as standard patterns. hadolint flags these as DL3048 (invalid label key) and DL3045 (COPY to relative path without WORKDIR), but both are correct for extensions.
**Fix:** Create `.hadolint.yaml` at the project root:

```yaml
ignored:
  - DL3048
  - DL3045
```

**Scope:** Applies to ALL Docker Desktop extensions (RunNotes, Runbooks, any future extension).

## 79. GitHub Secrets UI Is Buried Under Expandable Sidebar

**Platform:** GitHub
**Issue:** Repository secrets for GitHub Actions are under Settings > Secrets and variables > Actions. The "Secrets and variables" item has a dropdown arrow that must be clicked to expand and reveal the "Actions" submenu. Easy to miss when looking at the Settings sidebar.
**Fix:** Use CLI instead: `gh secret set SECRETNAME` (prompts for value). `gh secret list` to verify.

## 80. PowerShell StrictMode Throws on Nonexistent Property Access in Conditionals

**Platform:** PowerShell 7+
**Issue:** Under `Set-StrictMode -Version Latest`, accessing a property that doesn't exist on a `PSCustomObject` throws `PropertyNotFoundException` -- even inside a boolean conditional like `if (-not $obj.prop)`. The error fires before the `-not` operator evaluates. This breaks backward-compatibility shims that check for a property before adding it (e.g., `if (-not $manifest.shared) { Add-Member ... }`).
**Diagnosis:** Error says "The property 'X' cannot be found on this object" pointing to the conditional line, not to a property assignment.
**Fix:** Use `PSObject.Properties.Match()` for safe existence checks:

```powershell
# BAD: throws under StrictMode when 'shared' doesn't exist
if ($manifest.tiers -and -not $manifest.shared) {
    $manifest | Add-Member -NotePropertyName 'shared' -NotePropertyValue $manifest.tiers.universal
}

# GOOD: safe property existence check
$hasShared = $manifest.PSObject.Properties.Match('shared').Count -gt 0
if ($manifest.tiers -and -not $hasShared) {
    $manifest | Add-Member -NotePropertyName 'shared' -NotePropertyValue $manifest.tiers.universal
}
```

**Note:** This does NOT affect hashtables (`$hash.missing` returns `$null` under StrictMode). Only `PSCustomObject` (from `ConvertFrom-Json`, `New-Object`, etc.) throws.

## 81. @docker/extension-api-client Vitest Resolve Alias Needed

**Added:** 2026-03-02 | **Source:** RunNotes | **Status:** active

**Platform:** Docker Desktop Extensions (Vitest)
**Issue:** `@docker/extension-api-client` declares `"type": "commonjs"` in its package.json but the actual entry file uses ESM exports. Vitest runs through Vite's ESM pipeline and cannot resolve the module, failing with cryptic import errors. Standard `vi.mock()` calls in every test file are verbose and fragile.
**Diagnosis:** Vitest fails on any test importing `@docker/extension-api-client` with module resolution errors that don't mention the CJS/ESM mismatch.
**Fix:** Add a resolve alias in `vitest.config.ts` pointing to a manual mock file. This centralizes the mock and eliminates per-file `vi.mock()` calls:

```typescript
// vitest.config.ts
import path from "path";

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: "jsdom",
      globals: true,
      setupFiles: "./src/test-setup.ts",
    },
    resolve: {
      alias: {
        "@docker/extension-api-client": path.resolve(
          __dirname,
          "src/__mocks__/@docker/extension-api-client.ts"
        ),
      },
    },
  })
);
```

The mock file exports a fake `ddClient` with `vi.fn()` stubs for all SDK methods (`docker.cli.exec`, `extension.vm.service.get`, etc.).
**Scope:** Applies to ALL Docker Desktop extensions using Vitest for testing.
**See also:** KG#87 (general pattern for browser-only package exports in Vitest).

## 82. Version Drift Across Release Files with Git Tag Workflows

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** active

**Platform:** Docker Desktop Extensions / Any multi-file version project
**Issue:** Git tag-based release workflows (push tag -> CI builds and publishes) cause version drift when multiple files reference the version independently. Common drift pattern: `ui/package.json` says 0.1.0, Docker image tag is 0.1.1, Dockerfile ARG default is 0.1.0, CHANGELOG only documents 0.1.0. Root cause: pushing a git tag triggers Docker Hub publish with the tag version, but nobody bumps the other files.
**Diagnosis:** `docker extension validate` or Docker Hub shows a version that doesn't match `package.json`, CHANGELOG, or Dockerfile ARG defaults.
**Fix:** Designate one file as the version source of truth and have all build tools read from it:

1. Choose the source: `package.json` (frontend-centric) or a `VERSION` file (language-agnostic)
2. CI reads version from source: `jq -r .version ui/package.json` or `cat VERSION`
3. Dockerfile ARG defaults become fallbacks only -- CI overrides via `--build-arg`
4. Include "bump version in source of truth + update CHANGELOG" in every release checklist
5. Consider a `make release VERSION=x.y.z` target that updates all files atomically

**Prevention:** After every tagged release, verify all version references match: `grep -rn "0\.1\.0\|0\.1\.1" package.json Dockerfile CHANGELOG.md Makefile`.

## 83. Docker Extension Dockerfile Label Format Requirements

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** active

**Platform:** Docker Desktop Extensions (all)
**Issue:** Docker Desktop extension Dockerfiles require specific label formats that aren't well-documented. Labels must be valid JSON strings embedded in Dockerfile LABEL syntax with escaped quotes. Getting the format wrong causes `docker extension validate` failures or broken marketplace display.
**Fix:** Use these exact formats for extension labels:

```dockerfile
# Screenshots: JSON array of {alt, url} objects. URLs must be publicly accessible.
# Recommended dimensions: 2400x1600px. Minimum 3 screenshots.
LABEL com.docker.extension.screenshots="[{\"alt\": \"Main View\", \"url\": \"https://raw.githubusercontent.com/OWNER/REPO/main/docs/screenshots/main.png\"},{\"alt\": \"Settings\", \"url\": \"https://raw.githubusercontent.com/OWNER/REPO/main/docs/screenshots/settings.png\"},{\"alt\": \"Detail View\", \"url\": \"https://raw.githubusercontent.com/OWNER/REPO/main/docs/screenshots/detail.png\"}]"

# Changelog: HTML-safe string (no raw newlines, use <p> and <ul>/<li>)
LABEL com.docker.extension.changelog="<p>v0.1.0: Initial release.</p><ul><li>Feature one</li><li>Feature two</li></ul>"

# Additional URLs: JSON array of {title, url} objects
LABEL com.docker.extension.additional-urls="[{\"title\":\"Documentation\",\"url\":\"https://github.com/OWNER/REPO#readme\"},{\"title\":\"Report a Bug\",\"url\":\"https://github.com/OWNER/REPO/issues/new\"},{\"title\":\"Support\",\"url\":\"https://github.com/OWNER/REPO/issues\"}]"

# Icon: reference the local bundled file (COPY docker.svg . earlier in Dockerfile)
LABEL com.docker.desktop.extension.icon="docker.svg"
```

**Gotcha:** Raw GitHub URLs (`https://raw.githubusercontent.com/...`) work for screenshots hosted in the repo. The icon label references the local file copied into the image, not a URL.
**Reference:** [Docker extension labels documentation](https://docs.docker.com/extensions/extensions-sdk/extensions/labels/)

## 84. Multi-Arch Buildx Required for Docker Desktop Extensions

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** active

**Platform:** Docker Desktop Extensions (all)
**Issue:** Docker Desktop runs on macOS (arm64 Apple Silicon + amd64 Intel), Windows (amd64), and Linux (amd64/arm64). Extensions must provide multi-arch images for `linux/amd64` and `linux/arm64` at minimum. A single-arch image works on one platform but silently fails or shows "image not found" on the other. `docker extension validate` does not currently check for multi-arch -- the failure only surfaces when users on a different architecture try to install.
**Fix:** Always build with `docker buildx` and push both architectures:

```bash
docker buildx build --push \
  --platform=linux/amd64,linux/arm64 \
  --tag=IMAGE:VERSION \
  --tag=IMAGE:latest .
```

**Prerequisites:**

- `docker buildx create --use` (one-time setup for multi-arch builder)
- Multi-stage Dockerfile that doesn't use platform-specific binaries in the final stage (pure frontend extensions are inherently multi-arch)
- If the extension includes a Go backend: use `GOARCH` build args or multi-stage with `--platform=$BUILDPLATFORM`

**Verification:** `docker buildx imagetools inspect IMAGE:TAG` shows both `linux/amd64` and `linux/arm64` manifests.

## 85. MUI v5 Pinned via @docker/docker-mui-theme

**Added:** 2026-03-02 | **Source:** RunNotes | **Status:** active

**Platform:** Docker Desktop Extensions (React/MUI)
**Issue:** Docker Desktop extensions use `@docker/docker-mui-theme` for consistent theming with the Docker Desktop UI. This package pins MUI to v5. MUI v6+ changed several APIs, most notably TextField adornments: v5 uses `InputProps={{ startAdornment: ... }}` while v6+ uses `slotProps={{ input: { startAdornment: ... } }}`. Copying code examples from current MUI docs (which default to v6) produces TypeScript errors.
**Diagnosis:** `InputProps is not assignable to type 'TextFieldProps'` or similar TypeScript errors when using MUI v6 patterns.
**Fix:** Always reference MUI v5 documentation when building Docker Desktop extensions:

- TextField adornments: `InputProps={{ startAdornment }}` (not `slotProps.input`)
- Select: `SelectProps={{ ... }}` (not `slotProps.select`)
- Input: `inputProps={{ ... }}` for native input attributes (lowercase `i`)
- Check MUI version: `npm ls @mui/material` should show 5.x

**Prevention:** When using Context7 or web search for MUI examples, always specify "MUI v5" in the query. Current docs and Stack Overflow answers default to v6 syntax.

## 86. grep -c With || echo "0" Doubles Output on No Match

**Added:** 2026-03-02 | **Source:** DevKit | **Status:** active

**Platform:** Bash (all, especially CI)
**Issue:** `grep -c` outputs the match count to stdout (including "0" when no matches) AND exits with code 1 when the count is zero. Using `$(grep -cP 'pattern' file || echo "0")` captures BOTH the grep output "0" and the echo fallback "0", producing `"0\n0"`. This breaks bash arithmetic: `$((total - inactive))` fails with `syntax error in expression (error token is "0")`.
**Diagnosis:** Bash arithmetic error in CI where one of the operands came from `grep -c`. The error token shows two values joined by a newline.
**Fix:** Use `|| true` instead of `|| echo "0"` to suppress the non-zero exit code without duplicating the output:

```bash
# BAD: captures "0\n0" when grep finds no matches
count=$(grep -cP '^pattern' "$file" || echo "0")

# GOOD: grep -c already outputs "0", || true just suppresses exit code
count=$(grep -cP '^pattern' "$file" || true)
```

**See also:** KG#62 (CRLF breaks grep value extraction) -- different root cause but similar symptom (arithmetic errors from unexpected characters in grep output).

## 87. Vitest Cannot Resolve Browser-Only npm Package Exports

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** active

**Platform:** Vitest / Node.js
**Issue:** npm packages that only export via the `browser` field in `package.json` (not `main` or `exports`) cannot be resolved by Vitest, even with `environment: 'jsdom'`. Vitest uses Node.js module resolution which skips the `browser` field entirely. The error is a cryptic module resolution failure that doesn't mention the browser/node distinction.
**Diagnosis:** Vitest fails with import resolution errors on a package that works fine in the browser build (Vite). Check the package's `package.json` -- if it only has a `browser` field and no `main` or `exports`, this is the cause.
**Fix:** Add a `resolve.alias` in `vitest.config.ts` pointing directly to the package's dist entry file:

```typescript
// vitest.config.ts
resolve: {
  alias: {
    '@some/browser-only-pkg': path.resolve(
      __dirname, 'node_modules/@some/browser-only-pkg/dist/index.js'
    ),
  },
},
```

**See also:** KG#81 (`@docker/extension-api-client` specific case with mock file alias -- same root cause but uses a mock file instead of the real dist file).

## 88. .NET WPF Projects Fail dotnet restore on Linux CI

**Added:** 2026-03-02 | **Source:** IPScan | **Status:** active

**Platform:** .NET / GitHub Actions (Ubuntu runners)
**Issue:** `dotnet restore` on a solution containing WPF projects (targeting `net10.0-windows10.0.19041.0`) fails on Ubuntu with `NETSDK1100: To build a project targeting Windows on this operating system, set EnableWindowsTargeting to true`. The error blocks ALL test execution even for cross-platform test projects in the same solution.
**Diagnosis:** CI Test job fails at the restore step. The solution file includes both cross-platform libraries and Windows-only desktop projects. `dotnet restore` resolves the entire dependency graph including Windows TFMs.
**Fix:** Scope `dotnet restore` and `dotnet test` to individual cross-platform .csproj files instead of the solution:

```yaml
# BAD: restores entire solution including WPF project
- run: dotnet restore
- run: dotnet test --no-restore

# GOOD: restore only cross-platform test projects
- run: |
    dotnet restore tests/Project.Core.Tests/Project.Core.Tests.csproj
    dotnet restore tests/Project.CLI.Tests/Project.CLI.Tests.csproj
- run: |
    dotnet test tests/Project.Core.Tests/Project.Core.Tests.csproj --no-restore
    dotnet test tests/Project.CLI.Tests/Project.CLI.Tests.csproj --no-restore
```

**Alternative:** Add `<EnableWindowsTargeting>true</EnableWindowsTargeting>` to Directory.Build.props, but this may pull in unnecessary Windows SDK components on Linux.
**See also:** AP#117 (cross-project compliance audit where this was discovered).

## 89. go get Does Not Resolve All Transitive Dependencies

**Added:** 2026-03-02 | **Source:** Samverk | **Status:** active

**Platform:** Go (all)
**Issue:** `go get github.com/example/module@vX.Y.Z` adds the module to `go.mod` and downloads it, but does NOT always resolve all transitive dependencies into `go.sum`. Running `go build` after `go get` can fail with missing module errors for indirect dependencies.
**Diagnosis:** `go build ./...` fails with "missing go.sum entry for module providing package X" immediately after a successful `go get`.
**Fix:** Always run `go mod tidy` after `go get`:

```bash
go get github.com/example/module@vX.Y.Z
go mod tidy
```

`go mod tidy` resolves the full dependency graph and ensures `go.sum` is complete. This should be a reflexive habit after any `go get` invocation.
