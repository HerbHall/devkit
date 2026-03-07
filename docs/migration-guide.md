# Migration Guide

How to adopt DevKit in an existing project. This guide assumes DevKit is already installed on your machine (see [Getting Started](getting-started.md) if not).

## What DevKit Provides

DevKit gives your project access to:

- **Rules** (10 files, 135+ patterns) -- auto-loaded every Claude Code session
- **Skills** (19 invokable workflows) -- `/plan-review`, `/code-review`, `/autolearn`, etc.
- **Agent templates** (7 agents) -- plan reviewer, code reviewer, security analyzer, etc.
- **Hooks** -- SessionStart for automatic session orientation
- **CI templates** -- GitHub Actions workflows, pre-push hooks, lint configs
- **Project templates** -- CLAUDE.md, settings, community health files

## Step 1: Add Claude Code Settings

Copy the project-level settings template into your project:

```bash
mkdir -p .claude
cp devkit/project-templates/settings.json .claude/settings.json
```

This file defines tool-specific permission wildcards that are committed to the repo and shared with collaborators. Add `.claude/settings.local.json` to your `.gitignore` (it accumulates session-specific approvals).

## Step 2: Create a Project CLAUDE.md

Copy the project template and customize it:

```bash
cp devkit/project-templates/claude-md-template.md CLAUDE.md
```

Edit the file to include:

- Project name and description
- Build commands (`go build`, `npm run build`, etc.)
- Test commands (`go test`, `npm test`, etc.)
- Lint commands (`golangci-lint run`, `npx eslint .`, etc.)
- Project-specific architecture notes and gotchas

## Step 3: Add a Pre-Push Hook

Copy the pre-push hook template and customize for your stack:

```bash
mkdir -p .git/hooks
cp devkit/git-templates/hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

The template includes build, test, and lint steps. Edit it to match your project's toolchain. For example, a Go project would use `go build ./...`, `go test ./...`, and `golangci-lint run ./...`.

## Step 4: Add CI Workflows

Copy relevant CI workflow templates from `project-templates/`:

```bash
mkdir -p .github/workflows
```

Available templates by stack:

| Template | Stack | What It Does |
|----------|-------|-------------|
| `ci.yml` | Go | Build, test, lint (golangci-lint) |
| `ci-node.yml` | Node.js/React | Install, lint, type-check, build, test |
| `ci-rust.yml` | Rust | Build, test, clippy, fmt |
| `ci-dotnet.yml` | .NET | Restore, build, test |
| `release-please.yml` | All | Automated release PRs |
| `release-gate.yml` | All | Merge gate for release PRs |
| `retrigger-ci.yml` | All | Re-triggers CI when status checks are stale |
| `codeql.yml` | All | GitHub code scanning |

Copy the ones you need:

```bash
cp devkit/project-templates/ci.yml .github/workflows/ci.yml
cp devkit/project-templates/release-please.yml .github/workflows/release-please.yml
```

## Step 5: Add EditorConfig

Create a `.editorconfig` in your project root. If your project lives under a workspace that already has a root `.editorconfig`, use `root = false` to inherit those settings:

```ini
# Inherit from workspace root
root = false

[*.go]
indent_style = tab
```

For standalone projects (not under a workspace), use `root = true` and define all settings locally.

## Step 6: Add Markdownlint Config

If your project has markdown files, add a `.markdownlint.json`:

```json
{
  "default": true,
  "MD013": false,
  "MD060": false
}
```

This disables line-length (MD013) and table-column-style (MD060), matching DevKit conventions.

## Optional: Install a Stack Profile

If DevKit has a profile matching your project's stack, install it for additional tooling:

```powershell
pwsh -File devkit/setup/setup.ps1 -Kit stack
```

Profiles are defined in `profiles/` and include winget packages, VS Code extensions, and Claude skills specific to each technology stack. See [PROFILES.md](PROFILES.md) for the profile format.

## Verification Checklist

After completing the migration, verify these items:

- [ ] `.claude/settings.json` exists and is committed
- [ ] `.claude/settings.local.json` is in `.gitignore`
- [ ] `CLAUDE.md` exists at the project root with build/test/lint commands
- [ ] Pre-push hook runs successfully: `git hook run pre-push`
- [ ] CI workflow passes on a test branch
- [ ] `.editorconfig` is present with correct `root` setting

## Next Steps

- [Extending DevKit](extending-devkit.md) -- add custom skills, agents, or rules
- [Troubleshooting](troubleshooting.md) -- common issues and fixes
