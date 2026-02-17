# Status Update

Quick refresh of status.md from current project state.

## Steps

### 1. Gather Data

Run in parallel:

```bash
gh release list -R HerbHall/subnetree -L 3
gh issue list -R HerbHall/subnetree --state open --json number,title --limit 20
git -C /d/DevSpace/SubNetree log --oneline -5
```

### 2. Update status.md

Read `D:/DevSpace/.coordination/status.md` and update:
- Frontmatter comments (updated date, version, issue count)
- Latest Release line
- Open Issues count
- Recent Commits section (replace with latest 5)

### 3. Commit if Changed

```bash
cd /d/DevSpace/.coordination && git add status.md && git diff --cached --quiet || git commit -m "sync: status update $(date +%Y-%m-%d)"
```

## Output

- Updated status.md with current values
- Git commit if changes were made
- Summary of what changed
