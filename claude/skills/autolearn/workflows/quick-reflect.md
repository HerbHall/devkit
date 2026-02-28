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

### 5. Tier Boundary Check

Before updating any rules files, check the `tier` field in YAML frontmatter:

- **Tier 0** (`core-principles.md`, `error-policy.md`): NEVER modify. Immutable.
- **Tier 1** (`workflow-preferences.md`, `review-policy.md`): Do NOT edit directly.
  If a finding affects Tier 1 rules, create a DevKit issue instead.
- **Tier 2** (`autolearn-patterns.md`, `known-gotchas.md`): Safe to add entries.

### 6. Report Summary

Present a brief summary to the user:

```text
## Quick Reflect Summary

**Learnings stored:** N items
- [Category] Entity name: Brief description

**Skipped (already known):** N items
**Skipped (low confidence):** N items

Rules file updates suggested: [Yes/No]
- If yes, recommend running `/reflect` with "update knowledge" option
- Tier 1 changes proposed: [list DevKit issues created, if any]
```

### 6. DevKit Sync Check

After storing learnings, check if the DevKit clone has uncommitted changes (rules files were likely modified via symlinks):

```bash
# Find DevKit clone
DEVKIT=$(python3 -c "import json; c=json.load(open('$HOME/.devkit-config.json')); print(c['devspace']+'/devkit')" 2>/dev/null)
# Fallback paths
[ -z "$DEVKIT" ] && for d in "$HOME/DevSpace/devkit" "/d/DevSpace/devkit"; do [ -f "$d/.sync-manifest.json" ] && DEVKIT="$d" && break; done

if [ -n "$DEVKIT" ] && [ -n "$(git -C "$DEVKIT" status --porcelain -- claude/ 2>/dev/null)" ]; then
    git -C "$DEVKIT" diff --stat -- claude/
fi
```

If changes exist, prompt the user:

```text
**DevKit sync:** Uncommitted changes detected in DevKit clone.

  (1) Push DevKit changes now
  (2) Skip -- push later with /devkit-sync push
```

If the user selects **1**, run the push workflow inline:

1. Read machine ID from `~/.claude/.machine-id` (if missing, tell the user to run `/devkit-sync init` and stop)
2. `git -C <devkit> add claude/`
3. `git -C <devkit> commit` with message `chore(sync): <machine-id> session learnings <date>` and co-author tag
4. `git -C <devkit> push -u origin sync/<machine-id>`
5. Check for an existing PR with `gh pr list -R HerbHall/devkit --head sync/<machine-id>`; if none, create one with `gh pr create`
6. Report the PR URL

If the user selects **2**, acknowledge and move on. No further action needed.
