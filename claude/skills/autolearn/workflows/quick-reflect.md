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

### 3. Validate Proposed Rules

Before storing, run each HIGH-confidence finding through the validation pipeline
(see `references/validation-pipeline.md`):

1. **Dangerous pattern scan**: Check for blocked words (skip, bypass, ignore, suppress, disable, `--no-verify`, `--force`, nolint without justification). CRITICAL findings are rejected immediately.
2. **Core principles check**: Does the finding contradict any of the 10 core principles? If yes, reject.
3. **Risk classification**: LOW (auto-accept), MEDIUM (note in summary), HIGH (MCP Memory only, flag for review), CRITICAL (reject).

Skip validation for MEDIUM-confidence findings (they only go to MCP Memory, not rules files).

### 4. Check for Duplicates

Search MCP Memory for existing entities:

```text
search_nodes with keywords from each finding
```

If a match exists, plan to add an observation instead of creating a new entity.

### 5. Store Learnings

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

### 6. Scope Assessment and Rules Update

Determine where this session is running to decide how to handle rules:

**Detect context:**

- Check if `.sync-manifest.json` exists in the current working directory (or a parent)
- If found and contains `"version": 2`: this is the **DevKit repo** -- direct rules editing is allowed
- Otherwise: this is a **project context** -- rules files are read-only (symlinked)

**If in DevKit repo:**

Check tier boundaries before editing:

- **Tier 0** (`core-principles.md`, `error-policy.md`): NEVER modify. Immutable.
- **Tier 1** (`workflow-preferences.md`, `review-policy.md`): Do NOT edit directly.
  Create a DevKit issue instead.
- **Tier 2** (`autolearn-patterns.md`, `known-gotchas.md`): Safe to add entries directly.

**Update "last relevant" timestamps (DevKit context only):**

If an existing pattern or gotcha was actively applied during this session (not just read, but used to solve a problem or avoid a mistake), and the entry has a metadata line, update its `**Last relevant:**` field:

- If the entry already has `**Last relevant:**`, update the date
- If the entry has other metadata fields but no `**Last relevant:**`, append it
- If the entry has no metadata at all, skip (metadata addition is an audit task)

**If in a project (not DevKit):**

1. Store all learnings in MCP Memory only (step 5 above).
2. For findings that are universal (apply across projects) or stack-specific (apply to all projects using this language/framework), create a DevKit issue:

```bash
gh issue create -R HerbHall/devkit \
  --title "autolearn: <brief description>" \
  --body "Source project: $(basename $(pwd))
Category: <pattern|gotcha|correction>
Confidence: HIGH

<description of the learning>

Suggested rules file: <autolearn-patterns.md or known-gotchas.md>"
```

**Important:** Do NOT edit files in `~/.claude/rules/` -- they are symlinks to DevKit.

### 7. Report Summary

Present a brief summary to the user:

```text
## Quick Reflect Summary

**Learnings stored (MCP Memory):** N items
- [Category] Entity name: Brief description

**Skipped (already known):** N items
**Skipped (low confidence):** N items

**Validation results:**
- Rejected (CRITICAL): N items -- [reasons]
- Flagged for review (HIGH/MEDIUM): N items
- Accepted (LOW): N items

**Context:** [DevKit / Project (<name>)]
**Rules files updated:** [Yes (Tier 2 only) / No -- DevKit issues created instead]
- [List DevKit issue numbers if any were created]
```
