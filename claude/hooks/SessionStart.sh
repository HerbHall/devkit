#!/bin/bash
# SessionStart Hook
# 1. Auto-pull DevKit updates (symlinked files update instantly)
# 2. CLAUDE.md detection for new projects

# ===== DevKit Auto-Pull =====
# Resolve DevKit clone path from ~/.devkit-config.json or common locations.
# Hardened: rate-limited (1/hour), lock-file aware, logs last 10 results.
devkit_pull() {
    local devkit_path=""
    local claude_dir="$HOME/.claude"
    local last_pull_file="$claude_dir/.devkit-last-pull"
    local log_file="$claude_dir/.devkit-pull.log"

    # Append to pull log, keep last 10 entries
    _devkit_log() {
        mkdir -p "$claude_dir"
        echo "$(date -u +%Y-%m-%dT%H:%M:%S) $1" >> "$log_file"
        local tmp; tmp=$(tail -n 10 "$log_file"); printf '%s\n' "$tmp" > "$log_file"
    }

    # Rate limiting: skip if last pull was less than 1 hour ago
    if [ -f "$last_pull_file" ]; then
        local last_epoch now_epoch elapsed
        last_epoch=$(cat "$last_pull_file" 2>/dev/null)
        now_epoch=$(date +%s 2>/dev/null)
        elapsed=$(( ${now_epoch:-0} - ${last_epoch:-0} ))
        if [ "$elapsed" -gt 0 ] && [ "$elapsed" -lt 3600 ]; then return 0; fi
    fi

    # Try ~/.devkit-config.json first
    local config="$HOME/.devkit-config.json"
    if [ -f "$config" ]; then
        local devspace
        devspace=$(grep -o '"devspacePath"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspacePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        if [ -z "$devspace" ]; then
            devspace=$(grep -o '"devspace"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        fi
        if [ -n "$devspace" ] && [ -f "$devspace/devkit/.sync-manifest.json" ]; then
            devkit_path="$devspace/devkit"
        fi
    fi

    # Fallback: common locations (no hardcoded drive letters)
    if [ -z "$devkit_path" ]; then
        for candidate in "$HOME/DevSpace/devkit" "$HOME/workspace/devkit" "$HOME/devkit"; do
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

    # Skip if git lock file present (another git operation in progress)
    if [ -f "$devkit_path/.git/index.lock" ]; then
        echo "DevKit: pull skipped -- git lock file present"
        _devkit_log "SKIPPED_LOCKED"
        return 0
    fi

    # Skip if working tree is dirty (user has uncommitted changes)
    if [ -n "$(git -C "$devkit_path" status --porcelain 2>/dev/null)" ]; then
        echo "DevKit: pull skipped -- local changes detected"
        _devkit_log "SKIPPED_DIRTY"
        return 0
    fi

    # Ensure DevKit clone's origin points to Gitea (DevKit lives on Gitea).
    # This only affects the DevKit repo, not other project repos.
    local origin_url
    origin_url=$(git -C "$devkit_path" remote get-url origin 2>/dev/null)
    if [[ "$origin_url" == *"github.com"* ]]; then
        git -C "$devkit_path" remote set-url origin "https://gitea.herbhall.net/samverk/devkit.git" 2>/dev/null
        _devkit_log "REMOTE_REWRITTEN_TO_GITEA"
        echo "DevKit: origin rewritten from GitHub to Gitea"
        # Remove duplicate gitea remote if it points to the same URL
        local gitea_url
        gitea_url=$(git -C "$devkit_path" remote get-url gitea 2>/dev/null || true)
        if [ "$gitea_url" = "https://gitea.herbhall.net/samverk/devkit.git" ]; then
            git -C "$devkit_path" remote remove gitea 2>/dev/null || true
            _devkit_log "REMOVED_DUPLICATE_GITEA_REMOTE"
        fi
    fi

    # Fetch with timeout (5s) to avoid blocking on network issues
    if ! timeout 5 git -C "$devkit_path" fetch origin 2>/dev/null; then
        _devkit_log "SKIPPED_OFFLINE"
        return 0
    fi

    # Count commits behind
    local behind
    behind=$(git -C "$devkit_path" rev-list HEAD..origin/main --count 2>/dev/null)

    if [ -z "$behind" ] || [ "$behind" -eq 0 ]; then
        echo "DevKit: up to date"
        _devkit_log "UP_TO_DATE"
        date +%s > "$last_pull_file"
        return 0
    fi

    # Pull with rebase
    if git -C "$devkit_path" pull --rebase origin main 2>/dev/null; then
        echo "DevKit: pulled $behind new commit(s)"
        # Check if rules files changed in the pull
        local rules_changed
        rules_changed=$(git -C "$devkit_path" diff HEAD~"$behind" HEAD --name-only -- claude/rules/ 2>/dev/null | wc -l)
        if [ "$rules_changed" -gt 0 ]; then
            echo "DevKit: $rules_changed rule file(s) updated. Symlinked projects are current."
        fi
        _devkit_log "PULLED_$behind"
        date +%s > "$last_pull_file"
    else
        echo "DevKit: pull failed -- run /devkit-sync pull manually"
        _devkit_log "PULL_FAILED"
    fi
}

devkit_pull

# ===== Settings Reconciliation =====
# Merges structural keys from settings.template.json into live settings.json.
# Preserves all accumulated allow entries and local customizations.
# Only adds keys present in template but missing from live settings.
devkit_settings_reconcile() {
    local devkit_path="$1"
    local claude_dir="$HOME/.claude"
    local live="$claude_dir/settings.json"
    local template="$claude_dir/settings.template.json"

    # Both files must exist
    [ -f "$live" ] || return 0
    [ -f "$template" ] || return 0

    # Require python3 for JSON merge (bash can't safely parse JSON)
    command -v python3 >/dev/null 2>&1 || return 0

    python3 - "$template" "$live" <<'PYEOF'
import json, sys, shutil
from pathlib import Path

template_path, live_path = sys.argv[1], sys.argv[2]

try:
    with open(template_path) as f:
        template = json.load(f)
    with open(live_path) as f:
        live = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    sys.exit(0)

changed = False

# --- Merge permissions.deny from template ---
# Template deny entries are authoritative (fleet-wide policy).
# Add any template deny entries missing from live settings.
tmpl_deny = template.get("permissions", {}).get("deny", [])
if tmpl_deny:
    live.setdefault("permissions", {})
    live_deny = live["permissions"].get("deny", [])
    for entry in tmpl_deny:
        if entry not in live_deny:
            live_deny.append(entry)
            changed = True
    if live_deny:
        live["permissions"]["deny"] = live_deny

# --- Remove allow entries that are now denied ---
# If template added a deny wildcard, remove matching specific allows.
# e.g., deny "mcp__claude_ai_Samverk_MCP__*" removes
#        allow "mcp__claude_ai_Samverk_MCP__list_issues"
if tmpl_deny:
    import fnmatch
    live_allow = live.get("permissions", {}).get("allow", [])
    filtered = []
    for entry in live_allow:
        denied = any(fnmatch.fnmatch(entry, pat) for pat in tmpl_deny)
        if not denied:
            filtered.append(entry)
        else:
            changed = True
    if len(filtered) != len(live_allow):
        live["permissions"]["allow"] = filtered

# --- Merge hooks from template ---
# Add hook event types (UserPromptSubmit, Stop, etc.) that exist in
# template but are completely missing from live settings.
tmpl_hooks = template.get("hooks", {})
if tmpl_hooks:
    live.setdefault("hooks", {})
    for event_type, hooks_list in tmpl_hooks.items():
        if event_type not in live["hooks"]:
            live["hooks"][event_type] = hooks_list
            changed = True

# --- Merge enableAllProjectMcpServers from template ---
for key in ["enableAllProjectMcpServers", "autoUpdatesChannel"]:
    if key in template and key not in live:
        live[key] = template[key]
        changed = True

if changed:
    # Backup before modifying
    backup = Path(live_path).with_suffix(".json.bak")
    shutil.copy2(live_path, backup)
    with open(live_path, "w") as f:
        json.dump(live, f, indent=2)
        f.write("\n")
    print(f"DevKit: settings.json reconciled with template ({backup.name} backup created)")
PYEOF
}

devkit_settings_reconcile "$(_devkit_resolve_path)"

# ===== MCP Config Merge =====
# Merges local MCP server entries from template into ~/.claude/mcp.json.
# Preserves all existing servers -- only upserts servers defined in template.
# Ensures local-network machines use LAN addresses (not CF tunnel URLs).
# No secrets in repo -- tokens resolved from environment at runtime.
devkit_generate_mcp_json() {
    local devkit_path="$1"
    local claude_dir="$HOME/.claude"
    local target="$claude_dir/mcp.json"

    [ -z "$devkit_path" ] && return 0

    # Template may be symlinked or at the DevKit clone path
    local template=""
    if [ -f "$claude_dir/mcp/claude-code.template.json" ]; then
        template="$claude_dir/mcp/claude-code.template.json"
    elif [ -f "$devkit_path/mcp/claude-code.template.json" ]; then
        template="$devkit_path/mcp/claude-code.template.json"
    fi
    [ -z "$template" ] && return 0

    # Require auth token -- skip if not set
    local auth_token="${SAMVERK_AUTH_TOKEN:-}"
    if [ -z "$auth_token" ]; then
        echo "DevKit: mcp.json skipped -- SAMVERK_AUTH_TOKEN not set"
        return 0
    fi

    # Require python3 for safe JSON merge
    command -v python3 >/dev/null 2>&1 || return 0

    local host="${SAMVERK_HOST:-192.168.1.162}"

    python3 - "$template" "$target" "$auth_token" "$host" <<'PYEOF'
import json, sys, shutil
from pathlib import Path

template_path, target_path, auth_token, host = sys.argv[1:5]

# Load template and substitute env vars
try:
    raw = Path(template_path).read_text()
except FileNotFoundError:
    sys.exit(0)

raw = raw.replace("${SAMVERK_AUTH_TOKEN}", auth_token)
raw = raw.replace("${SAMVERK_HOST}", host)

try:
    template = json.loads(raw)
except json.JSONDecodeError:
    print("DevKit: mcp.json merge skipped -- template parse error")
    sys.exit(0)

template_servers = template.get("mcpServers", {})
if not template_servers:
    sys.exit(0)

# Load existing mcp.json (or start empty)
live = {"mcpServers": {}}
if Path(target_path).exists():
    try:
        with open(target_path) as f:
            live = json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        live = {"mcpServers": {}}

live.setdefault("mcpServers", {})

# Upsert template servers into live config
changed = False
for name, config in template_servers.items():
    if live["mcpServers"].get(name) != config:
        live["mcpServers"][name] = config
        changed = True

if changed:
    # Backup before modifying
    if Path(target_path).exists():
        backup = Path(target_path).with_suffix(".json.bak")
        shutil.copy2(target_path, backup)
    with open(target_path, "w") as f:
        json.dump(live, f, indent=2)
        f.write("\n")
    updated = ", ".join(template_servers.keys())
    print(f"DevKit: mcp.json updated ({updated}) -- other servers preserved")
PYEOF
}

devkit_generate_mcp_json "$(_devkit_resolve_path)"

# ===== Config Forge Patch =====
# Sets the machine default forge to Gitea for DevKit operations and new project
# scaffolding. Per-project forges are declared in .samverk/project.yaml and are
# not affected by this setting. Projects on GitHub remain on GitHub.
_devkit_patch_config_forge() {
    local config="$HOME/.devkit-config.json"
    [ -f "$config" ] || return 0
    command -v python3 >/dev/null 2>&1 || return 0

    python3 - "$config" <<'PYEOF'
import json, sys, shutil
from pathlib import Path

config_path = sys.argv[1]
try:
    with open(config_path) as f:
        config = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    sys.exit(0)

changed = False
forge = config.get("forge", {})

if forge.get("primary") == "github":
    forge["primary"] = "gitea"
    changed = True

if not forge.get("giteaUrl"):
    forge["giteaUrl"] = "http://192.168.1.160:3000"
    changed = True

if changed:
    config["forge"] = forge
    backup = Path(config_path).with_suffix(".json.bak")
    shutil.copy2(config_path, backup)
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)
        f.write("\n")
    print("DevKit: .devkit-config.json patched (forge.primary -> gitea)")
PYEOF
}

_devkit_patch_config_forge

# ===== Version Check =====
# Compare local VERSION with origin/main after devkit_pull's fetch.
# Only prints when a newer version is available (no noise otherwise).
devkit_version_check() {
    local devkit_path="$1"

    # Nothing to check if no DevKit path or no VERSION file
    if [ -z "$devkit_path" ] || [ ! -f "$devkit_path/VERSION" ]; then
        return 0
    fi

    local current remote
    current=$(cat "$devkit_path/VERSION" 2>/dev/null | tr -d '[:space:]')
    remote=$(git -C "$devkit_path" show origin/main:VERSION 2>/dev/null | tr -d '[:space:]')

    # Skip if either version is empty or they match
    if [ -z "$current" ] || [ -z "$remote" ] || [ "$current" = "$remote" ]; then
        return 0
    fi

    echo "DevKit: new version available (current: $current, latest: $remote)"
}

# Resolve devkit_path using the same logic as devkit_pull for the version check.
# This duplicates path resolution but keeps devkit_pull's local scope intact.
_devkit_resolve_path() {
    local config="$HOME/.devkit-config.json"
    if [ -f "$config" ]; then
        local devspace
        devspace=$(grep -o '"devspacePath"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspacePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        if [ -z "$devspace" ]; then
            devspace=$(grep -o '"devspace"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | head -1 | sed 's/.*"devspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's|\\\\|/|g')
        fi
        if [ -n "$devspace" ] && [ -f "$devspace/devkit/.sync-manifest.json" ]; then
            echo "$devspace/devkit"
            return 0
        fi
    fi
    for candidate in "$HOME/DevSpace/devkit" "$HOME/workspace/devkit" "$HOME/devkit"; do
        if [ -f "$candidate/.sync-manifest.json" ]; then
            echo "$candidate"
            return 0
        fi
    done
}

devkit_version_check "$(_devkit_resolve_path)"

# ===== Symlink Health Check =====
# Validates that critical DevKit files exist in ~/.claude/.
# Detects broken symlinks and missing files so the user can re-sync.
devkit_symlink_health() {
    local devkit_path="$1"
    local claude_dir="$HOME/.claude"
    local broken=0
    local missing=0

    # Skip if no DevKit path resolved
    if [ -z "$devkit_path" ]; then return 0; fi

    # Critical files that must exist in ~/.claude/
    local critical_targets=(
        "CLAUDE.md"
        "rules/core-principles.md"
        "rules/error-policy.md"
        "rules/autolearn-patterns.md"
        "rules/known-gotchas.md"
        "rules/workflow-preferences.md"
        "rules/review-policy.md"
        "rules/subagent-ci-checklist.md"
    )

    for rel in "${critical_targets[@]}"; do
        local target="$claude_dir/$rel"
        if [ -L "$target" ] && [ ! -e "$target" ]; then
            # Symlink exists but target is gone (broken)
            broken=$((broken + 1))
        elif [ ! -e "$target" ]; then
            # File doesn't exist at all
            missing=$((missing + 1))
        fi
    done

    if [ "$broken" -gt 0 ]; then
        echo "DevKit: $broken broken symlink(s) in ~/.claude/. Run: pwsh setup/sync.ps1 -Link"
    fi
    if [ "$missing" -gt 0 ]; then
        echo "DevKit: $missing critical file(s) missing from ~/.claude/. Run: pwsh setup/sync.ps1 -Link"
    fi
}

devkit_symlink_health "$(_devkit_resolve_path)"

# ===== Rules Drift Detection =====
# Compare entry counts between ~/.claude/rules/ and devkit clone.
# Warns when copies have diverged so user can push or pull.
devkit_drift_check() {
    local devkit_path="$1"
    [ -z "$devkit_path" ] && return 0
    [ ! -d "$devkit_path/claude/rules" ] && return 0

    local local_rules="$HOME/.claude/rules"
    [ ! -d "$local_rules" ] && return 0

    local files="autolearn-patterns.md known-gotchas.md workflow-preferences.md"
    local drifted=0

    for f in $files; do
        [ ! -f "$local_rules/$f" ] && continue
        [ ! -f "$devkit_path/claude/rules/$f" ] && continue

        local local_count devkit_count
        local_count=$(grep -c '^## [0-9]' "$local_rules/$f" 2>/dev/null || echo 0)
        devkit_count=$(grep -c '^## [0-9]' "$devkit_path/claude/rules/$f" 2>/dev/null || echo 0)

        if [ "$local_count" != "$devkit_count" ]; then
            local direction
            if [ "$local_count" -gt "$devkit_count" ]; then
                direction="local $local_count > devkit $devkit_count (push needed)"
            else
                direction="local $local_count < devkit $devkit_count (pull needed)"
            fi
            echo "DevKit drift: $f -- $direction"
            drifted=$((drifted + 1))
        fi
    done

    if [ "$drifted" -gt 0 ]; then
        echo "DevKit: $drifted rules file(s) out of sync. Run /devkit-sync push or pull."
    fi
}

devkit_drift_check "$(_devkit_resolve_path)"

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

# Check for missing project config files
missing_claude_md=false
missing_settings=false

if [ ! -f "CLAUDE.md" ]; then
    missing_claude_md=true
fi

if [ ! -f ".claude/settings.json" ]; then
    missing_settings=true
fi

# Nothing missing — done
if [ "$missing_claude_md" = false ] && [ "$missing_settings" = false ]; then
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

if [ "$missing_claude_md" = true ]; then
    echo ""
    echo "This project doesn't have a CLAUDE.md file."
    echo "  Create one: 'Create a CLAUDE.md for this project'"
fi

if [ "$missing_settings" = true ]; then
    echo ""
    echo "This project doesn't have .claude/settings.json (project-level permissions)."
    echo "  Copy from DevKit: cp <devkit>/project-templates/settings.json .claude/settings.json"
fi

# --- Session event recording (best-effort, silent on failure) ---
_devkit_record_session() {
  local project db
  project="$(basename "$PWD")"
  db="$HOME/databases/claude.db"
  [ -f "$db" ] || return 0
  command -v sqlite3 >/dev/null 2>&1 || return 0
  sqlite3 "$db" "CREATE TABLE IF NOT EXISTS session_events (id INTEGER PRIMARY KEY AUTOINCREMENT, project TEXT, event_type TEXT, event_date TEXT); INSERT INTO session_events (project, event_type, event_date) VALUES ('$project', 'start', datetime('now'));" 2>/dev/null || true
}
_devkit_record_session

echo ""
exit 0
