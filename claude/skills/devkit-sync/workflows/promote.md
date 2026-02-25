# DevKit Sync: Promote

Promote patterns from machine-tier `.local.md` files to universal-tier rules files in the DevKit clone.

## Steps

### 1. Scan for local rule files

Look in `~/.claude/rules/` for any `*.local.md` files:

```bash
ls ~/.claude/rules/*.local.md 2>/dev/null
```

Read each file found. Identify numbered entries -- these follow the format used in `autolearn-patterns.md` and `known-gotchas.md`:

- Entries start with `## N. Title` (H2 heading with a number)
- Each entry has **Category**, **Context**, **Fix** (or **Workaround**/**Platform**/**Issue**) fields
- Skip files that are empty or contain no numbered entries

If no `.local.md` files exist or none contain entries, report "No local entries found to promote" and stop.

### 2. Display candidates

Present each entry to the user in a numbered list:

```text
Promote Candidates
==================

From: autolearn-patterns.local.md
  [1] #3 - "Title of entry" (Category: pattern)
  [2] #7 - "Title of entry" (Category: lint-fix)

From: known-gotchas.local.md
  [3] #1 - "Title of entry" (Platform: Windows)
  [4] #2 - "Title of entry" (Platform: Go)

4 entries found across 2 files.
```

Mark any entries that have a `<!-- Promoted to universal: ... -->` comment above them as already promoted and skip them from the candidate list.

### 3. User selects entries

Ask the user which entries to promote:

```text
Which entries to promote? Enter numbers (e.g., "1,3"), "all", or "none".
```

**Wait for response.** If "none", stop.

### 4. Determine target file for each selected entry

Resolve the DevKit clone path from `~/.devkit-config.json` or common locations (`D:/DevSpace/devkit`, `~/DevSpace/devkit`).

Map each entry to its target universal file based on the source filename:

| Source file matches | Target file |
|---------------------|-------------|
| `*gotcha*` or `*known*` | `claude/rules/known-gotchas.md` |
| `*pattern*` or `*autolearn*` | `claude/rules/autolearn-patterns.md` |
| Anything else | Ask the user which universal file to target |

For the "anything else" case, show available targets:

```text
Entry [N] is from "<filename>" -- which universal file should it go to?
  (1) claude/rules/known-gotchas.md
  (2) claude/rules/autolearn-patterns.md
  (3) claude/rules/workflow-preferences.md
  (4) Other (specify)
```

### 5. Append to universal file

For each target universal file:

1. Read the file to find the highest existing entry number. Entry numbers are in `## N. Title` headings.
2. Assign the next sequential number to the promoted entry.
3. Rewrite the entry's heading from `## <old-number>. Title` to `## <new-number>. Title`.
4. Append the full entry (heading + all content until the next `## ` heading or end of file) to the end of the target file.
5. Ensure a blank line separates the new entry from the previous content.

### 6. Mark as promoted in source

For each promoted entry in the `.local.md` source file, add a comment directly above the entry's `## ` heading:

```markdown
<!-- Promoted to universal: YYYY-MM-DD -->
```

Do NOT delete the entry from the local file. The user can clean up later.

### 7. Report and suggest sync

Show the user what was done:

```text
Promote Summary
===============

Promoted N entries:
  - "Entry title" -> known-gotchas.md as #62
  - "Entry title" -> autolearn-patterns.md as #86

Source files updated with promotion markers.
```

Then suggest:

```text
Run `/devkit-sync push` to commit and push these changes to the DevKit repo.
```

## Edge Cases

- No `.local.md` files found: report and stop
- All entries already promoted: report "All local entries have already been promoted" and stop
- Entry format doesn't match numbered pattern: skip it and warn the user
- DevKit clone path not found: report error, suggest `/devkit-sync init`
- Target file doesn't exist: report error (it should always exist in the DevKit clone)
