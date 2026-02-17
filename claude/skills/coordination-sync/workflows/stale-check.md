# Stale Check

Identify outdated coordination data that needs updating.

## Steps

### 1. Check status.md Freshness

Read `D:/DevSpace/.coordination/status.md`:
- Compare `subnetree_version` comment against `gh release list -R HerbHall/subnetree -L 1`
- Compare recent commits against `git -C /d/DevSpace/SubNetree log --oneline -1`
- Flag if version is behind or commits are stale (>3 days old)

### 2. Check Research Needs Age

Read `D:/DevSpace/.coordination/research-needs.md`:
- List all entries under `## Open`
- Flag any with `Created` date older than 14 days
- Report: "RN-NNN has been open for X days"

### 3. Check Unprocessed Findings Age

Read `D:/DevSpace/.coordination/research-findings.md`:
- List all entries under `## Unprocessed`
- Flag any with `Created` date older than 7 days
- Report: "RF-NNN has been unprocessed for X days"

### 4. Check Priorities Currency

Read `D:/DevSpace/.coordination/priorities.md`:
- Check if "This Week" header date matches current week
- If not: flag as stale, suggest running full sync

### 5. Check Decisions Relevance

Read `D:/DevSpace/.coordination/decisions.md`:
- Flag any decisions older than 60 days
- Note if conditions cited in "Evidence" may have changed

### 6. Report

Present a stale-check summary:

```text
Coordination Hub Stale Check
=============================
status.md:           [FRESH/STALE] - last updated {date}, current version {v}
research-needs.md:   {N} open, {M} stale (>14 days)
research-findings.md:{N} unprocessed, {M} stale (>7 days)
priorities.md:       [CURRENT/STALE] - last week header: {date}
decisions.md:        {N} total, {M} may need review (>60 days)

Recommended actions:
- {list of specific actions to bring stale items current}
```
