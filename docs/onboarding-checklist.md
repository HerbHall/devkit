# New Project Onboarding Checklist

Complete guide from `git init` to a fully DevKit-governed project. Steps are ordered — do not skip ahead.

## Prerequisites

Before starting, verify these are available:

- [ ] DevKit cloned and symlinked (`setup/sync.ps1 -Link` shows all green)
- [ ] PowerShell 7+ (`pwsh --version`)
- [ ] Git with `gh` CLI authenticated (`gh auth status`)
- [ ] Node.js on PATH (`node --version`)

## Phase 1: Repository Creation

### 1.1 Create the GitHub repo

```bash
gh repo create OWNER/PROJECT --public --clone
cd PROJECT
```

### 1.2 Initialize with DevKit scaffolding

```powershell
pwsh -File ~/path-to-devkit/setup/setup.ps1 -Kit project
```

Or run interactively and select option 3 (New Project).

This creates:

- `CLAUDE.md` from `project-templates/claude-md-template.md`
- `.claude/settings.json` from `project-templates/settings.json`
- `.editorconfig` with `root = false` (inherits from DevSpace parent)
- `scripts/pre-push` hook

### 1.3 Create essential files

| File | Content | Template |
|------|---------|----------|
| `VERSION` | `0.1.0` | Manual |
| `LICENSE` | MIT license text | Manual |
| `.gitignore` | Stack-appropriate ignores | `project-templates/gitignore-*` |
| `Makefile` | `build`, `test`, `lint` targets | `project-templates/Makefile.*` |

### 1.4 Stack-specific lint config

| Stack | File | Template |
|-------|------|----------|
| Go | `.golangci.yml` | `project-templates/golangci.yml` |
| Node/React | `eslint.config.js` | `project-templates/eslint.config.js` |
| Rust | `[lints]` in `Cargo.toml` | N/A (built-in) |

### 1.5 Initial commit and push

```bash
git add -A
git commit -m "feat: initial project scaffold

Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin main
```

## Phase 2: CI and Release Automation

### 2.1 CI workflow

Copy the appropriate CI template to `.github/workflows/ci.yml`:

| Stack | Template |
|-------|----------|
| Go | `project-templates/ci.yml` |
| Node | `project-templates/ci-node.yml` |
| Rust | `project-templates/ci-rust.yml` |
| .NET | `project-templates/ci-dotnet.yml` |

Customize job names, build commands, and test commands for your project.

### 2.2 Release Please

Copy three files:

```bash
cp project-templates/release-please-config.json ./release-please-config.json
cp project-templates/release-please-manifest.json ./.release-please-manifest.json
cp project-templates/release-please.yml .github/workflows/release-please.yml
```

Edit `release-please-config.json` to set the correct release type (`go`, `node`, `rust`, `simple`).

### 2.3 Supporting workflows

| File | Template | Purpose |
|------|----------|---------|
| `.github/workflows/release-gate.yml` | `project-templates/release-gate.yml` | Auto-merge release PRs after CI |
| `.github/workflows/retrigger-ci.yml` | `project-templates/retrigger-ci.yml` | Re-run CI on stale release PRs |
| `.github/workflows/nightly.yml` | `project-templates/nightly-*.yml` | Scheduled builds (optional) |

### 2.4 Copilot integration files (optional)

| File | Template | Purpose |
|------|----------|---------|
| `.github/copilot-instructions.md` | `project-templates/copilot-instructions.md` | Copilot coding style |
| `AGENTS.md` | `project-templates/AGENTS.md` | Copilot agent boundaries |
| `.github/workflows/copilot-setup-steps.yml` | `project-templates/copilot-setup-steps-*.yml` | Agent dependency setup |

### 2.5 Commit and push CI files

```bash
git checkout -b chore/initial-ci
git add .github/ release-please-config.json .release-please-manifest.json
git commit -m "chore: add CI, release-please, and supporting workflows"
git push -u origin chore/initial-ci
```

Merge this PR after CI passes.

## Phase 3: Manual GitHub UI Settings

These settings **cannot** be configured via API or CLI. Each must be set manually in the GitHub web UI.

### 3.1 Actions PR Permission (REQUIRED)

**Path**: Repository Settings > Actions > General > Workflow permissions

1. Select **"Read and write permissions"**
2. Check **"Allow GitHub Actions to create and approve pull requests"**
3. Click **Save**

**Why**: Without this, `release-please`, `retrigger-ci`, and `release-gate` workflows fail with `Resource not accessible by integration` when they try to create or modify PRs using `GITHUB_TOKEN`. This setting defaults to **disabled** on new repositories.

**Failure symptom**: Release Please workflow runs succeed but never open a PR. Workflow log shows `HttpError: GitHub Actions is not permitted to create or approve pull requests`.

### 3.2 Copilot PR Review Ruleset (RECOMMENDED)

**Path**: Repository Settings > Rules > Rulesets > New ruleset > New branch ruleset

1. Name the ruleset **"Copilot PR Review"**
2. Set enforcement status to **Active**
3. Under "Target branches", add **Default branch**
4. Under "Branch rules", enable **"Require a pull request before merging"**
   - Set "Required approvals" to **0** (Copilot cannot approve, only comment)
   - Check **"Require review from GitHub Copilot"**
   - Check **"Review new pushes"**
5. Under "Branch rules", enable **"Restrict merge methods"**
   - Check **"Squash"** only
6. Under "Bypass list", add your admin account
7. Click **Create**

Alternatively, create the ruleset via API then enable Copilot manually:

```bash
bash scripts/copilot-review-setup.sh setup OWNER/REPO
# Then go to Settings > Rules > Rulesets > Copilot PR Review
# and manually enable the Copilot review toggle (API cannot set this)
```

**Why**: Copilot auto-review provides informational code review on every push. It is not a merge gate — CI is the only merge gate. See `docs/copilot-integration.md` for the full three-layer protection model.

### 3.3 Auto-Merge (REQUIRED if using release-gate)

**Path**: Repository Settings > General (scroll to "Pull Requests" section)

1. Check **"Allow auto-merge"**
2. Click **Save** (or update)

Can also be set via API:

```bash
gh api repos/OWNER/REPO -X PATCH -f allow_auto_merge=true
```

**Why**: The `release-gate.yml` workflow uses `gh pr merge --auto` to auto-merge release PRs after CI passes.

## Phase 4: Gitea Equivalents

For projects hosted on Gitea instead of GitHub:

| GitHub Step | Gitea Equivalent |
|-------------|-----------------|
| Actions PR Permission (3.1) | Not needed — Gitea Actions uses the repository token with full permissions by default |
| Copilot PR Review (3.2) | Not available — Gitea has no Copilot integration. Use manual review or skip |
| Auto-Merge (3.3) | Settings > Repository > Pull Requests > check "Enable auto-merge" |
| Release Please | Not available — use manual release workflow or `git-cliff` for changelogs |
| CI workflows | Gitea Actions uses the same workflow syntax as GitHub Actions (minor differences in runner labels) |

**Note**: `scripts/forge-wrappers.sh` provides portable CLI wrappers (`devkit-pr-create`, `devkit-issue-list`, etc.) that detect the forge automatically. Use these in skill workflows instead of raw `gh`/`tea` commands.

## Phase 5: Verification

After completing all steps, run the conformance audit:

```text
/conformance-audit
```

Select the single-project check and provide the project path. All 18 checks should pass (or show as "skip" for non-applicable stack checks).

### Expected results for a fully onboarded project

| Check | Expected |
|-------|----------|
| 1. CLAUDE.md | Pass |
| 2. Claude Settings | Pass |
| 3. CI Workflow | Pass |
| 4. Pre-push Hook | Pass |
| 5. Lint Config | Pass (or Skip for .NET) |
| 6. Makefile | Pass |
| 7. EditorConfig | Pass |
| 8. Release Please | Pass |
| 9. LICENSE | Pass |
| 10. VERSION | Pass |
| 11. Gitignore | Pass |
| 12. Nightly Build | Pass (or Skip for .NET desktop) |
| 13. Release Gate | Pass |
| 14. Workflow Triggers | Pass |
| 15. Retrigger CI | Pass |
| 16. Auto-Merge | Pass |
| 17. Rules File Size | Skip (DevKit only) |
| 18. Actions PR Permission | Pass (manual verification) |

If any check fails, the audit output includes the fix reference (template path or command).

## Quick Reference

### Automated (DevKit handles)

- Project scaffolding (`setup.ps1 -Kit project`)
- Symlink management (`sync.ps1 -Link`)
- Template files (copy from `project-templates/`)
- Pre-push hook installation
- Copilot ruleset creation via script (`copilot-review-setup.sh`)

### Manual (human in browser)

- Actions PR Permission (Settings > Actions > General)
- Copilot review toggle in ruleset (Settings > Rules > Rulesets)
- Auto-merge checkbox (Settings > General) — also settable via API

### Cannot be automated

- Actions PR Permission — no API exists
- Copilot review toggle within rulesets — API creates the ruleset but cannot enable the Copilot toggle
