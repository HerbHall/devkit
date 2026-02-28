---
description: Zero-tolerance error policy and fix-forward workflow. Replaces any "pre-existing" classification.
tier: 1
last_reviewed: "2026-02-28"
---

# Error Policy

## Zero-Tolerance Principle

Once found, always fix, never leave. There is no such thing as a
"pre-existing" error that someone else will handle. Finding an error
makes you responsible for ensuring it gets fixed or tracked.

## Fix-Forward Workflow

When you encounter an error during any task, follow this sequence:

### Step 1: Fix It

Fix the error inline if possible. Most lint errors, test failures,
and build issues can be resolved immediately.

### Step 2: Track It

If the fix is out of scope (different module, different language,
requires architectural change), create a GitHub issue immediately:

```bash
gh issue create -R OWNER/REPO --title "fix: <description>" \
  --body "Found during <task>. Error: <details>. Location: <file:line>"
```

Never leave an error undocumented. The issue is the minimum
acceptable response.

### Step 3: Assess the System

After fixing or tracking, ask: **why didn't our rules prevent
this?** This is the most important step. Possible answers:

- **Missing rule**: No pattern covers this error type. Create a
  DevKit issue to add one.
- **Rule exists but wasn't enforced**: The rule is advisory, not
  mandatory. Create a DevKit issue to strengthen enforcement.
- **Rule exists but agent ignored it**: The rule needs to be in a
  higher-priority location (subagent checklist, CLAUDE.md, or
  core principles).
- **New error category**: This is a novel class of error. Document
  it in autolearn patterns and assess abstraction level.

### Step 4: Propagate

Determine the abstraction level of the learning:

| Scope | Action |
|-------|--------|
| Project-specific | Add to project rules |
| Stack-specific (Go, React) | Create DevKit issue for stack rules |
| Universal principle | Create DevKit issue for core rules |
| Template-worthy | Create DevKit issue for project templates |

## Forbidden Practices

These are never acceptable, regardless of context:

- Classifying errors as "pre-existing" to avoid fixing them
- Marking work as complete when known errors remain
- Suppressing warnings without fixing the root cause
- Deferring fixes indefinitely without a tracking issue
- Blaming another agent, session, or developer for the error

## Cross-Project Error Discovery

When working in a project (e.g., Samverk) and finding a gap that
DevKit should address:

1. **Do NOT** edit DevKit files directly from the project context
2. **Do** create a GitHub issue in the DevKit repo:
   `gh issue create -R HerbHall/devkit --title "..." --body "..."`
3. Include: what was found, where, why current rules didn't prevent
   it, and a proposed fix
4. The fix gets implemented when actively working in DevKit context

Symlinks provide READ access to DevKit rules. Writing flows through
issues, not direct file edits.
