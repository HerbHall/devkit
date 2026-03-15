# Rework Report

Detailed rework rate analysis per project, identifying patterns in CI failures and fix-push cycles.

## Steps

### 1. Ensure Data Exists

Check if pr_metrics has data:

```sql
SELECT COUNT(*) FROM pr_metrics;
```

If zero, advise: "No PR data collected yet. Run `/metrics collect` first."

### 2. Summary by Project

```sql
SELECT
    repo,
    COUNT(*) as total_prs,
    ROUND(AVG(push_count), 1) as avg_pushes_per_pr,
    ROUND(100.0 * SUM(ci_first_pass) / COUNT(*), 0) as first_pass_pct,
    SUM(fix_push_cycles) as total_fix_cycles,
    ROUND(AVG(CASE WHEN fix_push_cycles > 0 THEN fix_push_cycles END), 1) as avg_cycles_when_failing
FROM pr_metrics
WHERE merged_at >= date('now', '-30 days')
GROUP BY repo
ORDER BY first_pass_pct ASC;
```

### 3. Worst Offenders (PRs with Most Rework)

```sql
SELECT repo, pr_number, branch, push_count, fix_push_cycles, ci_first_pass
FROM pr_metrics
WHERE merged_at >= date('now', '-30 days')
    AND fix_push_cycles > 0
ORDER BY fix_push_cycles DESC
LIMIT 10;
```

### 4. Trend Comparison (Last 30d vs Prior 30d)

```sql
SELECT
    'Last 30 days' as period,
    COUNT(*) as prs,
    ROUND(AVG(push_count), 1) as avg_pushes,
    ROUND(100.0 * SUM(ci_first_pass) / COUNT(*), 0) as first_pass_pct
FROM pr_metrics
WHERE merged_at >= date('now', '-30 days')
UNION ALL
SELECT
    'Prior 30 days' as period,
    COUNT(*) as prs,
    ROUND(AVG(push_count), 1) as avg_pushes,
    ROUND(100.0 * SUM(ci_first_pass) / COUNT(*), 0) as first_pass_pct
FROM pr_metrics
WHERE merged_at >= date('now', '-60 days')
    AND merged_at < date('now', '-30 days');
```

### 5. Format Report

Present as:

```text
## Rework Report

### Summary by Project
| Project | PRs | Avg Pushes | First-Pass % | Fix Cycles | Avg When Failing |
|---------|-----|------------|--------------|------------|------------------|

### Worst Offenders (Most Rework)
| Project | PR # | Branch | Pushes | Fix Cycles |
|---------|------|--------|--------|------------|

### Trend (30d vs Prior 30d)
| Period | PRs | Avg Pushes | First-Pass % | Direction |
|--------|-----|------------|--------------|-----------|
```

Add directional indicators: first-pass % improving = good, degrading = flag for attention.
