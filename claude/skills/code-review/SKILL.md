---
name: code-review
description: Submit changed files for independent review by the review-code agent before committing. Spawns the reviewer with fresh context and scoped to only the changed files and their direct dependencies. Critical/High findings block the commit. Use after implementing a feature, before any git commit touching more than one file.
---

# Code Review Skill

Submits changed files to the `review-code` agent for independent review before committing.
The reviewer starts with no knowledge of how the code was written.

## When to Use

- After implementing a feature, before `git commit`
- Before opening a PR
- Any time you want an independent assessment of code changes

## Steps

### 1. Identify changed files

```bash
git diff --name-only HEAD
git diff --name-only --cached
```

If there are no changed files, notify the user and stop.

For trivial-only changes (comments, docs, version bumps), confirm with the user whether
to proceed or use the `chore(no-review):` exception from `review-policy.md`.

### 2. Scope the review

Collect the changed files plus their direct dependencies (files they import or that import
them). Do **not** pass the full project. Limit to 15 files maximum.

```bash
# List changed files
git diff --name-only HEAD
git diff --name-only --cached
# Add direct dependencies manually based on imports
```

### 3. Spawn the review-code agent with fresh context

Use the Task tool to launch the `review-code` agent. Pass:

- The list of changed files
- Direct dependency files for context
- The git diff for precise change visibility
- No conversation history — the agent must start fresh

Prompt to pass to the agent:

```
Review the following changed files before they are committed.

Changed files:
[LIST_OF_CHANGED_FILES]

Context files (direct dependencies — read for understanding, not for review):
[LIST_OF_CONTEXT_FILES]

Git diff for reference:
[OUTPUT OF: git diff HEAD && git diff --cached]

Follow your review workflow exactly. Return a structured report with Summary,
Findings (by severity and file:line), and a Verdict of APPROVE, REQUEST_CHANGES,
or NEEDS_DISCUSSION.
```

### 4. Handle the verdict

**APPROVE** — Present the findings summary. Proceed to commit.

**REQUEST_CHANGES (Critical or High findings)** — Block the commit. Present findings
to the user. Address each Critical/High finding, then repeat from Step 1.
Maximum 3 rounds.

**REQUEST_CHANGES (Medium/Low findings only)** — Present findings to the user.
User decides whether to address before committing or note them as known issues.

**NEEDS_DISCUSSION** — Present findings to the user. Do not commit until the user
has reviewed and made an explicit decision on each flagged item.

### 5. Security escalation

If the `review-code` agent returns any Security category findings at Critical or High
severity, additionally spawn the `security-analyzer` agent on the affected files
for a deeper security pass before allowing the commit to proceed.

### 6. Record the outcome

After an APPROVE verdict, note in the session:

```
Code review: APPROVE (round N) — [files reviewed, one-line summary]
```

After addressing REQUEST_CHANGES:

```
Code review: APPROVE after revision (round N) — [findings addressed]
```

### 7. Proceed to commit

Once approved, use the standard commit format from `workflow-preferences.md`:

```bash
git add [specific files — never git add -A]
git commit -m "feat/fix/refactor: description

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

## Limits

- Maximum 3 review rounds before escalating to the user for a manual decision
- Critical/High security findings always escalate to `security-analyzer` — this cannot
  be bypassed
- If the review-code agent is unavailable, notify the user — do not silently skip review
- Trivial commits (typo, comment, version bump only) may bypass with
  `chore(no-review): <reason>` commit type per `review-policy.md`
