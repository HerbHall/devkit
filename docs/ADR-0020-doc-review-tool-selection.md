# ADR-0020: Doc-Review Tool Selection

- **Status**: Accepted
- **Date**: 2026-03-30
- **Deciders**: Herb, Claude

## Context

The doc-review system needs tools beyond the existing markdownlint-cli2 setup. Docs are machine-first (written and consumed by agents). The system needs: link integrity checking, structural schema validation, and formatting auto-fix. Four tools were evaluated: lychee (link checker), mdformat (auto-formatter), remark-lint (AST-based processing), and a custom Go validator using goldmark.

## Decision

Adopt a three-layer stack with zero overlap:

1. **markdownlint-cli2** (existing) -- style and formatting
2. **lychee** (new) -- link integrity checking
3. **Custom Go validator using goldmark** (new) -- structural schema validation against `doc-schemas.yaml`

Skip mdformat (markdownlint-cli2 `--fix` is sufficient). Defer remark-lint unless the custom validator's scope creeps into needing AST transforms.

## Consequences

### Positive

- No new JavaScript toolchain (lychee is a standalone Rust binary, custom validator is Go)
- Three orthogonal layers: style, links, structure -- clear separation of concerns
- Custom validator is exactly scoped to our doc-schemas.yaml use case (~80-100 lines of Go)
- lychee's `.lycheeignore` handles private/localhost URLs cleanly (Synapset, Gitea, Home Assistant)

### Negative

- Custom validator requires maintenance when doc-schemas.yaml changes (low burden -- schema changes are the config, not the code)
- lychee may need `.lycheeignore` tuning for rate-limited external sites

### Neutral

- If the custom validator later needs AST transforms (auto-inserting missing sections), remark becomes the upgrade path
- mdformat can be reconsidered if markdownlint-cli2 `--fix` proves insufficient

## Impact Assessment

- **Scope**: Cross-project (tools apply to all Toolkit projects)
- **Reversibility**: Easily reversible (both tools are additive, removing them has no side effects)
- **Dependencies affected**: CI workflows in all Toolkit projects will need lychee and validator steps
- **Review level required**: Self (cross-project but easily reversible)

## Alternatives Considered

### mdformat for auto-formatting

Idempotent CommonMark formatter. Rejected because markdownlint-cli2 `--fix` already handles formatting, and adding a Python dependency plus config alignment maintenance is not justified for marginal improvement.

### remark-lint for structural validation

Full AST access with custom plugin ecosystem. Rejected for now because running two markdown linting systems (markdownlint + remark) creates maintenance overhead. The custom validator handles the specific schema validation use case more simply. Revisit if AST transforms become necessary.

## References

- [lychee GitHub](https://github.com/lycheeverse/lychee)
- [goldmark Go markdown parser](https://github.com/yuin/goldmark)
- `devspace/templates/doc-schemas.yaml` (schema definitions)
- Doc-Review Roadmap Phase 0.1
