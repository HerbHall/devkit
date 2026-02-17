# Publish Research Finding

Create a new RF-NNN entry in research-findings.md. Called by other workflows or directly.

## Steps

### 1. Determine Next Number

Read `D:/DevSpace/.coordination/research-findings.md` and count existing RF-NNN entries (both Unprocessed and Processed) to determine the next sequential number.

### 2. Gather Finding Details

Collect from the user or from the calling workflow:
- **Source**: Where this finding came from (analysis file path, URL, or RN-NNN reference)
- **Impact**: High / Medium / Low
- **Summary**: 2-3 sentence description of the finding
- **Action**: Specific recommended action for SubNetree development

### 3. Write Entry

Edit `D:/DevSpace/.coordination/research-findings.md` and add under `## Unprocessed`:

```markdown
### RF-NNN - {Title}

- **Source**: {source}
- **Impact**: {High/Medium/Low}
- **Summary**: {summary}
- **Action**: {recommended action}
- **Processed**: No
- **Created**: {today's date YYYY-MM-DD}
```

### 4. Confirm

Report to user:
- "Published RF-NNN: {title}"
- "Impact: {level}"
- "Run `/coordination-sync` to propagate this finding to status and priorities."
