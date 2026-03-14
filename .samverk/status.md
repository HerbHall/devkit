---
phase: execution
updated: 2026-03-09T22:00:00Z
updated_by: claude-chat
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- Symlinked rules loaded by all Claude Code sessions via ~/.claude/
- 21 skills, 7 agents, 10 rules files, 170+ patterns
- SessionStart hook for context injection
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)

## In Flight

(none)

## Queued

- Synapset consumer integration -- when Synapset MVP ships, migrate autolearn backend from flat markdown to Synapset vector memory (189 entries). See Synapset project for implementation status.

## Recently Completed

- Gitea forge support in new-project.ps1 -- -Gitea switch, forge-aware scaffolding, gitea-labels.json, ci-go-gitea.yml (PR #285)
- MCP template ollama-local entry (PR #284)
- credentials.ps1 StrictMode fix KG#114 (PR #283)
- AP#124 human-label audit, KG#115 TS phantom field drift (PR #281)
- Samverk project overlay formalization (PR #282)

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server, DevKit is primary consumer
- **Samverk** (github:HerbHall/samverk) — Project lifecycle manager

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed — do not ask the user to explain project state
