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

Add dispatch functions to `claude-functions.sh`. Each function detects the forge, then delegates to the correct CLI:

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

The full set of wrappers (`devkit-issue-list`, `devkit-pr-create`, `devkit-pr-merge`) follows the same pattern. Each is under 10 lines.

## Configuration

The `forge` field in `~/.devkit-config.json` (machine tier, per [ADR-0012](ADR-0012-three-tier-architecture.md)) stores forge preferences:

```json
{
  "forge": {
    "primary": "github",
    "giteaUrl": null
  }
}
```

- **primary** -- `"github"` or `"gitea"`. Overrides auto-detection when set.
- **giteaUrl** -- Base URL of the Gitea instance (e.g., `https://git.example.com`). Required for `tea` login.

GitHub repos need no configuration. Gitea repos require `giteaUrl` to be set once per machine.

## Affected Skills

| Skill | `gh` usage | Change needed |
|-------|-----------|---------------|
| `manage-github-issues` | `gh issue list`, `gh issue create`, `gh label list` | Replace with `devkit-issue-*` wrappers |
| `devkit-sync` | `gh pr create` in push workflow | Replace with `devkit-pr-create` wrapper |
| `quality-control` | `gh pr checks`, `gh pr view` | Replace with wrappers; skip PR checks on Gitea |

## Forge-Specific Settings

Some settings are UI-only and differ between forges. When migrating repos from GitHub to Gitea (or vice versa), configure the equivalent settings on the target forge.

### Actions PR Permission

Workflows that create or modify PRs (release-please, retrigger-ci, release-gate) require explicit permission to do so. Without this, PRs are never opened and workflows fail silently.

**GitHub**:

- **Path**: Repository Settings → Actions → General → Workflow permissions
- **Setting**: "Allow GitHub Actions to create and approve pull requests" (checkbox)
- **Default**: Disabled on new repos
- **API**: Not available -- must be set in the UI
- **Failure mode**: Workflow log shows `Resource not accessible by integration` or `HttpError: GitHub Actions is not permitted to create or approve pull requests`

**Gitea**:

- **Path (site-wide)**: Site Administration → Settings → Repository (or Admin Panel → Settings depending on version)
- **Path (per-repo)**: Repository Settings → Actions (if the repo-level toggle exists in your Gitea version)
- **Setting**: "Allow Actions to create pull requests" -- the exact label varies by Gitea version (1.21+ introduced granular Actions permissions)
- **Default**: Depends on site-wide configuration; check with your Gitea administrator
- **Docs**: [Gitea Actions documentation](https://docs.gitea.com/usage/actions/overview) and [Gitea Actions permissions](https://docs.gitea.com/usage/actions/comparison#permissions)
- **Note**: Gitea 1.22+ aligns more closely with GitHub Actions permissions. Earlier versions may require site-level configuration. If the per-repo toggle is not visible, the site administrator must enable it globally

### Copilot Auto-Review (GitHub only)

GitHub Copilot code review is a GitHub-specific feature with no Gitea equivalent. Repos migrating to Gitea should replace Copilot review with an alternative code review mechanism (e.g., required human review count in branch protection, or a self-hosted review bot).

## Graceful Degradation

When `tea` is not installed and a Gitea repo is detected:

```text
[WARN] Gitea repo detected but 'tea' CLI is not installed.
       Install: https://gitea.com/gitea/tea/releases
       Then:    tea login add --name <name> --url <gitea-url> --token <token>
```

The wrapper returns exit code 1 so callers can handle the missing tool.
