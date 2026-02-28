# {{PROJECT_NAME}} - Development Guide

**Project scope:** {{PROJECT_DESCRIPTION}}

**Created:** 2026-02-21 · **Profile:** {{PROFILE}} · **Workspace:** {{DEVSPACE}}

**This file is your project's development handbook.** It contains build commands, test strategies, architecture notes, and workflow conventions specific to {{PROJECT_NAME}}.

## Quick Start

```bash
# First time setup: install git hooks
make hooks

# Build and test
make build
make test

# Run all lint checks (matches CI)
make lint-all

# Run the project
make run
```

The pre-push hook runs `build + test + lint` automatically before each push. See `Makefile` for all available targets.

## Project Structure

```text
{{PROJECT_NAME}}/
├── README.md              # Public-facing project overview
├── CLAUDE.md              # This file — development guide for AI agents
├── Makefile               # Build and development tasks
│
├── src/                   # Source code
│   └── main.{{PROFILE_EXT}}
│
├── tests/                 # Test suite
│   └── *_test.{{PROFILE_EXT}}
│
├── docs/                  # Architecture and design docs
│   ├── ARCHITECTURE.md    # System design and components
│   ├── decisions.md       # Architecture decision records (ADRs)
│   └── decisions/         # Individual ADRs
│
└── .github/workflows/     # CI/CD pipelines
    └── test.yml          # Automated tests on push
```

Replace {{PROFILE_EXT}} with appropriate extension (go, ts, rs, etc. based on profile).

## Tech Stack

**Language:** {{PROFILE}} profile
**Build tool:** Makefile
**Testing:** [match to profile]
**CI/CD:** GitHub Actions

See `.github/workflows/` for automated checks that run on each push.

## Development Workflow

### Branch Strategy

- **Never commit directly to main**
- Create feature branch: `git checkout -b feature/issue-NNN-description`
- Commit using conventional format: `feat: ...`, `fix: ...`, `docs: ...`
- Include co-author tag in all commits:

```bash
git commit -m "feat: add X

Co-Authored-By: Claude <noreply@anthropic.com>"
```

- Push branch and create PR via `gh pr create`
- Merge only after CI passes

### Testing Before Push

The pre-push hook handles this automatically. To run checks manually:

```bash
make ci    # build + test + lint (same checks as CI and the pre-push hook)
```

Fix all failures before pushing. CI should only confirm what you've already verified locally.

### Code Review

1. Push to feature branch
2. Create PR with `gh pr create`
3. Wait for CI to pass (GitHub Actions)
4. Merge via GitHub UI (`gh pr merge <number> --merge`)

## Conventions

### Commit Message Format

```text
feat: add user authentication
^--- type: one of feat, fix, refactor, docs, test, chore

Brief description (50 chars or less)

Longer explanation of the change and why it was made.

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types:**

- `feat:` new feature or enhancement
- `fix:` bug fix
- `refactor:` code restructuring (no behavior change)
- `docs:` documentation only
- `test:` test addition or modification
- `chore:` tooling, CI, dependencies, etc.

### Code Style

- Follow the language's idioms (Go conventions for Go, Python PEP 8, etc.)
- Comments only where logic isn't self-evident
- Watch for security issues: input validation, SQL injection, XSS, command injection
- Validate only at system boundaries (user input, external APIs)

### File Naming

- Use snake_case for files and directories
- Use PascalCase for type/class names
- Use camelCase for functions and variables

## Known Constraints

<!-- Fill these in as you discover them -->

- [Constraint 1]
- [Constraint 2]

## Debugging Tips

### When Tests Fail

1. Run the failing test in isolation: `make test TEST=TestName`
2. Add logging or breakpoints
3. Check git diff to understand what changed
4. Search for related issues on GitHub

### When CI Fails

1. Check the GitHub Actions logs (link in PR)
2. Run the failing job locally if possible
3. Common issues: missing dependencies, platform-specific bugs, lint errors
4. Push fix and re-run CI with `gh run rerun <run-id>`

## References

- **Architecture:** See `docs/ARCHITECTURE.md` for system design
- **Decisions:** See `docs/decisions.md` for ADRs and design rationale
- **Global conventions:** See `~/.claude/CLAUDE.md` for workspace-wide standards
- **Local overrides:** Add machine-specific or project-specific patterns to `~/.claude/rules/<name>.local.md` (never synced, never committed)

---

**Note:** This template was generated from `devkit/project-templates/claude-md-template.md`. Update it as the project evolves.
