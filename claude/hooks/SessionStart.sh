#!/bin/bash
# SessionStart Hook
# 1. Auto-pull DevKit updates (symlinked files update instantly)
# 2. CLAUDE.md detection for new projects

# ===== DevKit Auto-Pull =====
# Resolve DevKit clone path from ~/.devkit-config.json or common locations
devkit_pull() {
    local devkit_path=""

    # Try ~/.devkit-config.json first
    local config="$HOME/.devkit-config.json"
    if [ -f "$config" ]; then
        # Extract devspace path using simple grep (no jq dependency)
        local devspace
        devspace=$(grep -o '"devspace"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        if [ -n "$devspace" ] && [ -f "$devspace/devkit/.sync-manifest.json" ]; then
            devkit_path="$devspace/devkit"
        fi
    fi

    # Fallback: common locations
    if [ -z "$devkit_path" ]; then
        for candidate in "$HOME/DevSpace/devkit" "/d/DevSpace/devkit" "$HOME/workspace/devkit"; do
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

    # Skip if working tree is dirty (user has uncommitted changes)
    if [ -n "$(git -C "$devkit_path" status --porcelain 2>/dev/null)" ]; then
        echo "DEVKIT_SYNC: Local changes detected — skipping pull"
        return 0
    fi

    # Fetch with timeout (5s) to avoid blocking on network issues
    if ! timeout 5 git -C "$devkit_path" fetch origin 2>/dev/null; then
        return 0  # Network unavailable — skip silently
    fi

    # Count commits behind
    local behind
    behind=$(git -C "$devkit_path" rev-list HEAD..origin/main --count 2>/dev/null)

    if [ -z "$behind" ] || [ "$behind" -eq 0 ]; then
        echo "DEVKIT_SYNC: Up to date"
        return 0
    fi

    # Pull with rebase
    if git -C "$devkit_path" pull --rebase origin main 2>/dev/null; then
        echo "DEVKIT_SYNC: Pulled $behind new commit(s)"
    else
        echo "DEVKIT_SYNC: Pull failed — run /devkit-sync pull manually"
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
