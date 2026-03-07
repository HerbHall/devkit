# Getting Started with DevKit

A step-by-step guide from cloning DevKit to creating your first project.

## Prerequisites

Before you begin, ensure you have:

- **Windows 11** (or Windows 10 Build 19041+)
- **PowerShell 7+** (`pwsh`). Check with `$PSVersionTable.PSVersion`
- **Git** installed and on your PATH
- **GitHub account** with SSH or HTTPS access configured
- **Node.js** (required for Claude Code itself)

## Step 1: Clone DevKit

Clone the repository into your workspace root. The recommended location is `D:\DevSpace`, but any directory works.

```bash
cd ~/workspace  # or wherever your projects live
git clone https://github.com/HerbHall/devkit.git
```

## Step 2: Run Setup

Run the primary setup script from PowerShell:

```powershell
pwsh -File devkit/setup/setup.ps1
```

If Windows blocks the script, use the bypass flag for a one-time exception:

```powershell
pwsh -ExecutionPolicy Bypass -File devkit/setup/setup.ps1
```

### What setup does

- Creates **symlinks** from `~/.claude/` to the DevKit clone (rules, skills, agents, hooks)
- Installs **workspace configs** (`.editorconfig`, `.markdownlint.json`) into your workspace root
- Configures the **SessionStart hook** for automatic session orientation
- Runs basic **verification** to confirm everything is linked correctly

Because DevKit uses symlinks instead of copies, any edits to `~/.claude/rules/` directly modify the DevKit clone. Run `git diff` in the clone to see your changes.

> **Full bootstrap guide**: For detailed machine setup (installing tools via winget, setting up GitHub CLI, configuring MCP servers), see [BOOTSTRAP.md](BOOTSTRAP.md).

## Step 3: Create Your First Project

Use the project scaffolding kit:

```powershell
pwsh -File devkit/setup/setup.ps1 -Kit project
```

Or select option 3 from the setup menu if running interactively.

This copies starter files into your new project directory:

- `.claude/settings.json` from `project-templates/settings.json`
- `CLAUDE.md` from `project-templates/claude-md-template.md`
- `.editorconfig` configured to inherit from your workspace root
- Pre-push hook from `git-templates/hooks/pre-push`

## Step 4: Verify Installation

Run the verification kit:

```powershell
pwsh -File devkit/setup/setup.ps1 -Kit verify
```

> **Note**: `verify.ps1` is currently a stub (see [issue #204](https://github.com/HerbHall/devkit/issues/204)). As a workaround, use the bootstrap Phase 6 verification:
>
> ```powershell
> pwsh -File devkit/setup/bootstrap.ps1 -Phase 6
> ```

Verification checks that:

- Symlinks from `~/.claude/` point to the correct DevKit files
- Required tools (git, gh, node) are available on PATH
- Claude Code settings are properly configured

## Step 5: Configure GitHub Repository Settings

After creating your repo on GitHub, configure these **manual settings** that cannot be set via CLI:

1. **Actions PR Permission**: Settings → Actions → General → Workflow permissions → enable "Allow GitHub Actions to create and approve pull requests". Required for release-please and any workflow that opens PRs
2. **Copilot Auto-Review** (if using Copilot): Settings → Rules → Rulesets → "Copilot PR Review" → enable "Require review from GitHub Copilot". See [Copilot Integration](copilot-integration.md) for details

These settings default to disabled on new repos and cause silent failures if missed.

## Step 6: Start a Claude Code Session

Open your project directory and start Claude Code. The SessionStart hook fires automatically when you send your first message, providing:

- DevKit version and sync status
- CLAUDE.md detection for the current project
- Rule change notifications since your last session

## Next Steps

- **Adopting DevKit in an existing project?** See the [Migration Guide](migration-guide.md)
- **Want to add skills, agents, or rules?** See [Extending DevKit](extending-devkit.md)
- **Running into problems?** See [Troubleshooting](troubleshooting.md)
- **Full development methodology**: Read [METHODOLOGY.md](../METHODOLOGY.md) for the 6-phase process
