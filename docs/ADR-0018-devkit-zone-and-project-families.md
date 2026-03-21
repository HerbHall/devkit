# ADR-0018: DevKit Zone and Project Family Structure

## Status

Accepted

## Date

2026-03-21

## Context

As the DevSpace workspace grew from 3 projects to 12+, the flat root-level
structure became hard to navigate. All projects lived at the same depth with
no grouping by type, purpose, or management tier. Additionally:

- No mechanism existed to auto-discover which projects are DevKit-managed
- Compliance tooling (conformance audit, version propagation) required a
  hardcoded project list
- Tool version pins were scattered across projects with no central registry
  and no way to propagate updates consistently
- Three "toolkit-tier" tools (devkit, Synapset, Samverk) were co-mingled
  with product applications and personal projects
- No separation existed between the live running instances of toolkit tools
  and their development working copies (dogfooding problem)

## Decision

### 1. The DevKit Zone

Any git repository that lives inside a folder named `DevSpace` (case-insensitive)
is considered **DevKit-managed** by convention. The exact drive letter and
parent path are machine-specific; the folder name `DevSpace` is the universal
identifier.

The resolved absolute path for the current machine is stored in
`~/.devkit-config.json` as `devspacePath`, set automatically during bootstrap
by walking up from the devkit clone looking for a `DevSpace` parent. No manual
configuration is required on new machines.

Project discovery at runtime (`Get-DevKitProjects`) scans `devspacePath` for
git repositories up to depth 2, excluding directories containing `.devkit-ignore`.

### 2. Project Family Structure

Projects are organized into family folders (max depth 2 from DevSpace root).
Each family folder contains a `.devkit-family.json` declaring the default
compliance tier for its children.

```text
DevSpace/
├── devkit/            ← depth-1 special: root governance layer
│
├── Toolkit/           ← meta-tools: devkit, Synapset, Samverk
│   ├── .devkit-family.json  (tier: toolkit)
│   ├── devkit/        ← development copy (live = ~/.devkit-stable/ worktree)
│   ├── Synapset/      ← MCP memory server
│   └── samverk/       ← project lifecycle manager
│
├── Samverk/           ← Samverk-managed product projects
│   ├── .devkit-family.json  (tier: full, managed_by: samverk)
│   ├── SubNetree/
│   ├── RunNotes/
│   ├── Runbooks/
│   ├── DockPulse/
│   └── PacketDeck/
│
├── Websites/          ← web and hosting projects
│   ├── .devkit-family.json  (tier: web)
│   └── herbhall.net/
│
├── Personal/          ← standalone projects not in the Samverk workflow
│   ├── .devkit-family.json  (tier: full or minimal, per project)
│   ├── DigitalRain/
│   ├── IPScan/
│   └── CLI-Play/
│
└── Games/             ← game mods
    ├── .devkit-family.json  (tier: minimal)
    └── Timberborn-Mods/
```

**Why devkit stays at depth-1 during the transition period:** devkit is the
root governance layer. Its symlinks into `~/.claude/` must remain stable during
the Toolkit/ family setup. Once the stable-branch worktree is established,
devkit moves into `Toolkit/devkit/` as its development copy.

### 3. Compliance Tiers

Each project belongs to a compliance tier that determines which conformance
checks apply:

| Tier | Projects | Checks |
|------|----------|--------|
| `toolkit` | devkit, Synapset, Samverk | Self-governing; custom per-tool rules |
| `full` | Samverk-managed apps, Personal code projects | All conformance checks |
| `web` | Websites | Markdown, deployment CI; no language linters |
| `extension` | Docker Desktop extensions | Extension-specific checks |
| `minimal` | Research, game mods, utilities | Markdown + git hygiene only |

### 4. Project Enrollment: `.devkit.json`

Every git repository in the DevKit Zone must have a `.devkit.json` at its
root. This file is created by `setup/new-project.ps1` and serves as:

- The enrollment marker (presence = DevKit-managed)
- Type declaration for compliance profile selection
- Orphan detection anchor (missing = unregistered project)

```json
{
  "project": "herbhall.net",
  "tier": "web",
  "profile": "cloudflare-worker",
  "family": "Websites",
  "managed_by": null,
  "created": "2026-03-21",
  "devkit_version": "2.8.0"
}
```

Projects without `.devkit.json` are flagged by the SessionStart hook and
conformance audit as orphans.

### 5. Dev/Live Separation for Toolkit-Tier Projects (Dogfooding Pattern)

Toolkit-tier projects (devkit, Synapset, Samverk) use their own tools to
build themselves, creating a risk of breaking the live running instance during
development.

**Solution:** symlinks point to a `stable` branch git worktree, not the
development working copy.

For devkit specifically:

- Development: `DevSpace/Toolkit/devkit/` on the `main` or feature branch
- Live instance: `~/.devkit-stable/` git worktree tracking the `stable` branch
- `~/.claude/` symlinks point into `~/.devkit-stable/claude/`
- Promotion: merge dev changes to `stable` branch -> worktree auto-updates

Promotion command: `git -C DevSpace/Toolkit/devkit merge stable && git push stable`
or via `/devkit-sync promote` skill route.

The same pattern applies to Synapset and Samverk: CI/CD deploys to production
from the `stable` branch; development happens on `main`/feature branches. The
running service is never the working directory.

### 6. Automated Orphan Prevention

Three-layer defense against uncompliant project creation:

1. **Intercept at creation:** `New-DevKitProject` PowerShell function (shell
   alias `mkproject`) replaces `mkdir + git init` as the muscle memory.
   Calls `setup/new-project.ps1` internally.

2. **Detect at session start:** `SessionStart.sh` extended to scan DevSpace
   (depth 2) for git repos missing `.devkit.json`. Injects a warning into the
   session if orphans are found.

3. **Periodic audit:** Conformance audit check #22 (orphan detection) scans
   the full DevKit Zone and reports unregistered repos.

### 7. Tool Version Registry

A `tool-registry.json` at the devkit root serves as the single source of truth
for all tool version pins across all projects. See ADR-0019 for details on the
registry schema, template tokenization, and propagation workflow.

## Consequences

**Positive:**

- DevSpace root drops from 12+ folders to 5 clearly-categorized families
- Project discovery is convention-based (no hardcoded lists)
- Compliance tier controls which checks apply per project type
- Toolkit tools are protected from dogfooding instability
- Orphan detection catches projects created outside the standard workflow

**Negative:**

- All existing projects require migration (folder moves + `.devkit.json` retrofit)
- VS Code workspace files must be updated after folder moves
- The `stable` branch worktree adds a step to the devkit promotion workflow
- Discovery depth of 2 means projects cannot be nested deeper than
  `DevSpace/Family/Project/`

**Neutral:**

- Samverk-managed metadata (`.samverk/project.yaml`) is unaffected by folder
  location — Samverk management is orthogonal to folder hierarchy
- GitHub/Gitea remote URLs are unchanged by local folder moves

## Alternatives Considered

**Flat structure with metadata only:** Keep all projects at depth-1, use
`.devkit.json` for categorization. Rejected because the root folder becomes
unnavigable as projects grow past 15.

**Type-based folders (apps/, tools/, websites/):** Generic names without
clear ownership. Rejected in favor of Samverk-aligned naming that reflects
actual workflow relationships.

**Samverk/ folder for all Samverk-managed projects including devkit:**
devkit is special — it is the governance layer for everything below it.
Putting it inside a family it manages creates a conceptual circular dependency.
devkit stays at depth-1 during the transition, then moves to `Toolkit/devkit/`
once the stable-branch worktree is established.
