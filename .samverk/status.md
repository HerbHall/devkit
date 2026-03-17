---
phase: execution
updated: 2026-03-17T06:00:00Z
updated_by: claude-code
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- Symlinked rules loaded by all Claude Code sessions via ~/.claude/
- 23 skills, 7 agents, 11 rules files, 133 active patterns (AP: 67, KG: 66)
- 3 Claude Code hooks (SessionStart, SessionStop, SubagentVerify) + 3 git hooks (pre-push, pre-commit, commit-msg)
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)

## In Flight

(none)

## Queued

(none)

## Recently Completed

- **Hook expansion Phase 1-2**: SessionStop, SubagentVerify, commit/push reminder, pre-commit, commit-msg (PRs #365-#369)
- Cross-client Claude configuration guide (PR #358)
- KG#135 fix: OAuth not required for Custom Connectors (PR #357)
- Synapset skill with structured retrieval guide (PR #356)
- Autolearn ingests: trivy cleanup, Gitea merge API, Ollama gotchas, SQLite PRAGMA (PRs #347-#355)
- Metrics: HTML dashboard, Synapset tracking, weekly GH Action, conformance persistence (PRs #338-#352)
- Synapset batch-ingest sync (PR #339) -- closes #333
- Rules compaction: KG 44k->35k, AP 38k->35k (PR #331)
- Autolearn batch ingest: 15 issues -> 14 KG + 3 AP + 1 WP entries (PR #329)
- **v2.4.0 release** -- autonomous autolearn routing (PR #322)

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server, DevKit is primary consumer
- **Samverk** (github:HerbHall/samverk) — Project lifecycle manager

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed — do not ask the user to explain project state
