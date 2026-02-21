# Changelog

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
