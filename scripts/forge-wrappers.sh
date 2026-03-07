#!/usr/bin/env bash
# forge-wrappers.sh -- Forge abstraction layer for DevKit skills.
#
# Source this file to get portable wrapper functions that work with
# both GitHub (gh) and Gitea (tea) CLIs.
#
# Usage:
#   source scripts/forge-wrappers.sh
#   devkit-forge-detect          # prints "github" or "gitea"
#   devkit-pr-create --title "feat: ..." --body "..." --head "branch"
#
# See docs/forge-abstraction.md for the full specification.

set -euo pipefail

# ---------------------------------------------------------------------------
# devkit-forge-detect -- Identify the forge from git remote or config override
# ---------------------------------------------------------------------------
devkit-forge-detect() {
  # Check config override first
  local config="$HOME/.devkit-config.json"
  if [[ -f "$config" ]]; then
    local override
    override="$(python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    p = d.get('forge', {}).get('primary', '')
    if p: print(p)
except Exception:
    pass
" "$config" 2>/dev/null || true)"
    if [[ -n "$override" ]]; then
      echo "$override"
      return 0
    fi
  fi

  # Auto-detect from git remote
  local url
  url="$(git remote get-url origin 2>/dev/null || true)"
  case "$url" in
    *github.com*) echo "github" ;;
    *)            echo "gitea"  ;;
  esac
}

# ---------------------------------------------------------------------------
# _devkit-require-tea -- Check that tea CLI is installed; warn and fail if not
# ---------------------------------------------------------------------------
_devkit-require-tea() {
  if ! command -v tea &>/dev/null; then
    echo "[WARN] Gitea repo detected but 'tea' CLI is not installed." >&2
    echo "       Install: https://gitea.com/gitea/tea/releases" >&2
    echo "       Then:    tea login add --name <name> --url <gitea-url> --token <token>" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# devkit-auth-status -- Check forge authentication
# ---------------------------------------------------------------------------
devkit-auth-status() {
  case "$(devkit-forge-detect)" in
    github) gh auth status ;;
    gitea)  _devkit-require-tea && tea whoami ;;
  esac
}

# ---------------------------------------------------------------------------
# devkit-issue-list -- List issues (pass-through flags after forge dispatch)
# ---------------------------------------------------------------------------
devkit-issue-list() {
  case "$(devkit-forge-detect)" in
    github) gh issue list "$@" ;;
    gitea)  _devkit-require-tea && tea issues list "$@" ;;
  esac
}

# ---------------------------------------------------------------------------
# devkit-issue-create -- Create an issue
#   --title "title"  --body "body"  [extra flags passed through]
# ---------------------------------------------------------------------------
devkit-issue-create() {
  local title="" body=""
  local -a extra=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title) title="$2"; shift 2 ;;
      --body)  body="$2";  shift 2 ;;
      *)       extra+=("$1"); shift ;;
    esac
  done

  case "$(devkit-forge-detect)" in
    github) gh issue create --title "$title" --body "$body" "${extra[@]+"${extra[@]}"}" ;;
    gitea)  _devkit-require-tea && tea issues create --title "$title" --description "$body" "${extra[@]+"${extra[@]}"}" ;;
  esac
}

# ---------------------------------------------------------------------------
# devkit-pr-create -- Create a pull request
#   --title "title"  --body "body"  --head "branch"  [extra flags]
# ---------------------------------------------------------------------------
devkit-pr-create() {
  local title="" body="" head=""
  local -a extra=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title) title="$2"; shift 2 ;;
      --body)  body="$2";  shift 2 ;;
      --head)  head="$2";  shift 2 ;;
      *)       extra+=("$1"); shift ;;
    esac
  done

  case "$(devkit-forge-detect)" in
    github)
      gh pr create --title "$title" --body "$body" \
        ${head:+--head "$head"} "${extra[@]+"${extra[@]}"}"
      ;;
    gitea)
      _devkit-require-tea && tea pulls create --title "$title" --description "$body" \
        ${head:+--head "$head"} "${extra[@]+"${extra[@]}"}"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# devkit-pr-list -- List pull requests (pass-through flags)
# ---------------------------------------------------------------------------
devkit-pr-list() {
  case "$(devkit-forge-detect)" in
    github) gh pr list "$@" ;;
    gitea)  _devkit-require-tea && tea pulls list "$@" ;;
  esac
}

# ---------------------------------------------------------------------------
# devkit-pr-merge -- Merge a pull request
#   First positional arg is PR number/URL. Extra flags passed through.
# ---------------------------------------------------------------------------
devkit-pr-merge() {
  case "$(devkit-forge-detect)" in
    github) gh pr merge "$@" ;;
    gitea)  _devkit-require-tea && tea pulls merge "$@" ;;
  esac
}
