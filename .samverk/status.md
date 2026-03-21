---
phase: execution
updated: 2026-03-21T18:00:00Z
updated_by: claude-code
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- Symlinked rules loaded by all Claude Code sessions via ~/.claude/ (pointing to dev copy at D:\DevSpace\devkit\)
- `~/.devkit-stable/` worktree exists on `stable` branch — ready for symlink migration
- 27 skills, 7 agents, 11 rules files, 136 active patterns (AP: 71 entries up to AP#143; KG: 52 entries up to KG#174)
- 3 Claude Code hooks (SessionStart, SessionStop, SubagentVerify) + 3 git hooks (pre-push, pre-commit, commit-msg)
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)
- **Samverk dispatcher STOPPED** (2026-03-21) -- stopped to prevent file conflicts during restructuring.
  Restart: `ssh root@192.168.1.162` then run `samverk dispatch` with original flags (check process history).

## In Flight

- **PR #494** (feature/devkit-zone-infrastructure) -- OPEN on GitHub. Contains:
  - ADR-0018: DevKit Zone convention + project family structure
  - `tool-registry.json`: centralized tool version registry (initial versions, not yet wired to templates)
  - `.devkit-family.json` files for all 6 families: Toolkit, Samverk, Personal, Games, Unity, Websites
  - VS Code workspace files updated for all moved projects

## DevSpace Structure (as of 2026-03-21)

```text
D:\DevSpace\
├── devkit\                  ← TEMP at root; moves to Toolkit\ after sync.ps1 -LinkStable
├── Toolkit\samverk\         ← Samverk app (was D:\DevSpace\Samverk\)
├── Toolkit\Synapset\        ← MCP memory server (was D:\DevSpace\Synapset\)
├── Samverk\SubNetree\       ← network monitoring platform
├── Samverk\RunNotes\
├── Samverk\Runbooks\
├── Samverk\DockPulse\
├── Samverk\PacketDeck\
├── Websites\herbhall.net\   ← moved from D:\Websites\
├── Personal\DigitalRain\
├── Personal\IPScan\
├── Personal\CLI-Play\
├── Personal\ClaudeTokenStats\
├── Personal\claude-sync\
├── Games\Timberborn-Mods\   ← moved from D:\Timberborn-Mods\
└── Unity\mccrl21\           ← moved from D:\UnityDev\mccrl21\
```

D:\ root is now clean: bots\, Websites\, Timberborn-Mods\, UnityDev\ all removed.

## Queued (do in order)

1. **Wave 4: devkit move to Toolkit/** (fresh session, do first)
   - Run `pwsh D:\DevSpace\devkit\setup\sync.ps1 -LinkStable` to redirect ~/.claude/ to ~/.devkit-stable/
   - Then `mv D:/DevSpace/devkit D:/DevSpace/Toolkit/devkit`
   - Verify ~/.claude/ symlinks still resolve correctly

2. **Rules compaction** -- known-gotchas.md ~42k, autolearn-patterns.md ~41k (both above 40k threshold)
   - Run `/rules-compact` before next pattern ingest

3. **Ingest issues #476, #477, #478** (after compaction)
   - #476: Tauri 2 API gotchas → KG#176
   - #477: Tauri 2 multi-window label routing → AP#144
   - #478: Recharts 3 Tooltip formatter → KG#177

4. **Version management tooling** (new major feature, see ADR-0019 to be written)
   - `project-templates/src/` tokenized templates
   - `scripts/Invoke-VersionUpdate.ps1` (Render/Bump/Rollback/Propagate modes)
   - `scripts/check-registry-drift.py` + CI validation job
   - Conformance check #21 (tool version drift)
   - Propagate updated versions to all projects

5. **Restart Samverk dispatcher** after PR #494 merges and devkit move completes

## Recently Completed

- **DevSpace restructuring** (2026-03-21): Full project family infrastructure implemented.
  All 12 projects moved into correct families. 6 family folders created with .devkit-family.json.
  VS Code workspace files updated. D:\ root cleaned up (PR #494, in progress).
- **20-issue batch ingest** (2026-03-20): KG#171-174, AP#140-143 + extensions (PRs #464, #467)
- **Rules compaction** (2026-03-17): KG 63->52, AP 72->66 entries (PRs #471)
- **v2.7.0 release** (2026-03-17): AP#133-135, KG#157-159 ingested

## Related Projects

- **Synapset** (gitea:samverk-admin/synapset) — Vector memory MCP server; now at D:\DevSpace\Toolkit\Synapset\
- **Samverk** (gitea:samverk/samverk) — Project lifecycle manager; now at D:\DevSpace\Toolkit\samverk\

## Start Here (Cold Start Protocol)

1. Read this file
2. Check .samverk/project.yaml for lifecycle context
3. Read open issues if relevant to the task
4. Proceed -- do not ask the user to explain project state
