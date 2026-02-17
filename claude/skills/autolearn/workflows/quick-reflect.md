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
```
search_nodes with keywords from each finding
```

If a match exists, plan to add an observation instead of creating a new entity.

### 4. Store Learnings

For each HIGH-confidence finding:

**If new entity needed:**
```
create_entities: [{
  name: "<kebab-case-name>",
  entityType: "<Pattern|Gotcha|Correction|Decision>",
  observations: ["[YYYY-MM-DD] (source: <project>) (confidence: HIGH) (category: <type>) <description>"]
}]
```

**If existing entity found:**
```
add_observations: [{
  entityName: "<existing-name>",
  contents: ["[YYYY-MM-DD] (source: <project>) (confidence: HIGH) Additional context: <description>"]
}]
```

**Create relations if applicable:**
```
create_relations: [{
  from: "<learning-name>",
  to: "<project-name>",
  relationType: "DISCOVERED_IN"
}]
```

### 5. Report Summary

Present a brief summary to the user:

```
## Quick Reflect Summary

**Learnings stored:** N items
- [Category] Entity name: Brief description

**Skipped (already known):** N items
**Skipped (low confidence):** N items

Rules file updates suggested: [Yes/No]
- If yes, recommend running `/reflect` with "update knowledge" option
```
