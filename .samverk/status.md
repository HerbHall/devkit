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
- 21 skills, 7 agents, 11 rules files, 150 patterns (AP: 74, KG: 76)
- SessionStart hook for context injection
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)

## In Flight

(none)

## Queued

- Synapset deep migration -- evaluate replacing rules file reads with `search_memory` calls (semantic > keyword matching). Current: dual-store (rules files + Synapset)

## Recently Completed

- **v2.3.0 release** -- rules compaction, Synapset integration, MCP research, 16 new patterns
- Rules compaction: AP 42k->35k, KG 50k->30k (PR #295)
- Synapset integration: dual-store autolearn, [SYNAPSET] checklist block (PR #313)
- MCP lazy-loading research + feature request anthropics/claude-code#34471 (PR #305)
- Autolearn batches: 16 new entries from 11 issues (PRs #296, #308)
- Tool selection guide, cross-ref verification in /rules-compact (PRs #300, #311)
- 71 stale branches cleaned, doc counts fixed

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server, DevKit is primary consumer
- **Samverk** (github:HerbHall/samverk) — Project lifecycle manager

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed — do not ask the user to explain project state
