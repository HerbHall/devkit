# Conformance Audit: Full Audit

Run the 19-point conformance checklist across all projects in the DevSpace workspace.

## Steps

### 1. Resolve DevSpace Path

Read `.devkit-config.json` to find the workspace root:

```bash
# From DevKit project root
cat .devkit-config.json 2>/dev/null | python3 -c "
import json, sys
c = json.load(sys.stdin)
print(c.get('devspacePath', c.get('devspace', '')))
" 2>/dev/null

# Fallback: check common locations
# D:/DevSpace, ~/DevSpace
```

Store the resolved path as `DEVSPACE` for subsequent steps.

### 2. Discover Projects

Scan `DEVSPACE` for directories containing `.git/`. Exclude non-project directories:

```bash
for dir in "$DEVSPACE"/*/; do
    name=$(basename "$dir")

    # Skip non-project directories
    case "$name" in
        archive|.templates|.shared-vscode|.coordination|research|devkit|Websites)
            continue
            ;;
    esac

    # Must have a .git directory to be a project
    if [ -d "$dir/.git" ]; then
        echo "$dir"
    fi
done
```

Collect the list of discovered project paths and names.

### 3. Detect Stack per Project

For each discovered project, determine its stack:

```bash
detect_stack() {
    local project="$1"
    local stacks=""

    [ -f "$project/go.mod" ] && stacks="$stacks go"
    [ -f "$project/package.json" ] && stacks="$stacks node"
    [ -f "$project/Cargo.toml" ] && stacks="$stacks rust"
    ls "$project"/*.csproj "$project"/*.sln 2>/dev/null | grep -q . && stacks="$stacks dotnet"

    if [ -z "$stacks" ]; then
        stacks="unknown"
    fi

    echo "$stacks"
}
```

Record the detected stack(s) alongside each project name.

### 4. Run 16-Point Checklist

For each project, run every check from `references/checklist.md`. For each check:

1. Determine if the check applies to the project's stack (skip if not applicable)
2. Inspect the relevant file or directory
3. Record the result as **pass**, **fail**, or **skip**

Use these inspection commands:

```bash
# Check 1: CLAUDE.md
[ -f "$project/CLAUDE.md" ] && ! grep -q '{{PROJECT_NAME}}' "$project/CLAUDE.md"

# Check 2: .claude/settings.json
[ -f "$project/.claude/settings.json" ]

# Check 3: CI workflow
ls "$project/.github/workflows/"*ci* "$project/.github/workflows/"*lint* "$project/.github/workflows/"*test* "$project/.github/workflows/"*build* 2>/dev/null | grep -q .

# Check 4: Pre-push hook
[ -f "$project/scripts/pre-push" ]

# Check 5: Lint config (stack-specific)
# Go: [ -f "$project/.golangci.yml" ]
# Node: ls "$project/eslint.config."* "$project/.eslintrc"* 2>/dev/null | grep -q .
# Rust: grep -q '\[lints\]' "$project/Cargo.toml" 2>/dev/null || grep -q 'clippy' "$project/.github/workflows/"*.yml 2>/dev/null

# Check 6: Makefile
[ -f "$project/Makefile" ] && grep -q 'build' "$project/Makefile" && grep -q 'test' "$project/Makefile"

# Check 7: .editorconfig (root = false)
[ -f "$project/.editorconfig" ] && ! grep -q 'root = true' "$project/.editorconfig"

# Check 8: release-please
[ -f "$project/.release-please-manifest.json" ] && [ -f "$project/release-please-config.json" ] && [ -f "$project/.github/workflows/release-please.yml" ]

# Check 9: LICENSE
[ -f "$project/LICENSE" ]

# Check 10: VERSION
[ -f "$project/VERSION" ]

# Check 11: .gitignore
[ -f "$project/.gitignore" ]

# Check 12: Nightly workflow (skip for dotnet-desktop)
ls "$project/.github/workflows/"*nightly* 2>/dev/null | grep -q . || grep -ql 'schedule:' "$project/.github/workflows/"*.yml 2>/dev/null

# Check 13: Release gate (only if check 8 passes)
[ -f "$project/.github/workflows/release-gate.yml" ]

# Check 14: Workflow trigger patterns (only if check 8 passes)
# FAIL if any non-release-please workflow has 'tags: v*' or "tags: ['v*']"
for wf in "$project/.github/workflows/"*.yml; do
    [ "$(basename "$wf")" = "release-please.yml" ] && continue
    grep -q "tags:.*v\*" "$wf" 2>/dev/null && echo "FAIL: $(basename "$wf") has tag trigger"
done

# Check 15: Retrigger CI (only if check 8 passes)
ls "$project/.github/workflows/"*retrigger* 2>/dev/null | grep -q .

# Check 16: Auto-merge enabled (only if check 13 passes)
gh api "repos/$(gh repo view "$project" --json nameWithOwner -q .nameWithOwner 2>/dev/null)" --jq '.allow_auto_merge' 2>/dev/null | grep -q 'true'

# Check 17: Copilot PR Review ruleset exists
REPO_SLUG=$(gh repo view "$project" --json nameWithOwner -q .nameWithOwner 2>/dev/null)
gh api "repos/$REPO_SLUG/rulesets" --jq '.[] | select(.name | test("copilot|Copilot")) | .enforcement' 2>/dev/null | grep -q 'active'

# Check 18: Branch protection has no review requirement (only if check 17 passes)
# Returns null or 404 = pass, non-null = fail
REVIEWS=$(gh api "repos/$REPO_SLUG/branches/main/protection" --jq '.required_pull_request_reviews' 2>/dev/null)
[ "$REVIEWS" = "null" ] || [ -z "$REVIEWS" ]

# Check 19: CODEOWNERS exists
[ -f "$project/CODEOWNERS" ] || [ -f "$project/.github/CODEOWNERS" ] || [ -f "$project/docs/CODEOWNERS" ]
```

### 5. Generate Summary Report

Present results as a table. Use checkmarks and X marks for visual clarity:

```text
## Conformance Audit Report

| Project | Stack | 1-7 | 8 | 9-11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | Score |
|---------|-------|-----|---|------|----|----|----|----|----|----|----|----|-------|
| SubNetree | go,node | 7/7 | + | 3/3 | + | + | + | + | + | + | + | + | 100% |
| Runbooks | node | 6/7 | + | 3/3 | - | + | + | + | + | + | + | + | 89% |
| DigitalRain | rust | 5/7 | + | 3/3 | - | - | ~ | ~ | ~ | - | ~ | - | 63% |

Legend: + = pass, - = fail, ~ = skip (not applicable)
```

Use `+` for pass, `-` for fail, `~` for skip.

### 6. Calculate Scores

For each project:

- Count passing checks and failing checks (exclude skipped)
- Score = pass / (pass + fail) as a percentage
- Round to the nearest whole number

### 7. Identify Cross-Project Patterns

After all projects are audited, identify checks that fail across multiple projects:

```text
## Cross-Project Gaps

| Check | Failing Projects | Priority |
|-------|-----------------|----------|
| 6. Makefile | Runbooks, DigitalRain, IPScan | High (3 projects) |
| 12. Nightly | Runbooks, DigitalRain | Medium (2 projects) |
| 13. Release gate | Runbooks, DigitalRain | Medium (2 projects) |
```

### 8. Suggest Priority Order

Recommend fixing checks in this order:

1. Checks that fail across the **most** projects (highest cross-project impact)
2. Within equal failure counts, prioritize by check number (lower = more fundamental)
3. For each gap, state whether it can be auto-fixed with `/conformance-audit` option 3, or requires manual work

```text
## Recommended Fix Order

1. Makefile (3 projects) -- run `/conformance-audit fix` per project
2. Nightly workflow (2 projects) -- manual: copy template and customize
3. Release gate (2 projects) -- run `/conformance-audit fix` per project
```
