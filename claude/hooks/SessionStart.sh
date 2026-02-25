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
        _devkit_log "PULLED_$behind"
        date +%s > "$last_pull_file"
    else
        echo "DevKit: pull failed -- run /devkit-sync pull manually"
        _devkit_log "PULL_FAILED"
    fi
}

devkit_pull

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
