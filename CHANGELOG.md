# Changelog

## [2.5.0](https://github.com/HerbHall/devkit/compare/v2.4.0...v2.5.0) (2026-03-17)


### Features

* add archive recovery workflow and Synapset conformance check ([#379](https://github.com/HerbHall/devkit/issues/379)) ([96b5956](https://github.com/HerbHall/devkit/commit/96b5956de7d82168ace77819e7d7f7b760343a21))
* add synapset skill with structured retrieval guide ([#356](https://github.com/HerbHall/devkit/issues/356)) ([1c3be95](https://github.com/HerbHall/devkit/commit/1c3be9534e8faf7e5a5dae212128480a073051da))
* **autolearn:** ingest [#330](https://github.com/HerbHall/devkit/issues/330) + update status.md ([#332](https://github.com/HerbHall/devkit/issues/332)) ([daade3c](https://github.com/HerbHall/devkit/commit/daade3cff5888e79b084cda6e8f8726aa0820592))
* **autolearn:** ingest [#343](https://github.com/HerbHall/devkit/issues/343) (SQLite PRAGMA + Gitea assign gotchas) ([#347](https://github.com/HerbHall/devkit/issues/347)) ([ac4c5f8](https://github.com/HerbHall/devkit/commit/ac4c5f80a193468557f4e9d06e5999414f7934b1))
* **autolearn:** ingest [#348](https://github.com/HerbHall/devkit/issues/348) + [#349](https://github.com/HerbHall/devkit/issues/349) (Ollama gotchas) ([#351](https://github.com/HerbHall/devkit/issues/351)) ([19d2915](https://github.com/HerbHall/devkit/commit/19d29156dd31ffa5ecbe21f3365d32fef8f26d92))
* **autolearn:** ingest [#354](https://github.com/HerbHall/devkit/issues/354) (trivy cleanup + Gitea merge API) ([#355](https://github.com/HerbHall/devkit/issues/355)) ([25c8e66](https://github.com/HerbHall/devkit/commit/25c8e661aeddf686837013559c38e44f9387da69))
* **autolearn:** ingest 15 issues as rules entries ([#309](https://github.com/HerbHall/devkit/issues/309)-[#328](https://github.com/HerbHall/devkit/issues/328)) ([#329](https://github.com/HerbHall/devkit/issues/329)) ([dab9c64](https://github.com/HerbHall/devkit/commit/dab9c6440439a7fc030cc63b71680b424357b812))
* **autolearn:** sync batch-ingested entries to Synapset pool ([#333](https://github.com/HerbHall/devkit/issues/333)) ([#339](https://github.com/HerbHall/devkit/issues/339)) ([5c784e3](https://github.com/HerbHall/devkit/commit/5c784e31602c6df74486301d1ff09d9ad376b066))
* **hooks:** add commit/push verification reminder hook ([#369](https://github.com/HerbHall/devkit/issues/369)) ([e05e2c7](https://github.com/HerbHall/devkit/commit/e05e2c73ad71e1adb25089fbe3fce16dbe87fda5))
* **hooks:** add pre-commit and commit-msg git hook templates ([#366](https://github.com/HerbHall/devkit/issues/366)) ([919fe75](https://github.com/HerbHall/devkit/commit/919fe75552a33fbc03fdf7af7e6b237e227ce0a8))
* **hooks:** add SessionStop hook for session-end hygiene ([#365](https://github.com/HerbHall/devkit/issues/365)) ([16e7115](https://github.com/HerbHall/devkit/commit/16e7115b988b0a66fcd97dc073a6d958438b0018))
* **hooks:** add SubagentStop verification hook ([#368](https://github.com/HerbHall/devkit/issues/368)) ([1b75c04](https://github.com/HerbHall/devkit/commit/1b75c04bf02542eca6a8508a8e75401104e9df18))
* **metrics:** add conformance score persistence and autolearn velocity ([#336](https://github.com/HerbHall/devkit/issues/336)) ([#341](https://github.com/HerbHall/devkit/issues/341)) ([18d6eb4](https://github.com/HerbHall/devkit/commit/18d6eb496f46277369b67841ab032e65eabdad44))
* **metrics:** add effectiveness measurement skill and data model ([#334](https://github.com/HerbHall/devkit/issues/334)) ([#338](https://github.com/HerbHall/devkit/issues/338)) ([5b99d1e](https://github.com/HerbHall/devkit/commit/5b99d1ea56994be92744f38d2984ad3557dbbe90))
* **metrics:** add visual HTML dashboard generator ([#346](https://github.com/HerbHall/devkit/issues/346)) ([3a058f7](https://github.com/HerbHall/devkit/commit/3a058f7a5e281097632484629004fe5f475783fc))
* **metrics:** add weekly PR metrics collection GH Action ([#337](https://github.com/HerbHall/devkit/issues/337)) ([#342](https://github.com/HerbHall/devkit/issues/342)) ([1b51616](https://github.com/HerbHall/devkit/commit/1b51616605f897c2ba83649cbfd50ce86b40678d))
* **metrics:** enhance dashboard with unified theme ([#350](https://github.com/HerbHall/devkit/issues/350)) ([#352](https://github.com/HerbHall/devkit/issues/352)) ([ad80efa](https://github.com/HerbHall/devkit/commit/ad80efa3d4d8fba7bf092b541d4649ad1dab82a0))
* **metrics:** session instrumentation and pattern tracking ([#340](https://github.com/HerbHall/devkit/issues/340)) ([c5981dd](https://github.com/HerbHall/devkit/commit/c5981dd00642b5dfa0a40882c0a8763630c4df5d))
* **metrics:** track Synapset pattern applications across all projects ([#345](https://github.com/HerbHall/devkit/issues/345)) ([2554388](https://github.com/HerbHall/devkit/commit/255438804b2221029c7d4fa873831e8e1fb466b5))
* Synapset-backed compaction architecture ([#376](https://github.com/HerbHall/devkit/issues/376)) ([ae2948a](https://github.com/HerbHall/devkit/commit/ae2948ab485b648ab35a7d4a66f2df67e95f445f))


### Bug Fixes

* collect-pr-metrics.sh Python fallback for MSYS/Windows ([#344](https://github.com/HerbHall/devkit/issues/344)) ([39e32f2](https://github.com/HerbHall/devkit/commit/39e32f2a3cbd8f789eec9bdc42c0251f2f2269d5))
* **docs:** correct pattern counts and skill list drift ([#353](https://github.com/HerbHall/devkit/issues/353)) ([5888070](https://github.com/HerbHall/devkit/commit/588807057e7475415cdea7aa3a586cac77821c6e))
* **docs:** correct pattern counts and status drift ([#359](https://github.com/HerbHall/devkit/issues/359)) ([b39018a](https://github.com/HerbHall/devkit/commit/b39018aee611cc1ec0d326a62b4bf976beb44282))
* **rules:** correct KG[#135](https://github.com/HerbHall/devkit/issues/135) -- OAuth not required for Custom Connectors ([#357](https://github.com/HerbHall/devkit/issues/357)) ([113e5a2](https://github.com/HerbHall/devkit/commit/113e5a2e3d2f5ceb7fcb09f592cc3fec579c7440))
* sync release-please manifest to v2.4.0 ([#382](https://github.com/HerbHall/devkit/issues/382)) ([29520df](https://github.com/HerbHall/devkit/commit/29520df61f1f75b7b14fc24656500bc5dbff005d))

## v2.4.0 -- 2026-03-15

Autonomous autolearn -- removes manual menu and runs learnings capture automatically.

### Changed

- **Autolearn autonomous routing** (PR #322): Removed blocking 5-option intake menu from `/autolearn`. Skill now auto-selects the appropriate workflow (quick-reflect, session-review, update-knowledge, skill-improvement, audit-rules) based on session context analysis. Supports explicit args: `/autolearn review`, `/autolearn audit`, etc.
- **Autolearn runs autonomously**: CLAUDE.md updated from "suggest the user run /autolearn" to "run /autolearn autonomously at task completion boundaries." No user intervention required.
- **Hook text updated**: UserPromptSubmit hook instructs autonomous execution instead of passive suggestions. Both template and live settings updated.
- **Stale doc references fixed**: `docs/hook-expansion-research.md` updated to reflect autonomous model

## v2.3.0 -- 2026-03-14

Rules compaction, Synapset integration, and MCP research.

### Added

- **Rules compaction** (PR #295): AP 42k->35k, KG 50k->30k -- archived 29 stale entries, consolidated 9 clusters, trimmed 27 entries
- **Synapset integration** (PR #313): Semantic vector memory backend for autolearn -- `store_memory`/`search_memory` in dual-store workflows, [SYNAPSET] checklist block, pool strategy documentation
- **Tool selection guide** (PR #300): New rules file `claude/rules/tool-selection-guide.md` -- proactive decision tree for GitHub, web research, file ops, Go dev, shell scripting, and knowledge tools
- **MCP lazy-loading research** (PR #305): Feasibility assessment for custom MCP gateway -- verdict: wait (ToolSearch provides ~85% context reduction). Feature request filed: anthropics/claude-code#34471
- **Cross-reference verification** (PR #311): Step 8 in `/rules-compact` skill catches stale AP/KG cross-references after archiving
- **Autolearn entries** (PRs #296, #308): 16 new patterns and gotchas from 11 issues -- worktree isolation (AP#127), go:embed cache (KG#125), Tailscale Funnel (KG#126), Cloudflare Email Routing (AP#126), sqlite-vec dimensions (KG#127), and more
- **Release standardization templates** (ADR-0015): release-please config, manifest, workflow, and git-cliff templates
- **Rules reconciliation** (PR #140): Imported 44 orphaned entries from local copies back to devkit
- **Rules drift detection** (PR #141): `devkit_drift_check()` in SessionStart.sh
- **Project settings enforcement** (PR #145): Three-layer mechanism for `.claude/settings.json`
- **Gitea forge support** (PR #285): `-Gitea` switch in new-project.ps1, forge-aware scaffolding

### Fixed

- **Stale doc counts** (PR #286): README and CLAUDE.md pattern counts updated
- **credentials.ps1 StrictMode** (PR #283): Removed Set-StrictMode from dot-sourced lib (KG#114)
- **sync.ps1 StrictMode crash** (PR #142): `PSObject.Properties.Match()` for safe property checks
- **sync.ps1 Read-Host null** (PR #144): Null guard for non-interactive mode

### Changed

- Rules files: 10 -> 11 (added tool-selection-guide.md)
- Pattern counts: 170+ -> 150 (post-compaction: AP 74, KG 76)
- Autolearn workflows now dual-store to MCP Memory + Synapset
- 71 stale remote branches cleaned up
- `/devkit-sync verify` checks `.claude/settings.json` presence

## v2.2.0 -- 2026-02-28

Rule lifecycle management for the autolearn system.

### Added

- **Rule lifecycle metadata format** (PR #126): ADR-0014 defines per-entry metadata (`**Added:**`, `**Source:**`, `**Status:**`, `**Last relevant:**`, `**See also:**`), deprecation states, and archive strategy
- **Archive directory** (PR #126): `claude/rules/archive/` for deprecated entries (not loaded into sessions, frees context tokens)
- **Frontmatter extensions** (PR #126): `entry_count` and `last_updated` fields in Tier 2 rules file frontmatter
- **Metadata PoC** (PR #127): 10 proof-of-concept entries annotated with lifecycle metadata (5 AP, 5 KG)
- **Duplicate resolution** (PR #127): AP#27 superseded by KG#17, archived; swagger cluster cross-referenced (5 entries)
- **Rules audit workflow** (PR #128): `/reflect` option 5 for health check -- parses entries, generates report, identifies stale/duplicate entries, proposes actions
- **Last-relevant tracking** (PR #128): `/reflect` quick and session workflows update `**Last relevant:**` timestamps on entries applied during the session

### Changed

- Autolearn-patterns entry count: 76 -> 75 (AP#27 archived)

## v2.1.0 -- 2026-02-28

Governance and quality gates for the autolearn system.

### Added

- **Tiered rule governance** (PR #117): `core-principles.md` (Tier 0, immutable) and `error-policy.md` (Tier 1, governed) rules files with YAML frontmatter tier metadata
- **SessionStart health checks** (PR #118): symlink integrity verification and CLAUDE.md detection at session start
- **Pre-commit verification** (PR #119): build/test/lint gates before commit in workflow preferences
- **Fix-forward workflow** (PR #120): error-policy.md with zero-tolerance fix-forward, replaces "pre-existing" classification
- **Template quality gates** (PR #121): CI scaffolding templates include lint and test verification steps
- **Autolearn scope-aware routing** (PR #122): in DevKit, write Tier 2 rules directly; in projects, write to MCP Memory and create DevKit issues for universal learnings
- **Rule validation pipeline** (PR #123): five-stage gate for proposed rules (dangerous pattern scan, core principles check, conflict check, risk classification, storage decision) in `references/validation-pipeline.md`
- **Propagation verification** (PR #124): `/devkit-sync verify` checks all active projects for DevKit update propagation via symlink health; SessionStart reports rule file changes after pull
- `/devkit-sync promote` subcommand for graduating local patterns to universal rules
- `/devkit-sync update` subcommand for version checking and upgrading

### Changed

- Autolearn workflows (`quick-reflect.md`, `session-review.md`) now include validation and scope assessment steps
- `update-knowledge.md` requires DevKit context (context guard rejects non-DevKit sessions)
- Rules file count increased from 8 to 10

## v2.0.0 -- 2026-02-25

v2.0 represents a major architectural shift from a bash-centric toolkit to a
cross-platform, multi-tier system with formal versioning.

### Added

- Three-tier settings architecture (ADR-0012): User > DevSpace > Project cascade
- Dual-language scripting strategy (ADR-0013): PowerShell primary, bash legacy
- Cross-platform path resolution via `~/.devkit-config.json`
- Forge abstraction layer for GitHub/GitLab operations
- Project registry for multi-project coordination
- Local overrides via `.local.md` pattern (gitignored, machine-specific)
- SessionStart hardening: rate limiting (1/hour), lock-file awareness, pull logging
- Auto-push prompt after `/reflect` sessions
- Version-tagged releases with `VERSION` file as single source of truth
- SessionStart version check: notifies when a newer DevKit release is available
- `devkit update` command via `/devkit-sync` skill (check version, upgrade to tag or latest)
- `devkit promote` command for graduating local patterns to universal rules

### Version Policy

- MAJOR: Breaking changes to rules, skill interfaces, or sync protocol
- MINOR: New skills, agents, or non-breaking rule additions
- PATCH: Bug fixes, documentation, pattern additions

## v1.2.0 -- 2026-02-21

### Fixed

- claude/CLAUDE.md: replaced `YOUR_PLATFORM` placeholder with actual value and substitution note
- METHODOLOGY.md: added Windows warning for BMAD/Spec Kit tools (see known-gotchas #42-44)
- known-gotchas.md: renumbered contiguously 1-46 (was non-contiguous with gaps at 8-9, 13, 40, 42, 44 and #47 out of order)
- Cross-references to gotcha numbers updated in autolearn-patterns.md and workflow-preferences.md
- AGENT-WORKFLOW-GUIDE.md: replaced Python pseudo-code agent examples with correct `.claude/agents/*.md` format

### Added

- CI: README skill count accuracy check (fails if count doesn't match `claude/skills/` directories)
- CI: verify.sh skill list accuracy check (fails on missing directories, warns on unlisted skills)
- `profiles/` directory for Kit 2 stack profiles
- `project-templates/` directory for Kit 3 scaffolding
- `docs/` and `machine/` directories for guides and snapshots
- PowerShell stub files: setup.ps1, bootstrap.ps1, stack.ps1, new-project.ps1, verify.ps1, lib/*.ps1
- `setup/lib/ui.ps1`: console output library (Write-Section/Step/OK/Warn/Fail, Write-VerifyTable, Read-Required/Confirm/Menu, Invoke-ManualChecklist)
- `setup/lib/checks.ps1`: prerequisite and tool detection library (Test-Tool, Test-HyperV, Test-WSL2, Test-Virtualization, Test-DeveloperMode, Test-WindowsVersion, Test-ClaudeAuth/Skill/MCP, Test-DockerRunning/WSLBackend, Test-Credential, Get-PreflightStatus)
- `setup/lib/install.ps1`: winget and manual install wrappers (Install-WingetPackage/Packages, Install-VSCodeExtension/Extensions, Invoke-ManualInstall, Export-WingetManifest, Export-VSCodeExtensions)
- `setup/lib/credentials.ps1`: Windows Credential Manager integration (Set/Get/Test/Remove-DevkitCredential, Invoke-CredentialCollection with validation and secure input)
- `setup/setup.ps1`: main menu entry point with -Kit parameter for direct dispatch, version display, quick status check
- `machine/winget.json`: curated winget export (25 dev packages, personal apps removed)
- `machine/git-config.template`: gitconfig template with YOUR_NAME/YOUR_EMAIL placeholders
- `machine/manual-requirements.md`: reference for non-automatable setup steps (Hyper-V, WSL2, Docker config, Dev Mode)
- `setup/backup.ps1`: refresh machine snapshot files from current state with diff summary
- `setup/bootstrap.ps1` phases 1-2: pre-flight checks (Windows version, Hyper-V, WSL2, virtualization, Developer Mode) and core tool installs from machine/winget.json + vscode-extensions.txt
- `setup/bootstrap.ps1` phases 3-4: git config from template, devspace directory setup with ~/.devkit-config.json, PowerShell profile alias, credentials collection via Windows Credential Manager
- `setup/bootstrap.ps1` phases 5-6: AI layer deploy (Claude Code npm install, skills/rules/agents/hooks with hash-based overwrite, CLAUDE.md placeholder substitution) and full verification table with next steps
- `docs/BOOTSTRAP.md`: step-by-step new machine setup guide with troubleshooting section
- `setup/lib/profiles.ps1`: profile format parser with YAML frontmatter, dependency resolution, and cycle detection
- `project-templates/concept-brief.md`: project vision capture template for Kit 3 scaffolding
- `project-templates/claude-md-template.md`: fallback CLAUDE.md template for new projects
- `project-templates/github-labels.json`: standard label set (13 labels) for new GitHub repos
- `profiles/go-cli.md`: base Go profile (winget, linters, VS Code extensions, cross-compilation)
- `profiles/go-web.md`: extended Go+Web profile (buf, gRPC, REST client, Docker deployment)
- `profiles/iot-embedded.md`: ESP32/ESPHome profile (uv-managed tools, OTA/serial flashing, sensor patterns)
- `setup/stack.ps1`: Kit 2 profile selection and installer (-List, -ShowProfile, -Install, -Force flags)
- `setup/new-project.ps1` steps 1-2: concept collection (interactive + file), project scaffolding (git, GitHub, directories, labels, workspace)
- `setup/new-project.ps1` steps 3-4: Claude-generated CLAUDE.md (with template fallback), Phase 0 issue creation, workspace open

### Changed

- Bash setup scripts moved to `setup/legacy/` with deprecation headers (PowerShell primary)
- SKILLS-ECOSYSTEM.md: expanded Chat skill installation guide with rationale and sync process
- `devspace/CLAUDE.md` moved to `project-templates/workspace-claude-md-template.md`

### Removed

- go-development SKILL.md: removed network_security_patterns section (SubNetree-specific content)

## v1.1.0 -- 2026-02-17

### Removed

- coordination-sync, research-mode, dashboard, pm-view, dev-mode skills
  (moved to SubNetree project -- too project-specific for a general toolkit)

### Fixed

- settings.template.json: JSON syntax errors (missing commas on lines 17, 75)
- settings.template.json: removed hardcoded Windows drive path (`Read(//d/**)`)
- AUTOMATION-SETUP.md: fixed `Claude.md` -> `CLAUDE.md` capitalization (3 instances)
- SessionStart.sh: removed stale `D:/DevSpace/.coordination/` references
- verify.sh: now checks all 9 remaining skills (was only checking 5 of 14)

### Changed

- devspace/CLAUDE.md converted to template with generic placeholders
- memory-seeds.md converted to example with generic entity names
- claude/CLAUDE.md OS line made generic (was hardcoded to Windows MSYS_NT)
- settings.template.json: removed redundant granular permissions, trimmed plugin list to core set
- README.md: added Quick Start, What's Included section, updated skill inventory
- METHODOLOGY.md: updated tool references for removed skills
- SessionStart.sh: simplified to generic CLAUDE.md detection only

### Added

- GitHub Actions CI workflow: markdown lint + skill routing validation
- CHANGELOG.md

## v1.0.0 -- 2026-02-17

Initial release. 101 files: 5 rules (70+ patterns, 47+ gotchas), 14 skills,
6 agent templates, hooks, setup scripts, MCP config, project templates,
and development methodology.
