# Doc Review: Consistency Check

Cross-document contradiction scan. Uses Synapset `find_contradictions` when available, falls back to structural comparison when not.

## Steps

### 1. Determine Target Project

If the user specified a project, resolve its path. Otherwise use the current working directory.

```bash
PROJECT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PROJECT_NAME=$(basename "$PROJECT")
```

### 2. Check Synapset Availability

Attempt to verify if Synapset MCP tools are available and the `docs` pool exists:

```text
Try: list_pools via Synapset MCP
If available and "docs" pool exists: use SEMANTIC mode (Step 3a)
If available but no "docs" pool: use STRUCTURAL mode (Step 3b) + note that indexing is needed
If unavailable: use STRUCTURAL mode (Step 3b)
```

**Important:** If Synapset tools are not in the available tools list, skip the MCP call entirely (stdio MCP servers hang indefinitely when unavailable -- see KG#155).

### 3a. Semantic Mode (Synapset Available)

For each key document in the project (CLAUDE.md, README.md, ADRs, requirements):

1. Extract H2 sections as individual claims
2. For each section, call `find_contradictions`:

```text
find_contradictions(
  pool: "docs",
  query: "{section_content}",
  threshold: 0.85,
  limit: 5
)
```

1. Filter out self-matches (same file + same section)
2. Classify matches by similarity threshold:
   - 0.95+: Critical -- near-identical claims that may contradict
   - 0.90-0.95: High -- very similar claims, likely conflict
   - 0.85-0.90: Medium -- related claims, possible inconsistency

### 3b. Structural Mode (Fallback)

Without Synapset, check for common cross-document inconsistencies by comparing claims structurally:

**Build commands:**

```bash
# Extract build/test/lint commands from CLAUDE.md and Makefile
grep -n '`.*make\|go build\|go test\|npm\|pnpm\|cargo' "$PROJECT/CLAUDE.md" 2>/dev/null
grep -n '^[a-z].*:' "$PROJECT/Makefile" 2>/dev/null
```

Compare: does CLAUDE.md reference make targets that exist? Does it claim commands that differ from the Makefile?

**Version claims:**

```bash
# Compare version references across docs
grep -rn 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "$PROJECT"/*.md --include="*.md" 2>/dev/null | head -20
# Compare against VERSION file or package manifest
cat "$PROJECT/VERSION" 2>/dev/null
```

**Architecture claims:**

```bash
# Extract directory structure claims from CLAUDE.md
# Compare against actual directory structure
ls -d "$PROJECT"/*/  2>/dev/null | head -20
```

**ADR cross-references:**

```bash
# Find ADR references across all docs
grep -rn 'ADR-[0-9]\+' "$PROJECT" --include="*.md" 2>/dev/null
# Verify referenced ADRs exist
ls "$PROJECT"/docs/ADR-*.md 2>/dev/null
```

### 4. Compile Findings

For each detected inconsistency:

```text
- **Severity**: Critical / High / Medium
- **Category**: Contradiction | Version Drift | Missing Reference | Claim Mismatch
- **Source A**: file_path:line -- "{claim_a}"
- **Source B**: file_path:line -- "{claim_b}"
- **Issue**: What is inconsistent
- **Resolution suggestion**: Which source is likely correct and why
```

### 5. Produce Report

```text
# Consistency Report: {PROJECT_NAME}

**Mode**: {Semantic (Synapset) | Structural (fallback)}
**Documents checked**: {count}
**Contradictions found**: {count}

## Findings

### Critical (Conflicting Claims)
{findings}

### High (Likely Inconsistencies)
{findings}

### Medium (Possible Drift)
{findings}

## Summary

{One paragraph: overall consistency assessment, key areas of concern, recommended actions}
```

### 6. Offer Follow-Up

If in structural mode:

- "Synapset `docs` pool is not yet populated. Run the document indexing pipeline (Phase 2) to enable semantic contradiction detection."

For any findings:

- "Run `/doc-review <path>` on specific files to investigate findings in depth"
- "For version drift issues, update the stale document to match the current state"

### 7. Important Limitations

Note to the user:

- Structural mode catches surface-level inconsistencies (mismatched commands, version drift, missing references)
- Semantic mode (requires Synapset docs pool) catches deeper contradictions (conflicting architectural claims, divergent rationale)
- Neither mode catches omission contradictions (something was removed from code but the doc still claims it exists) -- that requires the audit workflow's semantic accuracy checks
