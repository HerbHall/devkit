# Doc Review: Consistency Check

Cross-document contradiction detection using Synapset semantic memory. Scans H2 sections against the `docs` pool to find conflicting claims across project documentation.

## Prerequisites

- Synapset MCP tools must be available (check tools list before calling -- stdio servers hang indefinitely when unavailable, see KG#155)
- The `docs` pool must exist and be populated (3,132+ indexed memories across Toolkit projects)
- Each memory in the pool is an H2-level section with metadata: `source={project}`, `category={doc-type}`, `tags={filename},{section-slug}`

If Synapset is unavailable or the `docs` pool is empty, inform the user:

> "The consistency workflow requires the Synapset `docs` pool. Run the document indexing pipeline to populate it, then re-run `/doc-review consistency`."

## Steps

### 1. Determine Scope

Accept one of:

- **Project name** (e.g., `samverk`, `devkit`, `synapset`, `opskit`) -- scan all `.md` files in the project root and key subdirectories (`docs/`, `claude/`, project root)
- **File path** (e.g., `docs/architecture.md`) -- scan only that file
- **No input** -- use the current working directory, derive the project name from `basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)`

```bash
# Resolve project
if [[ -n "$USER_INPUT" ]]; then
  if [[ -f "$USER_INPUT" ]]; then
    TARGET_FILES=("$USER_INPUT")
    PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
  else
    PROJECT_NAME="$USER_INPUT"
    PROJECT_ROOT=$(find /d/DevSpace/Toolkit -maxdepth 1 -iname "$PROJECT_NAME" -type d | head -1)
  fi
else
  PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  PROJECT_NAME=$(basename "$PROJECT_ROOT")
fi
```

When scanning a full project, collect `.md` files from these locations (skip `node_modules`, `vendor`, `.git`, `CHANGELOG.md`):

```bash
find "$PROJECT_ROOT" -name "*.md" \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/vendor/*" \
  -not -name "CHANGELOG.md" \
  | head -50
```

Cap at 50 files to keep the workflow tractable. If more exist, prioritize: `CLAUDE.md`, `README.md`, `METHODOLOGY.md`, `docs/*.md`, `claude/**/*.md`.

### 2. Split Each File into H2 Sections

For each `.md` file in scope, read the file and split on H2 (`##`) headings. Each H2 section becomes one unit for contradiction checking.

For each section, capture:

- **file_path**: absolute path to the source file
- **section_heading**: the H2 heading text
- **section_content**: full text from the H2 heading to the next H2 (or end of file)
- **section_slug**: lowercase, hyphenated version of the heading (matches the `tags` field in Synapset)

Skip sections shorter than 30 characters (headings with no substantive content).

### 3. Query Synapset for Contradictions

For each section, call `find_contradictions` against the `docs` pool:

```text
find_contradictions(
  pool: "docs",
  query: "{section_content}",
  threshold: 0.85,
  limit: 5
)
```

**Rate limiting**: Process sections sequentially. For large projects (20+ sections), batch in groups of 10 with a brief status update between batches so the user sees progress.

### 4. Filter Results

For each result set, apply these filters:

1. **Remove self-matches**: If a returned memory's `tags` contain the same filename as the source section, AND the similarity is above 0.95, it is almost certainly the same section. Discard it.

   Match logic: compare the source file's basename (e.g., `CLAUDE.md`) against the memory's `tags` field. If the tag list includes the same filename, it is a self-match.

2. **Remove same-file matches**: If both the source section and the matched memory come from the same file (same filename in tags), discard. Cross-document contradictions are the goal.

3. **Keep cross-project matches**: Matches where `source` differs from the current `PROJECT_NAME` are especially valuable -- these indicate cross-project drift.

### 5. Score and Classify by Severity

Group surviving matches into three severity levels:

| Severity | Similarity Range | Meaning |
|----------|-----------------|---------|
| **Critical** | 0.95+ | Near-identical claims across different documents. Very likely a contradiction or dangerous duplication where one copy could drift. |
| **High** | 0.90 -- 0.94 | Very similar claims. Probable conflict -- same topic described differently, or divergent instructions for the same procedure. |
| **Medium** | 0.85 -- 0.89 | Related claims. Possible inconsistency worth reviewing. May be complementary rather than contradictory. |

### 6. Produce Findings Report

Format the output as:

````text
# Consistency Report: {PROJECT_NAME}

**Scope**: {count} files, {total_sections} sections checked
**Contradictions found**: {critical_count} critical, {high_count} high, {medium_count} medium

## Critical (>0.95 similarity)

### Finding C-1

- **Source**: `{file_path}` > {section_heading}
- **Conflicts with**: `{matched_filename}` ({matched_project}) > {matched_section_summary}
- **Similarity**: {score}
- **Issue**: {one-line description of what conflicts}
- **Source excerpt**: "{first 100 chars of source section}"
- **Match excerpt**: "{first 100 chars of matched memory content}"

### Finding C-2
...

## High (0.90--0.95 similarity)

### Finding H-1
...

## Medium (0.85--0.90 similarity)

### Finding M-1
...

## Summary

{One paragraph: overall consistency assessment. Note which document pairs
have the most conflicts. Flag cross-project contradictions specifically.
Recommend which document should be treated as authoritative for each
conflicting claim.}

## Recommended Actions

- For critical findings: resolve immediately -- determine which document
  is authoritative and update the other
- For high findings: review during next doc maintenance pass
- For medium findings: note for awareness -- may be intentional variation
- For cross-project drift: file an issue in the authoritative project's
  repo to update the stale copy
````

### 7. Handle Edge Cases

**No contradictions found**: Report a clean bill of health:

> "No cross-document contradictions detected above 0.85 similarity threshold. {count} files and {sections} sections were checked."

**Synapset returns errors**: If `find_contradictions` fails for a specific section (e.g., content too long, API error), log the section path, skip it, and continue. Report skipped sections at the end:

> "Note: {N} sections were skipped due to API errors. Run `/doc-review consistency` again to retry, or check Synapset server health."

**Large sections (>2000 chars)**: Truncate the query to the first 1500 characters. Synapset embeddings work best on focused content. If a section is very large, note this in the finding.

### 8. Offer Follow-Up

After presenting the report:

- "Run `/doc-review {file_path}` on a specific file to investigate a finding in depth"
- "For critical findings, I can update the stale document now -- provide the authoritative source and I will align the other"
- "Run `/doc-review stale` to check if contradictions correlate with stale documents"

### 9. Limitations

Note to the user:

- Semantic similarity detects **surface contradictions** (same topic, different claims). It does not detect **omission contradictions** (something removed from code but docs still claim it exists) -- use the audit workflow for those.
- Threshold 0.85 balances precision and recall. Lower thresholds produce more noise. Raise to 0.90 if results are too noisy.
- The `docs` pool must be re-indexed after significant documentation changes for results to reflect the latest state.
- Self-match filtering relies on filename tags. If a memory was indexed without proper tags, self-matches may leak through.

## Post-Processing: Autolearn Capture

After generating findings, follow the [autolearn integration](autolearn-integration.md) workflow to capture recurring patterns.
