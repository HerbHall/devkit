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
```
search_nodes with relevant keywords
```

Categorize each as:
- **New**: No existing entity -- needs to be created
- **Update**: Existing entity -- add observation
- **Duplicate**: Already stored with same information -- skip
- **Superseded**: Existing entity is outdated -- update and add SUPERSEDES relation

### 4. Store New Entities

Create entities for all NEW findings:
```
create_entities: [
  { name: "...", entityType: "...", observations: ["[date] (source: ...) ..."] },
  ...
]
```

Add observations for UPDATE findings:
```
add_observations: [
  { entityName: "...", contents: ["[date] ..."] },
  ...
]
```

### 5. Create Relations

Link learnings to their context:
```
create_relations: [
  { from: "<learning>", to: "<project>", relationType: "DISCOVERED_IN" },
  { from: "<correction>", to: "<error-pattern>", relationType: "FIXES" },
  { from: "<pattern>", to: "<error-type>", relationType: "PREVENTS" },
  ...
]
```

### 6. Update Rules Files

Read current rules files:
- `~/.claude/rules/autolearn-patterns.md`
- `~/.claude/rules/known-gotchas.md`
- `~/.claude/rules/workflow-preferences.md`

For each HIGH-confidence finding that should be in rules:
1. Check if it's already in the appropriate file
2. If not, append a new numbered entry
3. Update the `entry_count` in YAML frontmatter
4. Update `last_updated` date

Keep rules files concise. If a file exceeds 30 entries, consider archiving older/less-relevant entries.

### 7. Generate Session Summary

Present a comprehensive summary:

```
## Session Review Summary

### Tasks Completed
- [List of tasks worked on]

### Learnings Stored (MCP Memory)
| Entity | Type | Confidence | Action |
|--------|------|-----------|--------|
| name   | type | HIGH/MED  | New/Updated/Skipped |

### Rules Files Updated
- autolearn-patterns.md: +N entries
- known-gotchas.md: +N entries
- workflow-preferences.md: +N entries

### Skill Improvement Opportunities
- [Any recurring mistakes that suggest a skill should be updated]
- [Any workflow inefficiencies that could be automated]

### Recommendations
- [Suggested follow-up actions]
```
