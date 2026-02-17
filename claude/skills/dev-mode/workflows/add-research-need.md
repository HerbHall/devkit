# Add Research Need

File a new RN-NNN research request from a development need.

## Steps

### 1. Get Next Number

Read `D:/DevSpace/.coordination/research-needs.md` and count existing RN-NNN entries (both Open and Completed) to determine the next sequential number.

### 2. Gather Details

Ask the user for:
- **Topic**: What needs researching? (brief title)
- **Priority**: High / Medium / Low
- **Context**: What triggered this? What are you working on?
- **Deliverable**: What output do you expect? (analysis doc, comparison table, recommendation, etc.)

### 3. Write Entry

Edit `D:/DevSpace/.coordination/research-needs.md` and add under `## Open`:

```markdown
### RN-NNN - {Topic}

- **Priority**: {High/Medium/Low}
- **Source**: SubNetree development
- **Context**: {context}
- **Deliverable**: {expected output}
- **Status**: Open
- **Created**: {today's date YYYY-MM-DD}
```

### 4. Confirm

Report: "Research need RN-NNN filed: {topic}. Priority: {level}."
Suggest: "Run `/coordination-sync` to propagate, or it will be picked up on next full sync."
