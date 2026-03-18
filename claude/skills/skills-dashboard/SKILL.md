---
name: skills-dashboard
description: Lists all available skills, their triggers, usage examples, and last-updated date. Provides a searchable, filterable dashboard for skill discovery and onboarding.
user_invocable: true
---

# Skills Dashboard

A meta-skill for discovering, browsing, and understanding all available skills in the system.

<essential_principles>

- **Discovery**: Lists all skills in `claude/skills/` and project-local `.claude/skills/` folders.
- **Documentation**: Shows name, description, triggers, usage examples, and last-updated date for each skill.
- **Search/Filter**: Allows filtering by keyword, category, or user-invocable status.
- **Onboarding**: Provides links to authoring guide and skill template generator.
- **Health**: Flags skills missing skip/dismiss, frontmatter, or with broken workflow references (integrates with skill audit).

</essential_principles>

<intake>
What would you like to do?

1. **List all skills**
2. **Search/filter skills**
3. **Show usage examples**
4. **Show skills missing best practices**
5. **Open skill authoring guide**
6. **Create new skill from template**

Type a number, keyword, or **skip** to dismiss.
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "list", "all", "skills" | workflows/list-all.md |
| 2, "search", "filter", "find" | workflows/search-filter.md |
| 3, "examples", "usage", "show examples" | workflows/usage-examples.md |
| 4, "missing", "audit", "health" | workflows/health-check.md |
| 5, "guide", "authoring", "help" | workflows/authoring-guide.md |
| 6, "create", "template", "new" | workflows/create-from-template.md |

If the user types **skip** or **dismiss**, confirm cancellation and end the skill.
If the input does not match, respond: "skills-dashboard was triggered but your input didn't match a workflow. Options: 1-6. Type skip to dismiss."

**After reading the workflow, follow it exactly.**
</routing>

<workflows_index>

- list-all.md: List all skills with summary info
- search-filter.md: Search/filter skills by keyword/category
- usage-examples.md: Show usage examples for a skill
- health-check.md: List skills missing best practices
- authoring-guide.md: Open the skill authoring guide
- create-from-template.md: Launch skill template generator

</workflows_index>
