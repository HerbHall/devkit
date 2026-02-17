# Process Research Findings

Walk through unprocessed RF-NNN entries and decide what to do with each.

## Steps

### 1. Read Findings

Read `D:/DevSpace/.coordination/research-findings.md`. Extract all entries under `## Unprocessed`.

### 2. Present Each Finding

For each unprocessed entry, display:

```text
RF-{NNN}: {Title}
  Impact: {High/Medium/Low}
  Summary: {one-line summary}
  Action: {recommended action from the finding}

  Options:
  a) Mark as processed (acknowledged, no immediate action)
  b) Mark as processed + create GitHub issue
  c) Mark as processed + add to this week's priorities
  d) Skip for now (leave unprocessed)
```

Wait for user response before moving to the next finding.

### 3. Execute User Choice

**Option a (acknowledge):**

1. Move the entry from `## Unprocessed` to `## Processed` in research-findings.md
2. Add `- **Processed**: Yes` and `- **Processed Date**: {today}`
3. Add `- **Resolution**: Acknowledged, no immediate action`

**Option b (create issue):**

1. Create a GitHub issue:

```bash
gh issue create -R HerbHall/subnetree --title "{derived from finding}" --body "{finding summary + action}" --label "enhancement"
```

2. Move entry to `## Processed` with resolution noting the issue number

**Option c (add to priorities):**

1. Add the action item to `D:/DevSpace/.coordination/priorities.md` under `## This Week > ### SubNetree Development`
2. Move entry to `## Processed` with resolution noting it was prioritized

**Option d (skip):**

Leave the entry in `## Unprocessed`. Move to the next finding.

### 4. Commit Changes

```bash
cd /d/DevSpace/.coordination && git add research-findings.md priorities.md && git diff --cached --quiet || git commit -m "sync: process research findings $(date +%Y-%m-%d)"
```

### 5. Return to Dashboard

After all findings are processed (or skipped), display:

```text
Processed {N} of {total} findings. {remaining} still unprocessed.
Returning to dashboard menu...
```

Re-display the numbered menu from the dashboard.
