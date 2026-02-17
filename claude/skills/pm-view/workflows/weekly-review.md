# Weekly Review

Structured review of both projects with priority re-ranking.

## Steps

### 1. Gather State

Read all 5 coordination files. Also run:

```bash
gh release list -R HerbHall/subnetree -L 1
gh issue list -R HerbHall/subnetree --state open --json number,title --limit 20
git -C /d/DevSpace/SubNetree log --oneline -5
```

### 2. Present Dashboard

```text
Weekly Review - {date}
======================

SubNetree
  Version: vX.Y.Z | Open Issues: N
  Recent: {last 3 commit summaries}

Research
  Open Needs: N (RN-NNN: {titles})
  Unprocessed Findings: N (RF-NNN: {titles})

Decisions
  Recent (last 7 days): {count}
  Total: {count}

Stale Items
  {list any stale items from stale-check logic}
```

### 3. Review Unprocessed Items

For each unprocessed RF-NNN:
- Present summary and recommended action
- Ask: "Process this finding? (mark as processed, create issue, defer)"

For each open RN-NNN older than 7 days:
- Ask: "Still relevant? (keep, deprioritize, close)"

### 4. Re-rank Priorities

Present current priorities from priorities.md.
Ask user to re-rank for the coming week:
- What should be #1 for SubNetree dev?
- What should be #1 for HomeLab research?
- Anything to add or remove?

### 5. Update priorities.md

- Archive current "This Week" section (move to end of file or remove)
- Write new "This Week ({date})" with user-approved rankings
- Update "Next Week" if needed

### 6. Commit

```bash
cd /d/DevSpace/.coordination && git add -A && git commit -m "review: weekly review $(date +%Y-%m-%d)"
```

## Output

- Dashboard summary presented
- Stale items identified and addressed
- Priorities re-ranked for coming week
- All changes committed
