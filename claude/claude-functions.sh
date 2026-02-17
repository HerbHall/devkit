#!/usr/bin/env bash
# Claude Code helper functions
# Source this file in ~/.bashrc or ~/.bash_profile:
#   source ~/.claude/claude-functions.sh

CLAUDE_HOME="$HOME/.claude"

# Initialize a new project with CLAUDE.md
claude-init-project() {
    local name="${1:?Usage: claude-init-project <name> [directory]}"
    local dir="${2:-./$name}"

    if [ -d "$dir" ]; then
        echo "Directory $dir already exists."
        return 1
    fi

    mkdir -p "$dir"
    cd "$dir" || return 1
    git init

    # Copy full template if available, otherwise use git template
    if [ -f "$CLAUDE_HOME/CLAUDE.md.template" ]; then
        cp "$CLAUDE_HOME/CLAUDE.md.template" CLAUDE.md
    elif [ -f "CLAUDE.md" ]; then
        # git init already placed a starter via init.templateDir
        :
    else
        echo "# $name" > CLAUDE.md
        echo "" >> CLAUDE.md
        echo "TODO: Fill in project details. See ~/.claude/CLAUDE.md.template" >> CLAUDE.md
    fi

    # Ensure CLAUDE.local.md is gitignored
    if [ -f ".gitignore" ]; then
        if ! grep -q "CLAUDE.local.md" .gitignore; then
            echo "CLAUDE.local.md" >> .gitignore
        fi
    fi

    echo "Project '$name' initialized at $dir with CLAUDE.md"
    echo "  Edit CLAUDE.md to add build commands, architecture, and conventions."
}

# Add CLAUDE.md to an existing project
claude-add-config() {
    if [ -f "CLAUDE.md" ]; then
        echo "CLAUDE.md already exists in this directory."
        return 1
    fi

    if [ -f "$CLAUDE_HOME/CLAUDE.md.template" ]; then
        cp "$CLAUDE_HOME/CLAUDE.md.template" CLAUDE.md
        echo "CLAUDE.md created from template."
    else
        echo "# $(basename "$PWD")" > CLAUDE.md
        echo "" >> CLAUDE.md
        echo "TODO: Fill in project details." >> CLAUDE.md
        echo "CLAUDE.md created (minimal). Install devkit for the full template."
    fi

    # Ensure CLAUDE.local.md is gitignored
    if [ -f ".gitignore" ] && ! grep -q "CLAUDE.local.md" .gitignore; then
        echo "CLAUDE.local.md" >> .gitignore
    fi

    echo "  Edit CLAUDE.md to add build commands, architecture, and conventions."
}

# Edit current project's CLAUDE.md
claude-edit() {
    if [ -f "CLAUDE.md" ]; then
        "${EDITOR:-code}" CLAUDE.md
    else
        echo "No CLAUDE.md in current directory. Run claude-add-config first."
        return 1
    fi
}

# Edit global CLAUDE.md
claude-edit-global() {
    if [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
        "${EDITOR:-code}" "$CLAUDE_HOME/CLAUDE.md"
    else
        echo "No global CLAUDE.md found at $CLAUDE_HOME/CLAUDE.md"
        return 1
    fi
}

# Check configuration status
claude-status() {
    echo "Claude Code Configuration Status"
    echo "================================="
    echo ""

    echo "Global config:"
    [ -f "$CLAUDE_HOME/CLAUDE.md" ] && echo "  [OK] ~/.claude/CLAUDE.md" || echo "  [MISSING] ~/.claude/CLAUDE.md"
    [ -f "$CLAUDE_HOME/settings.json" ] && echo "  [OK] ~/.claude/settings.json" || echo "  [MISSING] ~/.claude/settings.json"
    [ -d "$CLAUDE_HOME/rules" ] && echo "  [OK] ~/.claude/rules/ ($(ls "$CLAUDE_HOME/rules/"*.md 2>/dev/null | wc -l) files)" || echo "  [MISSING] ~/.claude/rules/"
    [ -d "$CLAUDE_HOME/skills" ] && echo "  [OK] ~/.claude/skills/ ($(ls -d "$CLAUDE_HOME/skills/"*/ 2>/dev/null | wc -l) skills)" || echo "  [MISSING] ~/.claude/skills/"
    echo ""

    echo "Git template:"
    local tmpl_dir
    tmpl_dir="$(git config --global --get init.templateDir 2>/dev/null || echo "")"
    if [ -n "$tmpl_dir" ]; then
        echo "  [OK] init.templateDir = $tmpl_dir"
        [ -f "$tmpl_dir/CLAUDE.md" ] && echo "  [OK] $tmpl_dir/CLAUDE.md" || echo "  [MISSING] $tmpl_dir/CLAUDE.md"
    else
        echo "  [NOT SET] git init.templateDir (run devkit setup to configure)"
    fi
    echo ""

    echo "Current project:"
    if [ -f "CLAUDE.md" ]; then
        echo "  [OK] CLAUDE.md exists"
        local lines
        lines=$(wc -l < CLAUDE.md)
        if [ "$lines" -lt 5 ]; then
            echo "  [WARN] CLAUDE.md is only $lines lines — consider filling it in"
        fi
    else
        echo "  [MISSING] No CLAUDE.md in current directory"
    fi
    [ -f "CLAUDE.local.md" ] && echo "  [OK] CLAUDE.local.md (personal preferences)" || echo "  [--] No CLAUDE.local.md (optional)"
}

# Show available commands
claude-help() {
    echo "Claude Code Helper Commands"
    echo "==========================="
    echo ""
    echo "  claude-init-project <name> [dir]  Create a new project with CLAUDE.md"
    echo "  claude-add-config                 Add CLAUDE.md to current project"
    echo "  claude-edit                       Edit current project's CLAUDE.md"
    echo "  claude-edit-global                Edit global ~/.claude/CLAUDE.md"
    echo "  claude-status                     Check configuration status"
    echo "  claude-help                       Show this help"
}
