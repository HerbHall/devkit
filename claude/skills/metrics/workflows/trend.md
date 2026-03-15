# Metrics Trend Analysis

Compare DevKit effectiveness metrics across time windows to identify improvement or degradation.

## Steps

### 1. Query Rework Trend

Compare last 30 days vs prior 30 days:

```sql
SELECT
    CASE
        WHEN merged_at >= date('now', '-30 days') THEN 'Last 30d'
        ELSE 'Prior 30d'
    END as period,
    COUNT(*) as prs,
    ROUND(AVG(push_count), 1) as avg_pushes,
    ROUND(100.0 * SUM(ci_first_pass) / COUNT(*), 0) as first_pass_pct,
    SUM(fix_push_cycles) as fix_cycles
FROM pr_metrics
WHERE merged_at >= date('now', '-60 days')
GROUP BY period
ORDER BY period DESC;
```

### 2. Query Conformance Trend

Show score progression per project:

```sql
SELECT repo, audit_date, score_pct
FROM conformance_scores
WHERE audit_date >= date('now', '-90 days')
ORDER BY repo, audit_date;
```

### 3. Query Pattern Application Trend

```sql
SELECT
    strftime('%Y-%m', session_date) as month,
    COUNT(*) as events,
    COUNT(DISTINCT entry_id) as unique_patterns
FROM pattern_events
WHERE session_date >= date('now', '-90 days')
GROUP BY month
ORDER BY month;
```

### 4. Format Report

```text
## Trend Analysis

### Rework Rate Trend
| Period | PRs | Avg Pushes | First-Pass % | Fix Cycles | Direction |
|--------|-----|------------|--------------|------------|-----------|

### Conformance Score Trend
| Project | 3 Months Ago | 2 Months Ago | Last Month | Direction |
|---------|-------------|-------------|------------|-----------|

### Pattern Application Trend
| Month | Events | Unique Patterns | Direction |
|-------|--------|-----------------|-----------|
```

Use directional indicators based on comparison to prior period.
