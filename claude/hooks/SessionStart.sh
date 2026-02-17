#!/bin/bash
# SessionStart Hook - CLAUDE.md detection for new projects

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
