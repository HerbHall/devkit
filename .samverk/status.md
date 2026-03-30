---
phase: execution
updated: 2026-03-21T22:00:00Z
updated_by: claude-code
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- `~/.claude/` symlinks pointing to `~/.devkit-stable/` (stable worktree, branch: stable)
  `-LinkStable` ran 2026-03-21 -- dev copy at D:\DevSpace\devkit\ no longer serves live rules
- `~/.devkit-stable/` worktree on `stable` branch — current live rules source
- 27 skills, 7 agents, 11 rules files, 95 active patterns (AP: 58 entries last AP#143; KG: 37 entries last KG#177)
- 3 Claude Code hooks (SessionStart, SessionStop, SubagentVerify) + 3 git hooks (pre-push, pre-commit, commit-msg)
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)
- **Samverk dispatcher STOPPED** (2026-03-21) -- stopped to prevent file conflicts during restructuring.
  Restart: `ssh root@192.168.1.162` then run `samverk dispatch` with original flags (check process history).

## In Flight

- **PR #494** (feature/devkit-zone-infrastructure) -- OPEN on GitHub. Contains:
  - ADR-0018: DevKit Zone convention + project family structure
  - ADR-0019: Centralized tool version registry
  - `tool-registry.json`: centralized tool version registry (wired to src/ templates via tokens)
  - `scripts/Invoke-VersionUpdate.ps1`: 5-mode version update script
  - `scripts/check-registry-drift.py`: CI drift detector (in lint.yml)
  - Conformance check #21: Tool Version Currency
  - `.devkit-family.json` files for all 6 families: Toolkit, Samverk, Personal, Games, Unity, Websites
  - VS Code workspace files updated for all moved projects
  - KG#176, KG#177, AP#144: Tauri 2 and Recharts patterns ingested
  - Rules compaction: KG 51→37, AP 68→58 (24 entries archived to Synapset IDs 728-751)

## DevSpace Structure (as of 2026-03-21)

```text
D:\DevSpace\
├── devkit\                  ← TEMP at root; move to Toolkit\ AFTER this CC session exits
│                              (Windows blocks mv while CC session has CWD = devkit)
│                              Command: Move-Item D:\DevSpace\devkit D:\DevSpace\Toolkit\devkit
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

1. **Wave 4: devkit move to Toolkit/** (NEXT SESSION, do first thing)
   - symlinks ALREADY pointing to stable worktree (-LinkStable done 2026-03-21)
   - In a terminal outside CC: `Move-Item D:\DevSpace\devkit D:\DevSpace\Toolkit\devkit`
   - Reopen CC from D:\DevSpace\Toolkit\devkit
   - Update ~/.devkit-config.json devspacePath if needed (or add devkitPath field)

2. **Merge PR #494** -- merge the zone infrastructure PR after move completes
   - After merge, promote stable: `pwsh setup/sync.ps1 -Promote`
   - Restart Samverk dispatcher

3. **Propagate tool versions to managed projects** (operational, not tooling)
   - `pwsh scripts/Invoke-VersionUpdate.ps1 -Mode Propagate -Projects all -DryRun`
   - Review and apply updates project by project

## Recently Completed

- **PR #494 prep complete** (2026-03-21): All deliverables committed to feature branch.
  Zone infrastructure, ADR-0018 + ADR-0019, version management tooling, rules compaction.
- **Rules compaction** (2026-03-21): KG 46.8k→36.9k (-21%), AP 42.8k→37.0k (-14%).
  24 entries archived to Synapset pool:devkit (IDs 728-751). Both files under 40k.
- **Ingest #476, #477, #478** (2026-03-21): KG#176 (Tauri 2 API), KG#177 (Recharts),
  AP#144 (Tauri 2 multi-window) -- all in commit f63f1e8 on feature branch.
- **sync.ps1 -LinkStable** (2026-03-21): 50 symlinks redirected to ~/.devkit-stable/.
  Dev copy no longer serves live rules. Safe to move devkit after CC session exits.
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
