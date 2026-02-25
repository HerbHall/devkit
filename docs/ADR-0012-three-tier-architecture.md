# ADR-0012: Three-Tier Configuration Architecture

## Status

Proposed

## Date

2026-02-25

## Context

ADR-0011 established symlink-based synchronization between a DevKit clone and `~/.claude/`. This works well for a single machine, but the system now needs to support:

- **Multiple workstations** (Windows, Linux, macOS) each with different tools, paths, and OS capabilities
- **Multiple projects** (GitHub and Gitea repositories) each with their own build commands, architecture, and project-specific patterns
- **Bidirectional sync** where patterns discovered in any project can flow back to DevKit, and DevKit updates reach all machines and projects

The current `.sync-manifest.json` divides files into "shared" (symlinked) and "local_only_patterns" (never synced). This is an implicit two-tier model. But there are actually three distinct scopes:

1. **Universal patterns** that apply everywhere (methodology, skills, rules, agents)
2. **Machine-specific config** that varies by workstation (OS, paths, tools, credentials)
3. **Project-specific config** that varies by project (CLAUDE.md, local skills, CI setup)

Without formal tiers, machine config leaks into universal files (hardcoded paths in rules), project patterns stay trapped in one project (no promotion path), and new machines require manual configuration that could be automated.

## Decision

Formalize a **three-tier configuration architecture** with explicit boundaries, precedence rules, and a promotion path for patterns to move between tiers.

### Tier Definitions

| Tier | Scope | Lifecycle | Storage |
|------|-------|-----------|---------|
| **Universal** | All machines, all projects | Git-tracked in DevKit repo | `claude/` directory, symlinked to `~/.claude/` |
| **Machine** | One workstation | Local files, never committed to DevKit | `~/.claude/*.local.md`, `~/.devkit-config.json` |
| **Project** | One repository | Committed to the project's own repo | Project's `CLAUDE.md`, `.claude/` directory |

### Precedence

**Project > Machine > Universal** (most-specific wins).

Claude Code's native loading supports this naturally:

1. It loads `~/.claude/CLAUDE.md` (universal, via symlink to DevKit)
2. It loads `~/.claude/rules/*.md` (universal rules, via symlinks) AND `~/.claude/rules/*.local.md` (machine rules, real files)
3. It loads `<project>/CLAUDE.md` (project tier)

Project-level instructions override machine-level, which override universal. No custom merge logic is needed -- Claude Code's built-in file loading provides the precedence.

### Universal Tier

Everything in the DevKit repo that gets symlinked to `~/.claude/`:

```text
claude/
├── CLAUDE.md              # Global instructions
├── claude-functions.sh    # Shell helpers
├── settings.template.json # Settings template
├── rules/                 # 8 shared pattern files
├── skills/                # 18 skill directories
├── agents/                # 7 agent templates
└── hooks/                 # SessionStart.sh
```

Also universal but NOT symlinked (reference material, browsable in the repo only):

```text
claude/AGENT-WORKFLOW-GUIDE.md    # Agent usage documentation
claude/AUTOMATION-SETUP.md        # Automation setup guide
claude/SKILLS-ECOSYSTEM.md        # Skills ecosystem overview
profiles/                         # Stack profile definitions (Kit 2)
project-templates/                # Scaffolding templates (Kit 3)
devspace/                         # Workspace shared configs (.editorconfig, VS Code fragments)
machine/                          # Tool manifests (winget.json, vscode-extensions.txt)
docs/                             # ADRs and guides
METHODOLOGY.md                    # Development process
```

Documentation files in `claude/` (e.g., `AGENT-WORKFLOW-GUIDE.md`) are intentionally excluded from symlink manifest. They are reference guides for DevKit contributors, not Claude Code runtime config. Symlinked files must be loadable by Claude Code; `.md` files in `~/.claude/` root are not auto-loaded (only `CLAUDE.md` and files in `rules/` are).

**Rule**: No file in the universal tier may contain hardcoded paths, machine names, usernames, or OS-specific logic. Use `$HOME`, `$DEVKIT_ROOT`, or config lookups instead.

### Machine Tier

Files that exist on one machine and are never committed to DevKit:

| File | Location | Purpose |
|------|----------|---------|
| `.devkit-config.json` | `$HOME/` | Machine identity and paths |
| `CLAUDE.local.md` | `~/.claude/` | Machine-specific instructions |
| `*.local.md` | `~/.claude/rules/` | Machine-specific patterns |
| `settings.local.json` | `~/.claude/` | Claude Code local settings |
| `.machine-id` | `~/.claude/` | Machine identifier for sync branches |
| `.credentials*` | `~/.claude/` | Authentication tokens |

**`.devkit-config.json` extended schema:**

```json
{
  "version": 2,
  "machineId": "desktop-main",
  "devspacePath": "D:\\DevSpace",
  "claudeHome": "C:\\Users\\herb\\.claude",
  "os": "windows",
  "forge": {
    "primary": "github",
    "giteaUrl": null
  },
  "installedProfiles": ["go-web"],
  "lastSync": "2026-02-25T10:00:00Z"
}
```

The schema uses camelCase to match the existing v1 field `devspacePath`. New fields over v1:

- `version` -- schema version for migration
- `machineId` -- moved from `.machine-id` file (single source of truth)
- `claudeHome` -- explicit path for OS portability (`~/.claude/` on Windows/macOS, `~/.config/claude/` on Linux with XDG)
- `os` -- detected platform (`windows`, `linux`, `darwin`)
- `forge` -- primary forge type and optional Gitea instance URL
- `installedProfiles` -- which Kit 2 profiles have been applied
- `lastSync` -- timestamp of last successful sync operation

**Rule**: Machine-tier files are NEVER committed to DevKit. The `.sync-manifest.json` `local_only_patterns` enforces this.

### Project Tier

Configuration that lives in each project's repository:

| File | Location | Purpose |
|------|----------|---------|
| `CLAUDE.md` | Project root | Build commands, architecture, project-specific instructions |
| `.claude/settings.local.json` | Project `.claude/` | Project-specific Claude Code settings |
| `.claude/rules/*.md` | Project `.claude/rules/` | Project-specific patterns (if any) |
| `.claude/skills/*/` | Project `.claude/skills/` | Project-specific skills (if any) |

DevKit does NOT store project-tier files. Projects own their own configuration. DevKit provides:

1. **Templates** (`project-templates/`) to scaffold new project configs
2. **A promotion path** (#86) to move project-discovered patterns into the universal tier
3. **A registry** (#85) to track which projects on a machine consume DevKit

**Rule**: Project-tier files are committed to the project's repo, not to DevKit. DevKit only stores templates and metadata.

### Tier Boundary Enforcement

The `.sync-manifest.json` is the enforcement mechanism. It defines three categories that map directly to tiers:

| Manifest Section (v2) | Tier | Sync Behavior |
|----------------------|------|---------------|
| `tiers.universal.*` (files, rules, skills, agents, hooks) | Universal | Symlinked to `~/.claude/` |
| `tiers.universal.reference` | Universal | NOT symlinked; repo-browsable reference material |
| `tiers.machine.local_only_patterns` | Machine | Never synced, never committed |
| `tiers.project.convention` | Project | Lives in project repo, not DevKit |

The v2 manifest replaces the v1 `shared` key with `tiers.universal`. `sync.ps1` normalizes v2 to a `.shared` property for backward compatibility with `Get-LinkPairs`.

### Pattern Promotion Flow

Patterns move upward through tiers via explicit user action:

```text
Project Tier                    Machine Tier                    Universal Tier
(project/.claude/rules/)  --->  (~/.claude/rules/*.local.md) ---> (devkit/claude/rules/*.md)
                           ^                                  ^
                           |                                  |
                      Manual copy                     /devkit-sync promote
                      or /reflect                     (issue #86)
```

- **Project -> Machine**: When `/reflect` captures a pattern during project work, it writes to the machine-tier `.local.md` file (already implemented)
- **Machine -> Universal**: The `/devkit-sync promote` command (#86) scans `.local.md` files, shows candidates, and appends selected entries to the universal rules file

Demotion (universal -> machine or machine -> project) is not automated. If a universal pattern is wrong, edit or remove it from the universal file directly.

### Migration from Current Layout

The current layout already matches this architecture. Migration is additive, not destructive:

| Change | Impact |
|--------|--------|
| Extend `.devkit-config.json` schema to v2 | `sync.ps1` reads `devspacePath` (matches v1); new fields (`claudeHome`, `os`, `forge`, etc.) reserved for future use |
| Add `tier` field to `.sync-manifest.json` entries | Informational; sync behavior unchanged |
| Move `.machine-id` into `.devkit-config.json` | Backward-compatible; both checked |
| Add `version` field to `.sync-manifest.json` | Enables future schema migrations |

No files are moved, renamed, or deleted. Existing symlinks continue to work. Existing `.local.md` files continue to load. The only breaking change would be a `.devkit-config.json` schema change, and that's handled via the `version` field with fallback.

## Alternatives Considered

### Separate directories per tier

Restructure DevKit into `universal/`, `machine/`, `project/` top-level directories.

**Rejected because:**

- Current `claude/` directory structure mirrors `~/.claude/` 1:1, making symlink creation trivial. Introducing a `universal/claude/` prefix would require all symlink logic to change.
- The existing layout already separates tiers implicitly (git-tracked = universal, `.local.md` = machine, project repo = project). Renaming directories adds churn without functional benefit.
- Machine-tier files don't live in DevKit at all, so a `machine/` directory would be empty in the repo.

### Per-machine branches instead of `.local.md` files

Store machine-tier config on `machine/<id>` branches in the DevKit repo.

**Rejected because:**

- Machine config contains paths, credentials references, and hardware info that shouldn't be in a shared repo (even on a branch).
- Branch proliferation makes the repo harder to navigate.
- The `.local.md` pattern is simpler: files that aren't in git don't need git management.

### Tier enforcement via CI

Add CI checks that validate no machine-specific content (paths, usernames) appears in universal-tier files.

**Deferred (not rejected):**

- Useful as a guardrail but not required for the architecture to work.
- Can be added later as a lint rule in `.github/workflows/lint.yml`.
- Pattern: `grep -r "C:\\\\Users\|/home/" claude/` should return nothing.

## Consequences

### Positive

- **Explicit boundaries**: Each file has a defined tier. Contributors know where new patterns belong.
- **Cross-platform ready**: `claude_home` and `os` fields in `.devkit-config.json` enable OS-specific path resolution without hardcoding.
- **Multi-forge ready**: `forge` field enables future GitHub/Gitea abstraction (#84).
- **Promotion path**: Patterns discovered in projects can flow to universal via a defined workflow, not ad-hoc copying.
- **Non-destructive migration**: Current setups continue working. New fields are additive.
- **Precedence is free**: Claude Code's native file loading provides project > machine > universal precedence without custom code.

### Negative

- **Schema versioning overhead**: `.devkit-config.json` and `.sync-manifest.json` now have versions that must be maintained.
- **No automatic demotion**: If a universal pattern is later found to be machine-specific, it must be manually moved. This is rare enough to not warrant automation.
- **Project tier is invisible to DevKit**: DevKit has no visibility into project-tier configs unless the project registry (#85) is implemented. Until then, promotion is purely manual.
- **`.local.md` naming convention is soft**: Nothing prevents a user from creating `rules/my-stuff.md` (no `.local.` infix) as a machine-tier file. It would be symlinked as universal on the next `sync.ps1 -Link` run. Documentation and convention are the only guardrails.

## References

- [ADR-0011: DevKit Synchronization Architecture](ADR-0011-sync-architecture.md)
- [Issue #81: Three-tier architecture design](https://github.com/HerbHall/devkit/issues/81)
- [Issue #85: Project registry](https://github.com/HerbHall/devkit/issues/85)
- [Issue #86: devkit promote command](https://github.com/HerbHall/devkit/issues/86)
