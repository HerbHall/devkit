# Doc Review: Full Audit

Scan all markdown files in a project, classify each by document type, validate against schemas, and produce a findings report.

## Steps

### 1. Determine Target Project

If the user specified a project name (e.g., `/doc-review audit samverk`), resolve its path.
If no project specified, use the current working directory.

```bash
# Verify the target is a git repo
git -C "$PROJECT_PATH" rev-parse --git-dir 2>/dev/null
```

Store the resolved path as `PROJECT` and the project name as `PROJECT_NAME`.

### 2. Load Document Schemas

Read the schema definitions:

```bash
cat "D:/DevSpace/Toolkit/devkit/devspace/templates/doc-schemas.yaml"
```

Parse the `document_types` map. Each type has `filename_patterns` (for detection) and `sections` (for validation).

### 3. Discover Markdown Files

Find all `.md` files in the project, excluding vendor directories:

```bash
find "$PROJECT" -name "*.md" \
  -not -path "*/node_modules/*" \
  -not -path "*/vendor/*" \
  -not -path "*/.git/*" \
  -not -path "*/.claude/worktrees/*" \
  -not -path "*/CHANGELOG.md" \
  | sort
```

Record the total count.

### 4. Classify Each File

For each discovered `.md` file, determine its document type by matching against `filename_patterns` from the schema:

```text
Pattern matching priority:
1. Exact filename match (e.g., "CLAUDE.md" -> claude-md type)
2. Glob pattern match (e.g., "ADR-*.md" -> adr type)
3. Directory-based match (e.g., files in "docs/adr/" -> adr type)
4. No match -> "unclassified" (skip schema validation, still check links)
```

Group files by detected type for the report.

### 5. Validate Structure per File

For each classified file, check against its schema's required sections:

1. Read the file content
2. Extract all headings (lines starting with `#`)
3. Compare against the schema's `sections` array:
   - Required sections: must be present (case-insensitive heading match)
   - Recommended sections: note if missing but don't fail
4. Check heading levels match schema expectations (e.g., H2 for top-level sections)
5. Record pass/fail per section

### 6. Check Required Document Types

Verify that the project has all commonly required document types:

- `CLAUDE.md` -- required for all projects
- `README.md` -- required for all projects
- `SECURITY.md` -- recommended (flag as Medium if missing)
- `CONTRIBUTING.md` -- recommended for open-source projects

### 7. Spot-Check Cross-References

For up to 20 files (prioritize classified files over unclassified):

```bash
# Extract internal links from markdown files
grep -n '\[.*\](\..*\.md' "$file" | head -20
```

For each internal link, verify the target file exists relative to the source file's directory.

### 8. Compile Report

Produce a structured report:

```text
# Documentation Audit: {PROJECT_NAME}

**Date**: {date}
**Files scanned**: {total_count}
**Classified**: {classified_count} ({type_breakdown})
**Unclassified**: {unclassified_count}

## Schema Compliance

| File | Type | Required Sections | Present | Missing | Status |
|------|------|-------------------|---------|---------|--------|
| ... | ... | ... | ... | ... | PASS/FAIL |

## Missing Required Documents

- {list any required doc types not found}

## Cross-Reference Issues

- {list broken internal links with file:line}

## Findings by Severity

### Critical
- {findings}

### High
- {findings}

### Medium
- {findings}

### Low
- {findings}

## Summary

- Pass: {count} files
- Fail: {count} files
- Skip: {count} files (unclassified)
- Score: {pass}/{pass+fail} ({percentage}%)
```

### 9. Present Results

Display the report to the user. If there are Critical or High findings, highlight them first. Offer to run `/doc-review fix` for formatting issues or `/doc-review <path>` for deep review of specific failing files.

## Post-Processing: Autolearn Capture

After generating findings, follow the [autolearn integration](autolearn-integration.md) workflow to capture recurring patterns.
