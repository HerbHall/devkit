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
