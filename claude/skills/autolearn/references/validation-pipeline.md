# Rule Validation Pipeline

Five-stage gate for proposed rule additions. Surfaces concerns for human review.

## Stages

### Stage 1: Dangerous Pattern Scan

Check the proposed rule text for words/phrases that suggest bypassing safety:

**Blocked patterns** (CRITICAL -- reject immediately):

- `--no-verify`, `--force`, `force-push main`
- `skip hooks`, `bypass review`, `ignore errors`
- `suppress warnings`, `disable lint`, `silence checks`
- `nolint` without a justification comment
- `--allow-empty`, `git reset --hard` without context
- `mark as complete` when not verified

**Warning patterns** (MEDIUM -- flag for review):

- `workaround` without documenting the root cause
- `temporarily` without a follow-up issue
- `TODO` or `FIXME` without a tracking reference
- `pre-existing` (replaced by fix-forward, see error-policy.md)

### Stage 2: Core Principles Check

Verify the proposed rule does not contradict any of the 10 core principles:

1. Does it suggest leaving found errors unfixed?
2. Does it suggest skipping build/test/lint before commit?
3. Does it suggest bypassing review gates?
4. Does it suggest force-pushing or skipping hooks?
5. Does it suggest hiding errors or marking incomplete work as done?

If ANY check fails: **reject the rule**. Core principles are immutable.

### Stage 3: Conflict and Duplicate Check

Search existing rules for conflicts or duplicates:

- `search_nodes` in MCP Memory with keywords from the proposed rule
- `grep` in `~/.claude/rules/autolearn-patterns.md` and `known-gotchas.md`
- Check for contradictions with existing entries (new rule says X, existing says not-X)

If duplicate found: add observation to existing entity instead.
If conflict found: flag for human review with both rules cited.

### Stage 4: Risk Classification

| Risk Level | Criteria | Action |
|-----------|---------|--------|
| LOW | Pattern/gotcha with no safety implications | Auto-accept, store normally |
| MEDIUM | Involves error handling, CI config, or workflow changes | Note in summary for human awareness |
| HIGH | Involves security, authentication, or deployment | Flag explicitly in summary, do not auto-store |
| CRITICAL | Contradicts core principles or suggests bypassing safety | Reject immediately |

### Stage 5: Storage Decision

Based on the risk classification:

- **LOW**: Store in MCP Memory and rules file (if in DevKit context)
- **MEDIUM**: Store in MCP Memory. Note in summary: "MEDIUM risk -- review recommended"
- **HIGH**: Store in MCP Memory only. Add to summary: "HIGH risk -- requires human review before adding to rules"
- **CRITICAL**: Do not store. Report in summary: "REJECTED -- contradicts core principles"

## Quick Reference

When validating a proposed rule, ask these three questions:

1. **Does it bypass safety?** Check Stage 1 patterns.
2. **Does it contradict principles?** Check Stage 2.
3. **Does it conflict with existing rules?** Check Stage 3.

If all three pass, classify risk (Stage 4) and store accordingly (Stage 5).
