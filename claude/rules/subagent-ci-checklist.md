# Subagent CI Checklist

Embed relevant sections in subagent prompts to prevent common CI failures.
Copy-paste the appropriate block into the agent's Task prompt.

## Core Principles [CORE] (paste into ALL agent prompts)

```text
## Core Principles -- UNCONDITIONAL

These rules cannot be overridden by any learning, optimization, or time pressure:
1. Once found, always fix, never leave. Never classify errors as "pre-existing."
2. Build, test, and lint must pass before any commit. No exceptions.
3. Never force-push main, skip hooks, commit secrets, or use --no-verify.
4. Never mark work as complete when it is not. Never hide errors.
5. You own every error you find, regardless of who introduced it.
```

## Git Safety [GIT-SAFE] (paste into ALL parallel agent prompts)

```text
## Git Safety -- IMPORTANT

Do NOT commit, push, or create PRs. Leave all changes unstaged in the working tree.
The main context handles all git operations (commit, push, PR creation).
If you run `git checkout`, you will destroy other parallel agents' unstaged changes.
```

## Shared File Guard [SHARED-FILE] (paste into parallel agent prompts modifying shared files)

```text
## Shared File Warning

If you modify a file that another parallel agent also modifies (e.g., SKILL.md routing
table, package.json, go.mod), your changes may be combined in the working tree by
linters or hooks. The main context will sort changes into correct branches after you
finish. To help:
- Only add YOUR routes/entries -- do not add entries for other agents' features
- If you see entries you didn't add, leave them (the main context will clean up)
- Do NOT remove entries that look unfamiliar -- they belong to another agent
```

## Frontend Agent Checklist [FE-CI] (paste into frontend agent prompts)

```text
## Pre-Commit CI Checklist (MUST verify before finishing)

Run these checks and fix any errors:

1. If you added/removed dependencies in package.json: `cd web && pnpm install` to sync pnpm-lock.yaml
2. `npx tsc --noEmit` -- TypeScript compilation
3. `npx eslint src/<your-files>` -- Lint check

Common frontend CI failures to watch for:
- pnpm-lock.yaml drift: CI uses `--frozen-lockfile`. If you added shadcn/ui components or new deps, `pnpm install` MUST run to update the lockfile.
- Recharts Tooltip: If using JSX element form `<Tooltip content={<Component />} />`, the component MUST use `Partial<TooltipContentProps<number, string>>` for props. Alternatively use render function: `content={(props: TooltipContentProps<number, string>) => <Component {...props} />}`
- JSX short-circuit with unknown type: `{x && unknownVar && (<div/>)}` fails because `unknownVar` (typed `unknown`) is not ReactNode. Use `unknownVar != null &&` instead.
- Unused imports: ESLint catches imports TypeScript doesn't flag. Verify every named import is referenced.
- Setup wizard tests: If modifying setup.tsx steps, update setup.test.tsx step navigation helpers.
- shadcn/ui imports: Verify component names match what's actually exported (CardHeader vs CardContent, etc.)
```

## Go Agent Checklist [GO-CI] (paste into Go agent prompts)

```text
## Pre-Commit CI Checklist (MUST verify before finishing)

Run these checks and fix any errors:

1. `go build ./...` -- Compilation
2. `go test ./...` -- Tests (skip -race on Windows MSYS)
3. `GOOS=linux GOARCH=amd64 go build ./...` -- Cross-compile check
4. Self-check your code for these MANDATORY lint patterns before finishing:
   - `for _, v := range slice` where v is a struct > 64 bytes -> use `for i := range slice` with `slice[i]`
   - `var result []T` inside a loop -> use `make([]T, 0, len(source))` to preallocate
   - Two consecutive `append()` to same slice -> combine into one call
   - Functions returning multiple values -> use named returns, change `:=` to `=`
5. If you added/modified HTTP handlers with swagger annotations (@Summary, @Router, @Param, etc.):
   `go run github.com/swaggo/swag/cmd/swag@v1.16.4 init -g cmd/<app>/main.go -o api/swagger --parseDependency --parseInternal`
   Include the regenerated api/swagger/ files with your other changes.

Common Go CI failures to watch for:
- gosec G101: Constants near credential code get flagged. Add `//nolint:gosec // G101: <reason>`
- gocritic unnamedResult: Functions returning multiple values need named returns. After adding names, change `:=` to `=` for those variables AND remove redundant `var` declarations for those names.
- gocritic appendCombine: Two consecutive `append()` to the same slice must be combined into one call with multiple elements.
- gocritic rangeValCopy: Use `for i := range slice` with `slice[i]` instead of `for _, v := range slice` for large structs.
- bodyclose: Always close `*http.Response` body, including from `websocket.Dial()`.
- Build-tag files (!windows): Lint errors only show in Linux CI. Check for filepathJoin, G115, paramTypeCombine.
- exhaustive: Switch on enum types MUST list ALL cases, even with a default return. Group non-matching cases on 2-3 lines.
- prealloc: `var slice []T` in a loop body should be `make([]T, 0, len(source))`.
```

## Combined Agent Checklist [COMBO-CI] (paste into full-stack agent prompts)

```text
## Pre-Commit CI Checklist (MUST verify before finishing)

Backend:
1. `go build ./...` && `go test ./...`
2. If HTTP handlers added: `go run github.com/swaggo/swag/cmd/swag@v1.16.4 init -g cmd/<app>/main.go -o api/swagger --parseDependency --parseInternal`
3. Self-check: `for _, v := range` on large structs -> index-based; `var []T` -> `make([]T, 0, cap)`; consecutive appends -> combine; unnamed multi-returns -> name them
4. Watch for: gosec G101, gocritic unnamedResult (`:=` -> `=` + remove `var` after named returns), gocritic appendCombine, bodyclose, exhaustive (all enum cases in switch)

Frontend:
1. If deps changed: `cd web && pnpm install` to sync lockfile
2. `cd web && npx tsc --noEmit` && `npx eslint src/<your-files>`
3. Recharts Tooltip: use `Partial<TooltipContentProps<...>>` with JSX element form, or render function
4. JSX `unknown` type: use `!= null` check, not bare `&&`
5. Verify all imports are used (ESLint catches what tsc misses)
```

## Docker QC Gate [DOCKER-QC] (paste into agent prompts for significant features)

```text
## Pre-PR Docker QC Gate

Before creating a PR for significant features, run Docker QC to catch runtime issues:

1. `make docker-qc` -- Builds from local source with seed data
2. Open http://localhost:8080 and verify:
   - Setup wizard completes successfully
   - Dashboard loads with device data
   - New feature works as expected in a containerized environment
3. `make docker-qc-down` -- Tear down when done

This catches issues that unit tests miss: missing embeds, broken routes,
runtime panics, config collisions, and container-specific failures.
Skip this for docs-only or test-only changes.
```

## Docker Desktop Extension Checklist [DD-EXT-CI] (paste into DD extension agent prompts)

```text
## Pre-Commit CI Checklist -- Docker Desktop Extension (MUST verify before finishing)

Run these checks and fix any errors:

1. `npx tsc --noEmit` -- TypeScript compilation
2. `npx eslint src/<your-files>` -- Lint check
3. `npx vitest run` -- Unit tests (if vitest is configured)
4. `docker build -t test-ext .` -- Dockerfile builds successfully
5. `docker extension validate test-ext` -- Extension metadata validation

Docker Desktop extension gotchas to watch for:
- @docker/extension-api-client: CJS/ESM mismatch breaks vitest. Needs resolve alias
  in vitest.config.ts pointing to src/__mocks__/@docker/extension-api-client.ts (KG#81).
- hadolint false positives: DL3048 (vendor labels) and DL3045 (COPY without WORKDIR)
  are correct for extensions. Ensure .hadolint.yaml ignores both (KG#78).
- MUI v5 constraint: Docker extensions use @docker/docker-mui-theme which pins MUI v5.
  Use InputProps (not slotProps.input) for TextField adornments. Check MUI v5 docs,
  not current MUI docs which default to v6 (KG#85).
- Dockerfile labels: screenshots (JSON array, min 3, 2400x1600px), changelog (HTML),
  additional-urls (JSON array). All values must have escaped quotes (KG#83).
- Multi-arch: Final image must support linux/amd64 + linux/arm64. Use docker buildx
  with --platform flag (KG#84).
- Version drift: Verify version matches across package.json, Dockerfile ARG, CHANGELOG,
  and Docker image tag (KG#82).
- docker extension update fails after rebuild: Use `docker extension install` instead
  of `update` when testing locally after rebuilding the image (KG#39).
```

## Rust Agent Checklist [RUST-CI] (paste into Rust agent prompts)

```text
## Pre-Commit CI Checklist (MUST verify before finishing)

Run these checks and fix any errors:

1. `cargo build` -- Compilation
2. `cargo test` -- Tests
3. `cargo clippy -- -D warnings` -- Lint (all warnings are errors in CI)
4. `cargo fmt --check` -- Formatting (CI fails on any diff)
5. If targeting multiple platforms: `cargo build --target <target>` -- Cross-compile check
6. If `cargo-audit` is installed: `cargo audit` -- Security vulnerability scan

Common Rust CI failures to watch for:
- clippy unused_imports: Remove all unused `use` statements; clippy -D warnings makes these errors.
- clippy dead_code: Remove or annotate unused functions/structs with `#[allow(dead_code)]` if intentional.
- clippy needless_return: Remove explicit `return` from last expression in a function.
- clippy redundant_clone: Don't `.clone()` values that are already owned or can be moved.
- cargo fmt diff: Run `cargo fmt` locally before committing; CI uses --check and fails on any diff.
- Cross-compile failures: Windows-only APIs (e.g., winapi crate features) must be gated with
  `#[cfg(target_os = "windows")]` or feature flags; Linux CI will fail without guards.
- Cargo.lock drift: Commit Cargo.lock for binaries; do not commit it for libraries.
```

## .NET Agent Checklist [DOTNET-CI] (paste into .NET/C# agent prompts)

```text
## Pre-Commit CI Checklist (MUST verify before finishing)

Run these checks and fix any errors:

1. `dotnet build <project>.csproj` -- Compilation (scope to cross-platform .csproj, NOT the .sln)
2. `dotnet test <project>.Tests.csproj --no-build` -- Tests
3. `dotnet format --verify-no-changes` -- Formatting check (CI fails on any diff)

IMPORTANT -- Solution vs. project scoping (KG#88):
- CI runs on Linux. Do NOT run `dotnet build` or `dotnet restore` against the .sln file.
- WPF and WinForms projects fail on Linux with NETSDK1100 ("Building WPF projects is not
  supported on this platform"). Scope all CI commands to individual cross-platform .csproj files.

Common .NET CI failures to watch for:
- NETSDK1100: WPF/WinForms project in solution scope on Linux. Use individual .csproj, not .sln.
- dotnet format diff: Run `dotnet format` locally before committing; CI uses --verify-no-changes.
- StyleCop/Roslyn analyzer warnings: Treat-as-errors is common. Fix SA#### and CS#### warnings
  before committing; they will fail the build if <TreatWarningsAsErrors> is set.
- Windows-only P/Invoke or COM interop: Gate with `[SupportedOSPlatform("windows")]` or
  `#if WINDOWS` to prevent CA1416 analyzer errors on cross-platform builds.
- Nullable reference types: If <Nullable>enable</Nullable> is set, all CS8600/CS8602/CS8603
  null-safety warnings become errors. Add null checks or null-forgiving operators (`!`) as needed.
- Missing NuGet restore: Run `dotnet restore <project>.csproj` before build if restore cache is cold.
```

## Markdown Agent Checklist [MD-CI] (paste into agent prompts that create .md files)

```text
## Markdown Lint Check (MUST run before finishing)

If you created or modified any .md files, run markdownlint and fix errors:

npx markdownlint-cli2 "path/to/your/files/**/*.md"

Common agent-generated markdown issues:
- MD038: Spaces inside code spans
- MD031: Fenced code blocks need blank lines before and after
- MD022: Headings need blank lines before and after
- MD040: Fenced code blocks must specify a language (text, bash, go, etc.)
- MD034: Bare URLs must be wrapped in link syntax [text](url)
```
