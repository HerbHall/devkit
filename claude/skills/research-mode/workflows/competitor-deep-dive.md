# Competitor Deep-Dive

## Input

Ask the user for the competitor name and GitHub repo (owner/repo) if not already provided.

## Steps

### 1. Gather Repository Data

Run these commands in parallel:

```bash
gh api repos/{owner}/{repo} --jq '{stars: .stargazers_count, forks: .forks_count, language: .language, license: .license.spdx_id, created: .created_at, updated: .pushed_at, topics: .topics}'
gh api repos/{owner}/{repo}/contents/ --jq '.[].name'
gh release list -R {owner}/{repo} --limit 20
gh api repos/{owner}/{repo}/contributors --jq '.[] | {login, contributions}' | head -20
```

### 2. Analyze Architecture

Read key files via GitHub API:

```bash
gh api repos/{owner}/{repo}/contents/README.md --jq '.content' | base64 -d
gh api repos/{owner}/{repo}/contents/go.mod --jq '.content' | base64 -d 2>/dev/null
gh api repos/{owner}/{repo}/contents/docker-compose.yml --jq '.content' | base64 -d 2>/dev/null
```

Note: technology stack, dependencies, deployment model, architecture patterns.

### 3. Mine Issues for Pain Points

```bash
gh issue list -R {owner}/{repo} --state open --json number,title,comments,labels --limit 50
```

Sort by comment count (highest friction = most comments). Identify:
- Recurring themes (what users complain about most)
- Feature requests (what users want that doesn't exist)
- Architecture limitations (what the maintainers say they can't do)

### 4. Assess Release Cadence

From the release list, calculate:
- Average time between releases
- Trend (accelerating, decelerating, stalled)
- Major vs. patch ratio

### 5. Evaluate Contributor Health

From the contributors list, assess:
- Bus factor (how many contributors have >10% of commits)
- Activity trend (is the main contributor still active?)
- Community vs. solo project

### 6. Compile Analysis

Structure the output as:

| Category | Finding |
|----------|---------|
| **Stars/Forks** | X stars, Y forks |
| **Technology** | Language, key deps |
| **Architecture** | Monolith/plugin/agent/etc. |
| **Strengths** | What they do well |
| **Weaknesses** | Pain points from issues |
| **Gaps** | What they don't do that SubNetree does |
| **Threats** | What they do better than SubNetree |
| **Release Cadence** | Frequency and trend |
| **Bus Factor** | Contributor concentration |

### 7. Publish Finding

Create an RF-NNN entry in `D:/DevSpace/.coordination/research-findings.md`:
1. Determine next RF-NNN number
2. Write entry under `## Unprocessed` with source, impact, summary, and recommended action
3. Remind user: "Run `/coordination-sync` to propagate this finding."

### 8. Update MCP Memory

Store the competitor as an entity in MCP Memory:

```
Entity: {CompetitorName} (type: Competitor)
Observations: stars, architecture, key strengths, key weaknesses, last analyzed date
Relation: COMPETES_WITH -> SubNetree-Project
```

## Output

- Structured analysis table
- RF-NNN entry published
- MCP Memory updated
- Recommended actions for SubNetree
