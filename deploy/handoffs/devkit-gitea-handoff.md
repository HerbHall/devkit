# DevKit Handoff — Gitea Setup and Migration

*Generated: 2026-03-17 | Source: Samverk Claude Code session*

## Context

Samverk completed all Gitea infrastructure work on 2026-03-17:

- Gitea upgraded to 1.25.5 on CT 200 (192.168.1.160:3000)
- `samverk` org standardized — all repos transferred
- Branch protection API confirmed working
- Daily backups configured (3 AM UTC)
- Release-please research: use semantic-release + @saithodev/semantic-release-gitea

DevKit has two blocked issues now unblocked.

## Tasks

### 1. Create samverk/devkit on Gitea (#393) — HIGH

The repo does NOT exist yet on Gitea. Create it and push code.

```bash
# Generate Gitea API token (SSH to CT 200)
ssh root@192.168.1.160 'su -s /bin/bash -c "/usr/local/bin/gitea admin user generate-access-token --username samverk-admin --token-name devkit-setup --scopes all --config /etc/gitea/app.ini" git'

# Create repo via API
GITEA_TOKEN="<token>"
curl -X POST "http://192.168.1.160:3000/api/v1/orgs/samverk/repos" \
  -H "Authorization: token $GITEA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "devkit", "private": true, "default_branch": "main"}'

# Push code from local clone
cd D:/DevSpace/devkit
git remote add gitea https://gitea.herbhall.net/samverk/devkit.git
git push gitea main
```

Then:

- Verify `.gitea/workflows/lint.yml` runs and passes
- Set branch protection: push whitelist samverk-admin, status checks
- Configure labels (base DevKit set)

### 2. DevKit issue migration plan (#394) — NORMAL

Decision already made in Samverk #632: **open-only migration, GitHub as read-only archive**. Apply same pattern:

- Migrate 5 open issues to Gitea
- Close GitHub issues with "moved" comment
- Keep HerbHall/devkit as public read-only archive

Close #394 with documented plan matching Samverk's approach.

### 3. Close #405 (autolearn entry)

Already stored in MCP Memory and Synapset. Close with "captured in autolearn" comment.

### 4. Register in Samverk server.yaml

After repo exists, SSH to CT 202 and add to server.yaml:

```yaml
  - name: devkit
    owner: samverk
    repo: devkit
    forge: gitea
    gitea_url: http://192.168.1.160:3000
```

Update existing `devkit` entry (currently points to GitHub HerbHall/devkit).

Restart: `systemctl restart samverk-serve`

## Infrastructure Reference

| Service | IP | Port |
|---------|-----|------|
| Gitea | 192.168.1.160 | 3000 |
| Samverk (server.yaml) | 192.168.1.162 | 8080 |

## Notes

- DevKit rules files are symlinked into other projects — repo transfer doesn't affect symlinks (they point to local paths, not git URLs)
- `.gitea/workflows/lint.yml` already exists in the repo — just needs Gitea runner to pick it up
- `metrics-collect.yml` port to Gitea deferred (low priority)
