# Forge Abstraction Layer

## Problem

DevKit skills (`manage-github-issues`, `devkit-sync`, `quality-control`) call `gh` CLI directly. This breaks on Gitea-hosted repositories where `tea` CLI is the equivalent tool. A thin abstraction lets the same skills work with both forges.

## Forge Detection

Parse the git remote URL to identify the forge automatically:

```bash
remote_url="$(git remote get-url origin 2>/dev/null)"
case "$remote_url" in
  *github.com*) forge="github" ;;
  *)            forge="gitea"  ;;
esac
```

GitHub repos are detected by domain. Everything else falls back to Gitea, which can be overridden via `.devkit-config.json` (see Configuration below).

## CLI Mapping

| Operation | `gh` | `tea` |
|-----------|------|-------|
| List issues | `gh issue list` | `tea issues list` |
| Create issue | `gh issue create` | `tea issues create` |
| View issue | `gh issue view N` | `tea issues N` |
| Create PR | `gh pr create` | `tea pulls create` |
| Merge PR | `gh pr merge` | `tea pulls merge` |
| PR checks | `gh pr checks` | Not available -- skip |
| Auth status | `gh auth status` | `tea whoami` |

Flags differ between CLIs. Wrappers normalize the interface so callers pass a consistent set of arguments.

## Wrapper Approach

Source `scripts/forge-wrappers.sh` to get dispatch functions. Each function detects the forge, then delegates to the correct CLI:

```bash
devkit-forge-detect() {
  local url
  url="$(git remote get-url origin 2>/dev/null)"
  case "$url" in
    *github.com*) echo "github" ;;
    *)            echo "gitea"  ;;
  esac
}

devkit-issue-create() {
  local title="$1" body="$2"
  case "$(devkit-forge-detect)" in
    github) gh issue create --title "$title" --body "$body" ;;
    gitea)  tea issues create --title "$title" --description "$body" ;;
  esac
}
```

The full set of wrappers (`devkit-issue-list`, `devkit-pr-create`, `devkit-pr-merge`, `devkit-pr-list`, `devkit-auth-status`) follows the same pattern. Implementation: `scripts/forge-wrappers.sh`.

## Configuration

The `forge` field in `~/.devkit-config.json` (machine tier, per [ADR-0012](ADR-0012-three-tier-architecture.md)) stores forge preferences:

```json
{
  "forge": {
    "primary": "gitea",
    "giteaUrl": "http://192.168.1.160:3000"
  }
}
```

- **primary** -- `"gitea"` (default) or `"github"`. Overrides auto-detection when set.
- **giteaUrl** -- Base URL of the Gitea instance. Required for `tea` login and API calls.

**GitHub is deprecated as a forge.** The SessionStart hook automatically rewrites the `origin` remote from GitHub to Gitea and patches `forge.primary` to `"gitea"` on all fleet machines. GitHub references in older configs are auto-corrected on the next session start.

## Affected Skills

| Skill | `gh` usage | Change needed |
|-------|-----------|---------------|
| `manage-github-issues` | `gh issue list`, `gh issue create`, `gh label list` | Replace with `devkit-issue-*` wrappers |
| `devkit-sync` | `gh pr create` in push workflow | Replace with `devkit-pr-create` wrapper |
| `quality-control` | `gh pr checks`, `gh pr view` | Replace with wrappers; skip PR checks on Gitea |

## Forge-Specific Settings

Some settings are UI-only and differ between forges:

| Setting | GitHub | Gitea |
|---------|--------|-------|
| Actions PR permission | Settings > Actions > General > Workflow permissions > "Allow GitHub Actions to create and approve pull requests" | Not applicable (Gitea Actions uses different permission model) |
| Copilot auto-review | Settings > Rules > Rulesets > enable Copilot review toggle | Not available (GitHub-only feature) |
| Auto-merge | `gh api repos/OWNER/REPO -X PATCH -f allow_auto_merge=true` | Repository settings > enable auto-merge (UI) |

These settings cannot be abstracted by the forge wrapper -- they must be configured manually per repository on each forge.

## Gitea Actions API for CI Status

Gitea provides a REST API for Actions workflow runs at `/api/v1/repos/{owner}/{repo}/actions/runs`. This could substitute for `gh pr checks` on Gitea-hosted repos.

### API Endpoint

```text
GET /api/v1/repos/{owner}/{repo}/actions/runs
```

Returns a list of workflow runs with `status` and `conclusion` fields. Filtering by branch or PR is possible via query parameters.

### Feasibility Assessment

**Viable but not yet implemented.** The API exists and returns the needed data, but:

1. `tea` CLI does not expose Actions runs (as of tea v0.9). Raw `curl` calls against the Gitea API would be required.
2. Mapping PR number to a specific workflow run requires correlating the PR's head branch with the run's branch — `gh pr checks` does this automatically.
3. Authentication requires a Gitea API token (already configured if `tea login` was run).

### Current Status

The `devkit-pr-checks()` wrapper in `scripts/forge-wrappers.sh` returns exit code 1 with a warning on Gitea repos. A future enhancement could implement the API call:

```bash
# Potential implementation (not yet active):
curl -s -H "Authorization: token $GITEA_TOKEN" \
  "$GITEA_URL/api/v1/repos/$OWNER/$REPO/actions/runs?branch=$HEAD_BRANCH" \
  | python3 -c "import json,sys; runs=json.load(sys.stdin)['workflow_runs']; \
    print('pass' if all(r['conclusion']=='success' for r in runs) else 'fail')"
```

This is deferred until a Gitea-hosted project needs CI status checking in automation.

## Graceful Degradation

When `tea` is not installed and a Gitea repo is detected:

```text
[WARN] Gitea repo detected but 'tea' CLI is not installed.
       Install: https://gitea.com/gitea/tea/releases
       Then:    tea login add --name <name> --url <gitea-url> --token <token>
```

The wrapper returns exit code 1 so callers can handle the missing tool.
