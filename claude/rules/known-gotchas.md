---
description: Known gotchas and platform-specific issues. Read when debugging unexpected behavior.
tier: 2
entry_count: 52
last_updated: "2026-03-30"
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

### Shared registration files are the most common parallel agent conflict surface (from issue #437)

**Issue:** Two parallel worktree agents both modifying a shared registration file (e.g. `tools.go`, `router.go`, `routes.go`, skill routing tables) create a two-block rebase conflict when the second branch is rebased onto main after the first merges.
**Fix:** When planning parallel agents that all add to a shared registration file, assign file ownership -- only ONE agent touches the shared file. Others wait or use a different integration point. Extends the general parallel-agent rule with the most common specific case.
### Worktree isolation is partial when launching 5+ agents simultaneously

**Issue:** When launching 5+ parallel agents with `isolation: "worktree"`, not all agents receive isolated worktrees. In observed sessions, only 2-3 of 5 agents got proper worktree directories. The other agents worked in the shared main working directory, causing cross-contamination (commits appearing in wrong branches, agents needing stash-based sorting).
**Fix:** After launching 5+ parallel agents, verify worktree-agent-{id} branches exist before assuming isolation (`git branch -r | grep worktree-agent`). Fallback: stash-based sorting from AP#22. Limit parallel worktree agents to 3 when isolation is critical.

### Parallel agents contaminate main worktree when feature branch is checked out

**Issue:** When parallel worktree agents are launched while the main worktree has a feature branch checked out, agents' commits can land on the main worktree's current branch in addition to their isolated worktree branches. Causes duplicate PRs and stacked commits on the wrong branch.
**Fix:** Before launching parallel agents, run `git checkout main` in the main worktree to avoid contaminating a feature branch.

### After worktree agent completes, main working dir may be on agent's feature branch

**Issue:** After a worktree-isolated Agent tool call completes, the main working directory may be on the agent's feature branch rather than main. Silent failure modes: cherry-pick returns "no changes added to commit", git commit creates commit on wrong branch, git push pushes wrong branch.
**Fix:** Always run `git branch --show-current` before any post-agent git operations. Run `git checkout main` (or your intended base branch) before cherry-picking, committing, or pushing.

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

## 98. Rules Files Over 40k Degrade Session Performance

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** active

**Platform:** Claude Code (all)
**Issue:** Rules files over 40k cause context to be silently dropped at task transitions.
**Fix:** Run `/rules-compact` to stay below 35k per file. `/conformance-audit` check #17 flags violations.
**Note:** DevKit CI (`lint.yml`) does NOT enforce these thresholds. Files over 40k will still pass CI — the limits are self-enforced performance guidelines only. Do not treat file size as a hard CI prerequisite when planning issue batches.

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

### PSUseApprovedVerbs: "Detect" and other common unapproved verbs

**Issue:** PSScriptAnalyzer warns `PSUseApprovedVerbs` when a function uses an unapproved verb. Common culprits: `Detect-`, `Check-`, `Validate-`, `Scan-`, `Discover-`. CI with `-Severity Warning` fails on these.
**Fix:** Rename to an approved verb. Replacements: `Detect-` → `Get-` or `Find-`; `Check-` → `Test-`; `Validate-` → `Confirm-` or `Test-`; `Scan-` → `Search-`; `Discover-` → `Find-`. Full approved list: `Get-Command -CommandType Cmdlet | Select-Object -ExpandProperty Verb -Unique | Sort-Object`.

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
**See also:** secrets distribution via `~/.devkit-config.json` (archived pattern AP120)

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

### Force-push rejected with 'stale info' -- fetch first

**Issue:** `git push --force` or `--force-with-lease` to Gitea fails with "stale info" when the local remote-tracking ref is stale or missing (e.g., branch was created remotely via a PR or prior push from another worktree).
**Fix:** `git fetch gitea <branch>` first, then force-push. The fetch creates the tracking ref. Occurs every time rebasing a branch originally created by a Gitea PR. Different from GitHub, which allows force-push with stale refs.

### semantic-release EGITNOPERMISSION via Cloudflare Tunnel -- needs second url.insteadOf

**Issue:** semantic-release uses `repositoryUrl` for both release notes link generation AND the git push target. If `repositoryUrl` points to the public Cloudflare Tunnel URL and Cloudflare strips `Authorization` headers, the tag push fails with `EGITNOPERMISSION`.
**Fix:** Add a second `url.insteadOf` rule rewriting the public Cloudflare Tunnel URL to authenticated localhost — the rule for `localhost:3000` alone is not enough. Both must be present: one for `http://localhost:3000/` and one for `https://gitea.herbhall.net/`.

### Issue creation requires label IDs, not names

**Issue:** `POST /api/v1/repos/{owner}/{repo}/issues` with `labels: ["agent:human"]` (string names) returns 422 Unprocessable Entity. Gitea requires integer label IDs. GitHub's API accepts both names and IDs, so code that works on GitHub silently fails on Gitea.
**Fix:** Query labels first to get the ID mapping: `GET /api/v1/repos/{owner}/{repo}/labels` returns `[{"id": 275, "name": "agent:human"}, ...]`. Pass integer IDs in the create payload: `{"title": "...", "labels": [275, 338]}`.

### force_merge 405 has two causes

**Issue:** HTTP 405 from the Gitea merge PR API has two distinct causes: (1) PR is already merged (empty body, documented in KG#123 above), and (2) PR has ancestor commits that Gitea main does not have (dual-forge drift) — returns 405 with body `{"message":"Please try again later"}` and PR state is `open` with `mergeable=False`.
**Fix:** Distinguish by checking PR state + body content before retrying. For case 2 (dual-forge drift), use the force-sync procedure from AP#140.

### gh CLI targets GitHub, not Gitea

**Issue:** When a repo has both GitHub (`origin`) and Gitea (`gitea`) remotes, `gh pr create --repo owner/repo` always creates a GitHub PR regardless of which forge is primary. Agent prompts using `gh pr create` will create GitHub PRs even when Gitea is the intended forge.
**Fix:** Use the Gitea REST API for Gitea PRs: `POST /api/v1/repos/{owner}/{repo}/pulls` with `Authorization: token {TOKEN}`. The `gh` CLI has no Gitea support.

### Hostname credential works with internal IP; local-IP credential is separate

**Issue:** Two distinct credential entries can exist for the same Gitea server: one for the public hostname (`gitea.herbhall.net`) and one for the local IP (`192.168.1.160:3000`). API calls using the local-IP credential may return 401. The hostname credential authenticates correctly against the internal IP URL.
**Fix:** Always extract credentials using the public hostname: `printf 'protocol=https\nhost=gitea.herbhall.net\n' | git credential fill | grep password`. Use that token with the internal IP API endpoint (`http://192.168.1.160:3000/api/v1/...`). The token is valid for both — it is the Gitea account token, not IP-specific.

## 125. go:embed Cache Misses Embedded File Changes

**Added:** 2026-03-14 | **Source:** Samverk | **Status:** active

**Platform:** Go (all)
**Issue:** Go build cache doesn't detect changes to `go:embed` files when Go source hasn't changed. Embedded SPA files (`web/dist/` -> `internal/server/static/`) stay stale after frontend rebuild, causing deployed binary to serve old JS bundles.
**Fix:** Always use `make build` or `make redeploy` for projects with embedded SPAs. Consider `go build -a` or touching a Go source file after SPA rebuild to bust cache.
**Deploy:** Ensure deploy scripts rebuild the SPA before `go build`. Skipping frontend build silently serves stale JS bundles baked in at compile time.

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
**Fix:** Add a top-level `ErrorBoundary` in `App.tsx` wrapping all routes (`<ErrorBoundary><Routes>...</Routes></ErrorBoundary>`). Minimum viable class: `state = { error: null }`, `getDerivedStateFromError` sets it, `render()` returns error message div when `this.state.error` is set, otherwise `this.props.children`. See AP#143 for full pattern.
**Note:** This error is silent in production. DevTools console shows the original TypeError.
**See also:** KG#173 (TypeScript fetch wrapper wrong shape)

## 175. TypeScript Interface Auto-Resolve Drops Closing Braces in Conflict Resolution

**Added:** 2026-03-20 | **Source:** Samverk | **Status:** active

**Platform:** TypeScript / Git (all)
**Issue:** Auto-resolving merge conflicts in `.ts` files using "keep both sides" concatenation can drop the closing `}` between adjacent interface declarations. The conflict zone boundary is treated as a text separator, not as syntax — the `}` ending one block gets swallowed when the next block starts immediately after.
**Symptom:** `TS1131: Property or signature expected` at the line where the next interface begins.
**Fix:** After any automated conflict resolution in `.ts` files, always run `npx tsc --noEmit` before committing. Visually inspect boundaries between adjacent interface or type declarations.
**See also:** KG#153 (cherry-pick conflict resolution truncates functions at marker boundaries)

## 176. Tauri 2 API Gotchas (Consolidated Reference)

**Added:** 2026-03-21 | **Source:** claude-token-stats | **Status:** active

**Platform:** Tauri 2 (all)

### tauri-plugin-positioner v2 has no tray-relative Position variants

**Issue:** `Position` enum in v2.3.1 only has screen-edge variants (TopLeft, TopRight, TopCenter, BottomLeft, BottomRight, BottomCenter, LeftCenter, RightCenter, Center). `TrayCenter`, `TrayBottomCenter`, etc. do not exist — compiler error: "no variant or associated item named TrayCenter found".
**Fix:** Use `Position::BottomRight` as the fallback for Windows system tray apps.

### TrayIconBuilder::menu_on_left_click renamed to show_menu_on_left_click

**Issue:** Method renamed in Tauri 2. Produces a deprecation warning pointing to the correct name.
**Fix:** Direct rename to `show_menu_on_left_click`. No behavior change.

### getCurrentWindow and WebviewWindow come from different modules

**Issue:** `getCurrentWindow()` is from `@tauri-apps/api/window`. `WebviewWindow` class (for `getByLabel`) is from `@tauri-apps/api/webviewWindow`. Mixing import sources causes TS2305.
**Fix:** Use two separate imports:

```ts
import { getCurrentWindow } from '@tauri-apps/api/window';
import { WebviewWindow } from '@tauri-apps/api/webviewWindow';
```

## 177. Recharts 3 Tooltip formatter Typed as ValueType | undefined

**Added:** 2026-03-21 | **Source:** claude-token-stats | **Status:** active

**Platform:** TypeScript / Recharts 3.x
**Issue:** Recharts 3.x Tooltip `formatter` callback parameter is typed as `ValueType | undefined` (where `ValueType = string | number | undefined`), not as `number`. Writing `(value: number) => ...` causes TS2322.
**Fix:** Guard the value before using numeric operations:

```ts
formatter={(value) => {
  const v = typeof value === 'number' ? value : Number(value ?? 0);
  return [`$${v.toFixed(4)}`, 'Cost'];
}}
```

For BarChart with custom payload fields (e.g. `tokens`, `sessions` added to chart data), cast `props.payload`:

```ts
formatter={(value, _name, props) => {
  const v = typeof value === 'number' ? value : Number(value ?? 0);
  const tokens = (props.payload as { tokens?: number } | undefined)?.tokens ?? 0;
  return [`$${v.toFixed(4)} · ${tokens} tokens`, 'Cost'];
}}
```

Applies to both AreaChart and BarChart Tooltip formatters in Recharts 3.x.

## 178. Stacked PR Branches Contain Prior Branch Commits — Cherry-Pick Required

**Added:** 2026-03-22 | **Source:** samverk | **Status:** active

**Platform:** Git / GitHub (all)
**Issue:** When feature branches are created by stacking (branch B based on branch A, so B contains A's commit + its own), after squash-merging A, a plain `git rebase origin/main` on B fails. Git replays A's original commit, which now conflicts with the squashed version already in main. The PR shows as "dirty" (conflicted) with no obvious cause.
**Fix:** Identify B's unique commit with `git log --oneline origin/feature/B | head -1`, reset to `origin/main`, then `git cherry-pick <that-commit>`. Force-push. See AP#146.

## 179. Dual-Remote Checkout Ambiguity With Same Branch Names

**Added:** 2026-03-22 | **Source:** samverk | **Status:** active

**Platform:** Git (dual-forge repos)
**Issue:** In repos with two remotes (e.g., `origin`=GitHub and `gitea`=Gitea) that both track identical branch names, `git checkout feature/foo` fails: `fatal: 'feature/foo' matched multiple (2) remote tracking branches`. Common in dual-forge setups where feature branches are mirrored to both remotes.
**Fix:** Always specify the remote explicitly: `git checkout --track origin/feature/foo -B feature/foo`. The `-B` flag creates or resets the local branch cleanly.

## 180. Gitea Protected Branch Blocks All Direct Pushes Including Admin Token

**Added:** 2026-03-22 | **Source:** samverk | **Status:** active

**Platform:** Gitea (all)
**Issue:** Unlike GitHub where admin users can bypass branch protection, Gitea's protection blocks ALL direct pushes — even with an admin token. Error: `Not allowed to push to protected branch main`. This affects migration syncs and emergency patches.
**Fix:** Temporarily delete the rule, push, then re-create:

```bash
# Delete
curl -X DELETE http://GITEA_INTERNAL/api/v1/repos/{owner}/{repo}/branch_protections/main \
  -H "Authorization: token TOKEN"
# Push
git push gitea main
# Re-create
curl -X POST http://GITEA_INTERNAL/api/v1/repos/{owner}/{repo}/branch_protections \
  -H "Authorization: token TOKEN" -H "Content-Type: application/json" \
  -d '{"branch_name":"main","rule_name":"main","enable_push":false}'
```

Use internal URL (not Cloudflare tunnel) — tunnel strips the Authorization header. See KG#123.

## 181. Dual-Forge Diverged Mains: Use Merge Commit, Not Force-Push

**Added:** 2026-03-22 | **Source:** samverk | **Status:** active

**Platform:** Git (dual-forge repos)
**Issue:** When GitHub and Gitea mains diverge (each has unique commits the other lacks), force-pushing one forge's main to the other destroys the unique commits on the receiving side. This is irreversible.
**Fix:** Use a merge commit — it preserves both sides and is accepted as a fast-forward by the receiving forge (because its current tip becomes a parent of the merge commit):

```bash
git fetch origin && git fetch gitea
git merge gitea/main --no-edit   # runs on local main tracking GitHub
git push gitea main               # fast-forward from Gitea's perspective
git push origin main              # sync merge commit back to GitHub
git push gitea v1.2.3            # also push tags if any
```

Note: reference the binary directly (`$HOME/.local/bin/trivy`) in the install step since `$GITHUB_PATH` is not applied to PATH until the **next** step.

## 167. markdownlint-cli2 False Positives on Non-.md Files

**Added:** 2026-03-18 | **Source:** DevKit | **Status:** active

**Platform:** markdownlint-cli2 (all)
**Issue:** Running `npx markdownlint-cli2` with a glob that accidentally includes non-`.md` files (e.g. `.gitignore`, `.sh` scripts) produces false positives. `#` comment lines are parsed as H1 headings, triggering MD022 (no blank line around headings), MD025 (multiple H1), and MD032 (no blank line around lists).
**Fix:** Always scope markdownlint globs to `**/*.md` only. CI lint job already does this correctly — the issue only appears in manual local runs where a non-md file is passed directly or included via a broad glob.

## 168. New Trivy CVE Day-Of Blocks All PRs — Hotfix With .trivyignore First

**Added:** 2026-03-18 | **Source:** Synapset | **Status:** active

**Platform:** GitHub Actions (CI with Trivy)
**Issue:** A CVE published to GitHub Security Advisories at 13:00 UTC caused all PRs to fail Trivy scans from ~19:35 UTC onward on the same day -- including PRs that added zero new dependencies. Trivy downloads a fresh vulnerability DB on each CI run.
**Fix:** For transitive deps with no fixed version, add a `.trivyignore` file suppressing the specific GHSA ID with a justification comment: (1) it is a transitive dep not directly used, (2) no fix is available, (3) attack surface is limited. Remove when upstream patches.
**Critical ordering:** Merge the `.trivyignore` hotfix PR *before* feature PRs so CI unblocks across the board. The hotfix PR itself passes Trivy because the ignore is included in its own CI run.

## 169. Gitea act_runner Host Executor Has No pip, ruby, or sudo

**Added:** 2026-03-19 | **Source:** DevKit | **Status:** active

**Platform:** Gitea Actions (act_runner host executor)
**Issue:** act_runner's host executor runs jobs directly on the server. The "ubuntu-latest" label is just a tag — the actual environment depends on what's installed on the host. Discovered: `python3` is available but has no `pip` (`No module named pip`). No `ruby`. No `sudo` (git user lacks sudo, causing `sudo apt-get` to hang indefinitely — not fail fast). `actions/setup-python@v5` and `actions/setup-node@v4` may also fail.
**Fix:** Use only Python3 stdlib. For third-party packages, bootstrap from PyPI source using `urllib.request` + `tarfile`:

```python
import sys, io, os, tarfile, json, urllib.request
try:
    import yaml
except ImportError:
    api = json.loads(urllib.request.urlopen(
        'https://pypi.org/pypi/PyYAML/json').read())
    src_url = next(u['url'] for u in api['urls']
                   if u['packagetype'] == 'sdist')
    data = urllib.request.urlopen(src_url).read()
    with tarfile.open(fileobj=io.BytesIO(data), mode='r:gz') as tf:
        os.makedirs('/tmp/pyyaml/yaml', exist_ok=True)
        for m in tf.getmembers():
            if '/yaml/' in m.name and m.name.endswith('.py'):
                fobj = tf.extractfile(m)
                if fobj:
                    open('/tmp/pyyaml/yaml/' + os.path.basename(m.name), 'wb').write(fobj.read())
    sys.path.insert(0, '/tmp/pyyaml')
    import yaml
```

**Diagnosis tip:** A job that fails "after 0s" but logs show the checkout succeeded indicates the next step is failing immediately — check for missing modules, not missing actions.

## 170. Gitea Actions Check Runs Do Not Satisfy Commit Status Branch Protection

**Added:** 2026-03-19 | **Source:** DevKit | **Status:** active

**Platform:** Gitea Actions / Gitea branch protection
**Issue:** Gitea branch protection `status_check_contexts` (required status checks) matches against *commit statuses*, but Gitea Actions creates *check runs* — a different system. A PR where Actions CI passes will still show "Not all required status checks successful" and block merge. `gh pr checks` or the Gitea API shows runs as `completed/success` but the merge is still blocked.
**Fix:** Use `"force_merge": true` in the Gitea merge PR API call:

```bash
curl -X POST "http://<gitea>/api/v1/repos/<owner>/<repo>/pulls/<N>/merge" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Do":"squash","merge_message_field":"...","force_merge":true}'
```

Alternatively, use branch protection rules that match check run names instead of commit status contexts — but the mismatch is architectural and `force_merge` is the practical workaround.
**See also:** KG#123 (Gitea API and Actions gotchas)
