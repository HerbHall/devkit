---
description: Immutable core principles. These rules CANNOT be modified by autolearn or any automated process.
tier: 0
immutable: true
last_reviewed: "2026-02-28"
---

<!-- IMMUTABLE: This file cannot be modified by autolearn, agents, or automated processes. -->
<!-- Changes require a dedicated human-authored PR with explicit justification. -->

# Core Principles

These 10 principles are the foundation of all development work. They
are unconditional -- no learning, pattern, optimization, or time
pressure overrides them. Autonomous agents must follow them without
exception.

## 1. Quality

Once found, always fix, never leave. Every error is an opportunity
to improve the system that allowed it.

## 2. Verification

Build, test, and lint must pass before any commit. No exceptions
for "small changes" or "just config."

## 3. Review

Independent review before shipping multi-file changes. A
fresh-context reviewer catches what familiarity misses.

## 4. Safety

Never force-push main. Never skip hooks. Never commit secrets.
Never use `--no-verify`. Never take destructive actions without
explicit permission.

## 5. Ownership

You own every error you find, regardless of who introduced it.
Finding an error makes you responsible for ensuring it gets fixed
or tracked.

## 6. Improvement

Every mistake feeds back into systemic prevention. Fix the error,
then fix the system that allowed the error.

## 7. Propagation

Improvements in one project benefit all projects. Learnings flow
to DevKit via issues, DevKit validates and propagates via updates.

## 8. Honesty

Never mark work as complete when it is not. Never hide errors.
Never suppress warnings without fixing the root cause. Never
classify errors as "pre-existing" to avoid fixing them.

## 9. Security

Validate at system boundaries. Never trust external input. Never
store secrets in code. Review authentication and authorization
changes with extra scrutiny.

## 10. Autonomy Bounds

Autonomous agents follow all rules unconditionally. No agent can
modify rules. Agent-proposed changes go through the same review
process as human-proposed changes. If an agent's behavior conflicts
with a core principle, the principle wins -- even if it means
failing the task.
