# Pre-Release Check

Validates release readiness before tagging. Catches issues that cause tag-fix-retag cycles.

**When to use:** Before tagging a release, after modifying `.goreleaser.yaml` / release workflow / Dockerfile, or when onboarding a project to GoReleaser.

**Philosophy:** Every check corresponds to a real release failure. No theoretical checks.

## Procedure

Run ALL checks below in order. Output a summary table at the end.

### 1. Git State

Verify the working tree is release-ready.

```bash
# Must be on main (or release branch)
git branch --show-current

# Must be clean (no uncommitted changes)
git status --porcelain

# Must be up to date with remote
git fetch origin && git status -uno
```

**Pass criteria:**
- On `main` branch (or user-specified release branch)
- `git status --porcelain` produces no output
- Branch is up to date with `origin/main`

**Fail fix:** Commit or stash changes. Pull latest from origin.

### 2. .gitignore Coverage

Check that common build artifacts are gitignored to prevent GoReleaser dirty-state errors.

**Required patterns** (check `.gitignore` contains these):
- `*.tsbuildinfo` -- TypeScript incremental build cache
- `coverage/` or `web/coverage/` -- test coverage output
- `dist/` -- build output (check both root and `web/dist/`)
- `node_modules/` -- npm/pnpm dependencies

```bash
grep -q 'tsbuildinfo' .gitignore
grep -qE '(^|/)coverage(/|$)' .gitignore
grep -qE '(^|/)dist(/|$)' .gitignore
grep -q 'node_modules' .gitignore
```

**Conditional:** Only check frontend patterns if `web/` or `frontend/` directory exists.

**Fail fix:** Add missing patterns to `.gitignore`.

### 3. GoReleaser Config Validation

**Conditional:** Only run if `.goreleaser.yaml` or `.goreleaser.yml` exists.

```bash
goreleaser check
```

If `goreleaser` is not installed locally, note it as SKIP (not FAIL) with instruction:
`go install github.com/goreleaser/goreleaser/v2@latest`

**Pass criteria:** Exit code 0 and no errors in output.
**Warnings are OK** -- only errors fail this check.

**Fail fix:** Fix the config issues reported by `goreleaser check`.

### 4. Release Workflow Prerequisites

Verify the GitHub Actions release workflow has all required steps based on GoReleaser config.

**File:** `.github/workflows/release.yml` (or file matching `on: push: tags:`)

**Conditional checks based on `.goreleaser.yaml` content:**

| GoReleaser Config Section | Required Workflow Step | How to Detect |
|--------------------------|----------------------|---------------|
| `dockers:` with `use: buildx` | `docker/setup-buildx-action` | Grep release workflow |
| `dockers:` with GHCR images | `docker/login-action` with `registry: ghcr.io` | Grep release workflow |
| `sboms:` | `anchore/sbom-action/download-syft` | Grep release workflow |
| N/A (always) | `goreleaser/goreleaser-action` | Grep release workflow |

**Additional checks:**
- If `web/` or `frontend/` directory exists: verify a frontend build step exists
- If frontend build exists: verify a cleanup step (`git checkout -- web/` or similar) follows it
- Workflow permissions include `contents: write` (for release creation)
- Workflow permissions include `packages: write` (if Docker images are pushed)

**Fail fix:** Add the missing step to the release workflow.

### 5. Version Injection (ldflags)

Cross-reference ldflags across all sources to ensure consistency.

**Sources to compare:**
1. `.goreleaser.yaml` -- `builds[].ldflags`
2. `.github/workflows/release.yml` -- ldflags in build steps (if any)
3. `.github/workflows/ci.yml` -- ldflags in build steps
4. `Dockerfile` or `Dockerfile.goreleaser` -- ARG/ldflags (if present)

**Target:** `internal/version/version.go` (or equivalent) -- extract `var` names

**Check:**
- Every `-X package.Variable` in ldflags must reference an actual `var` in version.go
- Package path must match the Go module path + package path
- Variable names must match exactly (case-sensitive): `Version`, `GitCommit`, `BuildDate`
- Common mismatches to flag: `Commit` vs `GitCommit`, `BuildTime` vs `BuildDate`

```bash
# Extract var names from version.go
grep -E '^\s+\w+\s*=' internal/version/version.go

# Extract ldflags from goreleaser
grep -A 5 'ldflags:' .goreleaser.yaml
```

**Fail fix:** Update ldflags to match the exact variable names in version.go.

### 6. Dockerfile Consistency

If `Dockerfile.goreleaser` exists, verify it's compatible with GoReleaser config.

**Checks:**
- Dockerfile referenced in `.goreleaser.yaml` `dockers[].dockerfile` exists
- If Dockerfile uses `COPY` for the binary, the binary name matches `builds[].binary`
- EXPOSE ports match the application's default ports

**Fail fix:** Update Dockerfile or GoReleaser config for consistency.

## Output Format

After running all checks, output a summary table:

```
## Pre-Release Check Results

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | Git State | PASS/FAIL/WARN | branch, clean state, sync status |
| 2 | .gitignore Coverage | PASS/FAIL | missing patterns (if any) |
| 3 | GoReleaser Config | PASS/FAIL/SKIP | goreleaser check output |
| 4 | Release Workflow | PASS/FAIL | missing steps (if any) |
| 5 | Version Injection | PASS/FAIL | mismatched variables (if any) |
| 6 | Dockerfile Consistency | PASS/FAIL/SKIP | issues found (if any) |

**Overall: READY / NOT READY**
```

If NOT READY, list actionable fix steps in priority order.

If READY, confirm safe to tag:
```
All checks passed. Safe to tag and push:
  git tag -a vX.Y.Z -m "vX.Y.Z"
  git push origin vX.Y.Z
```
