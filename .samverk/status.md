---
phase: execution
updated: 2026-03-15T23:00:00Z
updated_by: claude-code
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- Symlinked rules loaded by all Claude Code sessions via ~/.claude/
- 21 skills, 7 agents, 11 rules files, 128 active patterns (AP: 67, KG: 61)
- SessionStart hook for context injection
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)

## In Flight

(none)

## Queued

- Synapset deep migration -- evaluate replacing rules file reads with `search_memory` calls (semantic > keyword matching). Current: dual-store (rules files + Synapset)

## Recently Completed

- **v2.4.0 release** -- autonomous autolearn routing (PR #322)
- Autolearn batch ingest: 15 issues -> 14 KG + 3 AP + 1 WP entries (PR #329)
- Rules compaction: KG 44k->35k (90->60), AP 38k->35k (77->67) (PR #331)
- Synapset integration verified working (3 pools, dual-store operational)
- v2.3.0: Synapset backend, MCP research, cross-ref verification

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server, DevKit is primary consumer
- **Samverk** (github:HerbHall/samverk) — Project lifecycle manager

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed — do not ask the user to explain project state
