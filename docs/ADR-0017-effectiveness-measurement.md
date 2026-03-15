# ADR-0017: DevKit Effectiveness Measurement

## Status

Accepted (2026-03-15)

## Context

DevKit has anecdotal evidence of impact on code quality ("zero rework sprint" AP#101, "all CI-green first pass" AP#127) but no objective, quantifiable measurement system. Without data, we cannot:

- Prove DevKit reduces rework across projects
- Identify which patterns deliver the most value
- Track improvement or degradation over time
- Make evidence-based decisions about rule priorities

Samverk and Synapset both have production-grade monitoring (runtime metrics, failure tracking, tool call recording). DevKit needs an adapted approach since it is a configuration toolkit, not a running service.

## Decision

Implement a four-phase effectiveness measurement system using existing infrastructure.

### Architecture

Three storage tiers:

1. **SQLite MCP** (`~/databases/claude.db`) for structured metrics (PR data, CI pass rates, conformance scores, skill usage)
2. **Synapset MCP** (pool: `devkit-metrics`) for semantic search over session narratives
3. **GitHub API** (via `gh`) as source of truth for CI/PR data

Collection happens at natural boundaries (session start/end, autolearn runs, CI completions) rather than continuously. No new always-on processes.

### Key Metrics

| Metric | Source | Collection Method |
|--------|--------|------------------|
| Rework Rate (fix-push cycles per PR) | GitHub API | On-demand script |
| CI First-Pass Rate | GitHub API | On-demand script |
| Pattern Application | Autolearn skill | Session boundary |
| Autolearn Velocity | GitHub Issues + Rules | Session boundary |
| Skill Usage | Skill instrumentation | Per invocation |
| Conformance Score | Conformance audit | Per audit run |

### Why SQLite Over Synapset for Structured Metrics

Synapset excels at semantic search over unstructured text. Metrics are structured, relational data requiring aggregation (AVG, SUM, GROUP BY) and time-series comparison. SQLite via MCP provides this naturally. Synapset remains the store for session narratives and pattern application context.

## Alternatives Considered

1. **Synapset-only**: Rejected. Vector similarity search is wrong tool for numeric aggregation.
2. **GitHub API only (no persistence)**: Rejected. Rate limits and no historical trend capability.
3. **File-based JSON snapshots**: Considered for Phase 4 as git-tracked history supplement.
4. **External service (Grafana/Prometheus)**: Rejected. Over-engineered for a config toolkit.

## Consequences

- New `/metrics` skill with dashboard, collect, rework-report, trend workflows
- Schema in `scripts/metrics-init.sql` -- tables created on first use
- Collection script `scripts/collect-pr-metrics.sh` queries GitHub API
- Phases 2-3 instrument existing skills (autolearn, conformance-audit) with recording steps
- README skill count increases from 21 to 22
