# Update Knowledge

Merge accumulated learnings from MCP Memory into rules files. Ensures rules files stay current and useful.

## Steps

### 1. Read Current Rules Files

**Tier boundary check (MANDATORY):**

- **Tier 0** (`core-principles.md`, `error-policy.md`): NEVER modify. Immutable.
- **Tier 1** (`workflow-preferences.md`, `review-policy.md`): Propose only.
  Create a DevKit issue for changes. Do not edit directly.
- **Tier 2** (`autolearn-patterns.md`, `known-gotchas.md`): Autolearn can add entries.

Read Tier 2 rules files:

- `~/.claude/rules/autolearn-patterns.md`
- `~/.claude/rules/known-gotchas.md`

Note the current `entry_count` and `last_updated` from YAML frontmatter.

### 2. Fetch Recent MCP Memory Entries

Search MCP Memory for recent learnings:

```text
search_nodes: "pattern"
search_nodes: "gotcha"
search_nodes: "correction"
search_nodes: "preference"
```

For each result, check the most recent observation timestamp. Focus on entries added since the rules file `last_updated` date.

### 3. Merge New Learnings

For each MCP Memory entity not yet in rules files:

**Patterns and Corrections** -> `autolearn-patterns.md`:

- Add a new numbered entry with: category, context, fix/approach, example (if applicable)
- Increment `entry_count`

**Gotchas** -> `known-gotchas.md`:

- Add a new numbered entry with: platform, issue, workaround, note
- Increment `entry_count`

**Preferences** (Tier 1 -- propose only):

- Do NOT edit `workflow-preferences.md` directly
- Create a DevKit issue: `gh issue create -R HerbHall/devkit --title "pref: <description>"`
- Note the issue number in the update report

Update `last_updated` in all modified files.

### 4. Verify and Report

After updating:

1. Read each modified file to verify proper formatting
2. Check that entry numbering is sequential
3. Ensure no duplicate entries were introduced

Report:

```text
## Knowledge Update Summary

| Rules File | Before | After | Added |
|-----------|--------|-------|-------|
| autolearn-patterns.md | N entries | M entries | +K |
| known-gotchas.md | N entries | M entries | +K |
| workflow-preferences.md | N entries | M entries | +K |

New entries added:
- [List each new entry with brief description]

Files are up to date as of [current date].
```

## Maintenance Notes

- If any rules file exceeds 30 entries, suggest archiving older entries
- Consider splitting large files by subcategory (e.g., go-patterns.md, ci-patterns.md)
- Rules files are auto-loaded by Claude Code every session -- keep them focused and actionable
