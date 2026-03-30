# ADR Dependency Map

Cross-project Architecture Decision Record inventory and dependency graph
for the Toolkit family (DevKit, Samverk, Opskit, Synapset).

Generated: 2026-03-30

## ADR Inventory

| ADR ID | Project | Title | Status | References |
|--------|---------|-------|--------|------------|
| DK-0011 | DevKit | Synchronization Architecture | Accepted | -- |
| DK-0012 | DevKit | Three-Tier Configuration Architecture | Proposed | DK-0011 |
| DK-0013 | DevKit | Dual-Language Scripting Strategy | Accepted | DK-0012 |
| DK-0014 | DevKit | Rule Lifecycle Management | Accepted | -- |
| DK-0015 | DevKit | Release Standardization | Accepted | -- |
| DK-0016 | DevKit | Release Gating Strategy | Accepted | DK-0015 |
| DK-0017 | DevKit | Effectiveness Measurement | Accepted | -- |
| DK-0018 | DevKit | DevKit Zone and Project Family Structure | Accepted | DK-0019 |
| DK-0019 | DevKit | Centralized Tool Version Registry | Accepted | DK-0018 |
| DK-0020 | DevKit | Doc-Review Tool Selection | Accepted | -- |
| SV-001 | Samverk | Project Name | Accepted | -- |
| SV-002 | Samverk | Application Layer, Not Infrastructure | Accepted | -- |
| SV-003 | Samverk | Claude-Only for V1 | Partially Superseded | SV-008 |
| SV-004 | Samverk | Custom Orchestration | Accepted | -- |
| SV-005 | Samverk | Go as Implementation Language | Accepted | -- |
| SV-006 | Samverk | Async-First Architecture | Accepted | -- |
| SV-007 | Samverk | Hybrid Local/Cloud Agent Model | Accepted | -- |
| SV-008 | Samverk | Multi-Model by Default | Accepted | SV-003 |
| SV-009 | Samverk | Device Flexibility Non-Negotiable | Accepted | -- |
| SV-010 | Samverk | The Right Success Metric | Accepted | -- |
| SV-011 | Samverk | Chat as Primary Interface | Accepted | -- |
| SV-012 | Samverk | Git Issues as Communication Protocol | Accepted | -- |
| SV-013 | Samverk | Forge Abstraction | Accepted | -- |
| SV-014 | Samverk | Dispatcher Agent | Accepted | -- |
| SV-015 | Samverk | Three-Tier Autonomy Model | Accepted | SV-006 |
| SV-016 | Samverk | User Profile | Accepted | SV-017 |
| SV-017 | Samverk | DevKit as Reference Implementation | Accepted | SV-016 |
| SV-018 | Samverk | Release Versioning and V1 Scope | Accepted | SV-019 |
| SV-019 | Samverk | Self-Hosted-First Development | Accepted | SV-013, SV-018, SV-007 |
| SV-020 | Samverk | Web Dashboard for Operations | Accepted | SV-011, SV-019 |
| SV-021 | Samverk | Intent Verification Protocol | Accepted | SV-015, SV-006 |
| SV-022 | Samverk | Full Project Lifecycle | Accepted | SV-021 |
| SV-023 | Samverk | Per-Project Repos with Coordination | Accepted | SV-013 |
| SV-027 | Samverk | Failure Recovery and State Reconciliation | Proposed | SV-014 |
| SV-030 | Samverk | Cross-Model Quality Assurance | Proposed | SV-015, SV-008 |
| SV-031 | Samverk | Single-Forge-Per-Project Model | Revised | SV-013, SV-019 |
| SV-032 | Samverk | Adaptive Worker Scaling | Accepted | SV-014, SV-019, SV-027 |
| SV-033 | Samverk | PC Agent Worker Node | Accepted | SV-007, SV-013, SV-014, SV-015, SV-021, SV-023, SV-031 |
| SV-034 | Samverk | Cross-Agent Coordination Protocol | Proposed | SV-006, SV-012, SV-013, SV-015, SV-023, SV-027, SV-031 |
| SV-035 | Samverk | Solo Developer Agent Model | Proposed | SV-015, SV-033 |
| SV-036 | Samverk | Multi-Machine Free Agent Runtime | Proposed | SV-019, SV-030, SV-031 |
| SV-038 | Samverk | MAX Plan Token Policy | Accepted | -- |
| SV-039 | Samverk | Two-Location Centralization Rule | Accepted | SV-035 |
| SV-041 | Samverk | GitHub-Only Copilot Review Deprecation | Accepted | SV-013 |
| SV-042 | Samverk | Dispatch Efficiency / Event-Driven Migration | Proposed | SV-027, SV-013, SV-012, SV-039 |
| OK-001 | Opskit | CI Runner Overflow Architecture | Accepted | -- |

**Also found (design doc, not ADR):**

| ID | Project | Title | Status | References |
|----|---------|-------|--------|------------|
| DES-001 | DevKit | Synapset Document Indexing for Doc-Review | Draft | -- |

## Dependency Graph

Arrows indicate "references" or "depends on". Grouped by cluster.

### DevKit Internal

```text
DK-0011 (Sync Architecture)
  └── DK-0012 (Three-Tier Config) ── builds on DK-0011
        └── DK-0013 (Dual-Language Scripting) ── references DK-0012

DK-0015 (Release Standardization)
  └── DK-0016 (Release Gating) ── extends DK-0015

DK-0018 (Zone and Project Families)
  └── DK-0019 (Tool Version Registry) ── referenced by DK-0018, references DK-0018
```

Standalone (no ADR dependencies): DK-0014, DK-0017, DK-0020

### Samverk Core Architecture

```text
SV-003 (Claude-Only V1)
  └── SV-008 (Multi-Model) ── partially supersedes SV-003

SV-006 (Async-First)
  ├── SV-015 (Three-Tier Autonomy) ── references SV-006
  └── SV-021 (Intent Verification) ── references SV-006, SV-015
        └── SV-022 (Full Lifecycle) ── references SV-021

SV-011 (Chat as Interface)
  └── SV-020 (Web Dashboard) ── references SV-011

SV-013 (Forge Abstraction)
  ├── SV-019 (Self-Hosted First) ── references SV-013
  ├── SV-023 (Per-Project Repos) ── references SV-013
  ├── SV-031 (Single-Forge Model) ── references SV-013, SV-019
  ├── SV-034 (Cross-Agent Coord) ── references SV-013
  ├── SV-041 (Copilot Deprecation) ── references SV-013
  └── SV-042 (Dispatch Efficiency) ── references SV-013

SV-014 (Dispatcher Agent)
  ├── SV-027 (Failure Recovery) ── references SV-014
  ├── SV-032 (Adaptive Scaling) ── references SV-014, SV-019, SV-027
  └── SV-033 (PC Agent) ── references SV-014

SV-016 (User Profile) <--> SV-017 (DevKit Reference) ── mutual references
SV-018 (Release Versioning) <--> SV-019 (Self-Hosted First) ── mutual references
```

### Samverk Agent Pipeline (high-connectivity cluster)

```text
SV-033 (PC Agent Worker Node) ── most-connected ADR
  references: SV-007, SV-013, SV-014, SV-015, SV-021, SV-023, SV-031

SV-034 (Cross-Agent Coordination)
  references: SV-006, SV-012, SV-013, SV-015, SV-023, SV-027, SV-031

SV-035 (Solo Developer Agent Model)
  references: SV-015, SV-033

SV-036 (Multi-Machine Free Agent)
  references: SV-019, SV-030, SV-031

SV-042 (Dispatch Efficiency)
  references: SV-012, SV-013, SV-027, SV-039
```

### Cross-Project References

| Source ADR | Target | Relationship |
|------------|--------|-------------|
| SV-017 (DevKit as Reference) | DevKit project | Samverk uses DevKit as the reference implementation for user profiles |
| SV-005 (Go Language) | SubNetree | Mentions SubNetree as same-stack precedent |
| SV-039 (Two-Location Rule) | SV-035 | Relates to solo developer agent model |
| DK-0018 (Zone/Families) | Samverk project | Samverk is a Toolkit-tier project |
| DK-0018 (Zone/Families) | Synapset project | Synapset is a Toolkit-tier project |

No ADRs in Synapset (research docs only, no formal ADRs).
Opskit has a single standalone ADR (OK-001) with no cross-references.

## Orphan References

ADRs referenced in documents but not found as standalone files:

| Referenced As | Referenced In | Notes |
|---------------|---------------|-------|
| SV-024 through SV-026 | (gap in numbering) | Numbers skipped; no files exist |
| SV-028, SV-029 | (gap in numbering) | Numbers skipped; no files exist |
| SV-037 | (gap in numbering) | Number skipped; no file exists |
| SV-040 | (gap in numbering) | Number skipped; no file exists |

These are gaps in the numbering sequence, not missing files. Samverk uses
non-sequential numbering (likely numbers were reserved for ADRs that were
never written or were merged into other decisions).

## Stale "Proposed" ADRs

ADRs with status "Proposed" that may need review:

| ADR ID | Title | Date | Age (days) | Notes |
|--------|-------|------|------------|-------|
| DK-0012 | Three-Tier Configuration Architecture | 2026-02-25 | 33 | Foundational; referenced by DK-0013 which is Accepted. Consider accepting. |
| SV-027 | Failure Recovery and State Reconciliation | undated | unknown | Referenced by SV-032 (Accepted) and SV-034, SV-042. Core infrastructure -- consider accepting. |
| SV-030 | Cross-Model Quality Assurance | undated | unknown | Research-backed. Referenced by SV-036. |
| SV-034 | Cross-Agent Coordination Protocol | 2026-03-14 | 16 | Multi-phase implementation plan. Phase 1 may already be in progress. |
| SV-035 | Solo Developer Agent Model | 2026-03-15 | 15 | Active implementation tracked via issues #501, #503-506. |
| SV-036 | Multi-Machine Free Agent Runtime | 2026-03-15 | 15 | Hardware inventory documented; likely partially implemented. |
| SV-042 | Dispatch Efficiency / Event-Driven | undated | unknown | Addresses active OOM issue (#516). Phase 1 may be in progress. |

**Recommendation:** SV-027, SV-035, and SV-042 all have active implementation
work. Review whether their status should be updated to "Accepted" based on
implementation progress.

## Statistics

| Metric | Count |
|--------|-------|
| Total ADRs | 45 |
| DevKit ADRs | 10 |
| Samverk ADRs | 34 |
| Opskit ADRs | 1 |
| Synapset ADRs | 0 |
| Design docs (DES) | 1 |
| Status: Accepted | 30 |
| Status: Proposed | 7 |
| Status: Partially Superseded | 1 |
| Status: Revised | 1 |
| Status: Draft (DES only) | 1 |
| Cross-ADR references | 58 |
| Most-referenced ADR | SV-013 (Forge Abstraction) -- 7 inbound |
| Most-referencing ADR | SV-034 (Cross-Agent Coordination) -- 7 outbound |
| Highest connectivity | SV-033 (PC Agent) -- 7 outbound references |

## Most-Referenced ADRs (inbound count)

1. **SV-013** (Forge Abstraction) -- 7 references
2. **SV-015** (Three-Tier Autonomy) -- 6 references
3. **SV-019** (Self-Hosted First) -- 5 references
4. **SV-014** (Dispatcher Agent) -- 4 references
5. **SV-027** (Failure Recovery) -- 4 references
6. **SV-006** (Async-First) -- 3 references
7. **SV-023** (Per-Project Repos) -- 3 references
8. **SV-031** (Single-Forge Model) -- 4 references
