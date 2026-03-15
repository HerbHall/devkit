---
name: metrics
description: DevKit effectiveness measurement dashboard and collection
user_invocable: true
---

# Metrics

Measure DevKit's impact on code quality and rework reduction across all managed projects.

<essential_principles>

- All metrics stored in SQLite MCP (`~/databases/claude.db`)
- PR data sourced from GitHub API (immutable history)
- Collection happens at natural boundaries, not continuously
- Schema defined in `scripts/metrics-init.sql`

</essential_principles>

<routing>

| Input | Workflow | Description |
|-------|----------|-------------|
| `dashboard`, (default) | workflows/dashboard.md | Show current metrics summary |
| `collect` | workflows/collect.md | Run PR metrics collection from GitHub API |
| `rework`, `rework-report` | workflows/rework-report.md | Rework rate analysis per project |
| `trend` | workflows/trend.md | Compare metrics across time windows |

</routing>
