# Doc Review: Fix Formatting

Auto-correct markdown formatting issues using markdownlint-cli2 with the `--fix` flag.

## Steps

### 1. Determine Scope

If the user specified a path, scope to that file or directory.
If no path specified, scope to the current project's markdown files.

```bash
# Default: current project root
PROJECT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

### 2. Check Tool Availability

Verify markdownlint-cli2 is available:

```bash
npx markdownlint-cli2 --help > /dev/null 2>&1 && echo "available" || echo "not found"
```

If not available, inform the user:
"markdownlint-cli2 is not installed. Run `npm install -g markdownlint-cli2` or use `npx markdownlint-cli2`."

### 3. Dry Run First

Run markdownlint without `--fix` to show current violations:

```bash
npx markdownlint-cli2 "$SCOPE/**/*.md" 2>&1 | head -50
```

Report the count and categories of violations found. If zero violations, notify the user and stop.

### 4. Confirm with User

Before making changes, show the user what will be fixed:

```text
Found {N} formatting violations across {M} files.
Auto-fixable categories: {list MD codes that --fix handles}
Non-fixable (manual): {list MD codes that require manual intervention}

Proceed with auto-fix? (yes/no)
```

Wait for user confirmation before proceeding.

### 5. Apply Fixes

Run markdownlint with the `--fix` flag:

```bash
npx markdownlint-cli2 --fix "$SCOPE/**/*.md" 2>&1
```

### 6. Report Changes

After fixing, run markdownlint again to show remaining violations:

```bash
npx markdownlint-cli2 "$SCOPE/**/*.md" 2>&1 | head -50
```

Report:

```text
## Fix Results

- **Before**: {N} violations
- **Auto-fixed**: {fixed_count}
- **Remaining**: {remaining_count} (require manual intervention)

### Files Modified
- {list of files that changed}

### Remaining Issues (manual fix needed)
- {file:line}: {MD code} - {description}
```

### 7. Offer Follow-Up

If remaining issues exist, offer:

- "I can fix these manually -- want me to edit the files?"
- "Run `/doc-review audit` for a full structural review beyond formatting"
