---
phase: execution
updated: 2026-03-17T22:00:00Z
updated_by: claude-code
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- Symlinked rules loaded by all Claude Code sessions via ~/.claude/
- 25 skills, 7 agents, 11 rules files, 123 active patterns (AP: 68, KG: 55)
- 3 Claude Code hooks (SessionStart, SessionStop, SubagentVerify) + 3 git hooks (pre-push, pre-commit, commit-msg)
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)

## In Flight

None.

## Queued

- **Issue ingestion** (#418, #419, #422-#426): 7 autolearn patterns from Samverk/Synapset sessions — in this PR

## Recently Completed

- **KG#156 correction** (2026-03-17): CI validator scope (PR #420)
- **KG#162 ingestion** (2026-03-17): GitHub issues-disabled API quirk (PR #417)
- **Rules compaction** (2026-03-17): KG 63->52 entries, AP 72->66 entries (39.8k/38.6k -> 35.1k/35.9k), Synapset SYN#595-602
- **KG#160-161 ingestion** (2026-03-17): Gitea tunnel auth + Samverk MCP init gating
- **v2.7.0 release** (2026-03-17): AP#133-135, KG#157-159 ingested from Samverk/Synapset sessions
- **v2.6.0 release** (2026-03-17): Samverk MCP routing, samverk-dispatch skill, errcheck/MCP hang fixes
- **v2.5.0 release** (2026-03-17): Synapset-backed compaction, conformance check #20, archive recovery, hook expansion
- **Synapset-backed compaction**: New archive architecture -- tombstone + Synapset ID (PRs #372-#380)
- Legacy archive backfill: 51 entries stored in Synapset (SYN#515-565), archives converted to tombstone format
- Release-please permissions fix: enabled PR creation, synced manifest to v2.4.0 (PR #382)
- **Hook expansion Phase 1-2**: SessionStop, SubagentVerify, commit/push reminder, pre-commit, commit-msg (PRs #365-#369)
- **v2.4.0 release** -- autonomous autolearn routing (PR #322)

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server, DevKit is primary consumer
- **Samverk** (gitea:samverk/samverk) — Project lifecycle manager

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed — do not ask the user to explain project state
