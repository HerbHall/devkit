# Contributing to DevKit

DevKit is the development methodology and Claude Code configuration toolkit. This guide documents the development workflow for consistency and agent compliance.

## Getting Started

1. Clone the repository from Gitea: `git clone https://gitea.herbhall.net/samverk/devkit.git`
2. Run setup:
   - **PowerShell** (primary): `pwsh -File setup/setup.ps1`
   - **Bash** (legacy): `bash setup/legacy/install-tools.sh && bash setup/legacy/setup.sh`
3. Create a feature branch: `git checkout -b feature/issue-NNN-desc`
4. Make your changes
5. Run lint checks (see below)
6. Push and open a pull request on Gitea

## Development Workflow

Follow the **Explore -> Plan -> Code -> Verify -> Commit** flow:

1. **Explore**: Read existing rules, skills, and templates before making changes
2. **Plan**: Get plan approval before implementing multi-file changes
3. **Code**: Implement methodically, following existing patterns
4. **Verify**: Run validation checks locally before pushing

```bash
# Validate JSON templates
python -c "import json; json.load(open('claude/settings.template.json'))"

# Lint all markdown
npx markdownlint-cli2 "**/*.md"

# Check for hardcoded user-specific paths
grep -r "HerbHall\|SubNetree\|D:\\\\DevSpace" claude/ devspace/ mcp/ setup/
```

After verification, commit with clear messages using conventional prefixes.

### Key Conventions

- Skill `SKILL.md` files follow Claude Code skill format (YAML frontmatter + routing table)
- All workflow files referenced in routing tables must exist on disk (CI validates this)
- Rules files in `claude/rules/` are loaded into every session -- keep them concise (under 35k per file)
- Placeholders use `UPPERCASE_WITH_UNDERSCORES` (not angle brackets)

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` new skill, agent, rule, or template
- `fix:` bug fix in scripts, skills, or configurations
- `docs:` documentation updates (ADRs, methodology, guides)
- `test:` adding or updating validation tests
- `chore:` maintenance tasks (dependency updates, cleanup)
- `refactor:` restructuring without behavior change

Include the co-author tag for agent-generated commits:

```text
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Pull Requests

- Never commit directly to `main` -- all changes go through feature branches
- Branch naming: `feature/issue-NNN-desc`, `fix/issue-NNN-desc`
- Keep PRs focused on a single change
- Ensure CI passes (markdownlint, JSON validation, path checks) before merging
- Reference related issues with `Closes #N`

## Reporting Issues

- File issues in the [DevKit Gitea repository](https://gitea.herbhall.net/samverk/devkit/issues)
- Use conventional commit prefixes in issue titles: `feat:`, `fix:`, `docs:`, etc.
- Include steps to reproduce for bug reports
- Note affected components (rules, skills, agents, templates, setup scripts)
- Check existing issues before creating a new one

## Code of Conduct

Contributors are expected to maintain a professional and respectful environment. All changes must pass CI, and all errors found during development must be fixed or tracked with an issue.
