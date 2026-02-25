# Quick Reflect

Fast end-of-task assessment. Scans the current conversation for high-value learnings and stores them.

## Steps

### 1. Scan Conversation

Review the conversation for:

- **Corrections**: Mistakes made and fixed (e.g., wrong command, bad assumption, code that didn't compile)
- **Gotchas**: Surprising behaviors encountered (e.g., platform quirk, library bug, unexpected error)
- **Patterns**: Approaches that worked well and are reusable
- **Decisions**: Significant choices made with rationale

Focus on the most recent task. Don't rehash older context unless it's directly relevant.

### 2. Classify Findings

For each finding, determine:

- **Category**: correction, gotcha, pattern, or decision
- **Confidence**: HIGH (clear mistake/fix, confirmed behavior) or MEDIUM (useful but not critical)
- **Reusability**: Would this help in a different session or project?

Filter out:

- One-off observations that won't recur
- Trivial details (typos, formatting)
- Context-specific decisions that don't generalize

### 3. Check for Duplicates

Search MCP Memory for existing entities:

```text
search_nodes with keywords from each finding
```

If a match exists, plan to add an observation instead of creating a new entity.

### 4. Store Learnings

For each HIGH-confidence finding:

**If new entity needed:**

```text
create_entities: [{
  name: "<kebab-case-name>",
  entityType: "<Pattern|Gotcha|Correction|Decision>",
  observations: ["[YYYY-MM-DD] (source: <project>) (confidence: HIGH) (category: <type>) <description>"]
}]
```

**If existing entity found:**

```text
add_observations: [{
  entityName: "<existing-name>",
  contents: ["[YYYY-MM-DD] (source: <project>) (confidence: HIGH) Additional context: <description>"]
}]
```

**Create relations if applicable:**

```text
create_relations: [{
  from: "<learning-name>",
  to: "<project-name>",
  relationType: "DISCOVERED_IN"
}]
```

### 5. Report Summary

Present a brief summary to the user:

```text
## Quick Reflect Summary

**Learnings stored:** N items
- [Category] Entity name: Brief description

**Skipped (already known):** N items
**Skipped (low confidence):** N items

Rules file updates suggested: [Yes/No]
- If yes, recommend running `/reflect` with "update knowledge" option
```

### 6. DevKit Sync Check

After storing learnings, check if the DevKit clone has uncommitted changes (rules files were likely modified via symlinks):

```bash
# Find DevKit clone
DEVKIT=$(python3 -c "import json; c=json.load(open('$HOME/.devkit-config.json')); print(c['devspace']+'/devkit')" 2>/dev/null)
# Fallback paths
[ -z "$DEVKIT" ] && for d in "$HOME/DevSpace/devkit" "/d/DevSpace/devkit"; do [ -f "$d/.sync-manifest.json" ] && DEVKIT="$d" && break; done

if [ -n "$DEVKIT" ] && [ -n "$(git -C "$DEVKIT" status --porcelain -- claude/ 2>/dev/null)" ]; then
    echo "DevKit has uncommitted changes. Run /devkit-sync push to share them."
fi
```

If changes exist, append to the summary:

```text
**DevKit sync:** Uncommitted changes detected. Run `/devkit-sync push` to commit and share.
```
