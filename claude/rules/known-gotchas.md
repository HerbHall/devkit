---
description: Known gotchas and platform-specific issues. Read when debugging unexpected behavior.
tier: 2
entry_count: 52
last_updated: "2026-03-20"
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

### Worktrees cause markdownlint hangs on node_modules (was KG#117)

**Issue:** Agent worktrees (`.claude/worktrees/`) create full repo copies including `web/node_modules/`. Markdownlint's `**/*.md` scans them -- 800+ files, 14k+ errors, hangs pre-push hook for 30+ minutes.
**Fix:** Add `**/.claude` and `**/node_modules` to markdownlint exclusion patterns (not just root-level). Clean up with `rm -rf .claude/worktrees && git worktree prune`.
**See also:** KG#91 (nested node_modules not excluded by root pattern)

### Parallel git push triggers concurrent pre-push hooks (was KG#118)

**Issue:** Two concurrent `git push` commands trigger two parallel pre-push hooks sharing the same working directory, causing contention and hangs.
**Fix:** Always push sequentially. When using `isolation: "worktree"`, push one at a time after agents complete.

### Worktree isolation agents can commit to wrong branch (was KG#149)

**Issue:** Parallel agents with `isolation: "worktree"` can commit to the wrong branch. Both agents' commits end up on one branch while the other has none.
**Fix:** Verify branch assignments after parallel worktree agents complete. Recovery: cherry-pick each commit onto fresh branches from main, then create PRs.

### git checkout blocked by worktree holding branch (was KG#157)

**Issue:** `git checkout <branch>` fails with "already used by worktree" when the branch is checked out in any worktree (including agent worktrees).
**Fix:** Run `git worktree remove <path> --force` before checking out in the main tree. Prune worktrees after parallel agents complete.

### Worktree isolation is partial when launching 5+ agents simultaneously

**Issue:** When launching 5+ parallel agents with `isolation: "worktree"`, not all agents receive isolated worktrees. In observed sessions, only 2-3 of 5 agents got proper worktree directories. The other agents worked in the shared main working directory, causing cross-contamination (commits appearing in wrong branches, agents needing stash-based sorting).
**Fix:** After launching 5+ parallel agents, verify worktree-agent-{id} branches exist before assuming isolation (`git branch -r | grep worktree-agent`). Fallback: stash-based sorting from AP#22. Limit parallel worktree agents to 3 when isolation is critical.

## 26. Sequential Same-File PR Merge Requires Rebase Between Each

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** active

**Platform:** Git / GitHub
**Issue:** Multiple PRs modifying the same file conflict after one merges.
**Fix:** Merge one at a time, rebase each subsequent branch onto updated main, force-push. Use `GIT_EDITOR=true git rebase --continue` when rebase pauses with no conflicts.

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
- **Python binary-mode file manipulation:** `open(f, 'rb').read()` then `content.find(b'...\n')` returns -1 on CRLF files -- endings are `\r\n`. Using -1 as a slice index (`content[:-1]`) silently corrupts the file with no error. Fix: use `b'...\r\n'` in binary-mode searches.

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

### `?? 0` fallbacks mask field name mismatches (variant)

**Issue:** When `fetchJSON<T>()` is called with a TypeScript interface whose field names do not match the actual Go JSON response keys, `?? 0` / `?? []` fallbacks in components silently display 0 or empty instead of crashing. No TypeScript error, no console error. Example: interface has `total_cost_usd` but Go sends `estimated_cost_usd` — dashboard shows $0.00 for the entire project lifetime.
**Fix:** Curl the live endpoint and compare actual JSON keys to the TS interface before shipping any new API-connected component. This is different from phantom fields (extra fields the backend never sends) — this is completely wrong field names from day one.

## 116. Go context.WithTimeout Cancels Cleanup Operations

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Go (all)
**Issue:** Wrapping task execution with `context.WithTimeout` cancels ALL downstream operations when timeout fires -- including session status updates, failure comments, and cost recording.
**Fix:** Create a separate `cleanupCtx := context.Background()` BEFORE timeout wrapping. Pass it to the runner for cleanup/persistence paths. Use timeout-wrapped ctx only for the provider call itself.

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
**See also:** AP#120 (secrets distribution)

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

### API calls via Cloudflare tunnel fail -- use internal URL (was KG#160)

**Issue:** Gitea REST API calls via the Cloudflare tunnel URL fail with "token is required" because the tunnel strips the `Authorization` header.
**Fix:** Use the internal URL (e.g., `http://192.168.1.160:3000`) for all Gitea API calls. Token extraction: `printf 'protocol=https\nhost=gitea.example.com\n' | git credential fill | grep password`

### Samverk MCP handler init gated on GitHub env vars (was KG#161, resolved)

**Issue:** Samverk MCP handler init was gated on `GITHUB_TOKEN + SAMVERK_GITHUB_OWNER + SAMVERK_GITHUB_REPO` all being set. If any was missing, all MCP routes and server.yaml projects were skipped.
**Fix:** Resolved in Samverk refactor/38 -- MCP handler and server.yaml projects now initialize unconditionally. GitHub env vars only needed for GitHub-hosted projects.

### Force-push rejected with 'stale info' -- fetch first

**Issue:** `git push --force` or `--force-with-lease` to Gitea fails with "stale info" when the local remote-tracking ref is stale or missing (e.g., branch was created remotely via a PR or prior push from another worktree).
**Fix:** `git fetch gitea <branch>` first, then force-push. The fetch creates the tracking ref. Occurs every time rebasing a branch originally created by a Gitea PR. Different from GitHub, which allows force-push with stale refs.

### semantic-release EGITNOPERMISSION via Cloudflare Tunnel -- needs second url.insteadOf

**Issue:** semantic-release uses `repositoryUrl` for both release notes link generation AND the git push target. If `repositoryUrl` points to the public Cloudflare Tunnel URL and Cloudflare strips `Authorization` headers, the tag push fails with `EGITNOPERMISSION`.
**Fix:** Add a second `url.insteadOf` rule in CI that rewrites the public URL to authenticated localhost -- the first rule covering `localhost:3000` is not enough alone:

```yaml
git config --global url."http://user:${TOKEN}@localhost:3000/".insteadOf "http://localhost:3000/"
git config --global url."http://user:${TOKEN}@localhost:3000/".insteadOf "https://gitea.herbhall.net/"
```

### Issue creation requires label IDs, not names

**Issue:** `POST /api/v1/repos/{owner}/{repo}/issues` with `labels: ["agent:human"]` (string names) returns 422 Unprocessable Entity. Gitea requires integer label IDs. GitHub's API accepts both names and IDs, so code that works on GitHub silently fails on Gitea.
**Fix:** Query labels first to get the ID mapping: `GET /api/v1/repos/{owner}/{repo}/labels` returns `[{"id": 275, "name": "agent:human"}, ...]`. Pass integer IDs in the create payload: `{"title": "...", "labels": [275, 338]}`.

### force_merge 405 has two causes

**Issue:** HTTP 405 from the Gitea merge PR API has two distinct causes: (1) PR is already merged (empty body, documented in KG#123 above), and (2) PR has ancestor commits that Gitea main does not have (dual-forge drift) — returns 405 with body `{"message":"Please try again later"}` and PR state is `open` with `mergeable=False`.
**Fix:** Distinguish by checking PR state + body content before retrying. For case 2 (dual-forge drift), use the force-sync procedure from AP#140.

### gh CLI targets GitHub, not Gitea

**Issue:** When a repo has both GitHub (`origin`) and Gitea (`gitea`) remotes, `gh pr create --repo owner/repo` always creates a GitHub PR regardless of which forge is primary. Agent prompts using `gh pr create` will create GitHub PRs even when Gitea is the intended forge.
**Fix:** Use the Gitea REST API for Gitea PRs: `POST /api/v1/repos/{owner}/{repo}/pulls` with `Authorization: token {TOKEN}`. The `gh` CLI has no Gitea support.

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
**See also:** AP#28 (Go 1.22+ ServeMux route patterns)

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

## 152. Background Agents (`run_in_background`) Cannot Use MCP Tools

**Added:** 2026-03-17 | **Source:** DevKit | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Background subagents auto-deny any tool permissions not pre-approved before launch. MCP tools require interactive permission prompts that cannot be pre-collected, so they are systematically blocked. This is **by design** -- background agents use a permission snapshot, not live permission resolution. Foreground subagents (default mode) inherit full MCP tool access. Hooks also do not fire for background agent tool calls (anthropics/claude-code#34240).
**Fix:** For MCP-dependent work, use foreground agents (default). For background agents: (1) pre-fetch MCP data from main context and pass as text in the prompt, (2) use CLI fallbacks (`gh`, `git`, `curl`), or (3) split into foreground MCP-gather phase + background compute phase.
**Upstream:** anthropics/claude-code#18617 (open, no team response yet). MCP SDK has SEP-1686 Task support but Claude Code application layer does not invoke it.
**See also:** Issue #395 (research: enable MCP for background agents)

## 153. Cherry-Pick Conflict Resolution Truncates Functions at Marker Boundaries

**Added:** 2026-03-17 | **Source:** Synapset | **Status:** active

**Platform:** Git (all)
**Issue:** Automated cherry-pick/rebase conflict resolution scripts that "keep both sides" can break code when the `=======` marker falls inside a function body. Naive marker removal produces functions missing closing `}` and `)`.
**Fix:** Always compile-check after automated conflict resolution. Better approach: use a fresh worktree agent to rebuild changes cleanly on current main instead of manual conflict resolution.

## 155. stdio MCP Servers Hang Indefinitely When Unavailable

**Added:** 2026-03-17 | **Source:** Samverk | **Status:** active

**Platform:** Claude Code (all)
**Issue:** stdio-based MCP servers (sqlite, memory, sequential-thinking, context7, ms365-onenote) hang indefinitely when they fail to initialize (wrong path, missing auth, process crash). Tool calls never return and the session must be manually cancelled. The "If unavailable, skip" instruction in workflows has no way to detect unavailability before attempting the call.
**Fix:** Before calling any stdio MCP tool, verify it appears in the available tools list. If not listed, skip the call entirely. For workflows, add explicit pre-check instructions. HTTP-based MCP servers (Synapset) fail fast with connection errors instead of hanging.

## 156. DevKit CI Metadata Validator Checks See-Also Lines and Added Metadata

**Added:** 2026-03-17 | **Source:** DevKit | **Status:** active

**Platform:** DevKit CI (lint.yml)
**Issue:** The metadata validator (`Validate rule metadata` job) checks two things: (1) lines matching `^\*\*See also:\*\*` are scanned for `KG#N` and `AP#N` references -- each referenced entry must exist as `## N.` in the target file; (2) `**Added:**` lines must have exactly 3 pipe-separated fields (Added, Source, Status). Prose references like "(was KG#117)" in headings and body text do NOT trigger failures -- only `**See also:**` lines are validated.
**Fix:** When referencing archived entries in `**See also:**` lines, omit the `KG#`/`AP#` prefix or remove the reference. Prose labels (e.g., "(was KG#117)") anywhere else in the entry are safe. Never add extra pipe fields to `**Added:**` lines.

## 162. GitHub Issues-Disabled Repo: PRs Closeable but Regular Issues Need Re-Enable

**Added:** 2026-03-17 | **Source:** Samverk | **Status:** active

**Platform:** GitHub API / gh CLI
**Issue:** When `has_issues=false` on a GitHub repo, individual issue GETs return 410 and PATCH on regular issues returns 403. However, PRs (which share the `/issues` endpoint) can still be closed via PATCH even with issues disabled.
**Fix:** To close regular issues when issues are disabled: (1) re-enable: `GITHUB_TOKEN= gh api repos/OWNER/REPO -X PATCH -f has_issues=true`, (2) close the issues, (3) re-disable. The `GITHUB_TOKEN=` prefix clears any fine-grained PAT that lacks repo settings scope.
**See also:** KG#120 (fine-grained PAT shadows gh CLI OAuth)

## 163. semantic-release/git Incompatible With Branch Protection Requiring PR Status Checks

**Added:** 2026-03-17 | **Source:** Synapset | **Status:** active

**Platform:** Gitea / GitHub Actions
**Issue:** `@semantic-release/git` and `@semantic-release/changelog` push commits directly to the default branch. Branch protection requiring `(pull_request)` status checks always rejects these -- direct commits can never have a `pull_request` CI context. Error: "Protected branch update failed: changes must be made through a pull request".
**Fix:** Remove `@semantic-release/git` and `@semantic-release/changelog` from the plugin chain. Keep: `@semantic-release/commit-analyzer`, `@semantic-release/release-notes-generator`, and the release plugin. Semantic-release still creates the git tag and platform release without the direct-commit plugins.

## 164. Gitea act_runner actcache Grows Unboundedly, Causes ENOSPC

**Added:** 2026-03-17 | **Source:** Synapset | **Status:** active

**Platform:** Gitea Actions (act_runner / Linux)
**Issue:** act_runner caches workflow artifacts at `/home/git/.cache/actcache/cache/`. No built-in eviction. Can consume 20+ GB on a 40GB disk, causing ENOSPC in all running CI workflows.
**Fix:** (1) Immediate cleanup: `rm -rf /home/git/.cache/actcache/cache/*`. (2) Daily pruning cron (run as `git` user): `0 3 * * * find /home/git/.cache/actcache/cache -mindepth 1 -maxdepth 1 -mtime +7 -exec rm -rf {} +`. (3) Disk alert at >80% usage via `logger`.
**Infrastructure note:** `proxmox.herbhall.net` resolves to the dns-proxy LXC, NOT the Proxmox host. Actual Proxmox host is `192.168.1.203`. `pct resize` and `pvesm` are only available on the Proxmox host itself.

## 165. Lingering Process Blocks Binary Replacement During Deploy

**Added:** 2026-03-18 | **Source:** Samverk | **Status:** active

**Platform:** Linux deploy scripts
**Issue:** `scp` to replace a running Go binary fails with `dest open: Failure` even after `systemctl stop` because an orphaned process (launched outside systemd, or that survived the stop signal) keeps the binary mapped as its executable. `lsof /usr/local/bin/<binary>` shows the PID with type `txt`.
**Fix:** Add a `fuser -k` step to the deploy script before `scp`:

```bash
# Kill any processes holding the binary open
ssh "root@${HOST}" 'fuser -k /usr/local/bin/<binary> 2>/dev/null || true'
sleep 1
scp bin/<binary>-linux-amd64 "root@${HOST}:/usr/local/bin/<binary>"
```

Diagnose manually: `ssh root@host 'lsof /usr/local/bin/<binary>'` then kill listed PIDs.

## 166. Trivy install.sh Fails With Permission Denied on Pre-Installed Runner Binary

**Added:** 2026-03-18 | **Source:** Samverk | **Status:** active

**Platform:** GitHub Actions (Linux)
**Issue:** The aquasecurity `trivy` install.sh script fails with `install: cannot remove '/usr/local/bin/trivy': Permission denied` when the runner has trivy pre-installed at a system path. The CI job user cannot write to `/usr/local/bin`.
**Fix:** Install to a user-writable directory instead:

```yaml
- name: Install trivy
  run: |
    mkdir -p "$HOME/.local/bin"
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
      | sh -s -- -b "$HOME/.local/bin"
    echo "$HOME/.local/bin" >> "$GITHUB_PATH"
    "$HOME/.local/bin/trivy" --version
```

Note: reference the binary directly (`$HOME/.local/bin/trivy`) in the install step since `$GITHUB_PATH` is not applied to PATH until the **next** step.

## 167. markdownlint-cli2 False Positives on Non-.md Files

**Added:** 2026-03-18 | **Source:** DevKit | **Status:** active

**Platform:** markdownlint-cli2 (all)
**Issue:** Running `npx markdownlint-cli2` with a glob that accidentally includes non-`.md` files (e.g. `.gitignore`, `.sh` scripts) produces false positives. `#` comment lines are parsed as H1 headings, triggering MD022 (no blank line around headings), MD025 (multiple H1), and MD032 (no blank line around lists).
**Fix:** Always scope markdownlint globs to `**/*.md` only. CI lint job already does this correctly — the issue only appears in manual local runs where a non-md file is passed directly or included via a broad glob.

## 168. Gitea Repo Transfer Does Not Rename -- Separate PATCH Required

**Added:** 2026-03-18 | **Source:** DevKit | **Status:** active

**Platform:** Gitea REST API
**Issue:** `POST /api/v1/repos/{owner}/{repo}/transfer` moves a repo to a new org but keeps the original name. There is no `new_name` field in the transfer payload -- the request silently succeeds with the old name intact.
**Fix:** Always follow transfer with a rename step:

```bash
# Step 1: Transfer org
curl -X POST "$GITEA_URL/api/v1/repos/old-org/my-repo/transfer" \
  -H "Authorization: token $TOKEN" \
  -d '{"new_owner": "new-org"}'

# Step 2: Rename (separate call, after transfer completes)
curl -X PATCH "$GITEA_URL/api/v1/repos/new-org/my-repo" \
  -H "Authorization: token $TOKEN" \
  -d '{"name": "new-name"}'
```

Full repo management sequence: (1) `POST /api/v1/orgs` -- create org, (2) transfer, (3) rename, (4) `PATCH` description.

## 171. Samverk MCP Proxy 502 — Gitea API Fallback Pattern

**Added:** 2026-03-20 | **Source:** Synapset | **Status:** active

**Platform:** Claude Code / Samverk MCP
**Issue:** mcp-proxy.anthropic.com returns 502 Bad Gateway intermittently when calling Samverk MCP `create_issue`. Multiple parallel calls can fail simultaneously. Bash heredocs also fail with unexpected EOF when issue body contains apostrophes.
**Fix:** Fall back to Gitea API at `http://192.168.1.160:3000/api/v1`. Use Python `urllib.request` inside a PYEOF heredoc for multi-issue creation — bash heredocs break on apostrophes in body text:

````python
python3 << 'PYEOF'
import urllib.request, json
token = open('/dev/stdin').readline().strip()
data = json.dumps({"title": "...", "body": "it's fine to use apostrophes"}).encode()
req = urllib.request.Request(
    "http://192.168.1.160:3000/api/v1/repos/owner/repo/issues",
    data=data, headers={"Authorization": f"token {token}", "Content-Type": "application/json"}
)
urllib.request.urlopen(req)
PYEOF
````

## 172. ESLint v9 Requires eslint.config.js — .eslintrc.* Silently Fails

**Added:** 2026-03-20 | **Source:** Samverk | **Status:** active

**Platform:** Node.js / Frontend (ESLint v9+)
**Issue:** ESLint v9 dropped `.eslintrc.*` support entirely. Projects with ESLint v9 installed but no `eslint.config.(js|mjs|cjs)` file get exit code 2: "ESLint couldn't find an eslint.config.* file." The `pnpm lint` script appears to be configured but ESLint never actually runs — easy to miss because the script exits without surfacing a lint error. Discovered in a project where the lint script had existed since creation but was silently no-opping.
**Fix:** Create `eslint.config.js` (flat config format) or migrate from `.eslintrc.*` using the ESLint v9 migration guide. Verify lint is actually running by checking for output, not just exit code 0.

## 173. TypeScript Generic Fetch Wrapper Silently Accepts Wrong Response Shape

**Added:** 2026-03-20 | **Source:** Samverk | **Status:** active

**Platform:** TypeScript / React (all)
**Issue:** `fetchJSON<T>()` generic parameter does not validate the actual HTTP response shape at runtime. A Go handler returning `{items: T[], total: number}` typed as `fetchJSON<T[]>()` is silently accepted by TypeScript. The mismatch is benign until code calls `.forEach()` or `.map()` on the result, throwing `TypeError` at runtime. A later PR added `.forEach()` — the first iteration call — which crashed the entire React app (black screen, no error boundary).
**Fix:** Unwrap response in the API client: `const data = await fetchJSON<{items: T[]}>(...); return data.items`. Prevention: generate TS interfaces from Go DTOs using openapi-typescript or similar. Always curl the endpoint and verify the response shape matches the TS type before shipping.
**See also:** KG#115 (phantom field drift), KG#174 (black screen from missing error boundary)

## 174. React 18 Production: Missing Error Boundary Causes Silent Black Screen

**Added:** 2026-03-20 | **Source:** Samverk | **Status:** active

**Platform:** React 18 (production)
**Issue:** An unhandled `TypeError` in a `useMemo` or render function during re-render (post-loading-state) causes React to unmount the entire component tree if no error boundary exists. Result: completely blank/black page with no error message. Looks identical to a network hang or infinite load. Playwright may not reproduce if it snapshots during loading state before data arrives — misleading diagnosis.
**Fix:** Add a top-level `ErrorBoundary` component in `App.tsx` wrapping all routes. Use `getDerivedStateFromError` + `componentDidCatch`. Minimum viable:

````tsx
class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { error: Error | null }
> {
  state = { error: null }
  static getDerivedStateFromError(error: Error) { return { error } }
  componentDidCatch(error: Error) { console.error('App crashed:', error) }
  render() {
    if (this.state.error) {
      return (
        <div style={{padding: '2rem', color: 'red'}}>
          Error: {(this.state.error as Error).message}
        </div>
      )
    }
    return this.props.children
  }
}
````

**Note:** This error is silent in production. DevTools console shows the original TypeError.
**See also:** KG#173 (TypeScript fetch wrapper wrong shape)
