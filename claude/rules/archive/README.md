# Rules Archive

Deprecated and superseded rule entries live here. This directory is **not**
loaded into Claude Code sessions -- only top-level `rules/*.md` files are
auto-loaded.

## Purpose

When a rule entry is deprecated or superseded by another entry, its full text
is stored in Synapset (`pool: devkit`, tagged `archived`) and a tombstone is
written here for audit trail and cross-reference integrity.

## Format

Archive files mirror their source files:

- `autolearn-patterns.md` -- deprecated entries from `../autolearn-patterns.md`
- `known-gotchas.md` -- deprecated entries from `../known-gotchas.md`

**New entries (2026-03-17+)** use tombstone format: entry number, one-line
summary, status, and Synapset ID. Full text lives in Synapset for semantic search.

**Legacy entries (pre-2026-03-17)** retain full text inline. These will be
migrated to tombstone format in a future pass.

Entry numbers are never reused in the source file.

## When to Archive

An entry should be archived when:

- It is marked `**Status:** deprecated` (no longer applicable)
- It is marked `**Status:** superseded-by-XX#NN` (replaced by another entry)
- The `/autolearn audit` workflow recommends archival and the user approves

## Reference

See [ADR-0014](../../docs/ADR-0014-rule-lifecycle.md) for the full metadata
format specification and lifecycle rules.
