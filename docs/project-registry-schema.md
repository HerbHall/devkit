# Project Registry Schema

## Purpose

The project registry tracks which projects on a machine consume DevKit configuration. It enables answering:

- Which projects have local rules or skills that could be promoted to DevKit?
- Which projects need updating after a DevKit change?
- What is the full inventory of DevKit-managed projects on this machine?

## Location

`~/.devkit-registry.json` -- machine-tier, never committed to DevKit or any project repo.

## Schema

```json
{
  "version": 1,
  "projects": [
    {
      "path": "string (absolute path to project root)",
      "name": "string (display name)",
      "forge": "string (github | gitea | none)",
      "repo": "string (owner/repo slug, empty if forge is none)",
      "registered": "string (ISO 8601 date, YYYY-MM-DD)",
      "lastSync": "string (ISO 8601 datetime with timezone)",
      "hasLocalRules": "boolean (project has .claude/rules/*.md)",
      "hasLocalSkills": "boolean (project has .claude/skills/*/)"
    }
  ]
}
```

## Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `version` | integer | Schema version for forward compatibility |
| `projects` | array | List of registered project entries |
| `path` | string | Absolute path to the project root directory |
| `name` | string | Human-readable project name |
| `forge` | string | Git hosting platform: `github`, `gitea`, or `none` |
| `repo` | string | Owner/repo slug (e.g., `HerbHall/SubNetree`). Empty string if forge is `none` |
| `registered` | string | Date the project was registered (ISO 8601 date) |
| `lastSync` | string | Timestamp of last DevKit sync check (ISO 8601 datetime) |
| `hasLocalRules` | boolean | Whether the project has project-scoped rules in `.claude/rules/` |
| `hasLocalSkills` | boolean | Whether the project has project-scoped skills in `.claude/skills/` |

## Example

```json
{
  "version": 1,
  "projects": [
    {
      "path": "D:\\DevSpace\\SubNetree",
      "name": "SubNetree",
      "forge": "github",
      "repo": "HerbHall/SubNetree",
      "registered": "2026-02-25",
      "lastSync": "2026-02-25T10:00:00Z",
      "hasLocalRules": true,
      "hasLocalSkills": true
    },
    {
      "path": "D:\\DevSpace\\Runbooks",
      "name": "Runbooks",
      "forge": "github",
      "repo": "HerbHall/Runbooks",
      "registered": "2026-02-25",
      "lastSync": "2026-02-25T09:30:00Z",
      "hasLocalRules": false,
      "hasLocalSkills": true
    },
    {
      "path": "/home/herb/projects/internal-tool",
      "name": "internal-tool",
      "forge": "gitea",
      "repo": "herb/internal-tool",
      "registered": "2026-02-20",
      "lastSync": "2026-02-24T18:45:00Z",
      "hasLocalRules": true,
      "hasLocalSkills": false
    }
  ]
}
```

## Future Commands

| Command | Purpose |
|---------|---------|
| `devkit register` | Add the current project to the registry |
| `devkit list-projects` | Show all registered projects with sync status |
| `devkit check-projects` | Scan registered projects for local rules/skills to promote |
