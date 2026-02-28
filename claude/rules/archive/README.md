# Rules Archive

Deprecated and superseded rule entries live here. This directory is **not**
loaded into Claude Code sessions -- only top-level `rules/*.md` files are
auto-loaded.

## Purpose

When a rule entry is deprecated or superseded by another entry, its text moves
here to free context tokens from active sessions while preserving history.

## Format

Archive files mirror their source files:

- `autolearn-patterns.md` -- deprecated entries from `../autolearn-patterns.md`
- `known-gotchas.md` -- deprecated entries from `../known-gotchas.md`

Each archived entry retains its original number, heading, metadata, and content.
Entry numbers are never reused in the source file.

## When to Archive

An entry should be archived when:

- It is marked `**Status:** deprecated` (no longer applicable)
- It is marked `**Status:** superseded-by-XX#NN` (replaced by another entry)
- The `/reflect audit` workflow recommends archival and the user approves

## Reference

See [ADR-0014](../../docs/ADR-0014-rule-lifecycle.md) for the full metadata
format specification and lifecycle rules.
