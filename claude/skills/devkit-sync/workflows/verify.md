# Verify Propagation

Check whether DevKit updates have reached all active projects. Reports symlink health, stale copies, and missing files.

## Steps

### 1. Resolve DevKit Source Path

Find the DevKit clone (source of truth for all rules/skills):

```bash
# Try config file first
DEVKIT=$(python3 -c "import json; c=json.load(open('$HOME/.devkit-config.json')); print(c.get('devspacePath', c.get('devspace', ''))+'/devkit')" 2>/dev/null)

# Fallback paths
[ -z "$DEVKIT" ] && for d in "$HOME/DevSpace/devkit" "/d/DevSpace/devkit"; do
    [ -f "$d/.sync-manifest.json" ] && DEVKIT="$d" && break
done

if [ -z "$DEVKIT" ]; then
    echo "Cannot find DevKit clone. Run /devkit-sync init first."
    exit 1
fi
```

### 2. Discover Active Projects

Look for projects that should have DevKit files. Check these sources in order:

1. **Project registry** (`~/.devkit-registry.json`) -- if it exists, use it as the primary source
2. **Common locations** -- scan directories under the DevSpace root for git repos with `CLAUDE.md`

```bash
# Registry approach
if [ -f "$HOME/.devkit-registry.json" ]; then
    # Read project paths from registry
    python3 -c "
import json
reg = json.load(open('$HOME/.devkit-registry.json'))
for p in reg.get('projects', []):
    print(p.get('path', ''))
"
fi

# Fallback: scan DevSpace directory
DEVSPACE=$(dirname "$DEVKIT")
for dir in "$DEVSPACE"/*/; do
    [ -d "$dir/.git" ] && [ "$dir" != "$DEVKIT/" ] && echo "$dir"
done
```

### 3. Check Each Project

For each discovered project, verify these critical files:

**Files to check:**

| File | Source in DevKit | Expected in Project |
|------|-----------------|-------------------|
| `CLAUDE.md` | `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` (global) |
| `rules/*.md` | `claude/rules/*.md` | `~/.claude/rules/*.md` (global) |
| Project `CLAUDE.md` | n/a | `<project>/CLAUDE.md` (project-specific) |

**For each file, determine status:**

- **CURRENT (symlinked)**: File is a symlink pointing to DevKit source. Changes propagate automatically.
- **STALE (copy)**: File is a regular file (not symlink). Compare modification time with DevKit source. If DevKit source is newer, the copy is stale.
- **MISSING**: File does not exist in the expected location.
- **BROKEN**: File is a symlink but the target does not exist.

```bash
check_file() {
    local target="$1"    # expected file location
    local source="$2"    # DevKit source file

    if [ -L "$target" ]; then
        if [ -e "$target" ]; then
            echo "CURRENT (symlinked)"
        else
            echo "BROKEN (dangling symlink)"
        fi
    elif [ -f "$target" ]; then
        if [ "$source" -nt "$target" ]; then
            echo "STALE (copy, DevKit source is newer)"
        else
            echo "OK (copy, up to date)"
        fi
    else
        echo "MISSING"
    fi
}
```

### 4. Generate Report

Present results as a table:

```text
## Propagation Verification Report

### Global Files (~/.claude/)

| File | Status | Action Needed |
|------|--------|--------------|
| CLAUDE.md | CURRENT | None |
| rules/core-principles.md | CURRENT | None |
| rules/autolearn-patterns.md | STALE | Run: pwsh setup/sync.ps1 -Link |
| rules/error-policy.md | MISSING | Run: pwsh setup/sync.ps1 -Link |

### Projects

| Project | CLAUDE.md | Notes |
|---------|-----------|-------|
| SubNetree | Present (project-specific) | OK |
| Runbooks | Missing | Create with template |

### Summary

- Symlinked (current): N files
- Stale copies: N files
- Missing: N files
- Broken symlinks: N files
```

### 5. Suggest Remediation

Based on findings:

- **Stale copies or missing files**: `pwsh setup/sync.ps1 -Link` to re-establish symlinks
- **Broken symlinks**: DevKit clone may have moved. Run `/devkit-sync init` to reconfigure
- **Project missing CLAUDE.md**: Offer to create from template (`project-templates/claude-md-template.md`)
- **All current**: Report "All projects are current. No action needed."
