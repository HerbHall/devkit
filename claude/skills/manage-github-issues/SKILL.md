---
name: manage-github-issues
description: Reviews project roadmaps and requirements to generate, audit, and triage GitHub Issues. Keeps any project on track by syncing planning docs with actionable issues. Use when creating issues for a phase or milestone, auditing existing issues, or triaging and prioritizing open work.
---

<essential_principles>

**Issue Quality Criteria**
Every issue must be:

- **Specific**: Clear title and description that a developer can act on without additional context
- **Scoped**: One deliverable per issue; break epics into sub-tasks
- **Labeled**: Type, priority, area/module, and phase/milestone labels applied
- **Linked**: References the relevant planning or requirements doc section
- **Testable**: Acceptance criteria that define "done"

**Context Conservation**

- Read ONLY the specific docs needed for the current task
- Use the project config file (`.claude/github-issues-config.md`) to find which docs to read
- Never read multiple requirements/planning files in a single workflow run

**Duplicate Prevention**

- Always fetch existing issues with `gh issue list` before creating new ones
- Match by title keywords and labels to detect duplicates
- Present batch to user for review before creating any issues

**Label Categories (Summary)**
See `references/label-conventions.md` for full details.

| Category | Purpose | Examples |
|----------|---------|----------|
| Type | What kind of work | `feature`, `bug`, `enhancement`, `refactor`, `docs`, `test`, `chore` |
| Priority | How urgent | `P0-critical`, `P1-high`, `P2-medium`, `P3-low` |
| Area/Module | Which component | Project-specific (e.g., `mod:api`, `area:frontend`) |
| Phase/Milestone | When to deliver | Project-specific (e.g., `phase:1`, `sprint:3`) |

**GitHub CLI Usage**
All GitHub operations use the `gh` CLI. Key commands:

- `gh issue list --label LABEL --state STATE --limit N`
- `gh issue create --title TITLE --body BODY --label L1,L2 --milestone M`
- `gh issue edit NUMBER --add-label LABEL --milestone M`
- `gh issue view NUMBER`
- `gh label list --json name,description,color`

</essential_principles>

<project_config>

**Project Configuration Discovery**

This skill adapts to any GitHub project. Configuration is discovered in this order:

1. **Config file** (preferred): Read `.claude/github-issues-config.md` in the project root. This file defines project-specific phases, modules/areas, roadmap paths, and label conventions.

2. **CLAUDE.md hints**: Read the project's `CLAUDE.md` for documentation structure, architecture, and conventions.

3. **GitHub label discovery**: Run `gh label list --json name,description,color --limit 200` to discover existing labels.

4. **Ask the user**: If no config file exists and the project structure is unclear, ask the user about:
   - How the project organizes work (phases, sprints, milestones)
   - Where the roadmap or planning docs live
   - What module/area labels to use
   - What milestone naming convention to follow

**Config File Format**

The optional `.claude/github-issues-config.md` file should contain:

- Project name and description
- Phase/milestone definitions with descriptions
- Module/area labels with scopes
- Roadmap file path(s)
- Requirements/docs directory path
- Phase-to-documentation mapping
- Milestone naming conventions

If no config file exists, the skill will work by discovering project structure dynamically and confirming with the user.

</project_config>

<intake>
What would you like to do?

1. **Generate issues for a phase/milestone** - Read the roadmap, find incomplete items, create GitHub Issues
2. **Audit existing issues** - Compare open issues against the roadmap, find gaps and problems
3. **Triage and prioritize** - Review open issues, suggest priorities, update labels and milestones

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "generate", "create", "phase", "milestone" | workflows/generate-phase-issues.md |
| 2, "audit", "review", "check", "gaps" | workflows/audit-issues.md |
| 3, "triage", "prioritize", "sort" | workflows/triage-and-prioritize.md |

**After reading the workflow, follow it exactly.**
</routing>

<reference_index>
All domain knowledge in references/:

**Quality Standards**:

- issue-quality-standards.md (writing effective issues, best practices)
- label-conventions.md (label categories, labeling rules, conventions)
</reference_index>

<workflows_index>

| Workflow | Purpose |
|----------|---------|
| generate-phase-issues.md | Read roadmap phase, create missing GitHub Issues |
| audit-issues.md | Compare open issues against roadmap, find gaps |
| triage-and-prioritize.md | Review untriaged issues, suggest and apply priorities |

</workflows_index>

<templates_index>

| Template | Purpose |
|----------|---------|
| feature-issue.md | Feature or enhancement issue body |
| bug-issue.md | Bug report issue body |
| epic-issue.md | Epic/parent issue with task checklist |

</templates_index>

<error_handling>

**When `gh` commands fail:**

- Check authentication: `gh auth status`
- Check repo context: `gh repo view` (must be in a git repo with a GitHub remote)
- If rate-limited: wait and retry, or reduce `--limit` on list commands
- If label/milestone doesn't exist: create it first with `gh label create` or `gh api`
- If issue creation fails: report the error, skip that issue, continue with the batch
- **Never silently drop errors** -- always report failures to the user

**When labels don't exist yet:**
Create missing labels before issue creation:

```bash
gh label create "{LABEL_NAME}" --color "{HEX_COLOR}" --description "{DESCRIPTION}"
```

**When milestones don't exist yet:**

```bash
gh api repos/{owner}/{repo}/milestones -f title="{MILESTONE_NAME}" -f state=open
```

</error_handling>

<skill_coordination>

**Related skills and when to use them:**

| Skill | When to Use Instead |
|-------|-------------------|
| `/create-plan` | Before generating issues -- plan the implementation first, then create issues from the plan |
| `/check-todos` | For in-session task tracking; this skill is for persistent GitHub Issues |
| `/requirements_generator` | When requirements need updating before issues can be generated |
| `/ask-me-questions` | When unclear what phase or scope to generate issues for |

**Typical workflow sequence:**

1. `/requirements_generator` -- ensure requirements are current
2. `/manage-github-issues` (generate) -- create issues from requirements
3. `/manage-github-issues` (triage) -- prioritize the backlog
4. `/create-plan` -- plan implementation of the highest-priority issues
5. `/manage-github-issues` (audit) -- periodic check that issues stay on track

</skill_coordination>

<success_criteria>
A successful workflow run produces:

- [ ] Project configuration discovered (config file, CLAUDE.md, or user input)
- [ ] Relevant planning/requirements docs read for context
- [ ] Existing issues fetched and checked for duplicates
- [ ] Issues generated with proper title, body, labels, and milestone
- [ ] Batch presented to user for review before creation
- [ ] Issues created (or updates applied) via `gh` CLI
- [ ] Summary of actions taken reported to user
- [ ] Any errors encountered reported clearly
</success_criteria>
