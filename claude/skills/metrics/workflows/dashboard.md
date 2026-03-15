# Metrics Dashboard

Display a summary of DevKit effectiveness metrics from SQLite.

## Steps

### 1. Ensure Schema Exists

Run the schema initialization to ensure tables exist:

```bash
sqlite3 ~/databases/claude.db < scripts/metrics-init.sql
```

If `sqlite3` is unavailable, use the SQLite MCP tools to create tables from `scripts/metrics-init.sql`.

### 2. Query PR Metrics (Last 30 Days)

Use SQLite MCP `read_query` or `sqlite3` to run:

```sql
SELECT
    repo,
    COUNT(*) as prs,
    ROUND(AVG(push_count), 1) as avg_pushes,
    ROUND(100.0 * SUM(ci_first_pass) / COUNT(*), 0) as first_pass_pct,
    SUM(fix_push_cycles) as total_fix_cycles
FROM pr_metrics
WHERE merged_at >= date('now', '-30 days')
GROUP BY repo
ORDER BY repo;
```

### 3. Query Conformance Scores (Latest Per Project)

```sql
SELECT repo, audit_date, score_pct, passed, failed
FROM conformance_scores c1
WHERE audit_date = (SELECT MAX(audit_date) FROM conformance_scores c2 WHERE c2.repo = c1.repo)
ORDER BY repo;
```

### 4. Query Pattern Impact (Last 30 Days)

```sql
SELECT
    entry_id,
    entry_title,
    COUNT(*) as total_events,
    SUM(CASE WHEN event_type = 'applied' THEN 1 ELSE 0 END) as applied,
    SUM(CASE WHEN event_type = 'prevented' THEN 1 ELSE 0 END) as prevented,
    SUM(CASE WHEN event_type = 'caught' THEN 1 ELSE 0 END) as caught,
    MAX(session_date) as last_used
FROM pattern_events
WHERE session_date >= date('now', '-30 days')
GROUP BY entry_id
ORDER BY total_events DESC
LIMIT 20;
```

### 5. Query Skill Usage (Last 30 Days)

```sql
SELECT
    skill_name,
    COUNT(*) as invocations,
    ROUND(100.0 * SUM(completed) / COUNT(*), 0) as completion_pct
FROM skill_usage
WHERE invoked_at >= date('now', '-30 days')
GROUP BY skill_name
ORDER BY invocations DESC;
```

### 6. Query Autolearn Pipeline (Last 30 Days)

```sql
SELECT
    event_type,
    COUNT(*) as count
FROM autolearn_events
WHERE event_date >= date('now', '-30 days')
GROUP BY event_type
ORDER BY CASE event_type
    WHEN 'discovered' THEN 1
    WHEN 'issue_created' THEN 2
    WHEN 'ingested' THEN 3
    WHEN 'applied' THEN 4
    ELSE 5
END;
```

### 7. Format and Display

Present results in this format:

```text
## DevKit Effectiveness Dashboard

### Rework Rate (last 30 days)
| Project | PRs | Avg Pushes/PR | First-Pass CI % | Fix-Push Cycles |
|---------|-----|---------------|-----------------|-----------------|

### Conformance (latest audit)
| Project | Score | Passed | Failed | Date |
|---------|-------|--------|--------|------|

### Pattern Impact (last 30 days)
| Entry | Applied | Prevented | Caught | Last Used |
|-------|---------|-----------|--------|-----------|

### Skill Usage (last 30 days)
| Skill | Invocations | Completion % |
|-------|-------------|--------------|

### Autolearn Pipeline (last 30 days)
| Stage | Count |
|-------|-------|
```

If any table has no data, show "(no data collected yet -- run `/metrics collect` first)" instead.
