# Root Cause Analysis Workflow

When the same type of CI failure occurs repeatedly, dig deeper to find and fix the systemic cause.

## Trigger Conditions

Perform root cause analysis when:
- The same lint error type appears in multiple PRs
- A fix resolves CI, but a similar failure appears in the next PR
- You notice a pattern: "we keep having to add nolint directives for X"
- The user says something like "this keeps happening" or "why does this always fail"

## Analysis Process

### Step 1: Identify the Pattern

```bash
# Get recent CI failures (last 10 failed runs)
gh run list --status failure --limit 10 --json databaseId,displayTitle,headBranch

# For each failed run, extract the error pattern
gh run view <run_id> --log-failed 2>&1 | grep -E "##\[error\]" | head -10
```

**Classify the recurring pattern:**
- Same linter rule failing? (e.g., bodyclose, noctx, gocritic)
- Same file type affected? (e.g., *_test.go)
- Same code pattern triggering it? (e.g., HTTP requests, channel operations)

### Step 2: Compare Local vs CI

**Key question:** Does the same check pass locally but fail in CI?

| Check | Local Command | CI Equivalent |
|-------|--------------|---------------|
| Lint | `make lint` or direct `go vet` | `golangci-lint run ./...` |
| Tests | `go test ./...` | `go test -race ./...` |
| Build | `go build ./...` | `go build` with specific GOOS/GOARCH |

**Common mismatches:**
| Symptom | Root Cause | Prevention |
|---------|------------|------------|
| Local lint passes, CI fails | Makefile runs `go vet` but CI runs `golangci-lint` | Update Makefile to run `golangci-lint` |
| Local test passes, CI race fails | Local doesn't use `-race` flag | Add `make test-race` to dev workflow |
| Local build passes, CI cross-compile fails | CGO issues in CI | Test with `CGO_ENABLED=0` locally |

### Step 3: Find the Systemic Fix

For each pattern type, identify the preventive action:

**Tooling mismatch:**
```bash
# Check what the Makefile lint target does
grep -A2 "^lint:" Makefile
# Compare to CI workflow
cat .github/workflows/ci.yml | grep -A5 "golangci-lint"
```
**Fix:** Update Makefile/scripts to match CI tooling.

**Missing pre-commit checks:**
If developers could catch this before push, add a pre-commit hook or update CONTRIBUTING.md.

**Configuration drift:**
If local config differs from CI config, consolidate to a single source of truth (e.g., `.golangci.yml`).

### Step 4: Implement Prevention

After identifying the root cause, implement one of these preventive measures:

#### Option A: Update Makefile/Build Scripts
Make local dev tools match CI:
```makefile
lint:
    @which golangci-lint > /dev/null 2>&1 || (echo "golangci-lint not found" && exit 1)
    golangci-lint run ./...
```

#### Option B: Add to Learned Patterns
Update `~/.claude/rules/autolearn-patterns.md` with the pattern:
```markdown
## N. <Pattern Name>
**Category:** <lint-fix|ci-config|tooling-mismatch>
**Context:** <When this happens>
**Fix:** <How to fix>
**Prevention:** <How to avoid in future>
```

#### Option C: Update CI Failure Patterns
Add to `references/ci-failure-patterns.md` so future runs catch it faster.

#### Option D: Add Pre-commit Hook
Create `.claude/hooks/pre-commit` to run checks before commit.

### Step 5: Document the Learning

Create or update the project's development documentation:

1. **CLAUDE.md** - Add to "Known Issues" or "Development Setup" if project-specific
2. **autolearn-patterns.md** - Add pattern for cross-project learning
3. **ci-failure-patterns.md** - Add to this skill's reference for future diagnosis

## Reporting Template

After completing analysis, provide this summary:

```markdown
## Root Cause Analysis: [Failure Type]

**Pattern:** [What keeps failing]
**Occurrences:** [How many times, which PRs]

**Root Cause:**
[Why this keeps happening - systemic issue]

**Immediate Fix:**
[What we did to fix this instance]

**Preventive Measures Implemented:**
- [ ] [Measure 1]
- [ ] [Measure 2]

**Documentation Updated:**
- [ ] Makefile / build scripts
- [ ] CLAUDE.md or project docs
- [ ] autolearn-patterns.md
- [ ] ci-failure-patterns.md
```

## Success Criteria

Root cause analysis is complete when:
- [ ] Pattern is clearly identified with examples
- [ ] Local vs CI mismatch explained (if applicable)
- [ ] Systemic cause documented
- [ ] At least one preventive measure implemented
- [ ] Documentation updated to prevent recurrence
- [ ] User understands how to avoid this in future
