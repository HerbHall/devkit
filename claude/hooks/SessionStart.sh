#!/bin/bash
# SessionStart Hook - Dashboard status line + CLAUDE.md detection

COORD_DIR="/d/DevSpace/.coordination"

# Check if we're in a DevSpace project
is_devspace=false
case "$PWD" in
    /d/DevSpace/*|/c/Users/*/DevSpace/*|D:\\DevSpace\\*|D:/DevSpace/*)
        is_devspace=true
        ;;
esac

# DevSpace projects: show dashboard status line
if [ "$is_devspace" = true ] && [ -d "$COORD_DIR" ]; then
    # Count unprocessed findings
    findings=0
    if [ -f "$COORD_DIR/research-findings.md" ]; then
        findings=$(grep -c "Processed: No" "$COORD_DIR/research-findings.md" 2>/dev/null || echo 0)
    fi

    # Count open research needs
    needs=0
    if [ -f "$COORD_DIR/research-needs.md" ]; then
        needs=$(grep -c "Status: Open" "$COORD_DIR/research-needs.md" 2>/dev/null || echo 0)
    fi

    # Extract version from status.md
    version="unknown"
    if [ -f "$COORD_DIR/status.md" ]; then
        version=$(grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "$COORD_DIR/status.md" 2>/dev/null | head -1)
        [ -z "$version" ] && version="unknown"
    fi

    # Calculate staleness
    stale_msg=""
    if [ -f "$COORD_DIR/status.md" ]; then
        updated=$(grep -o 'updated: [0-9-]\+' "$COORD_DIR/status.md" 2>/dev/null | head -1 | cut -d' ' -f2)
        if [ -n "$updated" ]; then
            today=$(date +%s)
            updated_ts=$(date -d "$updated" +%s 2>/dev/null || echo 0)
            if [ "$updated_ts" -gt 0 ]; then
                days_ago=$(( (today - updated_ts) / 86400 ))
                if [ "$days_ago" -gt 3 ]; then
                    stale_msg=" | STALE (${days_ago}d since sync)"
                else
                    stale_msg=" | synced ${days_ago}d ago"
                fi
            fi
        fi
    fi

    # Build status line
    echo ""
    echo "Dashboard: ${version} | ${findings} new findings | ${needs} open needs${stale_msg}"
    echo "  Run /dashboard to start, or jump to a task directly."
    echo ""
    exit 0
fi

# Non-DevSpace: fall back to CLAUDE.md detection
if [ "$PWD" = "$HOME" ]; then
    exit 0
fi

is_project=false
if [ -d ".git" ] || [ -f "package.json" ] || [ -f "go.mod" ] || [ -f "Cargo.toml" ] || [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    is_project=true
fi

if [ "$is_project" = false ]; then
    exit 0
fi

if [ -f "CLAUDE.md" ]; then
    exit 0
fi

flag_file=".claude-init-prompted"
if [ -f "$flag_file" ]; then
    exit 0
fi

touch "$flag_file"
if [ -f ".gitignore" ] && ! grep -q "^\.claude-init-prompted$" .gitignore; then
    echo ".claude-init-prompted" >> .gitignore
fi

echo ""
echo "This project doesn't have a CLAUDE.md file."
echo "  Create one: 'Create a CLAUDE.md for this project'"
echo ""

exit 0
