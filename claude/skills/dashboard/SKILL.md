---
name: dashboard
description: Session control station. Displays project state, priorities, research findings, and provides numbered routing to all workflows. THE starting point for every session.
---

<essential_principles>

**Purpose**
This is the single entry point for all development and project management sessions. It replaces `/dev-mode` as the primary session starter. On every invocation, it reads coordination files, displays a unified status view, and presents numbered options for immediate action.

**Design Philosophy**
1. **Orientation first.** Show the user where things stand before asking what to do.
2. **Numbered routing.** Every action has a number. Type it and go.
3. **Stranger-friendly.** Someone seeing this for the first time should understand the project state and know how to proceed.
4. **Minimal context loading.** Read coordination files (summaries only). Never load full requirement docs -- those are for subagents.

**Session Start Protocol (AUTOMATIC)**
Before presenting the numbered menu, ALWAYS execute the session start workflow.
Follow `workflows/session-start.md` exactly. This reads all coordination files and renders the control station display.

**Context Files (read at invocation)**

| File | What to Read | Why |
| ---- | ------------ | --- |
| `D:/DevSpace/.coordination/research-findings.md` | `## Unprocessed` section | Count and summarize new findings |
| `D:/DevSpace/.coordination/research-needs.md` | `## Open` section | Count open research requests |
| `D:/DevSpace/.coordination/priorities.md` | `## This Week` section | Extract numbered priorities |
| `D:/DevSpace/.coordination/status.md` | Header metadata + SubNetree section | Version, issue count, staleness |

**Live Data (fetched at invocation)**

```bash
git -C /d/DevSpace/SubNetree log --oneline -3
gh issue list -R HerbHall/subnetree --state open --json number --jq 'length'
```

</essential_principles>

<session_start>
**This runs AUTOMATICALLY before showing the menu. Do not skip.**

Follow `workflows/session-start.md` exactly.
</session_start>

<intake>
After the control station display renders, the user sees numbered options.

**This Week's Priorities** (dynamic, from priorities.md):

Numbers 1-3: SubNetree dev priorities
Numbers 4-6: HomeLab research priorities

**Quick Actions** (static):

7. Full sync (`/coordination-sync 1`)
8. Sprint planning (`/pm-view 2`)
9. Weekly review (`/pm-view 1`)
10. File research request
11. Update dev status (end-of-session)
12. Stale check (`/coordination-sync 5`)

**Reference** (static):

13. Skill quick reference card
14. Project workflow guide

```text
Pick a number (or describe what you need):
```

**Wait for response before proceeding.**

**Post-Workflow Menu (IMPORTANT)**
After ANY workflow completes, ALWAYS re-display the compact menu so the user doesn't have to scroll back. Use markdown for readability:

```markdown
### Menu

| Dev | Research |
|-----|----------|
| **1** {dev_priority_1} | **4** {research_priority_1} |
| **2** {dev_priority_2} | **5** {research_priority_2} |
| **3** {dev_priority_3} | **6** {research_priority_3} |

**7** Sync | **8** Sprint | **9** Review | **10** Research need | **11** End session | **12** Stale check | **0** Refresh

Pick a number (or describe what you need):
```

Cache the priority labels from the initial session-start render so you can re-display them without re-reading files.
</intake>

<routing>
| Response | Action |
| -------- | ------ |
| 0, "menu", "options", "list" | Re-display the full control station (re-run session-start workflow) |
| 1, 2, or 3 | workflows/pick-priority.md (SubNetree dev priority by index) |
| 4 | workflows/process-findings.md (walk through unprocessed RF-NNN) |
| 5 or 6 | Route to `/research-mode` with the corresponding RN-NNN from priorities |
| 7, "sync", "full sync" | Invoke `/coordination-sync 1` |
| 8, "sprint", "planning" | Invoke `/pm-view 2` |
| 9, "review", "weekly" | Invoke `/pm-view 1` |
| 10, "research request", "file", "RN" | Follow workflow at `C:/Users/Herb/.claude/skills/dev-mode/workflows/add-research-need.md` |
| 11, "status", "update", "end", "done" | Follow workflow at `C:/Users/Herb/.claude/skills/dev-mode/workflows/session-end.md` |
| 12, "stale", "check" | Invoke `/coordination-sync 5` |
| 13, "qrc", "reference", "commands" | workflows/quick-reference.md (display QRC) |
| 14, "workflow", "guide", "how" | workflows/quick-reference.md (display workflow guide) |
| Free-text description | Interpret intent, suggest the best numbered option, or proceed directly |

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>
- Read, Edit, Write: For coordination files at `D:/DevSpace/.coordination/`
- Bash: `git` commands, `gh` commands for GitHub operations
- Glob, Grep: For searching coordination and project files
- All standard development tools remain available for coding work after a priority is selected
</tool_restrictions>
