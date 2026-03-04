# Conformance Audit: Fix Gaps

Auto-fix common conformance gaps for a project. Runs the single-project audit first, then attempts to fix each failing check using DevKit templates.

## Steps

### 1. Run Single-Project Audit

If results from a previous audit run are available in this session, use them. Otherwise, execute the single-project audit workflow (`workflows/single-project.md`) to get the current state.

Collect the list of failing checks and the detected stack.

### 2. Resolve DevKit Path

Locate the DevKit clone for template files:

```bash
# Read from config
DEVKIT_ROOT=$(python3 -c "
import json, sys
c = json.load(open('$HOME/.devkit-config.json'))
ds = c.get('devspacePath', c.get('devspace', ''))
print(ds + '/devkit')
" 2>/dev/null)

# Fallback
if [ -z "$DEVKIT_ROOT" ] || [ ! -d "$DEVKIT_ROOT" ]; then
    for d in "D:/DevSpace/devkit" "$HOME/DevSpace/devkit"; do
        [ -d "$d/project-templates" ] && DEVKIT_ROOT="$d" && break
    done
fi

echo "DevKit root: $DEVKIT_ROOT"
```

### 3. Auto-Fix Failing Checks

For each failing check, attempt the fix below. Track what was fixed and what needs manual attention.

**Check 1 -- CLAUDE.md** (auto-fix)

```bash
if [ ! -f "$PROJECT/CLAUDE.md" ]; then
    cp "$DEVKIT_ROOT/project-templates/workspace-claude-md-template.md" "$PROJECT/CLAUDE.md"
    # Substitute placeholders
    PROJECT_NAME=$(basename "$PROJECT")
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT/CLAUDE.md"
    echo "FIXED: Created CLAUDE.md from template"
else
    echo "MANUAL: CLAUDE.md exists but has placeholders -- edit manually"
fi
```

**Check 2 -- Claude Settings** (auto-fix)

```bash
if [ ! -f "$PROJECT/.claude/settings.json" ]; then
    mkdir -p "$PROJECT/.claude"
    cp "$DEVKIT_ROOT/project-templates/settings.json" "$PROJECT/.claude/settings.json"
    echo "FIXED: Created .claude/settings.json from template"
fi
```

**Check 3 -- CI Workflow** (manual only)

CI workflows are too project-specific to auto-create. Suggest the appropriate template:

```text
MANUAL: No CI workflow found.
  Suggested template based on stack:
    Go:     cp $DEVKIT_ROOT/project-templates/ci.yml $PROJECT/.github/workflows/ci.yml
    Node:   cp $DEVKIT_ROOT/project-templates/ci-node.yml $PROJECT/.github/workflows/ci.yml
    Rust:   cp $DEVKIT_ROOT/project-templates/ci-rust.yml $PROJECT/.github/workflows/ci.yml
    .NET:   cp $DEVKIT_ROOT/project-templates/ci-dotnet.yml $PROJECT/.github/workflows/ci.yml
  Copy the appropriate template and customize for your project.
```

**Check 4 -- Pre-push Hook** (auto-fix)

```bash
if [ ! -f "$PROJECT/scripts/pre-push" ]; then
    mkdir -p "$PROJECT/scripts"
    cp "$DEVKIT_ROOT/git-templates/hooks/pre-push" "$PROJECT/scripts/pre-push"
    chmod +x "$PROJECT/scripts/pre-push" 2>/dev/null || true
    echo "FIXED: Created scripts/pre-push from template"
fi
```

**Check 5 -- Lint Config** (auto-fix for Go and Node)

```bash
# Go
if echo "$STACKS" | grep -q "go" && [ ! -f "$PROJECT/.golangci.yml" ]; then
    cp "$DEVKIT_ROOT/project-templates/golangci.yml" "$PROJECT/.golangci.yml"
    echo "FIXED: Created .golangci.yml from template"
fi

# Node
if echo "$STACKS" | grep -q "node"; then
    if ! ls "$PROJECT/eslint.config."* "$PROJECT/.eslintrc"* 2>/dev/null | grep -q .; then
        cp "$DEVKIT_ROOT/project-templates/eslint.config.js" "$PROJECT/eslint.config.js"
        echo "FIXED: Created eslint.config.js from template"
    fi
fi
```

Rust and .NET lint configs are not auto-fixable (Rust uses inline `Cargo.toml` config, .NET has no standard external config).

**Check 6 -- Makefile** (auto-fix)

```bash
if [ ! -f "$PROJECT/Makefile" ]; then
    # Select template based on stack
    if echo "$STACKS" | grep -q "go"; then
        TEMPLATE="Makefile.go"
    elif echo "$STACKS" | grep -q "node"; then
        # Check for Docker extension
        if [ -f "$PROJECT/Dockerfile" ] && grep -q 'com.docker.desktop.extension' "$PROJECT/Dockerfile" 2>/dev/null; then
            TEMPLATE="Makefile.node-extension"
        else
            TEMPLATE="Makefile.node"
        fi
    elif echo "$STACKS" | grep -q "rust"; then
        TEMPLATE="Makefile.rust"
    else
        TEMPLATE=""
    fi

    if [ -n "$TEMPLATE" ] && [ -f "$DEVKIT_ROOT/project-templates/$TEMPLATE" ]; then
        cp "$DEVKIT_ROOT/project-templates/$TEMPLATE" "$PROJECT/Makefile"
        PROJECT_NAME=$(basename "$PROJECT")
        sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT/Makefile" 2>/dev/null || true
        echo "FIXED: Created Makefile from $TEMPLATE template"
    else
        echo "MANUAL: No Makefile template available for stack: $STACKS"
    fi
fi
```

**Check 7 -- EditorConfig** (auto-fix)

```bash
if [ ! -f "$PROJECT/.editorconfig" ]; then
    cat > "$PROJECT/.editorconfig" << 'EOF'
# EditorConfig — inherits from DevSpace parent
# https://editorconfig.org

root = false
EOF
    echo "FIXED: Created .editorconfig with root = false"
elif grep -q 'root = true' "$PROJECT/.editorconfig"; then
    echo "MANUAL: .editorconfig has root = true -- change to root = false to inherit from DevSpace"
fi
```

**Check 8 -- Release Please** (auto-fix)

```bash
MISSING=""
if [ ! -f "$PROJECT/.release-please-manifest.json" ]; then
    cp "$DEVKIT_ROOT/project-templates/release-please-manifest.json" "$PROJECT/.release-please-manifest.json"
    MISSING="$MISSING manifest"
fi
if [ ! -f "$PROJECT/release-please-config.json" ]; then
    cp "$DEVKIT_ROOT/project-templates/release-please-config.json" "$PROJECT/release-please-config.json"
    MISSING="$MISSING config"
fi
if [ ! -f "$PROJECT/.github/workflows/release-please.yml" ]; then
    mkdir -p "$PROJECT/.github/workflows"
    cp "$DEVKIT_ROOT/project-templates/release-please.yml" "$PROJECT/.github/workflows/release-please.yml"
    MISSING="$MISSING workflow"
fi
if [ -n "$MISSING" ]; then
    echo "FIXED: Created release-please files:$MISSING"
fi
```

**Check 9 -- LICENSE** (auto-fix)

```bash
if [ ! -f "$PROJECT/LICENSE" ]; then
    YEAR=$(date +%Y)
    OWNER=$(git -C "$PROJECT" config user.name 2>/dev/null || echo "OWNER_NAME")
    cat > "$PROJECT/LICENSE" << EOF
MIT License

Copyright (c) $YEAR $OWNER

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    echo "FIXED: Created MIT LICENSE"
fi
```

**Check 10 -- VERSION** (auto-fix)

```bash
if [ ! -f "$PROJECT/VERSION" ]; then
    echo "0.1.0" > "$PROJECT/VERSION"
    echo "FIXED: Created VERSION file with 0.1.0"
fi
```

**Check 11 -- Gitignore** (auto-fix)

```bash
if [ ! -f "$PROJECT/.gitignore" ]; then
    if echo "$STACKS" | grep -q "go"; then
        TEMPLATE="gitignore-go"
    elif echo "$STACKS" | grep -q "node"; then
        TEMPLATE="gitignore-node"
    elif echo "$STACKS" | grep -q "rust"; then
        TEMPLATE="gitignore-rust"
    elif echo "$STACKS" | grep -q "dotnet"; then
        TEMPLATE="gitignore-dotnet"
    else
        TEMPLATE=""
    fi

    if [ -n "$TEMPLATE" ] && [ -f "$DEVKIT_ROOT/project-templates/$TEMPLATE" ]; then
        cp "$DEVKIT_ROOT/project-templates/$TEMPLATE" "$PROJECT/.gitignore"
        echo "FIXED: Created .gitignore from $TEMPLATE template"
    else
        echo "MANUAL: No .gitignore template for stack: $STACKS"
    fi
fi
```

**Check 12 -- Nightly Workflow** (manual only)

Nightly workflows are too project-specific to auto-create. Suggest the template:

```text
MANUAL: No nightly workflow found.
  Suggested template based on stack:
    Go:     cp $DEVKIT_ROOT/project-templates/nightly-go.yml $PROJECT/.github/workflows/nightly.yml
    Node:   cp $DEVKIT_ROOT/project-templates/nightly-node.yml $PROJECT/.github/workflows/nightly.yml
    Rust:   cp $DEVKIT_ROOT/project-templates/nightly-rust.yml $PROJECT/.github/workflows/nightly.yml
  Copy the appropriate template and customize build commands, binary names, and test targets.
```

**Check 13 -- Release Gate** (auto-fix, only if check 8 passes)

```bash
if [ ! -f "$PROJECT/.github/workflows/release-gate.yml" ]; then
    mkdir -p "$PROJECT/.github/workflows"
    cp "$DEVKIT_ROOT/project-templates/release-gate.yml" "$PROJECT/.github/workflows/release-gate.yml"
    echo "FIXED: Created release-gate.yml from template"
fi
```

### 4. Substitute Placeholders

For all files that were copied from templates, substitute common placeholders:

```bash
PROJECT_NAME=$(basename "$PROJECT")
OWNER=$(git -C "$PROJECT" remote get-url origin 2>/dev/null | sed -n 's|.*github.com[:/]\([^/]*\)/.*|\1|p' || echo "OWNER")
REPO=$(git -C "$PROJECT" remote get-url origin 2>/dev/null | sed -n 's|.*/\([^.]*\).*|\1|p' || echo "$PROJECT_NAME")

# Common substitutions across all created files
for f in $(git -C "$PROJECT" status --porcelain | awk '{print $2}'); do
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT/$f" 2>/dev/null || true
    sed -i "s/{{OWNER}}/$OWNER/g" "$PROJECT/$f" 2>/dev/null || true
    sed -i "s/{{REPO}}/$REPO/g" "$PROJECT/$f" 2>/dev/null || true
done
```

### 5. Report Results

Summarize what was done:

```text
## Fix Results: <project-name>

### Auto-Fixed
- Check 2: Created .claude/settings.json
- Check 7: Created .editorconfig (root = false)
- Check 9: Created MIT LICENSE
- Check 10: Created VERSION (0.1.0)

### Needs Manual Attention
- Check 3 (CI Workflow): Copy and customize template
- Check 12 (Nightly): Copy and customize template

### Already Passing
- Check 1, 4, 5, 6, 8, 11, 13

### Updated Score
Before: 7/13 (54%)
After:  11/13 (85%)
Remaining: 2 checks need manual work
```

Remind the user to review auto-created files before committing, especially `CLAUDE.md` and `Makefile` which likely need project-specific edits.
