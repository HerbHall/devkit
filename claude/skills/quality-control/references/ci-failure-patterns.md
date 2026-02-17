# CI Failure Patterns Reference

Quick-reference for diagnosing and fixing common CI failures. Each pattern includes symptom, root cause, and fix.

## Local vs CI Mismatches

### Makefile Lint Mismatch (Most Common!)

**Symptom:** `make lint` passes locally but golangci-lint fails in CI with errors like `bodyclose`, `noctx`, `gocritic`, etc.

**Root Cause:** Makefile `lint` target runs only `go vet`, while CI runs full `golangci-lint` with all linters from `.golangci.yml`.

**Diagnosis:**

```bash
# Check what local lint does
grep -A2 "^lint:" Makefile
# If it shows "go vet ./..." instead of "golangci-lint run ./...", that's the problem
```

**Fix:** Update Makefile to run the same tooling as CI:

```makefile
lint:
    @which golangci-lint > /dev/null 2>&1 || (echo "Install: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest" && exit 1)
    golangci-lint run ./...
```

**Prevention:** Always ensure local tooling matches CI. Add a `lint-fast: go vet ./...` target for quick checks.

## Go Lint Failures

### gosec G101 - Hardcoded Credentials (False Positive)

**Symptom:** `G101: Potential hardcoded credentials (gosec)` on constants/variables containing "credential", "password", "secret", "token" in their name.
**Root Cause:** gosec flags any identifier with credential-related words, even if it's just a label or enum value.
**Fix:** Add `//nolint:gosec // G101: <reason why this is not a credential>` on the flagged line.

### gocritic rangeValCopy

**Symptom:** `rangeValCopy: each iteration copies N bytes (consider pointers or indexing) (gocritic)`
**Root Cause:** `for _, v := range slice` copies the struct on each iteration. Large structs (>64 bytes) trigger this.
**Fix:** Use `for i := range slice { ... slice[i].Field ... }` instead.

### bodyclose - HTTP Response Body Not Closed

**Symptom:** `response body must be closed (bodyclose)` on HTTP client calls.
**Root Cause:** The linter tracks that `http.Response.Body` must be closed. It cannot track closure across goroutine boundaries (e.g., response passed via channel).
**Fix Options:**

1. Close body immediately: `defer resp.Body.Close()` right after the check for `err != nil`
2. For channel patterns: Add `//nolint:bodyclose // Body closed in <location>` with explanation
3. For error paths: `if resp != nil { resp.Body.Close() }`

### noctx - HTTP Request Without Context

**Symptom:** `(*net/http.Client).Get must not be called (noctx)` or similar.
**Root Cause:** `http.Client.Get()` doesn't accept a context. The linter wants all HTTP calls to be cancellable.
**Fix:** Use `http.NewRequestWithContext` instead:

```go
// Instead of:
resp, err := client.Get(url)

// Use:
req, err := http.NewRequestWithContext(ctx, "GET", url, http.NoBody)
resp, err := client.Do(req)
```

### gocritic httpNoBody

**Symptom:** `httpNoBody: http.NoBody should be preferred to the nil request body (gocritic)`
**Root Cause:** `httptest.NewRequest(..., nil)` should use `http.NoBody` for clarity.
**Fix:** Replace `nil` with `http.NoBody`:

```go
// Instead of:
req := httptest.NewRequest(http.MethodGet, path, nil)
// Use:
req := httptest.NewRequest(http.MethodGet, path, http.NoBody)
```

### golangci-lint Version Mismatch

**Symptom:** `the Go language version used to build golangci-lint is lower than the targeted Go version`
**Root Cause:** Pre-built golangci-lint binary was compiled with an older Go version than the project requires.
**Fix:** In CI workflow, change `install-mode: binary` to `install-mode: goinstall` so golangci-lint is built from source using the project's Go version.

## License Check Failures

### Unknown License (go-licenses)

**Symptom:** `Failed to find license for <package>: cannot find a known open source license`
**Root Cause:** go-licenses can't locate or classify the license file for a dependency. Common with packages that have non-standard license file names or locations.
**Fix Options:**

1. Use grep-based blocked-license check instead of allowlist: `go-licenses check ./... 2>&1 | grep -E "GPL|AGPL|LGPL|SSPL" && exit 1 || echo "OK"`
2. Add `--ignore <package>` to exclude specific packages
3. For project's own code: `--ignore github.com/<owner>/<repo>`

### BSL 1.1 Not Recognized

**Symptom:** go-licenses fails on project's own internal packages when using `--allowed_licenses`.
**Root Cause:** BSL 1.1 is not in go-licenses' standard license database.
**Fix:** Add `--ignore github.com/<owner>/<repo>` to skip the project's own packages (only scan third-party dependencies).

## Build Failures

### CGo Required (race detector)

**Symptom:** `-race requires cgo` or `CGo is not available`
**Root Cause:** Go's race detector requires CGo, which may not be available on all platforms (e.g., Windows MSYS, cross-compilation).
**Fix:** Either enable CGo or remove `-race` flag for affected platforms. Or only run race detection on Linux CI runners.

### Cross-Compilation Failures

**Symptom:** Build fails with `GOOS=X GOARCH=Y` but succeeds natively.
**Root Cause:** Dependency uses CGo or platform-specific code.
**Fix:** Ensure `CGO_ENABLED=0` for cross-compilation, or use a compatible build tag.

## Frontend Failures

### Recharts Tooltip Content Prop Type Error

**Symptom:** `TS2739: Type '{}' is missing the following properties from type` on `<Tooltip content={<Component />} />`
**Root Cause:** Passing a JSX element to Recharts v3 `content` prop creates `{}` props, missing required `payload`, `coordinate`, `active`, etc.
**Fix:** Use a render function:

```tsx
// BAD:
<Tooltip content={<ChartTooltip />} />
// GOOD:
<Tooltip content={(props: TooltipContentProps<number, string>) => <ChartTooltip {...props} />} />
```

### JSX Short-Circuit with Unknown Type

**Symptom:** `TS2322: Type 'unknown' is not assignable to type 'ReactNode'`
**Root Cause:** `{x && unknownTypedVar && (<div/>)}` evaluates to `unknownTypedVar` (not boolean) when truthy. `unknown` is not ReactNode.
**Fix:** Use explicit null check: `unknownTypedVar != null &&` which evaluates to `boolean`.

### Unused Imports (ESLint)

**Symptom:** `@typescript-eslint/no-unused-vars` error on imports that TypeScript didn't flag.
**Root Cause:** `tsc --noEmit` passes but ESLint catches unused named imports (type-only imports, unused UI components).
**Fix:** Run `npx eslint src/<files>` after `tsc`. Remove any imports not actually referenced.

### Setup Wizard Test Breakage

**Symptom:** `setup.test.tsx` fails after modifying `setup.tsx` step count.
**Root Cause:** Tests navigate by step index. Adding/removing wizard steps shifts the navigation sequence.
**Fix:** Update `goToStepN()` test helpers to match new step count. Add mocks for any new API calls in new steps.

## Workflow/Infrastructure Failures

### All Checks Cancelled

**Symptom:** Every CI job shows CANCELLED with no step output.
**Root Cause:** Concurrency group cancelled the run (new push to same branch), workflow was manually cancelled, or runner allocation failed.
**Fix:** Re-run the workflow: `gh api repos/{owner}/{repo}/actions/runs/{run_id}/rerun -X POST`

### Stale Branch Conflicts

**Symptom:** PR shows merge conflicts or CI runs against outdated code.
**Fix:** Rebase the branch: `git checkout <branch> && git rebase main && git push --force-with-lease`

### CLA Check Failure

**Symptom:** CLA check fails or shows as pending.
**Root Cause:** Contributor hasn't signed the CLA.
**Fix:** User-level action required -- contributor must sign the CLA via the link in the PR check.
