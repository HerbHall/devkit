# Changelog

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
