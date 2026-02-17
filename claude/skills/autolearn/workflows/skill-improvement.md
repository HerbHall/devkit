# Skill Improvement

Analyze past mistakes from MCP Memory and improve existing skills/agents to prevent recurrence.

## Steps

### 1. Gather Correction History

Search MCP Memory for all corrections and recurring issues:
```
search_nodes: "correction"
search_nodes: "mistake"
search_nodes: "fix"
search_nodes: "failure"
```

Group findings by:
- **Recurring**: Same type of mistake happened more than once
- **Preventable**: A skill or rule could have prevented it
- **Systemic**: Points to a gap in workflow or tooling

### 2. Identify Improvement Targets

For each recurring or preventable issue, determine which skill or component could be improved:

| Issue Pattern | Improvement Target | Type |
|--------------|-------------------|------|
| Repeated lint errors | quality-control skill | Add diagnostic pattern |
| Missed test cases | go-development skill | Add testing checklist |
| CI config mistakes | setup-github-actions skill | Add validation step |
| Incomplete refactoring | rules/known-gotchas.md | Add gotcha entry |
| Forgotten MCP Memory saves | autolearn hooks | Adjust prompt |

### 3. Propose Changes

For each improvement target, draft the specific change:

**Skill updates:**
- Read the current skill file (SKILL.md, workflow .md, or reference .md)
- Identify where the new knowledge should be added
- Draft the addition (new section, new checklist item, new diagnostic pattern)

**Rules updates:**
- Identify which rules file needs the entry
- Draft the new entry following the existing format

**Hook updates:**
- If the autolearn hooks themselves need adjustment (e.g., Stop hook prompt is too broad or too narrow)
- Draft the modified prompt or script

### 4. Present Changes for Approval

Show each proposed change to the user:

```
## Proposed Skill Improvements

### 1. [Skill Name] - [Brief Description]
**File:** [path to file]
**Reason:** [What recurring issue this prevents]
**Change:**
[Diff or description of the change]

### 2. ...

Apply these changes? [Present each for approval]
```

### 5. Apply Approved Changes

For each approved change:
1. Read the target file
2. Apply the edit (Edit tool for existing files, Write for new sections)
3. Verify the file is well-formatted after the edit

Record the skill update in MCP Memory:
```
create_entities: [{
  name: "<skill-name>-update-<date>",
  entityType: "SkillUpdate",
  observations: ["[date] (source: global) (confidence: HIGH) Updated <skill> to <description>. Motivated by <recurring issue>."]
}]

create_relations: [{
  from: "<skill-name>-update-<date>",
  to: "<skill-name>",
  relationType: "IMPROVES"
}]
```

Report:
```
## Skill Improvement Summary

| Skill | Change | Motivated By |
|-------|--------|-------------|
| name  | description | recurring issue |

Changes applied: N
Changes deferred: N (with reasons)

Next review recommended after: [N more sessions or specific trigger]
```
