# Full Sync

Complete bidirectional sync of all coordination files.

## Steps

### 1. Gather Current State

Run in parallel:

```bash
gh release list -R HerbHall/subnetree -L 3
gh issue list -R HerbHall/subnetree --state open --json number,title,labels --limit 20
git -C /d/DevSpace/SubNetree log --oneline -5
```

### 2. Update status.md

Edit `D:/DevSpace/.coordination/status.md`:
- Update SubNetree version, open issue count, recent commits
- Update HomeLab last activity date
- Refresh the "Current Capabilities" list if new features shipped
- Update frontmatter comments with current values

### 3. Scan for New Research Needs

Review the open SubNetree issues for potential research questions:
- New technology choices that need competitive analysis
- Feature requests that need market validation
- Integration requests that need feasibility assessment

For each potential need, suggest adding an RN-NNN entry. Ask user to confirm before creating.

### 4. Scan for New Research Findings

Check HomeLab for new or updated analysis files:

```bash
# Find recently modified analysis files
find /d/DevSpace/research/HomeLab/analysis/ -name "*.md" -newer /d/DevSpace/.coordination/research-findings.md 2>/dev/null
```

For each new analysis, suggest creating an RF-NNN entry. Ask user to confirm.

### 5. Update Priorities

Read `D:/DevSpace/.coordination/priorities.md`:
- Check if "This Week" date matches current week
- If stale, shift current week to history and create new week header
- Suggest re-ranking based on any new findings or completed work

### 6. Review Decisions

Read `D:/DevSpace/.coordination/decisions.md`:
- Flag any decisions older than 30 days that reference changing conditions
- Suggest review if competitive landscape has shifted

### 7. Commit Changes

```bash
cd /d/DevSpace/.coordination && git add -A && git diff --cached --stat
```

If changes exist, commit:

```bash
git commit -m "sync: full bidirectional sync $(date +%Y-%m-%d)"
```

### 8. Regenerate DASHBOARD.md

After all coordination files are updated, regenerate `D:/DevSpace/.coordination/DASHBOARD.md`:

1. Read all 5 updated coordination files
2. Run `gh issue list -R HerbHall/subnetree --state open --json number,title --limit 10`
3. Rebuild DASHBOARD.md with current data:
   - Update the "Last updated" timestamp
   - Refresh "Current State" table with version and issue count
   - Refresh "This Week" checklist from priorities.md
   - Refresh "Attention Required" counts from findings and needs
   - Refresh "Open Issues" table from GitHub

The DASHBOARD.md is included in the git add from step 7 (uses `git add -A`).

## Output

Summary table of what was updated:

| File | Changes |
|------|---------|
| status.md | Updated version to vX.Y.Z, N new commits |
| research-needs.md | Added N new RN-NNN entries |
| research-findings.md | Added N new RF-NNN entries |
| priorities.md | Re-ranked for current week |
| decisions.md | No changes / N flagged for review |
