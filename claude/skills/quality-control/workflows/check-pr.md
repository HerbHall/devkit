# Check a Specific PR

## Input

Ask the user for the PR number if not already provided.

## Steps

### 1. Gather PR Information

Run these commands in parallel:

```bash
gh pr view <number> --json title,headRefName,state,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,body
gh pr checks <number>
```

### 2. Classify Each Check

For each check in the status rollup:

- **pass** - No action needed
- **fail** - Needs diagnosis (proceed to step 3)
- **pending** - Still running (note and report)
- **cancelled** - May need re-run (check if all checks are cancelled)

### 3. Diagnose Failures

For each failing check:

1. Get the workflow run ID from the checks output
2. Get job details:

   ```bash
   gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs --jq '.jobs[] | select(.conclusion == "failure") | {name: .name, steps: [.steps[] | select(.conclusion == "failure") | {name: .name}]}'
   ```

3. Get error logs:

   ```bash
   gh run view {run_id} --log --job={job_id} 2>&1 | grep -E "error|Error|FAIL|fatal|level=error" | head -20
   ```

4. Match error against known patterns from the `<diagnostics>` section in SKILL.md
5. Classify as: PR-introduced, base-branch, infrastructure, configuration, or dependency

### 4. Report Findings

Present a summary table:

| Check | Status | Category | Root Cause | Fix |
|-------|--------|----------|------------|-----|
| Build | pass | - | - | - |
| Lint | fail | base-branch | gosec G101 false positive | Add nolint directive |

### 5. Propose Fixes

For each fixable failure:

- Describe the specific fix needed
- Identify which file(s) to modify
- Ask user for permission to proceed if changes affect files outside the PR's scope

### 6. Apply Fixes

If user approves:

1. Checkout the PR branch
2. Apply fixes
3. Run local verification (go build, go test, go vet)
4. Commit with descriptive message
5. Push to trigger new CI run

### 7. Verify Fix

After pushing:

1. Wait for CI to start (check after 30 seconds)
2. Report initial check status
3. Note any checks still running

## Output

- Summary of all checks and their status
- Actions taken (fixes applied, re-runs triggered)
- Remaining issues that need manual intervention
