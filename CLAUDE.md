# devkit

Personal development methodology and Claude Code configuration, packaged as a portable toolkit.

## Quick Start

```powershell
# Primary (PowerShell)
pwsh -File setup/setup.ps1
```

```bash
# Legacy (Git Bash)
bash setup/legacy/install-tools.sh
bash setup/legacy/setup.sh
bash setup/legacy/verify.sh
```

## Project Structure

```text
devkit/
├── claude/              - Claude Code config (rules, skills, agents, hooks)
│   ├── CLAUDE.md        - Global instructions (installed to ~/.claude/)
│   ├── rules/           - Auto-loaded pattern files (8 files, 135+ patterns)
│   ├── skills/          - Invokable skills (18 skills with workflow files)
│   ├── agents/          - Agent templates (7 agents)
│   └── hooks/           - SessionStart hook
├── devspace/            - Workspace shared configs (.editorconfig, VS Code)
│   ├── templates/       - Project starter templates (ADR, design, test plan)
│   └── shared-vscode/   - VS Code setting fragments
├── docs/                - Architecture decisions and guides
├── machine/             - Machine state snapshots
├── mcp/                 - MCP server inventory and config templates
├── profiles/            - Kit 2 stack profiles (project type definitions)
├── project-templates/   - Kit 3 scaffolding templates
├── setup/               - PowerShell stubs (*.ps1, lib/*.ps1)
│   ├── lib/             - Shared PowerShell libraries
│   └── legacy/          - Deprecated bash scripts
├── tests/               - E2E tests (review pipeline validation)
├── METHODOLOGY.md       - 6-phase development process
└── CHANGELOG.md         - Version history
```

## Code Style

- All documentation follows markdownlint rules (see `devspace/.markdownlint.json`)
- Shell scripts use `#!/usr/bin/env bash` with `set -euo pipefail`
- JSON templates must be valid JSON (verify with `python -c "import json; json.load(open('file'))"`)
- Skill SKILL.md files follow Claude Code skill format (YAML frontmatter + routing table)
- Placeholders use `UPPERCASE_WITH_UNDERSCORES` (not angle brackets, which trigger MD033)

## Project Gotchas

**IMPORTANT**:

- `claude/CLAUDE.md` is the *global* config installed to `~/.claude/CLAUDE.md` — it is NOT this project's config
- `project-templates/workspace-claude-md-template.md` is a *template* for workspace roots — not used directly by this project
- Skill workflow files referenced in SKILL.md routing tables must exist on disk (CI validates this)
- `settings.template.json` must be valid JSON — easy to break with missing commas
- Rules files (`claude/rules/*.md`) are loaded into Claude Code's system prompt every session — keep them concise

## Key Dependencies

- `bash` - Setup and hook scripts
- `git` - Version control
- `node` / `npm` - Required for Claude Code itself
- `gh` - GitHub CLI for issue/PR operations in skills
- `markdownlint-cli2` - Markdown linting (CI and local)

## Testing

```bash
# Validate JSON templates
python -c "import json; json.load(open('claude/settings.template.json'))"

# Check for stale skill routing (all referenced workflows exist)
# Automated in CI: .github/workflows/lint.yml

# Lint all markdown
npx markdownlint-cli2 "**/*.md"

# Verify no hardcoded user-specific paths leaked in
grep -r "HerbHall\|SubNetree\|D:\\\\DevSpace" claude/ devspace/ mcp/ setup/
```

## Common Tasks

**Add a new skill:**

1. Create `claude/skills/{name}/SKILL.md` with YAML frontmatter
2. Create `claude/skills/{name}/workflows/*.md` for each routing target
3. Update `setup/legacy/verify.sh` to include the new skill name
4. Update `README.md` skills table

**Add a new rule pattern:**

1. Edit the appropriate file in `claude/rules/` (patterns, gotchas, etc.)
2. Keep entries numbered sequentially
3. Include: category, context, fix, and example

**Sync from a workstation:**

With symlinks active (via `setup/sync.ps1 -Link`), changes to `~/.claude/` are already in the DevKit clone. Run `/devkit-sync push` to commit and push. For manual sync without symlinks:

```bash
cp ~/.claude/rules/*.md claude/rules/
cp -r ~/.claude/skills/new-skill claude/skills/
```

---

**Note**: Add personal preferences to `CLAUDE.local.md` (gitignored) instead of this file.
