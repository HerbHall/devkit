#!/bin/bash
# SessionStart Hook
# 1. Auto-pull DevKit updates (symlinked files update instantly)
# 2. CLAUDE.md detection for new projects

# ===== DevKit Auto-Pull =====
# Resolve DevKit clone path from ~/.devkit-config.json or common locations.
# Hardened: rate-limited (1/hour), lock-file aware, logs last 10 results.
devkit_pull() {
    local devkit_path=""
    local claude_dir="$HOME/.claude"
    local last_pull_file="$claude_dir/.devkit-last-pull"
    local log_file="$claude_dir/.devkit-pull.log"

    # Append to pull log, keep last 10 entries
    _devkit_log() {
        mkdir -p "$claude_dir"
        echo "$(date -u +%Y-%m-%dT%H:%M:%S) $1" >> "$log_file"
        local tmp; tmp=$(tail -n 10 "$log_file"); printf '%s\n' "$tmp" > "$log_file"
    }

    # Rate limiting: skip if last pull was less than 1 hour ago
    if [ -f "$last_pull_file" ]; then
        local last_epoch now_epoch elapsed
        last_epoch=$(cat "$last_pull_file" 2>/dev/null)
        now_epoch=$(date +%s 2>/dev/null)
        elapsed=$(( ${now_epoch:-0} - ${last_epoch:-0} ))
        if [ "$elapsed" -gt 0 ] && [ "$elapsed" -lt 3600 ]; then return 0; fi
    fi

    # Try ~/.devkit-config.json first
    local config="$HOME/.devkit-config.json"
    if [ -f "$config" ]; then
        local devspace
        devspace=$(grep -o '"devspacePath"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspacePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        if [ -z "$devspace" ]; then
            devspace=$(grep -o '"devspace"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        fi
        if [ -n "$devspace" ] && [ -f "$devspace/devkit/.sync-manifest.json" ]; then
            devkit_path="$devspace/devkit"
        fi
    fi

    # Fallback: common locations (no hardcoded drive letters)
    if [ -z "$devkit_path" ]; then
        for candidate in "$HOME/DevSpace/devkit" "$HOME/workspace/devkit" "$HOME/devkit"; do
            if [ -f "$candidate/.sync-manifest.json" ]; then
                devkit_path="$candidate"
                break
            fi
        done
    fi

    # No DevKit clone found — skip silently
    if [ -z "$devkit_path" ]; then
        return 0
    fi

    # Skip if git lock file present (another git operation in progress)
    if [ -f "$devkit_path/.git/index.lock" ]; then
        echo "DevKit: pull skipped -- git lock file present"
        _devkit_log "SKIPPED_LOCKED"
        return 0
    fi

    # Skip if working tree is dirty (user has uncommitted changes)
    if [ -n "$(git -C "$devkit_path" status --porcelain 2>/dev/null)" ]; then
        echo "DevKit: pull skipped -- local changes detected"
        _devkit_log "SKIPPED_DIRTY"
        return 0
    fi

    # Fetch with timeout (5s) to avoid blocking on network issues
    if ! timeout 5 git -C "$devkit_path" fetch origin 2>/dev/null; then
        _devkit_log "SKIPPED_OFFLINE"
        return 0
    fi

    # Count commits behind
    local behind
    behind=$(git -C "$devkit_path" rev-list HEAD..origin/main --count 2>/dev/null)

    if [ -z "$behind" ] || [ "$behind" -eq 0 ]; then
        echo "DevKit: up to date"
        _devkit_log "UP_TO_DATE"
        date +%s > "$last_pull_file"
        return 0
    fi

    # Pull with rebase
    if git -C "$devkit_path" pull --rebase origin main 2>/dev/null; then
        echo "DevKit: pulled $behind new commit(s)"
        # Check if rules files changed in the pull
        local rules_changed
        rules_changed=$(git -C "$devkit_path" diff HEAD~"$behind" HEAD --name-only -- claude/rules/ 2>/dev/null | wc -l)
        if [ "$rules_changed" -gt 0 ]; then
            echo "DevKit: $rules_changed rule file(s) updated. Symlinked projects are current."
        fi
        _devkit_log "PULLED_$behind"
        date +%s > "$last_pull_file"
    else
        echo "DevKit: pull failed -- run /devkit-sync pull manually"
        _devkit_log "PULL_FAILED"
    fi
}

devkit_pull

# ===== Version Check =====
# Compare local VERSION with origin/main after devkit_pull's fetch.
# Only prints when a newer version is available (no noise otherwise).
devkit_version_check() {
    local devkit_path="$1"

    # Nothing to check if no DevKit path or no VERSION file
    if [ -z "$devkit_path" ] || [ ! -f "$devkit_path/VERSION" ]; then
        return 0
    fi

    local current remote
    current=$(cat "$devkit_path/VERSION" 2>/dev/null | tr -d '[:space:]')
    remote=$(git -C "$devkit_path" show origin/main:VERSION 2>/dev/null | tr -d '[:space:]')

    # Skip if either version is empty or they match
    if [ -z "$current" ] || [ -z "$remote" ] || [ "$current" = "$remote" ]; then
        return 0
    fi

    echo "DevKit: new version available (current: $current, latest: $remote)"
}

# Resolve devkit_path using the same logic as devkit_pull for the version check.
# This duplicates path resolution but keeps devkit_pull's local scope intact.
_devkit_resolve_path() {
    local config="$HOME/.devkit-config.json"
    if [ -f "$config" ]; then
        local devspace
        devspace=$(grep -o '"devspacePath"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspacePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        if [ -z "$devspace" ]; then
            devspace=$(grep -o '"devspace"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        fi
        if [ -n "$devspace" ] && [ -f "$devspace/devkit/.sync-manifest.json" ]; then
            echo "$devspace/devkit"
            return 0
        fi
    fi
    for candidate in "$HOME/DevSpace/devkit" "$HOME/workspace/devkit" "$HOME/devkit"; do
        if [ -f "$candidate/.sync-manifest.json" ]; then
            echo "$candidate"
            return 0
        fi
    done
}

devkit_version_check "$(_devkit_resolve_path)"

# ===== Symlink Health Check =====
# Validates that critical DevKit files exist in ~/.claude/.
# Detects broken symlinks and missing files so the user can re-sync.
devkit_symlink_health() {
    local devkit_path="$1"
    local claude_dir="$HOME/.claude"
    local broken=0
    local missing=0

    # Skip if no DevKit path resolved
    if [ -z "$devkit_path" ]; then return 0; fi

    # Critical files that must exist in ~/.claude/
    local critical_targets=(
        "CLAUDE.md"
        "rules/core-principles.md"
        "rules/error-policy.md"
        "rules/autolearn-patterns.md"
        "rules/known-gotchas.md"
        "rules/workflow-preferences.md"
        "rules/review-policy.md"
        "rules/subagent-ci-checklist.md"
    )

    for rel in "${critical_targets[@]}"; do
        local target="$claude_dir/$rel"
        if [ -L "$target" ] && [ ! -e "$target" ]; then
            # Symlink exists but target is gone (broken)
            broken=$((broken + 1))
        elif [ ! -e "$target" ]; then
            # File doesn't exist at all
            missing=$((missing + 1))
        fi
    done

    if [ "$broken" -gt 0 ]; then
        echo "DevKit: $broken broken symlink(s) in ~/.claude/. Run: pwsh setup/sync.ps1 -Link"
    fi
    if [ "$missing" -gt 0 ]; then
        echo "DevKit: $missing critical file(s) missing from ~/.claude/. Run: pwsh setup/sync.ps1 -Link"
    fi
}

devkit_symlink_health "$(_devkit_resolve_path)"

# ===== CLAUDE.md Detection =====

# Skip if we're in the home directory
if [ "$PWD" = "$HOME" ]; then
    exit 0
fi

# Check if this is a project directory
is_project=false
if [ -d ".git" ] || [ -f "package.json" ] || [ -f "go.mod" ] || [ -f "Cargo.toml" ] || [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    is_project=true
fi

if [ "$is_project" = false ]; then
    exit 0
fi

# Already has CLAUDE.md — nothing to do
if [ -f "CLAUDE.md" ]; then
    exit 0
fi

# Already prompted once — don't nag
flag_file=".claude-init-prompted"
if [ -f "$flag_file" ]; then
    exit 0
fi

# Mark as prompted and add to gitignore
touch "$flag_file"
if [ -f ".gitignore" ] && ! grep -q "^\.claude-init-prompted$" .gitignore; then
    echo ".claude-init-prompted" >> .gitignore
fi

echo ""
echo "This project doesn't have a CLAUDE.md file."
echo "  Create one: 'Create a CLAUDE.md for this project'"
echo ""

exit 0
