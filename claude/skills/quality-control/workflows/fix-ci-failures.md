# Fix CI Failures Across All Open PRs

## Purpose
Automatically diagnose and fix CI failures across all open PRs. Prioritizes shared fixes that unblock multiple PRs.

## Steps

### 1. Gather All Open PRs with Failures
```bash
gh pr list --state open --json number,title,headRefName,statusCheckRollup --limit 50
```

Filter to only PRs with failing or cancelled checks.

### 2. Collect All Failure Details
For each failing PR, get the specific errors:
```bash
gh pr checks <number>
```

For each failing check, get error details:
```bash
gh run view <run_id> --log --job=<job_id> 2>&1 | grep -E "error|Error|FAIL|fatal" | head -20
```

### 3. Deduplicate Failures
Group identical failures across PRs. Common patterns:
- Same lint error appearing in multiple PRs (pre-existing in base)
- Same license check failure (configuration issue)
- Same build error (dependency issue)

Create a deduplicated failure list:

| Failure | Affected PRs | Category |
|---------|-------------|----------|
| gosec G101 in roles.go | #55, #42, #41 | Pre-existing |
| License check fails | #41 | Configuration |

### 4. Prioritize Fix Order

1. **Shared pre-existing failures** - Fix once in base, unblocks all PRs
2. **Configuration failures** - Fix in the affected workflow/config
3. **Infrastructure issues** - Re-run workflows
4. **PR-specific failures** - Fix on each PR branch

### 5. Apply Shared Fixes
For pre-existing failures:
1. Create a fix branch from main (or add to an existing PR)
2. Apply the fix
3. Run local verification
4. Push and create/update PR
5. Once merged, rebase all affected PR branches

### 6. Apply PR-Specific Fixes
For each remaining failure:
1. Checkout the PR branch
2. Apply the fix
3. Verify locally
4. Commit and push
5. Return to main branch before processing next PR

### 7. Rebase After Base Fixes
After shared fixes merge to main:
```bash
git checkout <pr-branch>
git rebase main
git push --force-with-lease
```

### 8. Verify All PRs
After all fixes are applied:
```bash
gh pr list --state open --json number,title,statusCheckRollup --limit 50
```

Report final status of all PRs.

## Output
- List of failures found and fixed
- List of PRs rebased
- Final status of all open PRs
- Any remaining issues requiring manual intervention
