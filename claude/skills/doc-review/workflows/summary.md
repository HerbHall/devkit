# Doc Review: Summary

Human digest of documentation health. Compressed, decision-oriented -- no full document content, just actionable items. Designed for the project owner who reviews via summaries and directs changes through Claude.

## Steps

### 1. Determine Target Project

If the user specified a project, resolve its path. Otherwise use the current working directory.

```bash
PROJECT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROJECT_NAME=$(basename "$PROJECT")
```

### 2. Gather Metrics

Collect key statistics in parallel:

**File counts:**

```bash
# Total markdown files
find "$PROJECT" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" | wc -l

# Files by directory
find "$PROJECT" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -exec dirname {} \; | sort | uniq -c | sort -rn | head -10
```

**Recent changes (last 30 days):**

```bash
git -C "$PROJECT" log --since="30 days ago" --name-only --pretty=format: -- "*.md" \
  | sort -u | grep -v '^$'
```

**Staleness:**

```bash
# Count files not updated in 90+ days
for f in $(find "$PROJECT" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*"); do
  days=$(( ($(date +%s) - $(git -C "$PROJECT" log -1 --format=%ct -- "$f" 2>/dev/null || echo 0)) / 86400 ))
  [ "$days" -gt 90 ] && echo "$f"
done | wc -l
```

**Internal link count:**

```bash
grep -r '\[.*\](.*)' "$PROJECT" --include="*.md" -c 2>/dev/null | tail -1
```

### 3. Check Required Documents

Verify presence of core document types:

```text
Check for:
- CLAUDE.md (required)
- README.md (required)
- SECURITY.md (recommended)
- CONTRIBUTING.md (recommended)
- At least one ADR (recommended for projects with architectural decisions)
```

### 4. Identify Top Issues

Without running a full audit, do a quick structural scan:

- Check if CLAUDE.md has a "Quick Start" section
- Check if README.md has "Installation" and "Usage" sections
- Count broken internal links (sample first 10 files)

### 5. Produce Digest

Format as a compressed, scannable summary:

```text
# Doc Health: {PROJECT_NAME}

**{total_files}** markdown files | **{recent_changes}** changed in last 30 days | **{stale_count}** stale (90+ days)

## Status Indicators

| Indicator | Status |
|-----------|--------|
| Core docs present | {CLAUDE.md: Y/N, README: Y/N, SECURITY: Y/N} |
| Internal links | {sample_broken_count} broken in sample of {sample_size} |
| Freshness | {stale_percentage}% of docs over 90 days |

## Recent Activity

{List of files changed in last 30 days, grouped by type of change}

## Action Items

1. **{severity}**: {description} -- {suggested action}
2. **{severity}**: {description} -- {suggested action}
...

## Recommendations

- {One-line recommendation based on findings}
```

### 6. Keep It Short

The summary must fit in one screenful (~40 lines). If there are many findings, prioritize by severity and show only the top 5. Link to `/doc-review audit` for the full picture.

Do NOT include:

- Full file contents or long excerpts
- Detailed schema compliance tables (that is the audit workflow's job)
- Low-severity findings (save for the audit)
- Formatting issues (save for fix-formatting)
