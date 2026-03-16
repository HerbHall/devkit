# Skill Usage Recording

Standard block for recording skill invocations. Referenced by instrumented skills.

## Instructions

After selecting a workflow, record the skill invocation using SQLite MCP.
If SQLite MCP tools (`write_query`) are unavailable, skip silently -- usage
recording is best-effort and must never block skill execution.

```text
write_query(
  database: "claude.db",
  query: "CREATE TABLE IF NOT EXISTS skill_usage (id INTEGER PRIMARY KEY AUTOINCREMENT, skill_name TEXT NOT NULL, invoked_at TEXT NOT NULL, project TEXT, workflow_used TEXT, completed INTEGER DEFAULT 1); INSERT INTO skill_usage (skill_name, invoked_at, project, workflow_used) VALUES ('<skill-name>', datetime('now'), '<project>', '<workflow>');"
)
```

Replace `<skill-name>` with the skill's name from SKILL.md frontmatter,
`<project>` with `basename` of the current working directory, and
`<workflow>` with the selected workflow filename.
