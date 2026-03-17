#!/usr/bin/env bash
# SubagentVerify Hook
# Fires when a subagent (Task tool) completes.
# Detects modified files and runs stack-appropriate lint checks.
# Addresses AP#84: agents skip lint despite CI checklists.
set -euo pipefail

# --- Detect modified files ---
changed=$(git diff --name-only 2>/dev/null) || exit 0
if [ -z "$changed" ]; then
    # No changes -- exploration/research agent, nothing to verify
    exit 0
fi

echo "[SubagentVerify] Modified files detected:"
echo "$changed"
echo ""

errors=0

# --- Go stack detection and lint ---
go_files=$(echo "$changed" | grep '\.go$' || true)
if [ -n "$go_files" ]; then
    echo "[SubagentVerify] Go files changed -- running checks..."

    # Extract unique package directories
    go_dirs=$(echo "$go_files" | xargs -I{} dirname {} | sort -u | sed 's|$|/...|')

    if command -v go >/dev/null 2>&1; then
        echo "  go build..."
        if ! go build $go_dirs 2>&1; then
            echo "  [FAIL] go build"
            errors=1
        else
            echo "  [PASS] go build"
        fi

        echo "  golangci-lint..."
        if go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest run $go_dirs 2>&1; then
            echo "  [PASS] golangci-lint"
        else
            echo "  [FAIL] golangci-lint"
            errors=1
        fi
    else
        echo "  [SKIP] go not found"
    fi
fi

# --- TypeScript/JavaScript stack detection and lint ---
ts_files=$(echo "$changed" | grep -E '\.(ts|tsx|js|jsx)$' || true)
if [ -n "$ts_files" ]; then
    echo "[SubagentVerify] TypeScript/JavaScript files changed -- running checks..."

    if command -v npx >/dev/null 2>&1; then
        # Find the nearest package.json to determine project root
        ts_root=""
        for f in $ts_files; do
            dir=$(dirname "$f")
            while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
                if [ -f "$dir/package.json" ]; then
                    ts_root="$dir"
                    break 2
                fi
                dir=$(dirname "$dir")
            done
        done

        if [ -n "$ts_root" ] && [ -f "$ts_root/tsconfig.json" ]; then
            echo "  tsc --noEmit..."
            if (cd "$ts_root" && npx tsc --noEmit 2>&1); then
                echo "  [PASS] tsc"
            else
                echo "  [FAIL] tsc"
                errors=1
            fi
        fi

        echo "  eslint..."
        if npx eslint $ts_files 2>&1; then
            echo "  [PASS] eslint"
        else
            echo "  [FAIL] eslint"
            errors=1
        fi
    else
        echo "  [SKIP] npx not found"
    fi
fi

# --- Summary ---
if [ "$errors" -ne 0 ]; then
    echo ""
    echo "[SubagentVerify] FAILURES DETECTED -- review before committing."
else
    echo ""
    echo "[SubagentVerify] All checks passed."
fi

exit 0
