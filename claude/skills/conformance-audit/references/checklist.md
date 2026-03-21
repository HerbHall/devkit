# Conformance Checklist

21-point checklist for DevKit project conformance. Each check includes what to look for, which stacks need it, how to determine pass/fail, and which DevKit template provides the fix.

## Stack Detection

Before running checks, detect the project stack by inspecting the project root:

| Indicator File | Stack |
|----------------|-------|
| `go.mod` | Go |
| `package.json` | Node (check for Docker extension labels in Dockerfile for Node-Extension) |
| `Cargo.toml` | Rust |
| `*.csproj` or `*.sln` | .NET |
| None of the above | Unknown |

A project may match multiple stacks (e.g., Go backend + Node frontend). Apply checks for all detected stacks.

## Checks

### 1. CLAUDE.md

- **What to check**: `CLAUDE.md` exists at the project root with project-specific content
- **Stacks**: All
- **Pass criteria**: File exists and contains at least a heading and a build/test command
- **Fail indicators**: File is missing, or is an unmodified copy of the template (contains `{{PROJECT_NAME}}` placeholders)
- **Fix reference**: `project-templates/workspace-claude-md-template.md` (workspace root variant) or `project-templates/claude-md-template.md` (generic)

### 2. Claude Settings

- **What to check**: `.claude/settings.json` exists
- **Stacks**: All
- **Pass criteria**: File exists and is valid JSON
- **Fail indicators**: `.claude/` directory missing, or `settings.json` missing inside it
- **Fix reference**: `project-templates/settings.json`

### 3. CI Workflow

- **What to check**: `.github/workflows/ci.yml` (or variant like `ci-node.yml`, `ci-rust.yml`, `ci-dotnet.yml`)
- **Stacks**: All
- **Pass criteria**: At least one CI workflow file exists under `.github/workflows/` with a name containing `ci` or `lint` or `test` or `build`
- **Fail indicators**: No `.github/workflows/` directory, or no CI-related workflow files
- **Fix reference**: `project-templates/ci.yml` (Go), `project-templates/ci-node.yml` (Node), `project-templates/ci-rust.yml` (Rust), `project-templates/ci-dotnet.yml` (.NET)
- **Note**: CI workflows are too project-specific to auto-create; suggest the template but require manual customization

### 4. Pre-push Hook

- **What to check**: `scripts/pre-push` exists and is executable
- **Stacks**: All
- **Pass criteria**: File exists (executable bit is optional on Windows)
- **Fail indicators**: `scripts/` directory missing, or `pre-push` not present
- **Fix reference**: `git-templates/hooks/pre-push`

### 5. Lint Config

- **What to check**: Stack-appropriate lint configuration exists
- **Stacks**: Stack-specific
- **Pass criteria per stack**:
  - Go: `.golangci.yml` exists and contains `version: "2"`
  - Node/React: `eslint.config.js` or `.eslintrc.*` exists
  - Rust: `Cargo.toml` contains `[lints]` section, or `clippy` appears in CI workflow
  - .NET: skip (no standard external lint config file)
- **Fail indicators**: Expected lint config missing for the detected stack
- **Fix reference**: `project-templates/golangci.yml` (Go), `project-templates/eslint.config.js` (Node)

### 6. Makefile

- **What to check**: `Makefile` exists with standard targets
- **Stacks**: All
- **Pass criteria**: `Makefile` exists and contains at least `build`, `test`, and `lint` targets
- **Fail indicators**: No Makefile, or Makefile missing standard targets
- **Fix reference**: `project-templates/Makefile.go` (Go), `project-templates/Makefile.node` (Node), `project-templates/Makefile.node-extension` (Docker extension), `project-templates/Makefile.rust` (Rust)

### 7. EditorConfig

- **What to check**: `.editorconfig` exists with `root = false` (inherits from DevSpace)
- **Stacks**: All
- **Pass criteria**: File exists and does NOT contain `root = true` (so it inherits from the DevSpace parent)
- **Fail indicators**: File missing, or contains `root = true` which blocks inheritance
- **Fix reference**: Create minimal `.editorconfig` with `root = false`

### 8. Release Please

- **What to check**: release-please configuration files exist
- **Stacks**: All
- **Pass criteria**: All three files exist:
  - `.release-please-manifest.json`
  - `release-please-config.json`
  - `.github/workflows/release-please.yml`
- **Fail indicators**: Any of the three files missing
- **Fix reference**: `project-templates/release-please-manifest.json`, `project-templates/release-please-config.json`, `project-templates/release-please.yml`

### 9. LICENSE

- **What to check**: `LICENSE` file exists at project root
- **Stacks**: All
- **Pass criteria**: File exists and is non-empty
- **Fail indicators**: No LICENSE file
- **Fix reference**: Create MIT license with current year and owner name

### 10. VERSION

- **What to check**: `VERSION` file exists at project root
- **Stacks**: All
- **Pass criteria**: File exists and contains a semver string (e.g., `0.1.0`)
- **Fail indicators**: No VERSION file
- **Fix reference**: Create with `0.1.0` as initial content

### 11. Gitignore

- **What to check**: `.gitignore` exists and is stack-appropriate
- **Stacks**: All
- **Pass criteria**: File exists and is non-empty
- **Fail indicators**: No `.gitignore` file
- **Fix reference**: `project-templates/gitignore-go` (Go), `project-templates/gitignore-node` (Node), `project-templates/gitignore-rust` (Rust), `project-templates/gitignore-dotnet` (.NET)

### 12. Nightly Build Workflow

- **What to check**: `.github/workflows/nightly.yml` (or variant) exists
- **Stacks**: Go, Node/Docker extension, Rust (skip for .NET desktop)
- **Pass criteria**: A workflow file exists under `.github/workflows/` with `nightly` in its name or containing a `schedule:` trigger with a cron expression
- **Fail indicators**: No nightly/scheduled workflow found
- **Fix reference**: `project-templates/nightly-go.yml` (Go), `project-templates/nightly-node.yml` (Node), `project-templates/nightly-rust.yml` (Rust)
- **Note**: Nightly workflows are project-specific; suggest the template but require manual customization

### 13. Release Gate Workflow

- **What to check**: `.github/workflows/release-gate.yml` exists
- **Stacks**: Only if release-please is configured (check 8 passes)
- **Pass criteria**: File exists
- **Fail indicators**: release-please is configured but no release-gate workflow
- **Fix reference**: `project-templates/release-gate.yml`

### 14. Workflow Trigger Patterns

- **What to check**: No separate workflow uses `on: push: tags: v*` when release-please is configured
- **Stacks**: Only if release-please is configured (check 8 passes)
- **Pass criteria**: No workflow file (other than release-please.yml) contains a `tags:` trigger with `v*` pattern
- **Fail indicators**: A separate `release.yml` or `publish.yml` has `on: push: tags: ['v*']` -- these will never fire because GITHUB_TOKEN-created tags don't trigger push events (see KG#92)
- **Fix reference**: Move publish/deploy jobs into `release-please.yml` using the `release_created` output, or use `on: release: types: [published]` trigger

### 15. Retrigger CI Workflow

- **What to check**: `.github/workflows/retrigger-ci.yml` (or similar) exists
- **Stacks**: Only if release-please is configured (check 8 passes)
- **Pass criteria**: A workflow exists that triggers on `workflow_run` after Release Please and can close/reopen stale PRs
- **Fail indicators**: release-please is configured but no retrigger workflow exists
- **Fix reference**: `project-templates/retrigger-ci.yml`
- **Note**: Without this, release-please PRs may have missing CI checks due to a GitHub Actions race condition (see KG#92 on #191 branch)

### 16. Auto-Merge Enabled

- **What to check**: Repository has auto-merge enabled
- **Stacks**: Only if release-gate is configured (check 13 passes)
- **Pass criteria**: `gh api repos/OWNER/REPO --jq '.allow_auto_merge'` returns `true`
- **Fail indicators**: auto-merge is disabled, causing release-gate's auto-merge step to fail silently
- **Fix reference**: `gh api repos/OWNER/REPO -X PATCH -f allow_auto_merge=true`

### 17. Rules File Size

- **What to check**: No file in `claude/rules/` exceeds 40k
- **Stacks**: DevKit only (skip for non-DevKit projects)
- **Pass criteria**: `wc -c claude/rules/*.md` shows all files under 40,960 bytes
- **Fail indicators**: Any file over 40k. Output: `rules/<filename> is Xk -- exceeds 40k limit, run /rules-compact`
- **Fix reference**: Run `/rules-compact` skill to archive stale entries and consolidate duplicates

### 18. Release PAT Configured

- **What to check**: `RELEASE_PLEASE_TOKEN` secret is set on the repository
- **Stacks**: Only if release-please is configured (check 8 passes)
- **Pass criteria**: `gh secret list --repo OWNER/REPO` includes `RELEASE_PLEASE_TOKEN`
- **Fail indicators**: Secret missing; release-please workflow fails with `HttpError: Resource not accessible by integration`
- **Fix reference**: `scripts/Set-DevkitSecrets.ps1 -Repo OWNER/REPO` (reads from `~/.devkit-config.json` `.Secrets` block); or `new-project.ps1` section 2.7 sets it automatically on new projects
- **Note**: The "Allow GitHub Actions to create and approve pull requests" UI setting is NOT required when using `RELEASE_PLEASE_TOKEN` (a PAT). That restriction only applies to `GITHUB_TOKEN`. `release-gate.yml` and `retrigger-ci.yml` use `GITHUB_TOKEN` only for editing existing PRs (labels, comments, close/reopen) -- not creating new ones. The UI setting is therefore irrelevant for this setup.

### 19. Periodic Documentation Audit

- **What to check**: Documentation claims (skill counts, entry counts, feature lists) match actual on-disk state
- **Stacks**: DevKit only (skip for non-DevKit projects)
- **Pass criteria**: This is a **manual periodic check** — run an Explore subagent audit covering: (1) README count claims vs frontmatter, (2) skill names in verify.sh vs actual skills, (3) verify.ps1 tool list vs documented dependencies, (4) CI coverage gaps (missing lint jobs for active stacks)
- **Frequency**: Run after any sprint that adds skills, rules entries, or CI changes
- **Fail indicators**: README entry counts diverge from frontmatter `entry_count`; verify.sh lists fewer skills than `claude/skills/` contains; verify.ps1 missing tools referenced in CLAUDE.md
- **Fix reference**: AP#121 (structured 10-dimension audit prompt); run from main context with Explore subagent

### 20. Synapset Archive Sync (Informational)

- **What to check**: Active rules entries (AP/KG) have corresponding Synapset memories for semantic search discovery
- **Stacks**: DevKit only (skip for non-DevKit projects)
- **Pass criteria**: Sample 5 active entries from each rules file, query Synapset by entry ID tag (`query_memory(pool: "devkit", tags: "KG#N")`). At least 80% should return a match
- **Fail indicators**: Multiple active entries missing from Synapset corpus
- **Fix reference**: Run `/rules-compact` batch-ingest sync, or manually `store_memory` for missing entries
- **Note**: This check is **informational only** (does not affect score). Skip entirely if Synapset MCP tools are unavailable

### 21. Tool Version Currency

- **What to check**: CI workflow files use action versions that meet or exceed the `min_supported` version from the DevKit tool registry (`tool-registry.json`). Files using versions below `min_supported` are a hard fail. Files using versions below `current` (but at or above `min_supported`) are a soft warning.
- **Stacks**: All projects with `.github/workflows/`
- **Pass criteria**: Every `uses: owner/action@vN` in every workflow file resolves to a version at or above `min_supported` for that tool in the registry.
- **Fail indicators**: Any action pinned below `min_supported` (e.g., `actions/checkout@v2` when `min_supported` is v3). Also flag: floating version refs (`@master`, `@stable`, `@latest`) — these are always a fail.
- **Warning indicators**: Action pinned at or above `min_supported` but below `current` — project is behind but not critically. List as `WARN` in output, do not count against score.
- **Fix reference**: Run `scripts/Invoke-VersionUpdate.ps1 -Mode Propagate -Projects <name> -DryRun` to preview, then without `-DryRun` to create an update PR.
- **Registry location**: `D:\DevSpace\devkit\tool-registry.json` (or `$DEVKIT_ROOT/tool-registry.json`)
- **Check snippet**:

```bash
# Read registry min_supported versions and check project workflow files
REGISTRY="$DEVKIT_ROOT/tool-registry.json"
FAILS=0; WARNS=0
for wf in .github/workflows/*.yml; do
  while IFS= read -r line; do
    if echo "$line" | grep -qE 'uses: .+@(v[0-9]+|stable|master|latest)'; then
      action=$(echo "$line" | grep -oE '[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+(-[a-zA-Z0-9_-]+)*(?=@)')
      ver=$(echo "$line" | grep -oE '@.+$' | tr -d '@')
      # Floating refs are always FAIL
      if echo "$ver" | grep -qE '^(stable|master|latest)$'; then
        echo "FAIL: $wf: $action@$ver (floating ref -- pin to specific version)"; FAILS=$((FAILS+1))
        continue
      fi
      result=$(python3 -c "
import json, sys
reg = json.load(open('$REGISTRY'))
for t in reg['tools'].values():
    if t.get('action') == '$action':
        print(t.get('min_supported',''), t.get('current',''))
        sys.exit(0)
print('unknown unknown')
" 2>/dev/null)
      min_v=$(echo "$result" | cut -d' ' -f1 | tr -d 'v')
      cur_v=$(echo "$result" | cut -d' ' -f2 | tr -d 'v')
      act_v=$(echo "$ver" | tr -d 'v')
      [ "$result" = "unknown unknown" ] && continue
      if [ "$act_v" -lt "$min_v" ] 2>/dev/null; then
        echo "FAIL: $(basename $wf): $action@v$act_v below min_supported v$min_v"; FAILS=$((FAILS+1))
      elif [ "$act_v" -lt "$cur_v" ] 2>/dev/null; then
        echo "WARN: $(basename $wf): $action@v$act_v below current v$cur_v"; WARNS=$((WARNS+1))
      fi
    fi
  done < "$wf"
done
[ "$FAILS" -eq 0 ] && echo "PASS ($WARNS warnings)" || echo "FAIL ($FAILS critical, $WARNS warnings)"
```

### 22. DevKit Enrollment Marker Present

- **What to check**: The project root contains a `.devkit.json` enrollment marker with valid required fields.
- **Stacks**: All DevKit-managed projects (any repo under a DevSpace folder)
- **Pass criteria**: `.devkit.json` exists at repo root with `project`, `tier`, `family`, and `devkit_version` fields present and non-empty.
- **Fail indicators**: Missing `.devkit.json` (orphan project — was not created via `new-project.ps1`). Or missing required fields.
- **Fix reference**: Run `setup/new-project.ps1` for new projects. For existing projects, create manually:
  `{"project":"<name>","tier":"full","profile":"<stack>","family":"<Family>","managed_by":null,"created":"<date>","devkit_version":"<version>"}`
- **Note**: Orphan detection in `SessionStart.sh` also flags this at session start.

## Scoring

- **Pass**: Check criteria met
- **Fail**: Check criteria not met and the check applies to this stack
- **Skip**: Check does not apply to this stack (e.g., nightly for .NET desktop, lint config for .NET)
- **Score**: (pass count) / (pass count + fail count) as percentage; skipped checks excluded from denominator
