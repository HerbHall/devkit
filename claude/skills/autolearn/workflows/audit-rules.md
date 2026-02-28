# Audit Rules

Health check and maintenance workflow for Tier 2 rules files. Identifies stale entries, missing metadata, potential duplicates, and proposes actions.

## Context Guard

This workflow modifies rules files directly. It may only run in the DevKit repo.

**Check:** Does `.sync-manifest.json` exist with `"version": 2`?

- If yes: proceed
- If no: stop and tell the user this workflow requires a DevKit session

## Steps

### 1. Parse All Tier 2 Entries

Read both rules files:

- `~/.claude/rules/autolearn-patterns.md`
- `~/.claude/rules/known-gotchas.md`

For each entry, extract:

- Number and title (from `## N. Title`)
- Category or Platform (first bold field)
- Metadata fields if present (`**Added:**`, `**Source:**`, `**Status:**`, `**Last relevant:**`, `**See also:**`)

### 2. Generate Health Report

Present a summary table:

```text
## Rules Health Report

| Metric | autolearn-patterns | known-gotchas | Total |
|--------|-------------------|---------------|-------|
| Total entries | N | N | N |
| With metadata | N | N | N |
| Missing metadata | N | N | N |
| Active | N | N | N |
| Deprecated | N | N | N |
| Superseded | N | N | N |
| Stale (see below) | N | N | N |

Frontmatter entry_count: AP=N (actual N), KG=N (actual N)
```

Flag any mismatch between frontmatter `entry_count` and actual count.

### 3. Identify Stale Entries

An entry is **stale** if ALL of these are true:

- Has an `**Added:**` date older than 90 days
- Does NOT have a `**Last relevant:**` date
- Status is `active`

List stale entries:

```text
### Stale Entries (no recent relevance signal)

| Entry | Title | Added | Days Old |
|-------|-------|-------|----------|
| AP#N | ... | YYYY-MM-DD | N |
```

Note: stale does not mean wrong. Many entries remain valid indefinitely. This list is for review, not automatic deprecation.

### 4. Identify Potential Duplicates

Search for entries with:

- Same category/platform AND similar keywords in the title
- Cross-file overlaps (an AP entry and a KG entry covering the same topic)

Flag candidates but do NOT auto-merge. Present as:

```text
### Potential Duplicates

| Entry A | Entry B | Reason |
|---------|---------|--------|
| AP#N | KG#M | Same topic: <description> |
```

### 5. Propose Actions

For each finding, propose one of:

- **Confirm active**: Entry is still relevant, add `**Last relevant:**` date
- **Deprecate**: Entry is no longer applicable, move to archive
- **Merge**: Two entries cover the same topic, consolidate
- **Add metadata**: Entry is missing metadata fields
- **Cross-reference**: Related entries should link to each other

Present as a numbered action list:

```text
### Proposed Actions

1. [confirm] AP#5 -- Still relevant (WebSocket JWT pattern used in SubNetree)
2. [deprecate] AP#N -- No longer applicable because...
3. [merge] AP#N + KG#M -- Same topic, consolidate into KG#M
4. [metadata] KG#N -- Add Added/Source/Status fields
5. [xref] AP#17, KG#12, KG#57 -- Add See also cross-references
```

### 6. Execute Approved Actions

**Wait for user approval before executing.** The user may approve all, select specific actions, or skip entirely.

For each approved action:

- **Confirm active**: Add or update `**Last relevant:** YYYY-MM-DD`
- **Deprecate**: Mark `**Status:** deprecated (YYYY-MM-DD) -- reason`, move to archive file, update frontmatter `entry_count`
- **Merge**: Combine content into the surviving entry, supersede the other, archive the superseded entry
- **Add metadata**: Insert `**Added:** date | **Source:** project | **Status:** active` line
- **Cross-reference**: Add `**See also:**` lines to related entries

### 7. Report Summary

```text
## Audit Summary

**Actions executed:** N of M proposed
**Entries deprecated:** N (moved to archive)
**Entries merged:** N
**Metadata added:** N entries
**Cross-references added:** N entries
**Frontmatter updated:** [Yes/No]

Next audit recommended: YYYY-MM-DD (90 days from now)
```
