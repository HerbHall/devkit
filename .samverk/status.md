---
phase: execution
updated: 2026-03-14T20:00:00Z
updated_by: claude-code
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- Symlinked rules loaded by all Claude Code sessions via ~/.claude/
- 21 skills, 7 agents, 11 rules files, 140 patterns (AP: 72, KG: 68)
- SessionStart hook for context injection
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)

## In Flight

(none)

## Queued

- Synapset consumer integration -- when Synapset MVP ships, migrate autolearn backend from flat markdown to Synapset vector memory (140 entries post-compaction). See Synapset project for implementation status.
- MCP lazy-loading gateway feasibility research (#293)

## Recently Completed

- Rules compaction: AP 42k->35k, KG 50k->30k (PR #295)
- Autolearn batch: 6 new entries from #287-#291 (PR #296)
- Tool selection guide added as rules file
- Stale README/CLAUDE.md pattern counts fixed (PR #286)
- Synapset status update (PR #294)
- Gitea forge support in new-project.ps1 (PR #285)

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server, DevKit is primary consumer
- **Samverk** (github:HerbHall/samverk) — Project lifecycle manager

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed — do not ask the user to explain project state
