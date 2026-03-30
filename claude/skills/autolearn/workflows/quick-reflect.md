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

For each HIGH-confidence finding, store in **both** MCP Memory and Synapset:

**MCP Memory (knowledge graph):**

```text
create_entities: [{
  name: "<kebab-case-name>",
  entityType: "<Pattern|Gotcha|Correction|Decision>",
  observations: ["[YYYY-MM-DD] (source: <project>) (confidence: HIGH) (category: <type>) <description>"]
}]
```

If existing entity found, use `add_observations` instead. Create relations with `create_relations` if applicable.

**Synapset (semantic vector memory):**

If Synapset MCP tools are available, also store in the appropriate pool:

```text
store_memory(pool: "devkit", content: "<description of the learning>",
  source: "<project>", category: "<pattern|gotcha|correction|decision>",
  tags: "<language>,<topic>", summary: "<one-line summary>")
```

Use pool `devkit` for cross-project learnings. Use the project name as pool for project-specific learnings. If Synapset tools are not available, skip -- MCP Memory is sufficient.

**Batch ingest sync:** When adding entries to Tier 2 rules files (AP/KG) during this session -- whether from session learnings or issue ingestion -- also store each new entry in Synapset:

```text
store_memory(pool: "devkit", content: "<full entry text including title, context, and fix>",
  category: "<pattern|gotcha|correction>", source: "<project>",
  tags: "<entry_id>,<category>", summary: "<entry title>")
```

This ensures the Synapset corpus stays in sync with rules files. Without this step, batch-ingested entries are invisible to semantic search.

### 5b. Record Pattern Applications

Scan the conversation for patterns that were actively used to solve a problem or avoid a mistake. Check **both** sources:

1. **Rules file references**: Look for AP#N or KG#N citations in the conversation
2. **Synapset search results**: Look for `search_memory` or `search_all` tool calls where a returned result influenced the solution. Use the memory ID as `SYN#<id>` (e.g., `SYN#412`)

For each pattern that helped, record an application event using SQLite MCP.

**Pre-check:** Before calling any `mcp__sqlite__*` tool, verify it appears in your available tools. If not listed, skip step 5b entirely. Do NOT attempt the call -- stdio MCP servers hang indefinitely when unavailable.

```text
write_query(database: "claude.db", query: "CREATE TABLE IF NOT EXISTS pattern_events (id INTEGER PRIMARY KEY AUTOINCREMENT, entry_id TEXT NOT NULL, entry_title TEXT, event_type TEXT NOT NULL, project TEXT, session_date TEXT NOT NULL, description TEXT, source TEXT); INSERT INTO pattern_events (entry_id, entry_title, event_type, project, session_date, description, source) VALUES ('<AP#N, KG#N, or SYN#id>', '<title>', '<prevented|caught|applied>', '<project>', datetime('now'), '<brief note>', '<rules-file|synapset>');"
)
```

If SQLite MCP is unavailable, skip -- pattern recording is best-effort.

### 6. Scope Assessment and Rules Update

Determine where this session is running to decide how to handle rules:

**Detect context:**

- Check if `.sync-manifest.json` exists in the current working directory (or a parent)
- If found and contains `"version": 2`: this is the **DevKit repo** -- direct rules editing is allowed
- Otherwise: this is a **project context** -- rules files are read-only (symlinked)

**If in DevKit repo:**

**Branch first.** Create a feature branch before editing any files:

```bash
git checkout main
git pull --ff-only
git checkout -b autolearn/$(date +%Y%m%d)-session-learnings
```

Check tier boundaries before editing:

- **Tier 0** (`core-principles.md`, `error-policy.md`): NEVER modify. Immutable.
- **Tier 1** (`workflow-preferences.md`, `review-policy.md`): Do NOT edit directly.
  Create a DevKit issue instead.
- **Tier 2** (`autolearn-patterns.md`, `known-gotchas.md`): Safe to add entries on the feature branch.

**Update "last relevant" timestamps (DevKit context only):**

If an existing pattern or gotcha was actively applied during this session (not just read, but used to solve a problem or avoid a mistake), and the entry has a metadata line, update its `**Last relevant:**` field:

- If the entry already has `**Last relevant:**`, update the date
- If the entry has other metadata fields but no `**Last relevant:**`, append it
- If the entry has no metadata at all, skip (metadata addition is an audit task)

**If in a project (not DevKit):**

1. Store all learnings in MCP Memory only (step 5 above).
2. For findings that are universal (apply across projects) or stack-specific (apply to all projects using this language/framework), create a DevKit issue:

Use the Samverk MCP `create_issue` tool:

- `project`: `devkit`
- `title`: `autolearn: <brief description>`
- `body`:

```text
Source project: <project name>
Category: <pattern|gotcha|correction>
Confidence: HIGH

<description of the learning>

Suggested rules file: <autolearn-patterns.md or known-gotchas.md>
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

### 8. Commit and PR (DevKit context only)

If rules files were modified in step 6, commit and open a PR:

```bash
git add ~/.claude/rules/autolearn-patterns.md ~/.claude/rules/known-gotchas.md
git commit -m "chore(rules): autolearn session -- <brief summary of learnings>"
git push origin HEAD
source scripts/forge-wrappers.sh
devkit-pr-create --title "chore(rules): autolearn session learnings" --body "<list of entries added>"
```

**Never commit directly to main.** The PR ensures changes are reviewable and CI passes before merge.
