---
phase: execution
updated: 2026-03-21T22:30:00Z
updated_by: claude-code
managed_by: samverk
---

# DevKit — Current State

## Phase

Active maintenance and execution. AI tooling methodology, Claude Code configuration toolkit.
**Now formally managed by Samverk** (formalized 2026-03-09, retroactive lifecycle phases 1-5).

## What Is Running

- `~/.claude/` symlinks pointing to `~/.devkit-stable/` (stable worktree, branch: stable)
  50 valid symlinks confirmed; stable at ff10d8b (PR #494 merge commit, 2026-03-21)
- `~/.devkit-stable/` worktree on `stable` branch — current live rules source
- Dev copy at `D:\DevSpace\Toolkit\devkit\` on `main` branch (clean, up to date)
- 27 skills, 7 agents, 10 rules files, 95 active patterns (KG: 37 entries last KG#175; AP: 58 entries last AP#143)
- 3 Claude Code hooks (SessionStart, SessionStop, SubagentVerify) + 3 git hooks (pre-push, pre-commit, commit-msg)
- Credentials migrated to PowerShell SecretStore vault (HomeLabVault)
- **Samverk dispatcher STOPPED** (2026-03-21) -- stopped to prevent file conflicts during restructuring.
  Restart: `ssh root@192.168.1.162` then run `samverk dispatch` with original flags (check process history).

## In Flight

None. PR #494 merged and promoted to stable. Dev on main, stable at ff10d8b.

## VS Code Workspace

- `D:\DevSpace\devkit.code-workspace` -- created 2026-03-21 (was missing, caused session handoff errors)
  Open via: `code D:\DevSpace\devkit.code-workspace`

## DevSpace Structure (as of 2026-03-21)

```text
D:\DevSpace\
├── devkit.code-workspace    ← Open this to work on DevKit
├── Toolkit\devkit\          ← DevKit dev copy (branch: main)
├── Toolkit\samverk\         ← Samverk app
├── Toolkit\Synapset\        ← MCP memory server
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

1. **Restart Samverk dispatcher** (NEXT)
   - `ssh root@192.168.1.162` and run `samverk dispatch` with original flags
   - Check process history on server for flags used previously

2. **Propagate tool versions to managed projects** (operational, not tooling)
   - `pwsh scripts/Invoke-VersionUpdate.ps1 -Mode Propagate -Projects all -DryRun`
   - Review and apply updates project by project

## Recently Completed

- **PR #494 merge + stable promote** (2026-03-21): Zone infrastructure merged to main (ff10d8b).
  Fixed broken stable worktree `.git` pointer (old path D:\DevSpace\devkit -> D:\DevSpace\Toolkit\devkit).
  Reset stable to origin/main. Created `D:\DevSpace\devkit.code-workspace`. Dev switched to main.
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
