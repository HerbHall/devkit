# Doc Review: Autolearn Integration

Capture recurring doc-review findings as persistent knowledge. Classifies findings into the correct destination (known-gotchas, autolearn-patterns, or Synapset devkit pool) and prevents duplicate entries.

## Input

This workflow receives findings from other doc-review workflows (audit, consistency, single-file). Each finding has:

- **Severity**: Critical / High / Medium / Low
- **Category**: e.g., Contradiction, Missing Section, Version Drift, Broken Link
- **Description**: What was found
- **File(s)**: Where it was found
- **Project**: Which project the finding came from

## Steps

### 1. Classify Each Finding

For each finding, determine its destination by asking three questions:

```text
Q1: Has this same issue appeared in 2+ projects or 2+ audit sessions?
  YES -> recurring issue -> known-gotchas or autolearn-patterns (Step 2a)
  NO  -> continue to Q2

Q2: Does this finding represent a cross-project pattern or workflow improvement?
  YES -> cross-project pattern -> autolearn-patterns (Step 2b)
  NO  -> continue to Q3

Q3: Is this a novel, project-specific finding worth remembering?
  YES -> Synapset devkit pool (Step 2c)
  NO  -> skip (finding is transient, no persistence needed)
```

Classification guide by category:

| Finding Category | Typical Destination | Example |
|-----------------|---------------------|---------|
| Missing CLAUDE.md section | known-gotchas (if platform-specific) | "CLAUDE.md missing on Windows projects" |
| Build command drift | autolearn-patterns | "Makefile targets diverge from CLAUDE.md" |
| Version string inconsistency | autolearn-patterns | "VERSION file not updated with release" |
| Broken internal link | Synapset (project-specific) | "docs/ADR-005.md references deleted file" |
| Schema violation (recurring) | known-gotchas | "README missing Credits section" |
| Cross-doc contradiction | autolearn-patterns | "CLAUDE.md claims X, Makefile does Y" |

### 2a. Known-Gotchas Entry (Recurring Platform/Tool Issues)

Format the entry for `claude/rules/known-gotchas.md`:

```text
## N. {Short Title}

**Added:** {YYYY-MM-DD} | **Source:** {project} | **Status:** active

**Platform:** {platform or tool}
**Issue:** {What happens and why it is surprising}
**Fix:** {How to prevent or resolve}
```

Before adding, check for an existing entry that covers the same issue. Search by keywords in the existing file.

### 2b. Autolearn-Patterns Entry (Cross-Project Patterns)

Format the entry for `claude/rules/autolearn-patterns.md`:

```text
## N. {Short Title}

**Added:** {YYYY-MM-DD} | **Source:** {project} | **Status:** active

**Category:** {category}
**Context:** {When this pattern applies and what goes wrong without it}
**Fix:** {The correct approach}
```

Before adding, check for an existing entry. If one exists, consider consolidating rather than duplicating.

### 2c. Synapset Devkit Pool (Novel Project-Specific Findings)

Before storing, check for duplicates:

```text
search_memory(
  pool: "devkit",
  query: "{finding description}",
  min_similarity: 0.85,
  limit: 3
)
```

If no similar entry exists (all results below 0.85 similarity), store:

```text
store_memory(
  pool: "devkit",
  content: "{finding description with context}",
  category: "pattern",
  tags: "doc-review,{project_name},{finding_category}",
  source: "doc-review-{project_name}",
  summary: "{one-line summary}"
)
```

If a similar entry exists, skip or update the existing memory with additional context using `update_memory`.

### 3. Deduplicate Against Existing Knowledge

For every entry drafted in Step 2a or 2b, verify it is not already tracked:

```bash
# Check known-gotchas
grep -i "{key_phrase}" "D:/DevSpace/Toolkit/devkit/claude/rules/known-gotchas.md"

# Check autolearn-patterns
grep -i "{key_phrase}" "D:/DevSpace/Toolkit/devkit/claude/rules/autolearn-patterns.md"
```

If a match is found:

- **Exact match**: Skip the entry, note as "already tracked" in the output
- **Partial match**: Consider updating the existing entry with new context from this finding
- **No match**: Proceed with adding the new entry

### 4. Draft Output

Produce a structured summary of all classifications:

```text
# Autolearn Integration Report

**Source workflow**: {audit / consistency / single-file}
**Project**: {project_name}
**Total findings processed**: {count}

## New Entries to Add

### Known-Gotchas
{drafted entries, or "None"}

### Autolearn-Patterns
{drafted entries, or "None"}

### Synapset (devkit pool)
{stored entries with memory IDs, or "None"}

## Already Tracked

- {finding} -> matches KG#{N} / AP#{N} / SYN#{id}
- ...

## Skipped (Transient)

- {finding} -> reason for skipping
- ...

## Escalation Recommendations

- {any findings that suggest a rules file update, DevKit issue, or methodology change}
```

### 5. Apply or Defer

If running in an automated pipeline (e.g., post-audit script):

- Draft entries are written to a temporary file for human review
- Do NOT modify rules files without explicit approval

If running interactively:

- Present the draft to the user
- Apply approved entries to the target files
- Update `entry_count` and `last_updated` frontmatter in rules files when adding entries (per AP#119)
