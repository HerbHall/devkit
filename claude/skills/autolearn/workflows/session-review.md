# Session Review

Comprehensive session retrospective. Extracts all learnings, syncs to MCP Memory, and updates rules files.

## Steps

### 1. Gather Session Context

Identify the scope of the session:

- What tasks were worked on?
- What files were created or modified?
- Were there any errors, failures, or corrections?
- What tools/commands were used?
- Were any new libraries, APIs, or patterns introduced?

### 2. Extract All Artifacts

Scan the full conversation for each category:

**Corrections** (highest priority):

- Code that didn't compile and was fixed
- Commands that failed and were retried differently
- Wrong assumptions that were corrected
- CI failures that were diagnosed and fixed

**Gotchas** (high priority):

- Platform-specific issues encountered
- Library or tool quirks discovered
- Configuration issues that were non-obvious
- Environment differences (local vs CI)

**Patterns** (high priority):

- Code patterns that proved effective
- Testing approaches that worked well
- Workflow sequences that were efficient
- Tool usage patterns worth repeating

**Decisions** (medium priority):

- Architecture or design choices made
- Library or tool selections with rationale
- Trade-offs resolved and why

**Preferences** (store once):

- New user preferences expressed during the session
- Workflow adjustments requested by the user

### 3. Cross-Reference with MCP Memory

For each extracted artifact:

```text
search_nodes with relevant keywords
```

Categorize each as:

- **New**: No existing entity -- needs to be created
- **Update**: Existing entity -- add observation
- **Duplicate**: Already stored with same information -- skip
- **Superseded**: Existing entity is outdated -- update and add SUPERSEDES relation

### 4. Store New Entities

Create entities for all NEW findings:

```text
create_entities: [
  { name: "...", entityType: "...", observations: ["[date] (source: ...) ..."] },
  ...
]
```

Add observations for UPDATE findings:

```text
add_observations: [
  { entityName: "...", contents: ["[date] ..."] },
  ...
]
```

### 5. Create Relations

Link learnings to their context:

```text
create_relations: [
  { from: "<learning>", to: "<project>", relationType: "DISCOVERED_IN" },
  { from: "<correction>", to: "<error-pattern>", relationType: "FIXES" },
  { from: "<pattern>", to: "<error-type>", relationType: "PREVENTS" },
  ...
]
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

Read current Tier 2 rules files and for each HIGH-confidence finding:

1. Check if it's already in the appropriate file
2. If not, append a new numbered entry
3. Update the `entry_count` in YAML frontmatter
4. Update `last_updated` date

Keep rules files concise. If a file exceeds 30 entries, consider archiving older entries.

**If in a project (not DevKit):**

1. Store all learnings in MCP Memory only (steps 3-5 above).
2. For findings that are universal or stack-specific, create a DevKit issue:

```bash
gh issue create -R HerbHall/devkit \
  --title "autolearn: <brief description>" \
  --body "Source project: $(basename $(pwd))
Category: <pattern|gotcha|correction>
Confidence: HIGH

<description of the learning>

Suggested rules file: <autolearn-patterns.md or known-gotchas.md>"
```

**Important:** Do NOT edit files in `~/.claude/rules/` from a project context -- they are symlinks to DevKit.

### 7. Generate Session Summary

Present a comprehensive summary:

```text
## Session Review Summary

### Tasks Completed
- [List of tasks worked on]

### Learnings Stored (MCP Memory)
| Entity | Type | Confidence | Action |
|--------|------|-----------|--------|
| name   | type | HIGH/MED  | New/Updated/Skipped |

### Context
- Running in: [DevKit / Project (<name>)]

### Rules Files Updated (DevKit context only)
- autolearn-patterns.md: +N entries
- known-gotchas.md: +N entries

### DevKit Issues Created (project context only)
- #NNN: <description>

### Skill Improvement Opportunities
- [Any recurring mistakes that suggest a skill should be updated]
- [Any workflow inefficiencies that could be automated]

### Recommendations
- [Suggested follow-up actions]
```
