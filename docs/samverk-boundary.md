# DevKit -- Samverk Boundary Contract

This document defines the ownership boundary between DevKit (base toolkit) and
Samverk (optional lifecycle overlay). It exists to prevent scope creep, avoid
duplication, and make the dependency direction explicit.

## The Relationship

- **DevKit** is the base layer. It provides static scaffolding, templates, rules,
  skills, and conventions that apply to all projects regardless of lifecycle maturity.
- **Samverk** is an optional overlay. It adds dynamic lifecycle management, agent
  orchestration, and coordination tooling on top of a DevKit-configured project.
- **Dependency is one-way**: Samverk consumes DevKit. DevKit does not depend on Samverk.
  A project without Samverk is fully functional; a Samverk-managed project without
  DevKit is missing its foundation.

## The Overlay Model

A plain DevKit project uses the base label set, METHODOLOGY.md phases, and standard
templates. A Samverk-managed project (identified by a `.samverk/` directory) additionally
receives:

- Overlay labels applied via `devkit-sync` Apply Samverk workflow
- A `.samverk/project.yaml` tracking lifecycle phase and agent configuration
- A `.samverk/status.md` coordination hub for cross-session continuity
- Samverk dispatcher routing for issue triage and agent delegation

The overlay does not replace DevKit structures -- it extends them.

## Ownership Table

| Function | Owner | Consumer |
|----------|-------|----------|
| Base label set (feat, fix, chore, docs, test, research) | DevKit | Samverk reads |
| Priority labels (priority:critical/high/normal/low) | DevKit | Samverk reads |
| Milestone labels (milestone:N) | DevKit | Samverk reads |
| Agent delegation base labels (agent:copilot, agent:claude, agent:human) | DevKit | Samverk extends |
| Status labels (blocked, question) | DevKit | Samverk reads |
| Overlay agent labels (agent:orchestrator, agent:dispatcher, etc.) | Samverk | DevKit ignores |
| Status workflow labels (status:queued, status:in-progress, etc.) | Samverk | DevKit ignores |
| Complexity routing labels | Samverk | DevKit ignores |
| Phase lifecycle labels (phase:intake through phase:killed) | Samverk | DevKit ignores |
| METHODOLOGY.md phases 0--2 (Concept, Research, Validate) | DevKit | Samverk supersedes for managed projects |
| METHODOLOGY.md phases 3--5 (Build, Stabilize, Release) | DevKit | Samverk defers to |
| Project scaffolding (templates, settings, CI) | DevKit | Samverk reads |
| `.samverk/project.yaml` lifecycle state | Samverk | DevKit reads (registry only) |
| `.samverk/status.md` coordination hub | Samverk | DevKit ignores |
| Project registry (`~/.devkit-registry.json`) | DevKit | Samverk updates `samverk` field |
| SessionStart hook (auto-pull, version check) | DevKit | Samverk SessionStart reads status.md after |

## Label Architecture

Labels are organized in two tiers:

**Base tier (DevKit-owned)** -- applied to all projects. Defined in
`project-templates/github-labels.json`. These labels are disjoint from the overlay
tier by design: no name collisions, no prefix conflicts.

**Overlay tier (Samverk-owned)** -- applied only to Samverk-managed projects. Defined in
`Samverk/overlay/labels.json`. Uses `agent:orchestrator`, `status:*`, `complexity:*`,
and `phase:*` prefixes that DevKit does not use in its base set.

The invariant: every label in `project-templates/github-labels.json` must NOT appear
in `Samverk/overlay/labels.json`, and vice versa.

## Design Principles

1. **Tools vs orchestration** -- DevKit provides tools (templates, skills, rules).
   Samverk provides orchestration (lifecycle state, agent routing, coordination).
   Tools can exist without orchestration; orchestration needs tools to act on.

2. **Static vs dynamic** -- DevKit artifacts are static (files committed to repos,
   symlinked configs, markdown rules). Samverk artifacts are dynamic (phase transitions,
   dispatcher state, agent assignment). Different change rates, different owners.

3. **Machine vs service** -- DevKit is per-machine configuration. Samverk is
   per-project service state. DevKit syncs across machines; Samverk state lives in the
   project repo.

4. **Single source of truth** -- Each fact has one owner. Priority labels are defined
   in DevKit; Samverk reads them. Lifecycle phase is defined in `.samverk/project.yaml`;
   DevKit's registry reads it. Never duplicate definitions.

5. **Samverk consumes, DevKit provides** -- If Samverk needs something DevKit doesn't
   have, the right answer is either: (a) add it to DevKit so all projects benefit, or
   (b) keep it in Samverk as overlay-only. Never fork or shadow DevKit artifacts.

## Related Documents

- [Samverk overlay README](https://github.com/HerbHall/samverk/blob/main/overlay/README.md)
- [Samverk project lifecycle](https://github.com/HerbHall/samverk/blob/main/docs/project-lifecycle.md)
- [DevKit ADR-0012: Three-tier architecture](docs/ADR-0012-three-tier-architecture.md)
- [Project registry schema](docs/project-registry-schema.md)
- [Base label template](project-templates/github-labels.json)
- [Label conventions reference](claude/skills/manage-github-issues/references/label-conventions.md)
