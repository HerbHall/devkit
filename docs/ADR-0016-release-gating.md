# ADR-0016: Release Gating Strategy

## Status

Accepted

## Date

2026-03-04

## Context

ADR-0015 introduced release-please for automated release management. release-please
creates a Release PR on every push to main, but those PRs require manual merging.
For active projects with frequent commits, this creates friction:

- Patch-only releases (single typo fix) don't warrant a human merge ceremony
- Security fixes should ship immediately without waiting for a maintainer
- Minor releases with features should ship promptly
- But trivial patch releases can be batched until they reach a significance threshold

SubNetree PR #525 implemented a release gate workflow that evaluates release-please
PRs and auto-merges based on changelog significance. This ADR documents the strategy
and provides it as a DevKit template for all projects.

## Decision

Add a **Release Gate** workflow that runs on release-please PRs and classifies them
into three tiers based on the changelog content and version bump:

### Release Tiers

| Tier | Criteria | Action |
|------|----------|--------|
| Immediate | `fix!:`, `BREAKING CHANGE`, CVE, security/vulnerability keywords | Auto-merge now |
| Threshold | Major or minor version bump, OR 5+ accumulated fix commits | Auto-merge now |
| Batched | Below threshold (few patches, no features) | Label and wait for manual merge |

### How It Works

1. release-please creates/updates a Release PR with the `autorelease: pending` label
2. The Release Gate workflow triggers on PR open/sync/reopen/label events
3. It reads `.release-please-manifest.json` to compare current vs proposed version
4. It counts conventional commits since the last release tag by type (feat/fix)
5. Based on the tier classification, it either enables auto-merge or labels as batched
6. A structured comment is posted on the PR with the decision and reasoning
7. Previous bot comments are cleaned up to avoid spam

### Labels

- `release:auto` (green) -- auto-merge enabled, will merge when CI passes
- `release:batched` (yellow) -- below threshold, waiting for more changes or manual merge

### Integration with release-please

```text
Feature PRs merge to main
  -> release-please creates/updates Release PR
  -> Release Gate evaluates the PR
  -> Immediate/Threshold: auto-merge enabled, merges when CI green
  -> Batched: stays open, accumulates more commits
  -> On merge: release-please creates git tag + GitHub Release
  -> Tag triggers release.yml (GoReleaser, Docker, cargo)
```

The gate workflow is language-agnostic. It only reads the release-please manifest
and git history -- no build tools or language runtimes required.

## Nightly Builds

Alongside the release gate, DevKit provides nightly build templates for continuous
testing of the main branch between formal releases:

- **Go variant**: Docker image + cross-platform binary matrix
- **Node variant**: Docker image only (for Docker Desktop extensions)
- **Rust variant**: Cross-platform binary matrix

Nightly builds run at 2 AM UTC, skip if no commits in 24 hours, and can be
triggered manually. They push to GHCR with `nightly` and `nightly-YYYYMMDD` tags.
Artifacts have 7-day retention.

## Alternatives Considered

### Always Auto-Merge

Auto-merge every release-please PR regardless of content. Rejected because trivial
single-fix patches create noise in the release history and notification fatigue for
watchers.

### Manual-Only

Keep all release merges manual (status quo before this ADR). Rejected because it
creates friction for security fixes and feature releases that should ship promptly.

### Time-Based Batching

Auto-merge if the Release PR has been open for N days. Rejected because time-based
rules don't account for content significance -- a security fix shouldn't wait 3 days.

## Consequences

### Positive

- Security and breaking changes ship immediately without human intervention
- Feature releases auto-ship, reducing merge ceremony
- Trivial patches batch naturally until they reach significance
- PR labels and comments provide visibility into the gating decision
- Language-agnostic -- works for Go, Rust, Node.js, C#, and PowerShell projects

### Negative

- Adds another workflow file to maintain per project
- Auto-merge requires branch protection to allow GitHub Actions to merge
- The fix threshold (5) is a judgment call that may not suit all projects
- Batched releases can accumulate indefinitely if no features are added

### Risks

- A mislabeled commit (e.g., `fix:` for what should be `feat:`) could batch
  a release that should auto-merge. Mitigated by conventional commit enforcement
  in CI.
- Auto-merge on security keywords could be gamed. Low risk for private/small-team
  repos; larger teams should review the keyword list.
