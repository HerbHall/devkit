# Metrics Collection

Trigger PR metrics collection from GitHub API for all DevKit-managed repos.

## Steps

### 1. Run Collection Script

Execute the PR metrics collection script:

```bash
bash scripts/collect-pr-metrics.sh --days 30
```

If running in a context where `scripts/` is not the DevKit repo root, use the full path:

```bash
bash "$(git -C ~/.claude rev-parse --show-toplevel 2>/dev/null || echo d:/DevSpace/devkit)/scripts/collect-pr-metrics.sh" --days 30
```

### 2. Collect for Specific Repo (Optional)

If the user specifies a repo:

```bash
bash scripts/collect-pr-metrics.sh --repo OWNER/REPO --days 30
```

### 3. Report Results

After collection, show:

- Number of repos scanned
- Number of PRs collected
- Any errors encountered

Then suggest: "Run `/metrics dashboard` to view the results."
