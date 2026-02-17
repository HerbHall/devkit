# Sprint Planning

Plan next sprint across both projects.

## Steps

### 1. Gather Context

Read `D:/DevSpace/.coordination/priorities.md` and `D:/DevSpace/.coordination/status.md`.

```bash
gh issue list -R HerbHall/subnetree --state open --json number,title,labels --limit 20
```

### 2. Present Backlog

Show the combined backlog:

**SubNetree Issues (by label/priority)**

| # | Title | Labels |
|---|-------|--------|
| ... | ... | ... |

**Research Needs (Open)**

| # | Topic | Priority |
|---|-------|----------|
| RN-NNN | ... | High/Med/Low |

### 3. Recommend Sprint Scope

Based on recent velocity and priorities, suggest:
- **Dev**: 3-5 issues for SubNetree (mix of features, fixes, docs)
- **Research**: 2-3 research needs to process

Present reasoning for recommendations.

### 4. Get User Approval

Ask user to confirm, adjust, or reprioritize the sprint scope.

### 5. Create Missing Items

For approved dev items without GitHub issues:

```bash
gh issue create -R HerbHall/subnetree --title "{title}" --body "{description}" --label "enhancement"
```

For approved research items without RN-NNN entries, create them in research-needs.md.

### 6. Update Priorities

Write the sprint plan into `D:/DevSpace/.coordination/priorities.md`:
- "This Week" becomes the approved sprint items
- "Next Week" gets the overflow items

### 7. Commit

```bash
cd /d/DevSpace/.coordination && git add -A && git commit -m "plan: sprint planning $(date +%Y-%m-%d)"
```

## Output

- Sprint scope: N dev items + M research items
- GitHub issues created (if any)
- RN-NNN entries created (if any)
- Priorities updated and committed
