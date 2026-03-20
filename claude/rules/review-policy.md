---
description: Review and merge policy. Auto-loaded at session start. Defines when review is mandatory, how PRs are merged, and protections against policy regression.
tier: 1
last_updated: "2026-03-09"
---

# Review and Merge Policy

## PR Merge Model: CI Gate + Copilot Informational Review

All projects use a single combined GitHub ruleset ("Copilot PR Review") that
configures:

- **No required approving reviews** (`required_approving_review_count: 0`)
- **Copilot auto-review on push** (informational comments, not a merge gate)
- **Squash-only merges**
- **Admin bypass** for the repo owner (RepositoryRole id 5)

Copilot cannot approve PRs by design -- it can only leave comments.
Setting `required_approving_review_count` to 1 creates a gate that
can never be satisfied without `--admin`, which defeats automation.
The pipeline is:

1. Agent creates branch, implements feature, pushes
2. CI runs (build, test, lint)
3. Copilot auto-reviews and leaves comments
   > **Warning:** Copilot sub-PRs (auto-generated follow-up fix PRs) target the
   > feature branch, not `main`. Before merging any Copilot sub-PR, check its base:
   > `gh pr view <number> --json baseRefName,state`
   > If `baseRefName` is not `main` and the parent PR is already merged, apply
   > the fixes manually on a new branch from `main`. See KG#103.
4. Claude Code reads Copilot comments, implements valid ones, merges
5. No waiting for Copilot re-review -- Copilot cannot approve

Human review is reserved for contributor PRs from external collaborators.

### Protected Configuration

Copilot auto-review must remain enabled. Agents must NEVER:

- Remove the `copilot_code_review` rule from a ruleset
- Disable `review_on_push`
- Raise `required_approving_review_count` above 0 (creates unsatisfiable gate)
- Add `required_pull_request_reviews` to branch protection (conflicts with rulesets)
- Disable auto-merge on any repository

`--admin` bypass is NEVER valid to skip reading Copilot feedback.
It is ONLY valid when CI infrastructure itself is broken (flaky
runner, GitHub outage, misconfigured status check).

### Ruleset Template

The standard ruleset is defined in `project-templates/copilot-ruleset.json`.
Use `scripts/copilot-review-setup.sh audit` to verify compliance.

## Pre-Commit Review (Agent-to-Agent)

Fresh context catches what familiarity misses. Before committing,
agents review their own work using specialized review agents.

### Mandatory Review Triggers

| Trigger | Required Review | Tool |
|---------|----------------|------|
| Before starting implementation of any feature | Plan review | `/plan-review` |
| Before any commit touching more than one file | Code review | `/code-review` |
| Before opening a PR | Code review (if not already done) | `/code-review` |
| Any change to authentication, authorization, or secrets handling | Security review | `security-analyzer` agent |
| Any PR adding, removing, or modifying authentication/session handling | Workflow continuity assessment | Review manually |

### Workflow Continuity Assessment (auth/session PRs)

Any PR that adds, removes, or modifies authentication or session handling MUST include a workflow continuity assessment:

1. What does a currently-authenticated user experience after this change?
2. What does a user experience after a service restart?
3. Is the login/re-login flow smooth or disruptive?

This is separate from the security review. Security asks "is this safe?" Workflow continuity asks "does this break the user experience?"

### Required PR Description Section (handlers, middleware, auth PRs)

For any PR modifying existing handlers, middleware, or authentication, the PR description MUST include an "Impact on Existing Behaviors" section:

````markdown
## Impact on Existing Behaviors
- [ ] Authenticated users: [describe what changes for logged-in users]
- [ ] API clients: [describe what changes for Bearer token callers]
- [ ] After service restart: [describe the user experience]
- [ ] N/A: [only if the change is purely additive with no effect on existing paths]
````

Advisory sections get skipped under time pressure. This is a required checklist item.

### Scope Limits for Reviewers

Reviewers must operate with **limited scope** -- they receive only
what is directly relevant to the task being reviewed, not the full
project context.

- **Plan review**: reviewer receives the plan file + files directly referenced by the plan
- **Code review**: reviewer receives changed files (`git diff`) + their direct dependencies
- **Security review**: reviewer receives changed files only

### Severity Escalation

| Severity | Plan Review | Code Review |
|----------|------------|-------------|
| **Critical** | Block -- do not proceed to implementation | Block -- do not commit |
| **High** | REVISE verdict -- address before implementation | REQUEST_CHANGES -- address before commit |
| **Medium** | REVISE if 3+ findings; otherwise proceed with awareness | Agent decides |
| **Low / Info** | Note for awareness; do not block | Note for awareness; do not block |

Critical and High findings must be resolved, not dismissed.

### Fresh Context Requirement

Review agents should be spawned with fresh context (no prior
conversation history). This is handled automatically by the
`/plan-review` and `/code-review` skills.

### Exceptions

The following changes may bypass pre-commit code review with explicit
acknowledgement in the commit message:

- Typo or comment fixes only (no logic changes)
- Version bumps in a single file
- Documentation-only changes (`.md` files, no config or code)

Use `chore(no-review): <reason>` as the commit type to flag an
intentional bypass.

## Reference

- Ruleset template: `project-templates/copilot-ruleset.json`
- Compliance audit: `scripts/copilot-review-setup.sh`
- Plan review gate: `/plan-review` skill
- Code review gate: `/code-review` skill
- Review agents: `claude/agents/plan-reviewer.md`, `claude/agents/review-code.md`, `claude/agents/security-analyzer.md`
- Phase gates in methodology: `METHODOLOGY.md`
