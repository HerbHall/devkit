# Audit All Open PRs

## Steps

### 1. Fetch All Open PRs

```bash
gh pr list --state open --json number,title,headRefName,updatedAt,statusCheckRollup,mergeable,reviewDecision --limit 50
```

### 2. Categorize Each PR

For each PR, determine its health status:

| Status | Criteria |
|--------|----------|
| Healthy | All checks pass, mergeable, no conflicts |
| Failing | One or more checks failing |
| Stale | No updates in 7+ days |
| Blocked | Has merge conflicts or missing reviews |
| Cancelled | All checks cancelled (needs re-run) |

### 3. Build Summary Report

Create a markdown table:

```text
| PR | Title | Branch | Status | Issues |
|----|-------|--------|--------|--------|
| #55 | feat: add repos | feature/x | Healthy | - |
| #41 | chore: ci/cd | chore/y | Failing | Lint, License |
```

### 4. Prioritize Issues

Order by severity:

1. PRs with all checks cancelled (quick fix: re-run)
2. PRs with pre-existing failures (fix in one place, unblocks many)
3. PRs with configuration failures (CI/workflow issues)
4. PRs with PR-introduced failures (code bugs)
5. Stale PRs (may need rebase or abandonment)

### 5. Recommend Actions

For each unhealthy PR, recommend a specific action:

- **Re-run**: `gh api repos/{owner}/{repo}/actions/runs/{id}/rerun -X POST`
- **Rebase**: `git checkout <branch> && git rebase main && git push --force-with-lease`
- **Fix**: Specific code change needed (describe)
- **Close**: PR is abandoned or superseded

### 6. Execute Fixes (with approval)

If the user wants to proceed:

1. Fix PRs in priority order
2. Start with shared issues (e.g., base-branch lint errors) that unblock multiple PRs
3. After fixing shared issues, rebase dependent PRs
4. Verify each PR's CI restarts

## Output

- Summary table of all open PRs with health status
- Prioritized action list
- Actions taken (if user approved fixes)
