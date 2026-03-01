# Audit Settings

Check `~/.claude/settings.json` for redundant permissions that are subsumed by broad wildcards. Optionally clean up the file.

## Steps

### 1. Read the user-level settings file

```bash
cat ~/.claude/settings.json
```

If the file does not exist, report "No user-level settings.json found" and stop.

### 2. Identify broad wildcards

Parse the `permissions.allow` array. A **broad wildcard** is an entry with no parentheses -- it matches all invocations of that tool.

Examples of broad wildcards:

- `"Bash"` -- matches all Bash commands
- `"Read"` -- matches all Read operations
- `"mcp__*"` -- matches all MCP tools

### 3. Find redundant specific entries

For each broad wildcard found, identify specific entries it subsumes:

- `"Bash"` subsumes `"Bash(git add:*)"`, `"Bash(gh pr merge 30 --squash --admin)"`, etc.
- `"Read"` subsumes `"Read(d:/DevSpace/**)"`, etc.
- `"mcp__*"` subsumes `"mcp__memory__create_entities"`, `"mcp__MCP_DOCKER__mcp-find"`, etc.

An entry is redundant if a broader entry in the same array already covers it.

### 4. Report findings

Display a summary:

```text
Settings audit for ~/.claude/settings.json

Broad wildcards found: N
  - Bash
  - Read
  - Edit
  ...

Redundant specific entries: N
  - Bash(git add:*)          (subsumed by Bash)
  - Bash(gh pr merge 30 --squash --admin)  (subsumed by Bash)
  - Read(d:/DevSpace/**)     (subsumed by Read)
  ...

Deny rules (preserved): N
  - Bash(rm -rf /)
```

If zero redundant entries found, report "Settings are clean -- no redundant entries" and stop.

### 5. Ask user to confirm cleanup

Present the list of entries that would be removed. Explain:

- Broad wildcards are kept
- Deny rules are never removed
- Non-redundant specific entries are kept
- Only entries fully covered by a broad wildcard are removed

Ask: "Remove N redundant entries? (This modifies ~/.claude/settings.json)"

### 6. Clean up if confirmed

Read the current file, remove redundant entries from `permissions.allow`, and write back.

Use `Read` to get the current content, modify the JSON in a code block, and `Write` the cleaned version.

**Preserve:**

- All `permissions.deny` entries (never touch deny rules)
- All entries NOT subsumed by a broad wildcard
- All non-permission fields (`hooks`, `enabledPlugins`, `autoUpdatesChannel`, etc.)
- JSON formatting (2-space indent)

### 7. Report results

Show before/after entry count and the cleaned file path.

## Edge cases

- **No broad wildcards**: Report "No broad wildcards found. Specific entries are all necessary." and stop.
- **Mixed tool formats**: `"Bash(git:*)"` is subsumed by `"Bash"` but NOT by `"Bash(gh:*)"`. Only exact tool name match counts.
- **settings.local.json**: This workflow only audits the user-level `~/.claude/settings.json`. Project-level and local files are not touched.
- **Backup**: Before writing, create a backup at `~/.claude/settings.json.bak`.
