#!/usr/bin/env bash
# SessionStop Hook
# Fires when Claude Code session ends.
# 1. Warns about uncommitted changes
# 2. Reminds about /autolearn
set -euo pipefail

# --- Uncommitted changes check (best-effort, silent outside git repos) ---
uncommitted=$(git status --porcelain 2>/dev/null) || true
if [ -n "$uncommitted" ]; then
    echo "[SessionStop] WARNING: Uncommitted changes detected:"
    echo "$uncommitted"
fi

# --- Autolearn reminder ---
echo "[SessionStop] Reminder: Run /autolearn if this session produced notable learnings."

# --- Session event recording (best-effort, silent on failure) ---
_devkit_record_stop() {
    local project db
    project="$(basename "$PWD")"
    db="$HOME/databases/claude.db"
    [ -f "$db" ] || return 0
    command -v sqlite3 >/dev/null 2>&1 || return 0
    sqlite3 "$db" "CREATE TABLE IF NOT EXISTS session_events (id INTEGER PRIMARY KEY AUTOINCREMENT, project TEXT, event_type TEXT, event_date TEXT); INSERT INTO session_events (project, event_type, event_date) VALUES ('$project', 'stop', datetime('now'));" 2>/dev/null || true
}
_devkit_record_stop

exit 0
