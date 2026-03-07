# Conformance Audit: Single Project

Run the 17-point conformance checklist against one specific project.

## Steps

### 1. Accept Project Path

If the user provided a project name or path in their invoke args, use it. Otherwise, ask:

> Which project do you want to audit? Provide the project name (e.g., `Runbooks`) or full path.

Resolve the path:

- If a bare name is given, look under the DevSpace root (read `devspacePath` from `~/.devkit-config.json`)
- Construct the full path as `DEVSPACE/<name>`

### 2. Verify Project

Confirm the directory exists and is a git repository:

```bash
PROJECT="$1"

if [ ! -d "$PROJECT" ]; then
    echo "Directory not found: $PROJECT"
    exit 1
fi

if [ ! -d "$PROJECT/.git" ]; then
    echo "Not a git repository: $PROJECT"
    exit 1
fi

echo "Auditing: $PROJECT"
```

### 3. Detect Stack

Inspect the project root to determine the stack:

```bash
STACKS=""
[ -f "$PROJECT/go.mod" ] && STACKS="$STACKS go"
[ -f "$PROJECT/package.json" ] && STACKS="$STACKS node"
[ -f "$PROJECT/Cargo.toml" ] && STACKS="$STACKS rust"
ls "$PROJECT"/*.csproj "$PROJECT"/*.sln 2>/dev/null | grep -q . && STACKS="$STACKS dotnet"
[ -z "$STACKS" ] && STACKS="unknown"

echo "Detected stack(s): $STACKS"
```

If the stack is `unknown`, note that stack-specific checks (5, 12) will be skipped.

### 4. Read Checklist

Load the 17-point checklist from `references/checklist.md` in the conformance-audit skill directory. Use it as the authoritative source for what to check, pass criteria, and fix references.

### 5. Run Each Check

Execute all 17 checks. For each one, report the result with detail:

**Check 1 -- CLAUDE.md**

```bash
if [ -f "$PROJECT/CLAUDE.md" ]; then
    if grep -q '{{PROJECT_NAME}}' "$PROJECT/CLAUDE.md"; then
        echo "FAIL: CLAUDE.md exists but contains unsubstituted placeholders"
    else
        echo "PASS: CLAUDE.md exists with project-specific content"
    fi
else
    echo "FAIL: CLAUDE.md not found"
fi
```

**Check 2 -- Claude Settings**

```bash
if [ -f "$PROJECT/.claude/settings.json" ]; then
    python3 -c "import json; json.load(open('$PROJECT/.claude/settings.json'))" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "PASS: .claude/settings.json exists and is valid JSON"
    else
        echo "FAIL: .claude/settings.json exists but is not valid JSON"
    fi
else
    echo "FAIL: .claude/settings.json not found"
fi
```

**Check 3 -- CI Workflow**

```bash
if ls "$PROJECT/.github/workflows/"*.yml 2>/dev/null | grep -qiE 'ci|lint|test|build'; then
    echo "PASS: CI workflow found"
else
    echo "FAIL: No CI workflow found in .github/workflows/"
fi
```

**Check 4 -- Pre-push Hook**

```bash
if [ -f "$PROJECT/scripts/pre-push" ]; then
    echo "PASS: scripts/pre-push exists"
else
    echo "FAIL: scripts/pre-push not found"
fi
```

**Check 5 -- Lint Config** (stack-specific)

For Go: check `.golangci.yml` exists and contains `version: "2"`.
For Node: check `eslint.config.js` or `.eslintrc.*` exists.
For Rust: check `[lints]` in `Cargo.toml` or `clippy` in CI workflow.
For .NET or unknown: skip.

**Check 6 -- Makefile**

```bash
if [ -f "$PROJECT/Makefile" ]; then
    MISSING=""
    grep -q '^build' "$PROJECT/Makefile" || MISSING="$MISSING build"
    grep -q '^test' "$PROJECT/Makefile" || MISSING="$MISSING test"
    grep -q '^lint' "$PROJECT/Makefile" || MISSING="$MISSING lint"
    if [ -z "$MISSING" ]; then
        echo "PASS: Makefile exists with build, test, lint targets"
    else
        echo "FAIL: Makefile exists but missing targets:$MISSING"
    fi
else
    echo "FAIL: Makefile not found"
fi
```

**Check 7 -- EditorConfig**

```bash
if [ -f "$PROJECT/.editorconfig" ]; then
    if grep -q 'root = true' "$PROJECT/.editorconfig"; then
        echo "FAIL: .editorconfig has root = true (blocks DevSpace inheritance)"
    else
        echo "PASS: .editorconfig exists with root = false"
    fi
else
    echo "FAIL: .editorconfig not found"
fi
```

**Check 8 -- Release Please**

```bash
MISSING=""
[ ! -f "$PROJECT/.release-please-manifest.json" ] && MISSING="$MISSING manifest"
[ ! -f "$PROJECT/release-please-config.json" ] && MISSING="$MISSING config"
[ ! -f "$PROJECT/.github/workflows/release-please.yml" ] && MISSING="$MISSING workflow"
if [ -z "$MISSING" ]; then
    echo "PASS: release-please fully configured"
else
    echo "FAIL: release-please missing:$MISSING"
fi
```

**Check 9 -- LICENSE**

```bash
if [ -f "$PROJECT/LICENSE" ] && [ -s "$PROJECT/LICENSE" ]; then
    echo "PASS: LICENSE exists"
else
    echo "FAIL: LICENSE not found or empty"
fi
```

**Check 10 -- VERSION**

```bash
if [ -f "$PROJECT/VERSION" ]; then
    VERSION_CONTENT=$(cat "$PROJECT/VERSION" | tr -d '[:space:]')
    if echo "$VERSION_CONTENT" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
        echo "PASS: VERSION file contains $VERSION_CONTENT"
    else
        echo "FAIL: VERSION file exists but does not contain a semver string"
    fi
else
    echo "FAIL: VERSION file not found"
fi
```

**Check 11 -- Gitignore**

```bash
if [ -f "$PROJECT/.gitignore" ] && [ -s "$PROJECT/.gitignore" ]; then
    echo "PASS: .gitignore exists"
else
    echo "FAIL: .gitignore not found or empty"
fi
```

**Check 12 -- Nightly Workflow** (skip for .NET desktop)

```bash
if ls "$PROJECT/.github/workflows/"*nightly* 2>/dev/null | grep -q .; then
    echo "PASS: Nightly workflow found"
elif grep -qlr 'schedule:' "$PROJECT/.github/workflows/"*.yml 2>/dev/null; then
    echo "PASS: Scheduled workflow found"
else
    echo "FAIL: No nightly or scheduled workflow found"
fi
```

**Check 13 -- Release Gate** (only if check 8 passed)

```bash
if [ -f "$PROJECT/.github/workflows/release-gate.yml" ]; then
    echo "PASS: release-gate.yml exists"
else
    echo "FAIL: release-gate.yml not found"
fi
```

**Check 14 -- Workflow Trigger Patterns** (only if check 8 passed)

Check that no non-release-please workflow uses `on: push: tags: v*`. See checklist for details.

**Check 15 -- Retrigger CI** (only if check 8 passed)

```bash
if ls "$PROJECT/.github/workflows/"*retrigger* 2>/dev/null | grep -q .; then
    echo "PASS: Retrigger CI workflow found"
else
    echo "FAIL: No retrigger CI workflow found"
fi
```

**Check 16 -- Auto-Merge Enabled** (only if check 13 passed)

```bash
REPO_SLUG=$(cd "$PROJECT" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
AUTO_MERGE=$(gh api "repos/$REPO_SLUG" --jq '.allow_auto_merge' 2>/dev/null || echo "false")
if [ "$AUTO_MERGE" = "true" ]; then
    echo "PASS: Auto-merge enabled"
else
    echo "FAIL: Auto-merge not enabled"
fi
```

**Check 17 -- Actions PR Permission** (only if check 8 passed; **manual verification required**)

This check **cannot be automated** -- the GitHub API does not expose this setting.

```text
WARN: Manual verification required.
  Navigate to: Settings > Actions > General > Workflow permissions
  Verify: "Allow GitHub Actions to create and approve pull requests" is CHECKED.
  Without this, release-please and release-gate workflows fail silently.
  Known failure: HerbHall/samverk had 31 consecutive failed runs.
```

Report this check as `?` (manual) in the summary, not pass or fail.

### 6. Provide Fix Commands for Failures

For each failing check, output the specific fix. Reference the DevKit template path and the command to copy it:

```text
## Fix Commands

Check 6 (Makefile) FAIL:
  cp <devkit>/project-templates/Makefile.go <project>/Makefile
  # Then customize targets for your project

Check 12 (Nightly) FAIL:
  cp <devkit>/project-templates/nightly-go.yml <project>/.github/workflows/nightly.yml
  # Then update the binary name and build commands
```

Replace `<devkit>` and `<project>` with actual resolved paths.

### 7. Report Final Score

Summarize the audit:

```text
## Audit Summary: <project-name>

Stack: <detected-stack>
Score: N/M applicable checks passing (XX%)

Passing: 1, 2, 3, 7, 8, 9, 10, 11
Failing: 4, 5, 6
Skipped: 12, 13
Manual: 17 (verify in GitHub UI)

Run `/conformance-audit fix` to auto-fix applicable gaps.
```
