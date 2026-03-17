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
- 23 skills, 7 agents, 11 rules files, 121 active patterns (AP: 67, KG: 54)
- 3 Claude Code hooks (SessionStart, SessionStop, SubagentVerify) + 3 git hooks (pre-push, pre-commit, commit-msg)
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)

## In Flight

(none)

## Queued

(none)

## Recently Completed

- **v2.5.0 release** (2026-03-17): Synapset-backed compaction, conformance check #20, archive recovery, hook expansion
- **Synapset-backed compaction**: New archive architecture -- tombstone + Synapset ID (PRs #372-#380)
- Legacy archive backfill: 51 entries stored in Synapset (SYN#515-565), archives converted to tombstone format
- Release-please permissions fix: enabled PR creation, synced manifest to v2.4.0 (PR #382)
- **Hook expansion Phase 1-2**: SessionStop, SubagentVerify, commit/push reminder, pre-commit, commit-msg (PRs #365-#369)
- **v2.4.0 release** -- autonomous autolearn routing (PR #322)

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server, DevKit is primary consumer
- **Samverk** (github:HerbHall/samverk) — Project lifecycle manager

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed — do not ask the user to explain project state
