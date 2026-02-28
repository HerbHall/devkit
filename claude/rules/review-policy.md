---
description: Independent review policy. Auto-loaded at session start. Defines when review is mandatory, scope limits for reviewers, and how to handle findings.
tier: 1
last_updated: "2026-02-24"
---

# Independent Review Policy

## Core Principle

Fresh context catches what familiarity misses.

When a session has been deeply involved in designing or implementing something, it carries accumulated assumptions, rationalizations, and context that make it difficult to see the work objectively. An independent reviewer with no prior context reads what is actually there — not what was intended.

This is not a lack of trust in the main session. It is a structural safeguard, the same reason professional engineering teams require peer review before shipping code they wrote themselves.

## Mandatory Review Triggers

Independent review is **required** (not optional) in these situations:

| Trigger | Required Review | Tool |
|---------|----------------|------|
| Before starting implementation of any feature | Plan review | `/plan-review` |
| Before any commit touching more than one file | Code review | `/code-review` |
| Before opening a PR | Code review (if not already done) | `/code-review` |
| Any change to authentication, authorization, or secrets handling | Security review | `security-analyzer` agent |

## Scope Limits for Reviewers

Reviewers must operate with **limited scope** — they receive only what is directly relevant to the task being reviewed, not the full project context.

- **Plan review**: reviewer receives the plan file + files directly referenced by the plan
- **Code review**: reviewer receives changed files (`git diff`) + their direct dependencies
- **Security review**: reviewer receives changed files only

Passing the full codebase to a reviewer defeats the purpose — it reintroduces the same context the independent review is meant to avoid, and increases noise.

## Severity Escalation

| Severity | Plan Review | Code Review |
|----------|------------|-------------|
| **Critical** | Block — do not proceed to implementation | Block — do not commit |
| **High** | REVISE verdict — address before implementation | REQUEST_CHANGES — address before commit |
| **Medium** | REVISE if 3+ findings; otherwise proceed with awareness | User decides |
| **Low / Info** | Note for awareness; do not block | Note for awareness; do not block |

Critical and High findings must be resolved, not dismissed. If you believe a finding is wrong, address it in the plan or code — do not simply override the reviewer's verdict.

## Fresh Context Requirement

Where possible, review agents should be spawned with fresh context (no prior conversation history). This is handled automatically by the `/plan-review` and `/code-review` skills.

If you invoke a review agent manually from within an active implementation session, acknowledge that the reviewer is not fully independent — the shared context may limit its ability to challenge your assumptions.

## Exceptions

The following changes may bypass code review with explicit acknowledgement in the commit message:

- Typo or comment fixes only (no logic changes)
- Version bumps in a single file
- Documentation-only changes (`.md` files, no config or code)

Use `chore(no-review): <reason>` as the commit type to flag an intentional bypass. Do not use this exception for logic changes, even small ones.

## Reference

- Plan review gate: `/plan-review` skill
- Code review gate: `/code-review` skill
- Review agents: `claude/agents/plan-reviewer.md`, `claude/agents/review-code.md`, `claude/agents/security-analyzer.md`
- Phase gates in methodology: `METHODOLOGY.md`
