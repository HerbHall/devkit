---
phase: execution
updated: 2026-03-09T15:00:00Z
updated_by: claude-chat
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- Symlinked rules loaded by all Claude Code sessions via ~/.claude/
- 21 skills, 7 agents, 8 rules files, 135+ patterns
- SessionStart hook for context injection
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)

## In Flight

- Synapset integration research (OpenBrain-inspired vector memory for autolearn)
- Credential management integration (Set-DevkitSecrets.ps1 patched for vault)

## Queued

- Update MCP template for vault-based credential references
- Review setup/lib/credentials.ps1 compatibility with vault
- docs/credentials.md for new vault workflow
- Synapset consumer integration (autolearn → vector memory)

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server, DevKit is primary consumer
- **Samverk** (github:HerbHall/samverk) — Project lifecycle manager

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed — do not ask the user to explain project state
