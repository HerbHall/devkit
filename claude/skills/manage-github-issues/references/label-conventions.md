<label_conventions>

This defines the standard label categories for GitHub Issues. Project-specific label names
(modules, phases) are defined in the project's `.claude/github-issues-config.md` file.

**Type Labels** (exactly one per issue)

| Label | Suggested Color | Use When |
|-------|----------------|----------|
| `feature` | `#0E8A16` | New capability that doesn't exist yet |
| `bug` | `#D73A4A` | Something is broken or behaves incorrectly |
| `enhancement` | `#A2EEEF` | Improving an existing feature |
| `refactor` | `#D4C5F9` | Code restructuring with no behavior change |
| `docs` | `#0075CA` | Documentation only |
| `test` | `#BFD4F2` | Adding or improving tests |
| `chore` | `#EDEDED` | Build, CI, tooling, dependency updates |

**Priority Labels** (exactly one per issue)

| Label | Suggested Color | Meaning |
|-------|----------------|---------|
| `P0-critical` | `#B60205` | Blocks current phase/milestone; fix immediately |
| `P1-high` | `#D93F0B` | Important for current work; resolve this sprint/cycle |
| `P2-medium` | `#FBCA04` | Should complete in current phase; schedule normally |
| `P3-low` | `#0E8A16` | Nice to have; defer if time is tight |

**Area/Module Labels** (one or more per issue)

These are project-specific. Define them in `.claude/github-issues-config.md`.

Common naming conventions:

- `mod:{name}` -- for modular architectures (e.g., `mod:auth`, `mod:api`)
- `area:{name}` -- for area-based organization (e.g., `area:frontend`, `area:backend`)
- `component:{name}` -- for component-based projects (e.g., `component:sidebar`)

Each label should have a clear, non-overlapping scope.

**Phase/Milestone Labels** (exactly one per issue)

These are project-specific. Define them in `.claude/github-issues-config.md`.

Common naming conventions:

- `phase:{N}` -- for phased development (e.g., `phase:1`, `phase:2`)
- `sprint:{N}` -- for sprint-based development (e.g., `sprint:5`)
- `milestone:{name}` -- for milestone-based planning (e.g., `milestone:mvp`)

**Contributor Labels** (optional)

| Label | Meaning |
|-------|---------|
| `good first issue` | Suitable for new contributors |
| `help wanted` | Actively seeking community help |
| `mentor available` | Maintainer will guide the contributor |

**Status Labels** (optional, applied as needed)

| Label | Meaning |
|-------|---------|
| `blocked` | Cannot proceed; blocker described in comments |
| `needs-design` | Requires architectural decision before implementation |
| `needs-review` | Implementation done, awaiting review |
| `wontfix` | Intentionally not fixing; close with explanation |

</label_conventions>

<labeling_rules>

1. Every issue MUST have exactly one type label
2. Every issue SHOULD have a priority label (required for active work)
3. Every issue SHOULD have at least one phase/milestone label (if the project uses them)
4. Every issue SHOULD have at least one area/module label (if the project uses them)
5. Status and contributor labels are applied as circumstances change
6. When creating issues via `gh issue create`, pass labels as comma-separated:
   `--label "feature,P2-medium,mod:auth,phase:1"`

</labeling_rules>

<creating_labels>

To create labels that don't exist yet:

```bash
# Type labels (universal)
gh label create "feature" --color "0E8A16" --description "New capability"
gh label create "bug" --color "D73A4A" --description "Something is broken"
gh label create "enhancement" --color "A2EEEF" --description "Improving existing feature"
gh label create "refactor" --color "D4C5F9" --description "Code restructuring"
gh label create "docs" --color "0075CA" --description "Documentation only"
gh label create "test" --color "BFD4F2" --description "Adding or improving tests"
gh label create "chore" --color "EDEDED" --description "Build, CI, tooling"

# Priority labels (universal)
gh label create "P0-critical" --color "B60205" --description "Blocks current phase; fix immediately"
gh label create "P1-high" --color "D93F0B" --description "Important; resolve this sprint"
gh label create "P2-medium" --color "FBCA04" --description "Should complete this phase"
gh label create "P3-low" --color "0E8A16" --description "Nice to have; defer if tight"

# Area/module labels (project-specific -- customize these)
gh label create "mod:example" --color "BFD4F2" --description "Example module"

# Phase labels (project-specific -- customize these)
gh label create "phase:1" --color "0E8A16" --description "Phase 1"
```

</creating_labels>
