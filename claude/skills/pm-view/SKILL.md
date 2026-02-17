---
name: pm-view
description: Bird's-eye project management view across SubNetree and HomeLab. Weekly reviews, sprint planning, roadmap revision, and cross-project decision recording.
---

<essential_principles>

**Purpose**
This skill provides a unified project management view across both SubNetree (development) and HomeLab (research). It loads summary-level context from all coordination files and supports planning activities that span both projects.

**Context Loading**
Read all 5 coordination files at invocation:
- `D:/DevSpace/.coordination/status.md`
- `D:/DevSpace/.coordination/research-needs.md`
- `D:/DevSpace/.coordination/research-findings.md`
- `D:/DevSpace/.coordination/decisions.md`
- `D:/DevSpace/.coordination/priorities.md`

**PM Principles**
1. **Unified view.** Both projects are one initiative with different workstreams.
2. **Evidence-based priorities.** Ranking decisions cite research findings or user feedback.
3. **Lightweight process.** No ceremonies, no overhead. Just clear priorities and decisions.
4. **Record decisions.** Cross-project decisions get D-NNN entries for future reference.

</essential_principles>

<intake>
What would you like to do?

1. **Weekly review** -- Review both projects, update priorities for coming week
2. **Sprint planning** -- Plan next sprint across both projects
3. **Roadmap revision** -- Incorporate research findings into SubNetree roadmap
4. **Decision needed** -- Record a cross-project decision (D-NNN)

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "weekly", "review", "week" | workflows/weekly-review.md |
| 2, "sprint", "plan", "planning", "next" | workflows/sprint-planning.md |
| 3, "roadmap", "revision", "incorporate", "findings" | Read research-findings.md unprocessed entries, present how each might affect SubNetree roadmap, ask user for decisions, update priorities.md |
| 4, "decision", "decide", "D-NNN", "record" | Read decisions.md, determine next D-NNN number, ask user for: context, decision, evidence, impact. Write entry and commit. |

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>
- Read, Edit, Write: For coordination files at `D:/DevSpace/.coordination/`
- Bash: `gh` CLI (issues, releases), `git` commands
- Glob, Grep: For searching coordination and project files
</tool_restrictions>
