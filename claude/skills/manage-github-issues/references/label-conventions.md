<label_conventions>

This defines the standard label categories for GitHub Issues. Project-specific label names
(modules, milestones) are defined in the project's `.claude/github-issues-config.md` file.

**Type Labels** (exactly one per issue)

| Label | Suggested Color | Use When |
|-------|----------------|----------|
| `feat` | `#0075CA` | New capability that doesn't exist yet |
| `fix` | `#D73A4A` | Something is broken or behaves incorrectly |
| `chore` | `#E4E669` | Build, CI, tooling, dependency updates, refactoring |
| `docs` | `#0075CA` | Documentation only |
| `test` | `#BFD4F2` | Adding or improving tests |
| `research` | `#7D5C2F` | Research and investigation |

**Priority Labels** (exactly one per issue)

| Label | Suggested Color | Meaning |
|-------|----------------|---------|
| `priority:critical` | `#B60205` | Blocks work streams; address immediately |
| `priority:high` | `#D93F0B` | Important; schedule next |
| `priority:normal` | `#0075CA` | Standard priority; schedule normally |
| `priority:low` | `#C2E0C6` | Nice to have; defer if time is tight |

**Area/Module Labels** (one or more per issue)

These are project-specific. Define them in `.claude/github-issues-config.md`.

Common naming conventions:

- `mod:{name}` -- for modular architectures (e.g., `mod:auth`, `mod:api`)
- `area:{name}` -- for area-based organization (e.g., `area:frontend`, `area:backend`)
- `component:{name}` -- for component-based projects (e.g., `component:sidebar`)

Each label should have a clear, non-overlapping scope.

**Milestone Labels** (exactly one per issue)

These are project-specific. Define them in `.claude/github-issues-config.md`.

Common naming conventions:

- `milestone:{N}` -- for milestone-based development (e.g., `milestone:1`, `milestone:2`)
- `sprint:{N}` -- for sprint-based development (e.g., `sprint:5`)
- `milestone:{name}` -- for named milestones (e.g., `milestone:mvp`)

Note: The word "phase" is reserved for Samverk lifecycle phases. Use `milestone:` for
release milestones in the base label set.

**Contributor Labels** (optional)

| Label | Meaning |
|-------|---------|
| `good-first-issue` | Suitable for new contributors |
| `help-wanted` | Actively seeking community help |

**Agent/Delegation Labels** (optional, applied during triage)

| Label | Suggested Color | Meaning |
|-------|----------------|---------|
| `agent:copilot` | `#1F6FEB` | Suitable for Copilot coding agent (assign via GitHub UI) |
| `agent:claude` | `#7C3AED` | Requires Claude Code subagent (deep context needed) |
| `agent:human` | `#E8EAED` | Requires human decision or design input |

**Status Labels** (optional, applied as needed)

| Label | Meaning |
|-------|---------|
| `blocked` | Cannot proceed; blocker described in comments |
| `question` | Needs clarification, decision, or design review |

**Samverk Overlay Labels**

Samverk-managed projects (projects with a `.samverk/` directory) have additional labels
applied from the Samverk overlay. These include agent types (`agent:orchestrator`,
`agent:dispatcher`, `agent:code-gen`, etc.), status workflow labels (`status:queued`,
`status:in-progress`, etc.), complexity routing labels, and lifecycle phase labels
(`phase:intake` through `phase:killed`).

The overlay labels are defined in the Samverk repository at `overlay/labels.json`. This
skill should recognize overlay labels when they exist on a project but should not create
or manage them -- the Samverk overlay application handles that.

</label_conventions>

<labeling_rules>

1. Every issue MUST have exactly one type label
2. Every issue SHOULD have a priority label (required for active work)
3. Every issue SHOULD have at least one milestone label (if the project uses them)
4. Every issue SHOULD have at least one area/module label (if the project uses them)
5. Status and contributor labels are applied as circumstances change
6. When creating issues via `gh issue create`, pass labels as comma-separated:
   `--label "feat,priority:normal,mod:auth,milestone:1"`

</labeling_rules>

<creating_labels>

To create labels that don't exist yet:

```bash
# Type labels (base set -- all projects)
gh label create "feat" --color "0075CA" --description "New feature or enhancement"
gh label create "fix" --color "D73A4A" --description "Bug fix"
gh label create "chore" --color "E4E669" --description "Maintenance, refactor, tooling"
gh label create "docs" --color "0075CA" --description "Documentation"
gh label create "test" --color "BFD4F2" --description "Tests and test infrastructure"
gh label create "research" --color "7D5C2F" --description "Research and investigation"

# Priority labels (base set -- all projects)
gh label create "priority:critical" --color "B60205" --description "Blocks work streams; address immediately"
gh label create "priority:high" --color "D93F0B" --description "Important; schedule next"
gh label create "priority:normal" --color "0075CA" --description "Standard priority"
gh label create "priority:low" --color "C2E0C6" --description "Nice to have; defer if tight"

# Agent/delegation labels (base set -- all projects)
gh label create "agent:copilot" --color "1F6FEB" --description "Suitable for Copilot coding agent"
gh label create "agent:claude" --color "7C3AED" --description "Requires Claude Code subagent"
gh label create "agent:human" --color "E8EAED" --description "Requires human decision"

# Milestone labels (project-specific -- customize these)
gh label create "milestone:1" --color "A2EEEF" --description "Milestone 1"

# Area/module labels (project-specific -- customize these)
gh label create "mod:example" --color "BFD4F2" --description "Example module"
```

For Samverk-managed projects, apply overlay labels from the Samverk overlay spec
using the devkit-sync apply-samverk workflow.

</creating_labels>
