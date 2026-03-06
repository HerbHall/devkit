# Extending DevKit

How to add new skills, agents, rules, profiles, and templates to DevKit.

## Adding a Skill

Skills are invokable workflows triggered with `/skill-name` in Claude Code.

### File structure

```text
claude/skills/{name}/
├── SKILL.md              # Entry point with YAML frontmatter and routing table
└── workflows/
    ├── action-one.md     # Workflow file for route 1
    └── action-two.md     # Workflow file for route 2
```

### Steps

1. Create the skill directory: `claude/skills/{name}/`
2. Create `SKILL.md` with YAML frontmatter defining the skill's description and instructions
3. Create workflow files in `workflows/` for each routing target
4. Update `setup/legacy/verify.sh` to include the new skill name in the verification list
5. Update the skill count in `README.md` (currently 19 skills)

### SKILL.md format

The frontmatter must include a `description` field. The body contains a routing table that maps user intents to workflow files:

```markdown
---
description: Short description of what this skill does
---

# Skill Name

Brief overview of the skill's purpose.

## Routes

| When the user wants to... | Workflow |
|---------------------------|----------|
| Do action one | workflows/action-one.md |
| Do action two | workflows/action-two.md |
```

### Validation

CI validates that all workflow files referenced in SKILL.md routing tables actually exist on disk. Missing files cause lint failures.

## Adding an Agent

Agents are reusable prompt templates for specialized tasks (code review, security analysis, plan review).

### Steps

1. Create `claude/agents/{name}.md`
2. Include clear instructions for the agent's role, scope, and output format
3. Reference the agent from skills or documentation as needed

### Agent format

Agent files are plain markdown with structured instructions. They typically include:

- **Role**: What the agent does
- **Scope**: What files or context the agent receives
- **Output format**: How findings are reported (severity levels, verdict, etc.)
- **Checklist items**: Specific things to check

## Adding a Rule Pattern

Rules are auto-loaded into every Claude Code session. They live in `claude/rules/`.

### Rule files

| File | Content | Governance |
|------|---------|------------|
| `core-principles.md` | Immutable development principles | Tier 0: human PR only |
| `error-policy.md` | Fix-forward error handling | Tier 0: human PR only |
| `workflow-preferences.md` | User workflow conventions | Tier 1: DevKit issue required |
| `review-policy.md` | Independent review requirements | Tier 1: DevKit issue required |
| `autolearn-patterns.md` | Discovered patterns and fixes | Tier 2: autolearn can add |
| `known-gotchas.md` | Platform quirks and workarounds | Tier 2: autolearn can add |
| `subagent-ci-checklist.md` | CI checklists for subagents | Tier 1: DevKit issue required |
| `markdown-style.md` | Markdown formatting conventions | Tier 1: DevKit issue required |
| `compaction-recovery.md` | Context compaction guidelines | Tier 1: DevKit issue required |
| `agent-team-coordination.md` | Multi-agent coordination rules | Tier 1: DevKit issue required |

### Adding a Tier 2 entry

For `autolearn-patterns.md` or `known-gotchas.md`:

1. Add entries sequentially numbered (next available number)
2. Include required metadata fields:
   - **Added**: date (YYYY-MM-DD)
   - **Source**: project where discovered
   - **Status**: `active`, `superseded-by-{ref}`, or `deprecated`
3. Include the pattern structure: Category, Context, Fix, and Example
4. Cross-reference related entries with **See also** links

### Deprecating a rule

When a rule is no longer relevant:

1. Set `Status: deprecated` on the entry
2. Move the entry to `claude/rules/archive/autolearn-patterns.md`
3. The archive directory is not loaded into sessions, reducing context usage

## Adding a Profile

Profiles define stack-specific tooling for project types (Go, React, Rust, etc.).

### Steps

1. Create `profiles/{name}.md` with YAML frontmatter
2. Follow the schema defined in [PROFILES.md](PROFILES.md)
3. Include: `name`, `version`, `description`, `requires`, `winget`, `manual`, `vscode-extensions`, `claude-skills`
4. The markdown body provides context for when to use the profile and known gotchas

## Adding a Project Template

Project templates are starter files copied into new projects during scaffolding.

### Steps

1. Add the template file to `project-templates/`
2. Use `UPPERCASE_WITH_UNDERSCORES` for placeholder values (not angle brackets, which trigger MD033)
3. Ensure the file passes relevant linting (markdownlint for `.md`, JSON validation for `.json`)
4. Document the template's purpose in `README.md` if it appears in the Templates table

### Current templates

Templates cover CI workflows, community health files, lint configs, Makefiles, gitignore files, and release automation. See the full list in `project-templates/`.

## Rule Governance Tiers

DevKit uses three governance tiers to control how rules can be modified:

| Tier | Files | Who Can Modify | Process |
|------|-------|----------------|---------|
| **0 - Immutable** | `core-principles.md`, `error-policy.md` | Humans only | Dedicated PR with justification |
| **1 - Governed** | Most rule files | DevKit maintainers | DevKit issue required |
| **2 - Learned** | `autolearn-patterns.md`, `known-gotchas.md` | Autolearn system | Validation pipeline, periodic review |

No agent can modify Tier 0 or Tier 1 rules. Tier 2 entries go through a 5-stage validation pipeline before being written (evidence check, core principle alignment, best practices review, conflict check, risk classification).

## Next Steps

- [Getting Started](getting-started.md) -- initial setup
- [Migration Guide](migration-guide.md) -- adopt DevKit in existing projects
- [Troubleshooting](troubleshooting.md) -- common issues
