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

## Phase 3: Automated Repository Configuration

All repository configuration is applied via API or CLI — no browser steps required.

### 3.1 Release PAT Secret (AUTOMATED by new-project.ps1)

`new-project.ps1` section 2.7 reads `RELEASE_PLEASE_TOKEN` from `~/.devkit-config.json` and sets it automatically. For existing repos, run:

```powershell
pwsh scripts/Set-DevkitSecrets.ps1 -Repo OWNER/REPO
```

**Why**: `release-please.yml` uses this PAT (not `GITHUB_TOKEN`) to create release PRs. A PAT acts as a user token and is not subject to the "Allow GitHub Actions to create PRs" repository permission, which only restricts the built-in `GITHUB_TOKEN`. See KG#94.

### 3.2 Auto-Merge (AUTOMATED by new-project.ps1)

`new-project.ps1` enables auto-merge via API during scaffolding. For existing repos:

```bash
gh api repos/OWNER/REPO -X PATCH -f allow_auto_merge=true
```

**Gitea**: Set via API: `PATCH /api/v1/repos/{owner}/{repo}` with `allow_auto_merge: true`.

**Why**: `release-gate.yml` uses `gh pr merge --auto` to merge release PRs after CI passes.

### 3.3 Copilot PR Review Ruleset (OPTIONAL, GitHub-only, partially automated)

Creates the ruleset via API. The Copilot review toggle within the ruleset requires a one-time UI action and cannot be set via API:

```bash
bash scripts/copilot-review-setup.sh setup OWNER/REPO
```

**Note**: This is informational only — Copilot cannot approve PRs (KG#99). CI is the merge gate. Skip this step on Gitea-hosted projects (no Copilot equivalent exists).

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

Select the single-project check and provide the project path. All 19 checks should pass (or show as "skip" for non-applicable stack checks).

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
| 18. Release PAT Configured | Pass |
| 19. Periodic Documentation Audit | Skip (DevKit only) |

If any check fails, the audit output includes the fix reference (template path or command).

## Quick Reference

### Automated (DevKit handles)

- Project scaffolding (`setup.ps1 -Kit project`)
- Symlink management (`sync.ps1 -Link`)
- Template files (copy from `project-templates/`)
- Pre-push hook installation
- Copilot ruleset creation via script (`copilot-review-setup.sh`)

### Manual (human in browser)

- Copilot review toggle in ruleset (Settings > Rules > Rulesets) — optional, GitHub-only, informational only

### Cannot be automated

- Copilot review toggle within rulesets — API creates the ruleset but cannot enable the Copilot toggle (GitHub-only feature; not applicable on Gitea)
