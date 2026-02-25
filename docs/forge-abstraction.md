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

## Graceful Degradation

When `tea` is not installed and a Gitea repo is detected:

```text
[WARN] Gitea repo detected but 'tea' CLI is not installed.
       Install: https://gitea.com/gitea/tea/releases
       Then:    tea login add --name <name> --url <gitea-url> --token <token>
```

The wrapper returns exit code 1 so callers can handle the missing tool.
