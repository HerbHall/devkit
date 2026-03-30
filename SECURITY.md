# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in DevKit, please report it responsibly.

**Do not open a public issue.** Instead, use one of these methods:

1. **Gitea Private Reporting**: Use the security advisory feature on the [DevKit repository](https://gitea.herbhall.net/samverk/devkit)
2. **Email**: Contact the maintainer directly

## What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Affected component (rules, skills, templates, setup scripts, hooks)
- Suggested fix (if you have one)

### DevKit-Specific Concerns

DevKit distributes methodology and configuration to all projects via symlinks and setup scripts. Pay special attention to:

- **Credential distribution**: The `devkit-config.json` secret distribution mechanism and symlinked settings files
- **Permission wildcards**: `settings.json` and `settings.template.json` contain MCP tool permission patterns that control agent capabilities
- **Template injection**: Scaffolding templates (`project-templates/`) are copied into new projects -- malicious content would propagate to all future projects
- **Hook execution**: `SessionStart` and `UserPromptSubmit` hooks execute shell commands automatically in every Claude Code session
- **Rules file manipulation**: Rules files in `claude/rules/` are loaded into every agent's system prompt -- compromised rules could alter agent behavior across all projects

## Response Timeline

- **Acknowledgement**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Fix or mitigation**: Depends on severity, targeting 30 days for critical issues
- Compromised templates or hooks are patched and re-synced immediately upon confirmation

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | Yes       |
| Older   | No        |
