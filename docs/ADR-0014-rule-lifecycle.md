# ADR-0014: Rule Lifecycle Management

## Status

Accepted

## Date

2026-02-28

## Context

The DevKit rules corpus (autolearn-patterns.md + known-gotchas.md) has grown
to 136 numbered entries across 1,882 lines, all loaded into every Claude Code
session. Growth is append-only with no deprecation, consolidation, or staleness
tracking. One exact duplicate exists (AP#27 = KG#17). Several thematically
related entries (swagger cluster: AP#17, AP#35, KG#12, KG#57, KG#59) lack
cross-references.

Without lifecycle management, the rules files will continue growing, consuming
more context tokens per session and making it harder to find relevant patterns.

## Decision

Introduce lightweight per-entry metadata, a deprecation mechanism, an archive
directory, and an audit workflow.

### Entry Metadata Format

One metadata line below each entry heading:

```markdown
## 1. gosec G101 False Positive on Constants Near Credential Code

**Added:** 2026-01-15 | **Source:** SubNetree | **Status:** active
```

Fields:

| Field | Required | Format | Description |
|-------|----------|--------|-------------|
| `**Added:**` | Yes | `YYYY-MM-DD` | Date first committed (infer from git log) |
| `**Source:**` | Yes | Project name | Where discovered: `SubNetree`, `devkit`, `global`, `samverk`, etc. |
| `**Status:**` | Yes | See below | Lifecycle state |
| `**Last relevant:**` | No | `YYYY-MM-DD` | Updated by `/reflect` when pattern is applied in a session |
| `**See also:**` | No | Entry references | Cross-references: `AP#17`, `KG#12`, etc. |

### Status Values

| Status | Meaning |
|--------|---------|
| `active` | Current and applicable |
| `deprecated (YYYY-MM-DD) -- reason` | No longer applicable; kept in archive for history |
| `superseded-by-XX#NN` | Replaced by another entry (e.g., `superseded-by-KG17`) |

### Deprecation Flow

1. Mark the entry: `**Status:** deprecated (YYYY-MM-DD) -- reason`
2. Move the entry text to `claude/rules/archive/<original-filename>.md`
3. Update the source file's frontmatter `entry_count`
4. The entry number is retired (never reused) to preserve cross-references

### Archive Directory

`claude/rules/archive/` -- subdirectory of `rules/` but NOT loaded into
Claude Code sessions. Claude Code only auto-loads top-level `rules/*.md`
files, not subdirectories. Deprecated entries move here to free context
tokens while remaining accessible for history and audit.

### Frontmatter Extensions

Add `entry_count` and `last_updated` to Tier 2 rules files:

```yaml
---
description: Learned patterns from past sessions.
tier: 2
entry_count: 76
last_updated: "2026-02-28"
---
```

These enable quick health checks without parsing every entry.

### Cross-Reference Format

Use `**See also:**` for related entries across files:

```markdown
**See also:** AP#17, KG#12, KG#57
```

Prefix convention: `AP#` for autolearn-patterns, `KG#` for known-gotchas.

## Consequences

### Positive

- Context tokens freed when deprecated entries move to archive
- Stale entries identifiable via `**Last relevant:**` absence + age
- Duplicates and related entries linked via cross-references
- Entry counts in frontmatter enable quick health audits
- Retired numbers prevent broken cross-references

### Negative

- Metadata adds ~1 line per entry (~136 lines total when fully annotated)
- Initial metadata population requires git log analysis (one-time cost)
- Audit workflow adds maintenance overhead (mitigated by automation)

### Neutral

- Entry numbers are never reused, so gaps will accumulate over time
- Archive files follow the same format as active files (just in a subdirectory)

## Alternatives Considered

### Inline YAML frontmatter per entry

Each entry would have its own YAML block. Rejected: too verbose, breaks the
markdown reading flow, and markdownlint would flag the repeated `---` blocks.

### Database-backed metadata

Store metadata in SQLite or JSON. Rejected: adds tooling complexity, breaks
the "rules files are plain markdown" principle, and loses git history benefits.

### Time-based auto-deprecation

Automatically deprecate entries older than N days. Rejected: age alone doesn't
indicate staleness. A 2-year-old gotcha about Windows MSYS paths is still
relevant. The `**Last relevant:**` field provides better signal.
