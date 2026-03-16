#!/usr/bin/env bash
set -euo pipefail

# Collect PR metrics from GitHub API for all DevKit-managed repos.
# Populates pr_metrics table in ~/databases/claude.db via sqlite3.
#
# Usage: collect-pr-metrics.sh [--days N] [--repo OWNER/REPO]
# Defaults: last 30 days, all repos in D:\DevSpace\

DAYS=30
TARGET_REPO=""
DB="$HOME/databases/claude.db"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --days) DAYS="$2"; shift 2 ;;
        --repo) TARGET_REPO="$2"; shift 2 ;;
        --db)   DB="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Ensure database and schema exist
mkdir -p "$(dirname "$DB")"
# Try sqlite3 first, fall back to Python for MSYS/Windows compatibility
if command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 "$DB" < "$SCRIPT_DIR/metrics-init.sql" 2>/dev/null || true
else
    python3 -c "
import sqlite3
conn = sqlite3.connect('$DB')
with open('$SCRIPT_DIR/metrics-init.sql') as f:
    conn.executescript(f.read())
conn.close()
" 2>/dev/null || true
fi

# Discover repos or use specified one
if [[ -n "$TARGET_REPO" ]]; then
    REPOS=("$TARGET_REPO")
else
    REPOS=()
    # Read repos from devkit config if available
    CONFIG="$HOME/.devkit-config.json"
    if [[ -f "$CONFIG" ]]; then
        DEVSPACE=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('devspacePath', 'D:/DevSpace'))" 2>/dev/null || echo "D:/DevSpace")
    else
        DEVSPACE="D:/DevSpace"
    fi

    # Find git repos with GitHub remotes
    for dir in "$DEVSPACE"/*/; do
        if [[ -d "$dir/.git" ]]; then
            remote=$(git -C "$dir" remote get-url origin 2>/dev/null || true)
            if [[ "$remote" == *"github.com"* ]]; then
                # Extract OWNER/REPO from remote URL
                repo=$(echo "$remote" | sed -E 's|.*github\.com[:/]([^/]+/[^/.]+)(\.git)?$|\1|')
                if [[ -n "$repo" ]]; then
                    REPOS+=("$repo")
                fi
            fi
        fi
    done
fi

if [[ ${#REPOS[@]} -eq 0 ]]; then
    echo "No GitHub repos found." >&2
    exit 1
fi

SINCE=$(date -u -d "$DAYS days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
        date -u -v-${DAYS}d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
        echo "2026-01-01T00:00:00Z")
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "Collecting PR metrics since $SINCE for ${#REPOS[@]} repo(s)..."

TOTAL_PRS=0
TOTAL_INSERTED=0

for repo in "${REPOS[@]}"; do
    echo "  $repo..."

    # Fetch merged PRs since SINCE
    prs=$(gh api "repos/$repo/pulls?state=closed&sort=updated&direction=desc&per_page=100" \
        --jq "[.[] | select(.merged_at != null and .merged_at >= \"$SINCE\") | {number, branch: .head.ref, created_at, merged_at}]" 2>/dev/null || echo "[]")

    count=$(echo "$prs" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

    if [[ "$count" == "0" ]]; then
        echo "    No merged PRs in period."
        continue
    fi

    TOTAL_PRS=$((TOTAL_PRS + count))

    # Process each PR
    echo "$prs" | python3 -c "
import json, sys, subprocess, sqlite3, os

prs = json.load(sys.stdin)
repo = '$repo'
db_path = '$DB'
now = '$NOW'

conn = sqlite3.connect(db_path)
cur = conn.cursor()
inserted = 0

for pr in prs:
    num = pr['number']
    branch = pr['branch']

    # Count CI workflow runs for this PR's branch
    try:
        result = subprocess.run(
            ['gh', 'api', f'repos/{repo}/actions/runs?branch={branch}&per_page=100',
             '--jq', '[.workflow_runs[] | {conclusion, created_at}]'],
            capture_output=True, text=True, timeout=30, encoding='utf-8'
        )
        runs = json.loads(result.stdout) if result.returncode == 0 else []
    except Exception:
        runs = []

    total_runs = len(runs)
    green_runs = sum(1 for r in runs if r.get('conclusion') == 'success')

    # First CI pass: did the earliest run succeed?
    ci_first_pass = 0
    if runs:
        sorted_runs = sorted(runs, key=lambda r: r.get('created_at', ''))
        if sorted_runs and sorted_runs[0].get('conclusion') == 'success':
            ci_first_pass = 1

    # Push count approximation: number of CI runs triggered
    push_count = max(total_runs, 1)

    # Fix-push cycles: pushes after first failure
    fix_push_cycles = max(0, push_count - 1) if not ci_first_pass else 0

    try:
        cur.execute('''
            INSERT OR REPLACE INTO pr_metrics
            (repo, pr_number, branch, created_at, merged_at, push_count,
             ci_first_pass, ci_total_runs, ci_green_runs, fix_push_cycles, collected_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (repo, num, branch, pr.get('created_at'), pr.get('merged_at'),
              push_count, ci_first_pass, total_runs, green_runs, fix_push_cycles, now))
        inserted += 1
    except Exception as e:
        print(f'    Error inserting PR #{num}: {e}', file=sys.stderr)

conn.commit()
conn.close()
print(f'    {inserted}/{len(prs)} PRs collected.')
" 2>&1

    result=$?
    if [[ $result -eq 0 ]]; then
        TOTAL_INSERTED=$((TOTAL_INSERTED + count))
    fi
done

echo ""
echo "Done. $TOTAL_PRS PRs processed across ${#REPOS[@]} repo(s)."
echo "Database: $DB"
