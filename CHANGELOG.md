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

### Changed

- Bash setup scripts moved to `setup/legacy/` with deprecation headers (PowerShell primary)
- SKILLS-ECOSYSTEM.md: expanded Chat skill installation guide with rationale and sync process

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
