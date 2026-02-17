# Session Start

Runs automatically when `/dashboard` is invoked. Reads coordination files and renders the control station display.

## Steps

### 1. Read Coordination Files

Read these files (summary sections only):

- `D:/DevSpace/.coordination/research-findings.md` -- extract entries under `## Unprocessed`
- `D:/DevSpace/.coordination/research-needs.md` -- extract entries under `## Open`
- `D:/DevSpace/.coordination/priorities.md` -- extract `## This Week` section
- `D:/DevSpace/.coordination/status.md` -- extract `updated` comment and SubNetree version

### 2. Fetch Live Data

```bash
git -C /d/DevSpace/SubNetree log --oneline -3
git -C /d/DevSpace/SubNetree branch --show-current
gh issue list -R HerbHall/subnetree --state open --json number --jq 'length'
```

### 3. Calculate Staleness

Parse the `<!-- updated: YYYY-MM-DD -->` comment from `status.md`. Calculate days since last update. Flag if >3 days.

### 4. Render Control Station

Output the following format, substituting live data:

Use markdown for readability. Bold the numbers so they stand out. Group by purpose.

```markdown
## SubNetree Control Station

**{version}** | **{issue_count}** open issues | `{branch}` branch
Research: **{unprocessed_count}** new findings | **{open_needs}** open needs
{if stale: "> Stale: status.md last updated {N} days ago -- run `7` to sync"}

Recent: `{commit1_hash}` {commit1_msg} | `{commit2_hash}` {commit2_msg} | `{commit3_hash}` {commit3_msg}

### Dev Priorities

**1** - {dev_priority_1}
**2** - {dev_priority_2}
**3** - {dev_priority_3}

### Research Priorities

**4** - {research_priority_1}
**5** - {research_priority_2}
**6** - {research_priority_3}

### Actions

| | | |
|---|---|---|
| **7** Sync all | **8** Sprint plan | **9** Weekly review |
| **10** File research need | **11** End-of-session | **12** Stale check |
| **13** Quick reference | **14** Workflow guide | **0** Refresh dashboard |

Pick a number (or describe what you need):
```

### 5. Wait for User Input

Do not proceed until the user selects an option. Route per the SKILL.md routing table.
