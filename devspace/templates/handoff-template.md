# Handoff Template

Use this template when creating handoff documents for Claude Code sessions.
Handoffs transfer work from Claude Chat (planning/design) to Claude Code (execution).

## Required Sections

```markdown
# Handoff: <Title>

**Date:** YYYY-MM-DD
**Type:** Tier 1 | Tier 2 | Tier 3
**Repo:** <path to repo>
**Branch:** Create `<branch-name>` from `main`

---

## Context

<What was decided, why, and any relevant prior work.>

---

## Changes Required

<Numbered list of specific file changes with exact content or clear specs.>

---

## Git Workflow (MANDATORY)

All changes MUST follow this workflow:

1. Create a feature branch from main:
   ```bash
   git checkout main && git pull origin main
   git checkout -b <branch-name>
   ```

2. Make all changes on the feature branch (never on main).

3. Commit with a descriptive message:
   ```bash
   git add <specific files>
   git commit -m "<type>: <description>"
   ```

4. Push and open a PR:
   ```bash
   git push origin HEAD
   gh pr create --title "<type>: <description>" --body "<summary>"
   ```

5. Wait for CI to pass. Merge via PR, not direct push.

**CRITICAL: Never commit directly to main.** This rule has no exceptions,
even for documentation-only changes, autolearn entries, or config files.

---

## Validation

<How to verify the changes are correct after implementation.>

---

## Commit Message

```
<type>: <description>
```

## Template Usage Notes

- **Always include the Git Workflow section.** It is not optional. Past incidents
  have shown that omitting explicit branching instructions leads to direct-to-main
  commits, which bypass review and can auto-close issues incorrectly.

- **Tier determines confirmation behavior:**
  - Tier 1: Restate plan in one sentence, then execute.
  - Tier 2: Present plan in 2-3 sentences, wait for confirmation.
  - Tier 3: Full scope assessment with goal, approach, and clarifying questions.

- **Branch naming conventions:**
  - `feature/<description>` for new capabilities
  - `fix/<description>` for bug fixes
  - `docs/<description>` for documentation changes
  - `chore/<description>` for maintenance
  - `autolearn/<date>-<description>` for autolearn rule updates
