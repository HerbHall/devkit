---
name: coordination-sync
description: Sync coordination files between SubNetree and HomeLab. Updates status, scans for new findings and needs, checks for stale data. Replaces the deleted PowerShell sync script.
---

<essential_principles>

**Purpose**
This skill synchronizes the cross-project coordination hub at `D:/DevSpace/.coordination/` with current state from both SubNetree (development) and HomeLab (research). It replaces the deleted `scripts/sync-subnetree.ps1`.

**Data Sources**
- SubNetree: `gh` CLI (releases, issues, PRs), `git log` (recent commits)
- HomeLab: `D:/DevSpace/research/HomeLab/` (analysis files, tracking docs)
- Coordination hub: `D:/DevSpace/.coordination/` (5 markdown files)

**Sync Direction**
- **To coordination**: Pull latest state from both projects into hub files
- **From coordination**: Hub files are the source of truth for cross-project awareness
- **Bidirectional**: Changes flow through the hub, never directly between projects

</essential_principles>

<intake>
What kind of sync would you like to perform?

1. **Full sync** -- Update all coordination files from both projects
2. **Status only** -- Quick refresh of status.md with latest releases, commits, issues
3. **Scan findings** -- Check HomeLab for new analyses that should become RF-NNN entries
4. **Scan needs** -- Review SubNetree issues for potential research questions
5. **Stale check** -- Identify outdated coordination data that needs updating

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "full", "all", "everything", "complete" | workflows/full-sync.md |
| 2, "status", "quick", "refresh" | workflows/status-update.md |
| 3, "findings", "scan findings", "analyses", "RF" | workflows/scan-findings.md |
| 4, "needs", "scan needs", "issues", "RN" | workflows/scan-needs.md |
| 5, "stale", "check", "outdated", "fresh" | workflows/stale-check.md |

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>
- Bash: `gh` CLI (releases, issues, PRs), `git log`, `git -C .coordination add/commit`
- Read, Edit, Write: For coordination files in `D:/DevSpace/.coordination/`
- Read: For HomeLab files in `D:/DevSpace/research/HomeLab/`
- Glob, Grep: For searching analysis files and tracking docs
</tool_restrictions>
