# Post-Push Verification

## Purpose
Monitor CI after pushing code to verify all checks pass. Designed to be used immediately after `git push` or `gh pr create`.

## Input
- PR number (ask if not provided, or detect from current branch)

## Steps

### 1. Detect PR
If no PR number given, detect from current branch:
```bash
gh pr view --json number,title,headRefName --jq '{number, title, branch: .headRefName}'
```

### 2. Initial Status Check
```bash
gh pr checks <number>
```

Report which checks are:
- Already passing
- Still pending/running
- Already failing (immediate diagnosis needed)

### 3. Monitor Running Checks
If checks are still running, wait 30 seconds and check again:
```bash
sleep 30 && gh pr checks <number>
```

Repeat up to 3 times (90 seconds total). After that, report current status and let the user know which checks are still pending.

### 4. Final Report

**If all checks pass:**
Report success. PR is ready for review/merge.

**If any checks fail:**
Transition to the check-pr workflow for diagnosis. Follow the steps in `workflows/check-pr.md`.

**If checks are still running after monitoring:**
Report current status and suggest the user can:
- Wait and run `/quality-control` again later
- Check manually with `gh pr checks <number>`

## Output
- Final check status table
- Whether PR is ready for merge
- Any failures diagnosed with recommended fixes
