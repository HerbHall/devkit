# GitHub Copilot Integration Strategy

Research findings and integration strategy for GitHub Copilot across all DevKit projects.

## Overview

GitHub Copilot Pro provides four distinct capabilities, each driven by different configuration
files and serving different workflows:

- **Completions** -- Inline code suggestions as you type. Driven by `copilot-instructions.md`
  and `.instructions.md` files.
- **Code review** -- Automated PR review comments. Driven by `copilot-instructions.md`
  (first ~4,000 characters read).
- **Chat** -- Interactive assistant in VS Code / GitHub.com. Driven by
  `copilot-instructions.md` and `AGENTS.md`.
- **Coding agent** -- Autonomous issue resolution (assigns Copilot to a GitHub issue).
  Driven by `AGENTS.md` and `copilot-setup-steps.yml`.

## File Architecture

| File | Purpose | Scope | Used By |
|------|---------|-------|---------|
| `.github/copilot-instructions.md` | Project context, coding standards, style | Repo-wide | Completions, chat, code review |
| `.github/AGENTS.md` | Behavioral guidance for autonomous agent | Repo-wide | Coding agent, chat |
| `.github/workflows/copilot-setup-steps.yml` | Pre-install dependencies for agent sessions | CI runner | Coding agent only |
| `.github/instructions/*.instructions.md` | Path-specific coding patterns | Per-file-glob | Completions, chat, code review |

### Scope Split

`copilot-instructions.md` and `AGENTS.md` serve distinct roles and should not be merged:

- `copilot-instructions.md` = what kind of code to write (style, conventions, architecture)
- `AGENTS.md` = how to behave autonomously (boundaries, safety constraints, process)
- `CLAUDE.md` = instructions for Claude Code (separate tool, not Copilot)

## Findings and Improvements

### Analysis Source

GitHub's analysis of 2,500+ repositories with `AGENTS.md` files identified the patterns
that produce the most consistent agent behavior. Key finding: **three-tier boundaries are
the most effective pattern** -- explicitly separating what the agent should always do, ask
first, and never do.

### What Samverk Currently Has

Samverk has no Copilot-specific files. No `copilot-instructions.md`, no `AGENTS.md`,
no `copilot-setup-steps.yml`, no `.instructions.md` files exist in the repo as of
the time of this document.

### Improvement Opportunities for All Projects

**`copilot-instructions.md`** should include five sections (from GitHub's 5-tip guide):

1. Project overview and purpose
2. Tech stack with versions
3. Coding guidelines and style rules
4. Project structure (key directories and what lives where)
5. Available resources (make targets, test commands, CI scripts)

Keep under ~1,000 lines. Code review reads only the first ~4,000 characters -- put the
most important conventions near the top.

**`AGENTS.md`** must define three-tier boundaries explicitly:

```text
## Always Do
- Run the CI checklist before finishing any task
- Create a branch, never commit to main directly

## Ask First
- Changes affecting authentication, secrets handling, or security
- Modifying shared types used across multiple packages
- Adding new external dependencies

## Never Do
- Commit with --no-verify or skip pre-push hooks
- Push to main or force-push any branch
- Store secrets, tokens, or credentials in code
```

Put executable commands early in `AGENTS.md` (agent reads top-down, may stop before
reaching the end on long files). Real code examples beat prose descriptions.

**`copilot-setup-steps.yml`** must be a full workflow file, not bare `steps:`. The job
name must be exactly `copilot-setup-steps` or Copilot ignores it entirely:

```yaml
name: "Copilot Setup Steps"
on: workflow_dispatch

jobs:
  copilot-setup-steps:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Go dependencies
        run: go mod download
```

Pre-install all dependencies rather than letting the agent discover them at runtime.
Agent discovery is slow and unreliable -- a cold `go build` that downloads modules
mid-task frequently times out or produces confusing errors.

**`.instructions.md` files** use `applyTo` frontmatter to target specific paths:

```yaml
---
applyTo: "**/*.go"
---
```

These are applied to completions, chat, and code review for matching files. Use them
to encode stack-specific patterns from DevKit's autolearn library (117 patterns,
91 gotchas) in a form Copilot can apply inline.

**CodeQL** is free for public repos with Copilot Autofix. Requires
`security-events: write` permission in the CI workflow. Autofix generates a PR with
the suggested security fix -- worth enabling on all Go and TypeScript projects.

## Templates Provided

DevKit provides ready-to-copy templates in `project-templates/`:

| Template | Path | Description |
|----------|------|-------------|
| Go instructions | `project-templates/instructions/go.instructions.md` | Go-specific lint patterns, test conventions |
| React/TypeScript instructions | `project-templates/instructions/react.instructions.md` | React/TS patterns, MUI conventions |
| AGENTS.md | `project-templates/agents-template.md` | Three-tier boundary template |
| copilot-instructions | `project-templates/copilot-instructions-template.md` | Five-section template |
| copilot-setup-steps | `project-templates/copilot-setup-steps-template.yml` | Full workflow with job name |

Note: As of the time of writing, the templates directory contains `instructions/` as
a placeholder. Templates should be created as part of the Copilot integration rollout.

## Per-Project Rollout Checklist

For each existing project, complete in order:

- [ ] Create `.github/copilot-instructions.md` with five sections (overview, stack,
  guidelines, structure, resources)
- [ ] Create `.github/AGENTS.md` with three-tier boundaries (always/ask/never),
  setup commands, and project-specific constraints
- [ ] Create `.github/workflows/copilot-setup-steps.yml` as a full workflow with
  job name `copilot-setup-steps`; pre-install all dependencies
- [ ] Add `.github/instructions/` directory with at least one language-specific
  `.instructions.md` file using `applyTo` frontmatter
- [ ] Enable CodeQL if the repo is public (add `security-events: write` permission,
  add CodeQL workflow step)
- [ ] Test by assigning Copilot to a simple issue (bug fix or test addition) and
  verifying the agent reads setup steps correctly

## Delegation Model

### Good Tasks for Copilot Coding Agent

These are well-scoped, low-ambiguity tasks where agent behavior is predictable:

- Bug fixes with a clear reproduction case
- Test expansion for existing functionality (add table-driven test cases)
- Documentation updates (README sections, inline comments, docstrings)
- Simple refactors (rename, extract function, reformat)
- Dependency version bumps (with CI verification)
- Adding markdownlint/ESLint fixes for existing violations
- Implementing a clearly-specced new function against an existing interface

### Tasks to Route to Claude Code Instead

These require context, judgment, or multi-file coordination:

- Multi-file architectural features (new module, new API surface)
- Security-sensitive changes (authentication, authorization, secrets handling)
- Ambiguous requirements that need clarification before implementation
- Changes to shared types or interfaces used across packages
- Database schema migrations
- CI/CD workflow changes
- Any task requiring deviation from established patterns

### Assignment Workflow

1. Open a GitHub issue with a clear, single-sentence task description
2. Verify the task fits the "good tasks" list above
3. Add to the issue: reproduction steps (for bugs) or acceptance criteria (for features)
4. Assign `Copilot` as the assignee from the GitHub issue UI
5. Review the generated PR with code review enabled -- Copilot's own instructions
   govern what it will produce

## Interaction Model

Copilot and Claude Code serve different workflows and do not conflict:

| Concern | Copilot | Claude Code |
|---------|---------|-------------|
| Inline completions | Yes -- always active | No |
| Code review on PRs | Yes -- automated comments | No |
| Simple issue resolution | Yes -- assign in GitHub UI | No |
| Multi-file features | No | Yes -- main tool |
| Architecture decisions | No | Yes -- `/create-plan` |
| Codebase exploration | No | Yes -- Glob/Grep agents |
| Rule learning (`/reflect`) | No | Yes -- autolearn pipeline |

Both tools read different instruction files. `AGENTS.md` governs Copilot agent behavior.
`CLAUDE.md` governs Claude Code behavior. Changes to one do not affect the other.

The shared constraint is **branch safety**: both tools should be configured to never
commit directly to main and never skip pre-push hooks. This is enforced by:

- `AGENTS.md` never-do list (Copilot)
- `CLAUDE.md` Git Safety rules (Claude Code)
- Pre-push hook (catches both)

## References

- [How to write a great AGENTS.md -- lessons from 2,500+ repositories](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [5 tips for writing better custom instructions for Copilot](https://github.blog/ai-and-ml/github-copilot/5-tips-for-writing-better-custom-instructions-for-copilot/)
- [Best practices for using Copilot to work on tasks](https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/best-practices-for-using-copilot-to-work-on-tasks)
- [Adding custom instructions for GitHub Copilot](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [github/awesome-copilot](https://github.com/github/awesome-copilot)
