# Session End

Update status.md with development progress from this session.

## Steps

### 1. Gather Progress

Ask the user: "Brief summary of what was accomplished this session?"

### 2. Get Current State

```bash
git -C /d/DevSpace/SubNetree log --oneline -5
gh release list -R HerbHall/subnetree -L 1
```

### 3. Update status.md

Read and edit `D:/DevSpace/.coordination/status.md`:
- Update `updated` comment to today's date
- Update `subnetree_version` if a new release was made
- Replace "Recent Commits" with latest 5
- Update "Current Capabilities" if new features were shipped
- Update open issue count if issues were closed

### 4. Commit

```bash
cd /d/DevSpace/.coordination && git add status.md && git diff --cached --quiet || git commit -m "sync: dev session update $(date +%Y-%m-%d)"
```

### 5. Suggest Next Steps

- "Consider running `/coordination-sync` for a full bidirectional update."
- "Consider running `/reflect` to capture any learnings from this session."
