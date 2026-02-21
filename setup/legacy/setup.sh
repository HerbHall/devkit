#!/usr/bin/env bash
# ⚠ DEPRECATED: This script is superseded by setup.ps1 (PowerShell).
# It still works in Git Bash but is no longer maintained.
# Use: pwsh -File setup/setup.ps1
# Last maintained: v1.0
#
# devkit setup script
# Installs Claude Code configuration, shared configs, and development templates
#
# Usage: ./setup/legacy/setup.sh [--workspace-root /path/to/workspace]
# Default workspace root: parent directory of this repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_HOME="$HOME/.claude"
WORKSPACE_ROOT="${1:-$(dirname "$REPO_DIR")}"

# Colors (only if terminal supports them)
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "========================================="
echo "  devkit setup"
echo "========================================="
echo ""
echo "  Repo:       $REPO_DIR"
echo "  Claude home: $CLAUDE_HOME"
echo "  Workspace:   $WORKSPACE_ROOT"
echo ""

# --- Prerequisites check ---
echo "Checking prerequisites..."
MISSING=0

for cmd in git node npm gh; do
    if command -v "$cmd" &>/dev/null; then
        info "$cmd found: $(command -v "$cmd")"
    else
        error "$cmd not found"
        MISSING=1
    fi
done

# Python/uv (optional but recommended)
if command -v uv &>/dev/null; then
    info "uv found: $(command -v uv)"
elif command -v python3 &>/dev/null; then
    warn "uv not found, python3 available (install uv for MCP servers)"
else
    warn "Neither uv nor python3 found (needed for some MCP servers)"
fi

# Docker (optional)
if command -v docker &>/dev/null; then
    info "docker found: $(command -v docker)"
else
    warn "docker not found (needed for MCP_DOCKER gateway)"
fi

if [ "$MISSING" -eq 1 ]; then
    error "Missing required tools. Run setup/legacy/install-tools.sh first."
    exit 1
fi

echo ""

# --- Claude Code configuration ---
echo "Setting up Claude Code configuration..."

# Create directories if needed
mkdir -p "$CLAUDE_HOME/rules"
mkdir -p "$CLAUDE_HOME/skills"
mkdir -p "$CLAUDE_HOME/agents"
mkdir -p "$CLAUDE_HOME/hooks"

# Copy CLAUDE.md (global instructions)
if [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
    warn "~/.claude/CLAUDE.md already exists. Backing up to CLAUDE.md.bak"
    cp "$CLAUDE_HOME/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md.bak"
fi
cp "$REPO_DIR/claude/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
info "CLAUDE.md installed"

# Copy rules files
for rule in "$REPO_DIR"/claude/rules/*.md; do
    filename=$(basename "$rule")
    cp "$rule" "$CLAUDE_HOME/rules/$filename"
done
info "Rules files installed ($(ls "$REPO_DIR"/claude/rules/*.md | wc -l) files)"

# Copy skills
for skill_dir in "$REPO_DIR"/claude/skills/*/; do
    skill_name=$(basename "$skill_dir")
    rm -rf "$CLAUDE_HOME/skills/$skill_name"
    cp -r "$skill_dir" "$CLAUDE_HOME/skills/$skill_name"
done
info "Skills installed ($(ls -d "$REPO_DIR"/claude/skills/*/ | wc -l) skills)"

# Copy agents
for agent in "$REPO_DIR"/claude/agents/*.md; do
    cp "$agent" "$CLAUDE_HOME/agents/"
done
info "Agent templates installed ($(ls "$REPO_DIR"/claude/agents/*.md | wc -l) agents)"

# Copy hooks
for hook in "$REPO_DIR"/claude/hooks/*; do
    cp "$hook" "$CLAUDE_HOME/hooks/"
    chmod +x "$CLAUDE_HOME/hooks/$(basename "$hook")" 2>/dev/null || true
done
info "Hook scripts installed"

# Copy supplementary docs
for doc in CLAUDE.md.template CLAUDE.local.md.template AGENT-WORKFLOW-GUIDE.md AUTOMATION-SETUP.md; do
    if [ -f "$REPO_DIR/claude/$doc" ]; then
        cp "$REPO_DIR/claude/$doc" "$CLAUDE_HOME/$doc"
    fi
done
info "Supplementary docs installed"

# Shell helper functions
cp "$REPO_DIR/claude/claude-functions.sh" "$CLAUDE_HOME/claude-functions.sh"
chmod +x "$CLAUDE_HOME/claude-functions.sh" 2>/dev/null || true
info "claude-functions.sh installed"

# Settings template (don't overwrite existing settings)
if [ ! -f "$CLAUDE_HOME/settings.json" ]; then
    cp "$REPO_DIR/claude/settings.template.json" "$CLAUDE_HOME/settings.json"
    info "settings.json created from template (customize tool permissions)"
else
    warn "settings.json already exists. Template at: claude/settings.template.json"
fi

echo ""

# --- Git template directory ---
echo "Setting up git template directory..."

GIT_TMPL="$HOME/.git-templates"
mkdir -p "$GIT_TMPL"
cp "$REPO_DIR/git-templates/CLAUDE.md" "$GIT_TMPL/CLAUDE.md"
cp "$REPO_DIR/git-templates/.gitignore" "$GIT_TMPL/.gitignore"
info "Git template files installed at $GIT_TMPL"

# Configure git to use the template directory
CURRENT_TMPL="$(git config --global --get init.templateDir 2>/dev/null || echo "")"
if [ -z "$CURRENT_TMPL" ]; then
    git config --global init.templateDir "$GIT_TMPL"
    info "git init.templateDir configured"
elif [ "$CURRENT_TMPL" != "$GIT_TMPL" ]; then
    warn "git init.templateDir already set to: $CURRENT_TMPL"
    warn "  devkit template is at: $GIT_TMPL"
    warn "  Run: git config --global init.templateDir '$GIT_TMPL' to switch"
else
    info "git init.templateDir already configured correctly"
fi

echo ""

# --- DevSpace shared configs ---
echo "Setting up workspace shared configs..."

# .editorconfig
if [ ! -f "$WORKSPACE_ROOT/.editorconfig" ]; then
    cp "$REPO_DIR/devspace/.editorconfig" "$WORKSPACE_ROOT/.editorconfig"
    info ".editorconfig installed at workspace root"
else
    warn ".editorconfig already exists at workspace root"
fi

# .markdownlint.json
if [ ! -f "$WORKSPACE_ROOT/.markdownlint.json" ]; then
    cp "$REPO_DIR/devspace/.markdownlint.json" "$WORKSPACE_ROOT/.markdownlint.json"
    info ".markdownlint.json installed at workspace root"
else
    warn ".markdownlint.json already exists at workspace root"
fi

# Templates directory
if [ ! -d "$WORKSPACE_ROOT/.templates" ]; then
    cp -r "$REPO_DIR/devspace/templates" "$WORKSPACE_ROOT/.templates"
    info ".templates/ installed at workspace root"
else
    warn ".templates/ already exists at workspace root"
fi

# VS Code shared fragments
if [ ! -d "$WORKSPACE_ROOT/.shared-vscode" ]; then
    cp -r "$REPO_DIR/devspace/shared-vscode" "$WORKSPACE_ROOT/.shared-vscode"
    info ".shared-vscode/ installed at workspace root"
else
    warn ".shared-vscode/ already exists at workspace root"
fi

echo ""

# --- Verification ---
echo "Running verification..."
bash "$SCRIPT_DIR/verify.sh"

echo ""
echo "========================================="
echo "  Setup complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Review ~/.claude/settings.json and add project-specific tool permissions"
echo "  2. Add to ~/.bashrc:  source ~/.claude/claude-functions.sh"
echo "  3. Set up MCP servers: see mcp/servers.md for instructions"
echo "  4. Copy mcp/claude-desktop.template.json to %APPDATA%/Claude/ and add your tokens"
echo "  5. Start a new Claude Code session to verify everything loads"
echo ""
