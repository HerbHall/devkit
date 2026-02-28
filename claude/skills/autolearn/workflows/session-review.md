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

### 6. Update Rules Files

**Tier boundary check (MANDATORY):**

- **Tier 0** (`core-principles.md`, `error-policy.md`): NEVER modify. These are immutable.
  Changes require a human-authored PR with explicit justification.
- **Tier 1** (`workflow-preferences.md`, `review-policy.md`): Propose changes only.
  Create a DevKit issue instead of editing directly.
- **Tier 2** (`autolearn-patterns.md`, `known-gotchas.md`): Autolearn can add entries.

Read current Tier 2 rules files:

- `~/.claude/rules/autolearn-patterns.md`
- `~/.claude/rules/known-gotchas.md`

For each HIGH-confidence finding that should be in rules:

1. Check if it's already in the appropriate file
2. If not, append a new numbered entry
3. Update the `entry_count` in YAML frontmatter
4. Update `last_updated` date

For findings that affect Tier 1 rules (workflow preferences, review policy):

1. Create a GitHub issue in the DevKit repo:
   `gh issue create -R HerbHall/devkit --title "rule: <description>" --body "..."`
2. Note the issue number in the session summary

Keep rules files concise. If a file exceeds 30 entries, consider archiving older/less-relevant entries.

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

### Rules Files Updated
- autolearn-patterns.md: +N entries
- known-gotchas.md: +N entries
- workflow-preferences.md: +N entries

### Skill Improvement Opportunities
- [Any recurring mistakes that suggest a skill should be updated]
- [Any workflow inefficiencies that could be automated]

### Recommendations
- [Suggested follow-up actions]

### DevKit Sync
- [Handled in Step 8 -- prompted user to push or skip]
```

### 8. DevKit Sync Check

After the summary, check if the DevKit clone has uncommitted changes:

```bash
# Find DevKit clone (same logic as quick-reflect step 6)
DEVKIT=$(python3 -c "import json; c=json.load(open('$HOME/.devkit-config.json')); print(c['devspace']+'/devkit')" 2>/dev/null)
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
