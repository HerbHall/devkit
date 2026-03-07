# Audit Rules File Metadata

Verify that YAML frontmatter metadata in rules files matches actual content.

## Procedure

### Step 1: Enumerate rules files

Check these files for frontmatter metadata:

- `claude/rules/autolearn-patterns.md`
- `claude/rules/known-gotchas.md`

### Step 2: For each file, verify entry_count

1. Read the YAML frontmatter (if present) and extract `entry_count`
2. Count actual numbered entries in the file (lines matching `## N.` pattern for top-level entries)
3. **FAIL** if `entry_count` does not match the actual count
4. **PASS** if they match or if the file has no `entry_count` frontmatter

### Step 3: Verify last_updated

1. Extract `last_updated` from frontmatter
2. **WARN** if `last_updated` is more than 30 days old and the file has recent git commits
3. **PASS** otherwise

### Step 4: Output report

```text
## Rules Metadata Audit
- autolearn-patterns.md: entry_count=N, actual=N [PASS/FAIL]
- known-gotchas.md: entry_count=N, actual=N [PASS/FAIL]
```
