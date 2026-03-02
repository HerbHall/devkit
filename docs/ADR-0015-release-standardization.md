# ADR-0015: Release Standardization

## Status

Accepted

## Date

2026-03-02

## Context

10 projects under DevSpace have fragmented version tracking and inconsistent
changelog practices:

- **Version source of truth** varies: `VERSION` file (3 projects), `Cargo.toml`
  (1), Dockerfile ARG (1), git tags only (1), nothing (4).
- **Changelog practices** are inconsistent: manual Keep a Changelog (3), GoReleaser
  auto-generated (1), none (6).
- **Release automation** exists for 3 projects (SubNetree, Runbooks, DigitalRain)
  but each uses a different pattern. The other 7 have no release infrastructure.
- **Version drift** between files is a known risk (KG#82) -- Runbooks had version
  in Dockerfile ARG but not in package.json.

All projects already use conventional commits, which is the prerequisite for
automated versioning.

## Decision

Standardize all projects on three components:

### 1. VERSION File as Single Source of Truth

Every project has a plain-text `VERSION` file at the repo root containing
`X.Y.Z`. Stack-native files (package.json, Cargo.toml, Dockerfile ARG) are
synced from it by the release tool.

### 2. release-please for Automated Release Management

[release-please](https://github.com/googleapis/release-please) (Google, v4
GitHub Action) creates and maintains a Release PR on every push to main:

- Analyzes conventional commits to determine the next semver version
- Updates `VERSION`, `CHANGELOG.md`, and stack-native files in a PR
- Human merges the Release PR (one-click review gate)
- Creates a git tag and GitHub Release on merge
- The tag triggers existing `release.yml` workflows (GoReleaser, Docker, cargo)

release-please is chosen over semantic-release because:

- Works with standard `GITHUB_TOKEN` (no branch protection workaround needed)
- The Release PR provides a human review gate (aligns with core principle #3)
- Native support for Go, Rust, and Node.js release types
- Existing tag-triggered release.yml workflows are unchanged
- No Node.js dependency in CI (runs as a GitHub Action)

### 3. git-cliff for Changelog Generation (Phase 2)

[git-cliff](https://github.com/orhun/git-cliff) generates high-quality
changelogs from conventional commits using Tera templates. It replaces
release-please's built-in changelog with customizable output.

git-cliff is deferred to Phase 2 to avoid debugging two new tools simultaneously.
Initial rollout uses release-please's built-in changelog.

### Release-Type Mapping

| Stack | release-type | Files Managed |
|-------|-------------|---------------|
| Go | `go` | VERSION, CHANGELOG.md |
| Rust | `rust` | VERSION, Cargo.toml, CHANGELOG.md |
| Node.js / React | `node` | VERSION, package.json, CHANGELOG.md |
| Docker extensions | `node` + extra-files | VERSION, package.json, Dockerfile, CHANGELOG.md |
| C# / .NET | `simple` + extra-files | VERSION, .csproj, CHANGELOG.md |
| PowerShell / generic | `simple` | VERSION, CHANGELOG.md |

### Release Flow

```text
Feature PRs merge to main (conventional commits)
  -> release-please detects new commits
  -> Creates/updates Release PR ("chore(main): release X.Y.Z")
  -> Human merges Release PR
  -> release-please creates git tag (vX.Y.Z) + GitHub Release
  -> Tag triggers existing release.yml (GoReleaser, Docker, cargo)
```

### Per-Project Configuration

Each project gets three files:

- `release-please-config.json` -- release type, version file path, changelog sections
- `.release-please-manifest.json` -- current version (set manually on first setup)
- `.github/workflows/release-please.yml` -- GitHub Actions workflow

Templates for all three are in `project-templates/`.

## Alternatives Considered

### semantic-release

Fully headless automation (every qualifying push to main triggers a release).
Rejected because:

- Cannot push version/changelog commits back to protected branches without a
  GitHub App token -- operational burden with our enforced branch protection
- No human review gate before releases
- Requires Node.js in CI even for Go/Rust/C# projects
- Monorepo support is effectively abandoned

### Manual Tagging (status quo)

Human decides when to release, manually creates tags and GitHub Releases.
Rejected because:

- Inconsistent across projects (some have it, most don't)
- VERSION files drift from tags
- No automated changelog generation
- Releases are skipped because the manual process is tedious

### git-cliff Standalone

Changelog generator only -- no version management or release automation.
Not rejected, but insufficient alone. Adopted as a Phase 2 complement to
release-please for higher-quality changelog output.

## Consequences

### Positive

- Every project has a consistent release process
- VERSION file is the single source of truth -- no more drift
- Changelogs are auto-generated from conventional commits
- Release PRs provide a review checkpoint before publishing
- Existing release.yml workflows (GoReleaser, Docker, cargo) are unchanged
- New projects get release infrastructure from day 1 via devkit templates

### Negative

- release-please adds a "chore: release" commit to main on every release
- C#/.NET support requires workarounds (not a first-class release type)
- The Release PR must be manually merged (intentional, but adds a step)
- git-cliff integration (Phase 2) requires coordinating two tools

### Risks

- release-please is maintained by Google but could be deprecated
- `extra-files` marker syntax (`x-release-please-version`) is mildly invasive
- Projects with irregular commit history may generate noisy first changelogs
  (mitigated with `bootstrap-sha` to exclude ancient history)

## Rollout Plan

1. **Phase 1**: DevKit templates and this ADR
2. **Phase 2**: Projects with existing releases (SubNetree, Runbooks, DigitalRain)
3. **Phase 3**: Projects with some infrastructure (DevKit, Samverk, RunNotes, DockPulse)
4. **Phase 4**: Greenfield projects (CLI-Play, IPScan, PacketDeck)
5. **Phase 5** (future): git-cliff integration for enhanced changelogs

Each phase is independent. Phases 2-4 can run in parallel once templates are ready.
