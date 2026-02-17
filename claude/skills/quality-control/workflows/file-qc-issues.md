# File QC Issues

Create GitHub issues for findings from a QC testing session. Captures bugs, UX problems, and enhancement requests discovered during manual testing.

## Steps

### 1. Gather Findings

Ask the user (or review conversation history) for:
- Pages tested and screenshots reviewed
- Bugs found (broken functionality, errors, crashes)
- UX issues (confusing UI, missing links, poor defaults)
- Enhancement requests (new features, improvements)
- Items already fixed during the session (PRs merged)
- Items already filed as issues

### 2. Categorize Each Finding

| Category | Label | Description |
|----------|-------|-------------|
| Bug | `bug` | Broken functionality, errors, crashes |
| UX Issue | `bug` | Confusing UI, missing guidance, poor defaults |
| Enhancement | `enhancement` | New features, improvements, quality of life |
| Documentation | `documentation` | Missing help text, unclear instructions |

### 3. Check for Duplicates

For each finding, search existing issues:
```bash
gh issue list --state open --search "<keywords>" --json number,title --limit 5
```

Skip any finding that already has an open issue.

### 4. Batch Create Issues

For each new finding, create a GitHub issue with:
- Clear, specific title (action-oriented: "Windows Scout binary fails to run")
- Description with: what was observed, steps to reproduce (if applicable), expected vs actual behavior
- Appropriate label (`bug`, `enhancement`, `documentation`)
- "Found During" section noting QC session date

Use `gh issue create` with HEREDOC for the body:
```bash
gh issue create --title "Title" --body "$(cat <<'EOF'
## Description
...

## Found During
QC testing session (YYYY-MM-DD)
EOF
)" --label "bug"
```

Launch parallel `gh issue create` calls when possible (issues are independent).

### 5. Generate Summary

Present a markdown table of all session results:

```markdown
## QC Session Summary

### Fixed This Session
| PR | Fix |
|----|-----|
| #NNN | Description |

### Issues Filed This Session
| Issue | Title | Label |
|-------|-------|-------|
| #NNN | Title | bug/enhancement |

### Previously Filed
| Issue | Title |
|-------|-------|
| #NNN | Title |
```

## Output

- Count of issues created with links
- Summary table of all QC findings (fixed, filed, previously tracked)
- Recommendation for next QC session focus areas
