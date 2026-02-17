# Shared Templates

Starter files for new projects. Copy what you need — these are the single source of truth for structure and formatting conventions across all DevSpace projects.

## Usage

When creating a new project, copy the relevant templates into your project and customize:

```powershell
# Example: setting up coordination for a new project
cp D:\DevSpace\.templates\adr-template.md D:\DevSpace\MyProject\coordination\decisions\
cp D:\DevSpace\.templates\claude-md-template.md D:\DevSpace\MyProject\CLAUDE.md
```

## Available Templates

| Template | Purpose | Copy To |
|----------|---------|---------|
| `claude-md-template.md` | CLAUDE.md boilerplate for new projects | `{project}/CLAUDE.md` |
| `adr-template.md` | Architecture Decision Record | `{project}/coordination/decisions/ADR-NNN-title.md` |
| `design-template.md` | Lightweight RFC / design doc | `{project}/coordination/designs/DES-NNN-title.md` |
| `test-plan-template.md` | Test plan for features or releases | `{project}/coordination/test-plans/TP-NNN-title.md` |

## Maintenance

These templates reflect current best practices. When you improve a pattern in one project, update the template here so future projects benefit. Templates are never auto-applied — projects own their copies.
