#!/usr/bin/env bash
# Install development tools required by devkit
# Supports: Windows (winget/choco), macOS (brew), Linux (apt/dnf)
#
# Usage: ./setup/install-tools.sh

set -euo pipefail

echo "========================================="
echo "  devkit tool installation"
echo "========================================="
echo ""

# Detect platform
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
    Darwin*)               PLATFORM="macos" ;;
    Linux*)                PLATFORM="linux" ;;
    *)                     PLATFORM="unknown" ;;
esac

echo "Platform: $PLATFORM"
echo ""

# --- Required tools ---

echo "=== Required Tools ==="
echo ""

# Git
if command -v git &>/dev/null; then
    echo "[OK] git $(git --version | cut -d' ' -f3)"
else
    echo "[INSTALL] git"
    case "$PLATFORM" in
        windows) echo "  winget install Git.Git" ;;
        macos)   echo "  brew install git" ;;
        linux)   echo "  sudo apt install git  # or: sudo dnf install git" ;;
    esac
fi

# Node.js
if command -v node &>/dev/null; then
    echo "[OK] node $(node --version)"
else
    echo "[INSTALL] node"
    case "$PLATFORM" in
        windows) echo "  winget install OpenJS.NodeJS.LTS" ;;
        macos)   echo "  brew install node" ;;
        linux)   echo "  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install nodejs" ;;
    esac
fi

# GitHub CLI
if command -v gh &>/dev/null; then
    echo "[OK] gh $(gh --version | head -1 | cut -d' ' -f3)"
else
    echo "[INSTALL] gh"
    case "$PLATFORM" in
        windows) echo "  winget install GitHub.cli" ;;
        macos)   echo "  brew install gh" ;;
        linux)   echo "  sudo apt install gh  # or: https://github.com/cli/cli/blob/trunk/docs/install_linux.md" ;;
    esac
fi

echo ""
echo "=== Recommended Tools ==="
echo ""

# uv (Python package manager)
if command -v uv &>/dev/null; then
    echo "[OK] uv $(uv --version 2>/dev/null || echo 'installed')"
else
    echo "[INSTALL] uv (Python package manager for MCP servers)"
    case "$PLATFORM" in
        windows) echo "  powershell -ExecutionPolicy ByPass -c \"irm https://astral.sh/uv/install.ps1 | iex\"" ;;
        macos)   echo "  brew install uv  # or: curl -LsSf https://astral.sh/uv/install.sh | sh" ;;
        linux)   echo "  curl -LsSf https://astral.sh/uv/install.sh | sh" ;;
    esac
fi

# Docker
if command -v docker &>/dev/null; then
    echo "[OK] docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
else
    echo "[INSTALL] docker (required for MCP_DOCKER gateway)"
    case "$PLATFORM" in
        windows) echo "  winget install Docker.DockerDesktop" ;;
        macos)   echo "  brew install --cask docker" ;;
        linux)   echo "  https://docs.docker.com/engine/install/" ;;
    esac
fi

echo ""
echo "=== Optional Tools (project-specific) ==="
echo ""

# Go
if command -v go &>/dev/null; then
    echo "[OK] go $(go version | cut -d' ' -f3)"
else
    echo "[--] go (needed for Go projects)"
    case "$PLATFORM" in
        windows) echo "  winget install GoLang.Go" ;;
        macos)   echo "  brew install go" ;;
        linux)   echo "  https://go.dev/doc/install" ;;
    esac
fi

# .NET
if command -v dotnet &>/dev/null; then
    echo "[OK] dotnet $(dotnet --version)"
else
    echo "[--] dotnet (needed for C#/.NET projects)"
    case "$PLATFORM" in
        windows) echo "  winget install Microsoft.DotNet.SDK.10" ;;
        macos)   echo "  brew install dotnet-sdk" ;;
        linux)   echo "  https://learn.microsoft.com/dotnet/core/install/linux" ;;
    esac
fi

# Rust
if command -v rustc &>/dev/null; then
    echo "[OK] rustc $(rustc --version | cut -d' ' -f2)"
else
    echo "[--] rustc (needed for Rust projects)"
    echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

echo ""
echo "Install missing tools, then re-run setup/setup.sh"
