#!/usr/bin/env bash
# Verify devkit installation
# Checks that all configuration files are in place

set -euo pipefail

CLAUDE_HOME="$HOME/.claude"
PASS=0
FAIL=0

check() {
    if [ -e "$1" ]; then
        echo "  [OK] $2"
        PASS=$((PASS + 1))
    else
        echo "  [MISSING] $2 ($1)"
        FAIL=$((FAIL + 1))
    fi
}

check_dir() {
    local count
    count=$(ls "$1" 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        echo "  [OK] $2 ($count items)"
        PASS=$((PASS + 1))
    else
        echo "  [EMPTY] $2 ($1)"
        FAIL=$((FAIL + 1))
    fi
}

echo "Verifying Claude Code configuration..."
check "$CLAUDE_HOME/CLAUDE.md" "Global CLAUDE.md"
check "$CLAUDE_HOME/settings.json" "Settings file"
check "$CLAUDE_HOME/claude-functions.sh" "Shell helper functions"
check_dir "$CLAUDE_HOME/rules" "Rules directory"
check_dir "$CLAUDE_HOME/skills" "Skills directory"
check_dir "$CLAUDE_HOME/agents" "Agents directory"
check "$CLAUDE_HOME/hooks/SessionStart.sh" "SessionStart hook"

echo ""
echo "Verifying individual rules files..."
for rule in autolearn-patterns known-gotchas markdown-style subagent-ci-checklist workflow-preferences; do
    check "$CLAUDE_HOME/rules/$rule.md" "$rule"
done

echo ""
echo "Verifying individual skills..."
for skill in autolearn docker-containerization go-development manage-github-issues quality-control react-frontend-development requirements-generator setup-github-actions windows-development; do
    check "$CLAUDE_HOME/skills/$skill/SKILL.md" "$skill skill"
done

echo ""
echo "Verifying git template directory..."
GIT_TMPL="$HOME/.git-templates"
check "$GIT_TMPL/CLAUDE.md" "Git template CLAUDE.md"
check "$GIT_TMPL/.gitignore" "Git template .gitignore"

GIT_TMPL_CFG="$(git config --global --get init.templateDir 2>/dev/null || echo "")"
if [ -n "$GIT_TMPL_CFG" ]; then
    echo "  [OK] git init.templateDir = $GIT_TMPL_CFG"
    PASS=$((PASS + 1))
else
    echo "  [MISSING] git init.templateDir not configured"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    echo "Some items are missing. Re-run setup/setup.sh to fix."
    exit 1
else
    echo "All checks passed."
fi
