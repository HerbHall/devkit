# DES-001: Synapset Document Indexing for Doc-Review

- **Status**: Draft
- **Date**: 2026-03-30
- **Author**: Claude + Herb
- **Related**: Doc-Review Roadmap (Phase 0.5), ADR template update (G2)

## Problem Statement

400+ markdown files across Toolkit projects contain claims, decisions, and specifications that can contradict each other. No system currently indexes document content for semantic search or contradiction detection. Synapset has `find_contradictions` but no `docs` pool to search against.

## Goals

- Index all project documentation into Synapset for semantic search
- Enable `find_contradictions` to detect cross-document inconsistencies
- Support the `/doc-review consistency` workflow from the doc-review skill
- Keep the index fresh as documents change

## Non-Goals

- Replacing git as the source of truth (Synapset is a search index, not storage)
- Indexing code files (only .md documentation)
- Real-time indexing (periodic batch is sufficient)
- Indexing external documentation or dependencies

## Proposed Design

### Pool Strategy: Single `docs` Pool

Use a single `docs` pool (not per-project) because:
- `find_contradictions` searches within a single pool -- cross-project contradictions are the highest-value detection
- Source metadata (`source=samverk`, `source=devkit`) enables per-project filtering when needed
- Simpler to maintain than 4+ pools

### Chunking: Per-Section (H2 Level)

Index each H2 section as a separate memory entry. This gives:
- **Good granularity** for contradiction detection (a section about "Build Commands" won't conflict with a section about "Architecture")
- **Meaningful context** per chunk (H2 sections are typically 50-300 words, well within embedding model range)
- **Traceable references** (source file + section heading = exact location)

Exceptions:
- Files with no H2 headings: index the entire file as one entry
- Very long sections (>600 tokens): use Synapset's `chunk_large_content` flag to auto-split

### Metadata Schema

Each indexed section gets:

```yaml
pool: docs
content: "{section text including H2 heading}"
category: "{doc-type from doc-schemas.yaml}" # adr, claude-md, runbook, etc.
source: "{project-name}" # samverk, devkit, opskit, synapset
tags: "{filename},{section-heading-slug}"
summary: "{filename} > {section heading}"
confidence: 1.0
trust_tier: verified # docs in git are verified by definition
```

### Update Strategy: Periodic Batch via Samverk Scheduled Task

1. Weekly Samverk scheduled task triggers doc indexing
2. For each registered project:
   - List all .md files via Samverk `list_files`
   - Compare file hashes against last-indexed hashes (stored as a Synapset memory in `docs` pool with tag `index-state`)
   - For changed files: delete old sections, re-index new sections
   - For deleted files: delete old sections
3. Log index stats (files indexed, sections added/updated/removed)

Manual trigger: `/doc-review consistency` can force a re-index before running contradiction checks.

### Contradiction Detection Workflow

When `/doc-review consistency` runs:

1. Ensure `docs` pool is up-to-date (re-index if stale)
2. For each section in the current project:
   - Call `find_contradictions(pool="docs", query="{section content}", threshold=0.85)`
   - Filter out self-matches (same file + same section)
   - Score remaining matches by similarity
3. Report findings grouped by severity:
   - **Critical** (similarity > 0.95): Near-identical claims with different content -- likely a real contradiction
   - **High** (similarity 0.90-0.95): Very similar claims that may conflict
   - **Medium** (similarity 0.85-0.90): Related claims worth human review

## Implementation Plan

1. Create the `docs` pool in Synapset (trivial -- first `store_memory` auto-creates it)
2. Write a document indexing script (Python or Go) that:
   - Parses .md files into H2 sections
   - Calls `store_memory` for each section with correct metadata
   - Tracks index state for incremental updates
3. Wire into Samverk scheduled task for periodic execution
4. Wire into `/doc-review consistency` workflow for on-demand execution

## Open Questions

- [ ] Should the index include YAML frontmatter as separate entries? (ADR metadata like Status/Date could conflict with other claims)
- [ ] What's the right `find_contradictions` threshold? 0.85 is the Synapset default but may need tuning for documentation content
- [ ] Should we index DevKit rules files (autolearn-patterns.md, known-gotchas.md)? They contain claims about how things work that could contradict project docs.
- [ ] How do we handle intentional overrides? (Project CLAUDE.md intentionally diverges from DevKit global conventions)

## References

- Synapset `find_contradictions` tool documentation
- Doc-Review Roadmap (Phase 0.5, 2.1, 2.5)
- `doc-schemas.yaml` (document type definitions)
