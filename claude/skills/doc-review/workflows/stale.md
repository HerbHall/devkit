# Doc Review: Stale Check

Find documentation files that have not been updated while related code has changed. A document is "stale" when it has not been modified in 90+ days AND the code it describes has been actively changed in that period.

## Steps

### 1. Determine Target Project

If the user specified a project, resolve its path. Otherwise use the current working directory.

```bash
PROJECT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROJECT_NAME=$(basename "$PROJECT")
```

### 2. Discover Markdown Files

Find all `.md` files, excluding generated and vendor content:

```bash
find "$PROJECT" -name "*.md" \
  -not -path "*/node_modules/*" \
  -not -path "*/vendor/*" \
  -not -path "*/.git/*" \
  -not -path "*/.claude/worktrees/*" \
  -not -path "*/CHANGELOG.md" \
  | sort
```

### 3. Get Last Modified Date per File

For each markdown file, get the last meaningful commit date:

```bash
git -C "$PROJECT" log --follow -1 --format="%ci %H" -- "$file"
```

Calculate days since last modification. Flag files where `days_since > 90`.

### 4. Get Code Activity Window

Determine if the project has had recent code changes:

```bash
# Count code file commits in last 90 days
git -C "$PROJECT" log --since="90 days ago" --name-only --pretty=format: -- \
  "*.go" "*.ts" "*.tsx" "*.js" "*.rs" "*.cs" "*.py" "*.yaml" "*.yml" "*.toml" \
  | sort -u | wc -l
```

If zero code changes in 90 days, the project is dormant -- report this and skip staleness flags (docs not stale if nothing changed).

### 5. Cross-Reference Doc-to-Code Staleness

For each stale document (90+ days), check if it references files that HAVE been modified recently:

```bash
# Extract file references from the document
grep -oE '[a-zA-Z0-9_/.-]+\.(go|ts|tsx|js|rs|cs|py|yaml|yml|sh|ps1)' "$doc_file" | sort -u
```

For each referenced code file, check if it was modified in the last 90 days:

```bash
git -C "$PROJECT" log --since="90 days ago" -1 --format="%ci" -- "$code_file"
```

A document is **actively stale** if it references code files that changed recently. A document is **passively stale** if it is old but its references are also old.

### 6. Classify Results

```text
Categories:
- ACTIVELY STALE: Doc 90+ days old, references code changed in last 90 days (High severity)
- PASSIVELY STALE: Doc 90+ days old, no referenced code changes (Low severity)
- CURRENT: Doc updated within 90 days (no action needed)
- DORMANT PROJECT: No code changes in 90 days (informational)
```

### 7. Produce Report

```text
# Freshness Report: {PROJECT_NAME}

**Date**: {date}
**Files checked**: {total_count}
**Threshold**: 90 days

## Actively Stale (High Priority)

These documents reference code that has changed since the doc was last updated:

| Document | Last Updated | Days Stale | Changed Code References |
|----------|-------------|------------|------------------------|
| ... | ... | ... | file1.go (5 days ago), file2.ts (12 days ago) |

## Passively Stale (Low Priority)

These documents are old but the code they reference is also unchanged:

| Document | Last Updated | Days Stale |
|----------|-------------|------------|
| ... | ... | ... |

## Current Documents

{count} documents updated within the last 90 days.

## Summary

- Actively stale: {count} (action needed)
- Passively stale: {count} (monitor)
- Current: {count}
```

### 8. Offer Follow-Up

For actively stale documents:

- "Run `/doc-review <path>` on any of these for a deep review"
- "These documents likely need updating to reflect recent code changes"

If many documents are stale, suggest a batch approach:

- "Consider running `/doc-review audit` for a full structural check alongside freshness"
