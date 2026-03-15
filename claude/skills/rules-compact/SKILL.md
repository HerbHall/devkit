---
name: rules-compact
description: Compact oversized rules files by archiving stale entries, deduplicating same-root-cause patterns, and consolidating related entries. Targets under 35k per file.
user_invocable: true
---

# Rules Compact

Compact oversized rules files in `claude/rules/` by archiving stale entries, deduplicating same-root-cause patterns, and consolidating related entries. Targets under 35k per file.

<essential_principles>

**Why this matters.** Rules files load into every Claude Code session. Files over 40k degrade performance -- large input blocks get ignored at task transitions (Variant B stall pattern). Keeping files under 35k leaves headroom for growth.

**Archive, never delete.** Removed entries go to `claude/rules/archive/` with full text preserved. Zero information loss.

**Consolidation over deletion.** Entries sharing the same root cause merge into a single super-entry with subsections. This reduces line count without losing detail.

**Entry numbering is stable.** Consolidated entries keep the lowest original number. Archived entries retain their number in the archive file. New entries use the next available number.

</essential_principles>

<intake>

Running rules file compaction. This skill executes a fixed workflow -- no options needed.

</intake>

<workflow>

## Step 1: Inventory

List all files in `claude/rules/` with sizes:

```bash
wc -c claude/rules/*.md | sort -rn
```

Flag any file over 40k as needing compaction. If all files are under 35k, report "All rules files within limits" and stop.

## Step 2: Analyze candidates

For each file over 35k, count entries and identify:

1. **Stale entries** -- `last_relevant` date older than 90 days (or `Added` date if no `last_relevant`), with no cross-references from other entries
2. **Duplicates** -- entries covering the same fix as another entry (check for overlapping `Category` and similar `Fix` sections)
3. **Consolidation candidates** -- 3+ entries sharing a root cause (e.g., multiple gocritic lint patterns, multiple swagger platform issues)

Report findings before proceeding:

```text
autolearn-patterns.md: 45k, 80 entries
  - 12 stale (older than 90 days, no cross-refs)
  - 3 duplicate pairs
  - 2 consolidation groups (8 entries -> 2 super-entries)
  Projected: 45k -> 32k
```

## Step 3: Archive stale entries

For each stale entry:

1. Copy the full entry text to `claude/rules/archive/<filename>`
2. Add under a dated header: `## Archived YYYY-MM-DD: Rules compaction`
3. Remove the entry from the active file
4. If Synapset MCP is available, store the archived entry for long-tail search:
   `store_memory(pool: "devkit", content: "<archived entry>", category: "general", tags: "archived,<entry_id>", summary: "<title> (archived)")`

## Step 4: Deduplicate

For each duplicate pair:

1. Keep the entry with more detail or broader scope
2. Archive the other with a `**Status:** superseded-by-KG#N` or `superseded-by-AP#N` note
3. Add a `**See also:** KG#N` cross-reference to the surviving entry if not already present

## Step 5: Consolidate

For each consolidation group (3+ related entries):

1. Create a super-entry using the lowest original entry number
2. Structure as: shared context at top, then `### Sub-pattern: Name` subsections
3. Each subsection keeps: symptom, fix, example (if code-heavy)
4. Archive the individual entries that were absorbed

## Step 6: Update metadata

Update the YAML frontmatter in each modified file:

- `entry_count`: new count
- `last_updated`: today's date

## Step 7: Verify

```bash
wc -c claude/rules/*.md | sort -rn
npx markdownlint-cli2 "claude/rules/<modified-files>"
```

Report before/after:

```text
autolearn-patterns.md: 45k / 80 entries -> 32k / 55 entries (29% reduction)
known-gotchas.md: 38k / 82 entries -> 33k / 70 entries (13% reduction)
```

## Step 8: Verify cross-references

After archiving or consolidating, cross-references between AP and KG files may point to archived entries. Check for stale references:

1. Collect all entry numbers that were archived or consolidated in this compaction
2. Grep both active files for references to those numbers (e.g., `grep -n "AP#N[^0-9]" claude/rules/known-gotchas.md` for each archived AP entry N, and vice versa for KG entries)
3. For each stale reference found, either update to point to the surviving consolidated entry, append "(archived)" to indicate the target was intentionally archived, or remove the reference if no longer relevant

Report any fixes made. This step prevents cross-reference drift (see MCP Memory entity `cross-reference-drift-after-compaction`).

</workflow>

<success_criteria>

- [ ] All rules files under 35k
- [ ] Archived entries preserved in `claude/rules/archive/` with full text
- [ ] No information loss (every removed entry exists in archive)
- [ ] YAML frontmatter `entry_count` updated
- [ ] markdownlint passes on all modified files
- [ ] Before/after report shown to user
- [ ] No stale cross-references between AP and KG files (Step 8 verified)

</success_criteria>
