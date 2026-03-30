# ADR-0018: Multi-Forge Release Strategy

**Status**: Accepted
**Date**: 2026-03-21
**Deciders**: Herb Hall

## Context

DevKit projects may be hosted on GitHub, Gitea, or both. ADR-0015 standardised
on release-please with a GitHub Action, but did not address Gitea-hosted or
dual-forge scenarios. Claude Token Stats (Gitea-only) was the first project to
surface this gap.

Three options were considered:

1. **GitHub-only releases** — all projects pushed to GitHub for release tooling
2. **Per-forge templates** — identical tool, forge-specific workflow file
3. **Custom abstraction** — build a forge-agnostic release tool from scratch

## Decision

**Option 2: Per-forge templates** — same tool (release-please), same conventions
(conventional commits, `VERSION` file, `CHANGELOG.md`), different CI runtime.

DevKit provides two equivalent workflow templates:

| Forge | Template | Mechanism |
|-------|----------|-----------|
| GitHub | `project-templates/release-please.yml` | `googleapis/release-please-action@v4` |
| Gitea | `project-templates/release-please-gitea.yml` | `npx release-please` CLI |

Orchestration workflows (release-gate, retrigger-ci) follow the same pattern:
Gitea variants use `curl` + Gitea REST API in place of the `gh` CLI.

## Consequences

**Positive:**

- Zero new tooling — release-please already has Gitea API support via `--repo-url`
- Consistent developer experience: same PR flow, same commit conventions, same
  `CHANGELOG.md` format regardless of forge
- Forge-detection added to conformance audit (check 3, 8, 12, 13, 15) so audits
  correctly evaluate Gitea projects without false FAILs
- `RELEASE_PLEASE_TOKEN` is the single secret required on all forges

**Negative / Constraints:**

- Dual-forge projects must designate one forge as authoritative for versioning
- Gitea release-gate uses `merge_when_checks_succeed` instead of `gh pr merge --auto`;
  behaviour may differ subtly
- `workflow_run` trigger unavailable in some act_runner versions — Gitea retrigger-ci
  uses `push: branches: ["release-please--**"]` as a workaround

## Forge Selection Rules

1. Inspect the `origin` remote. GitHub URL → use GitHub templates. Gitea URL → use
   Gitea templates.
2. For dual-forge (origin = GitHub, gitea = mirror or vice versa): run release-please
   on the **primary forge only**. Tags propagate to the secondary forge via
   `git push --tags <remote>` or `devkit-sync`.
3. Never run release-please on both forges simultaneously — duplicate release PRs and
   conflicting tags will result.

## Implementation

- `project-templates/release-please-gitea.yml` — Gitea release workflow
- `project-templates/release-gate-gitea.yml` — Gitea release gate (DevKit #489)
- `project-templates/retrigger-ci-gitea.yml` — Gitea CI retrigger (DevKit #489)
- Conformance audit checks 3, 8, 12, 13, 15 updated (DevKit #488)
- `METHODOLOGY.md` Phase 5 updated with forge selection guide

## References

- ADR-0015: Release Standardization (chose release-please, VERSION file)
- ADR-0016: Release Gating Strategy (tiers: immediate / threshold / batched)
- DevKit issues #488, #489, #490
- Claude Token Stats issue #1 (first Gitea-hosted project using this pattern)
