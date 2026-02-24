---
name: plan-review
description: Submit the current implementation plan for independent review by the plan-reviewer agent. Spawns the reviewer with fresh context and limited file scope — no implementation history carried over. Use before starting any significant implementation. Blocks on REVISE/REJECT until the plan is approved or the user overrides.
---

# Plan Review Skill

Submits the current plan to the `plan-reviewer` agent for independent adversarial review.
The reviewer starts with no knowledge of how the plan was developed.

## When to Use

- After completing a plan in plan mode, before switching to implementation
- After writing a feature spec, before writing any code
- Any time you want a second opinion on an approach before investing in it

## Steps

### 1. Capture the plan

Identify where the current plan lives. It will be one of:

- The active plan mode document (check system context for plan file path)
- A file the user specifies (e.g. `PLAN.md`, `docs/feature-spec.md`)
- If neither exists, ask the user to confirm the plan before proceeding

Write the plan to a temp file if it is not already a standalone file:

```bash
# Example — adapt path as needed
cat > /tmp/plan-review-$RANDOM.md << 'PLAN'
[paste plan content here]
PLAN
```

### 2. Identify scoped files

Collect only the files directly referenced by the plan — source files it proposes to create or modify. Do **not** pass the full project. Limit to 10 files maximum.

```bash
# List the files the plan references — check plan text for explicit file paths
```

### 3. Spawn the plan-reviewer with fresh context

Use the Task tool to launch the `plan-reviewer` agent. Pass:

- The plan file path
- The list of scoped source files (read-only context)
- No conversation history — the agent must start fresh

Prompt to pass to the agent:

```
Review the implementation plan at [PLAN_FILE_PATH].

Relevant source files for context (read these to understand existing code the plan builds on):
[LIST_OF_SCOPED_FILES]

Follow your review workflow exactly. Return a structured report with Summary,
Assumptions, Findings (by severity), and a Verdict of APPROVE, REVISE, or REJECT.
```

### 4. Handle the verdict

**APPROVE** — Present the findings summary to the user. Proceed to implementation.

**REVISE** — Present findings to the user. Work through each High/Medium finding and
update the plan to address them. Then repeat from Step 1. Maximum 3 rounds.

**REJECT** — Present findings to the user. The plan has Critical issues that must be
resolved before implementation. Do not proceed until either:

- The plan is revised and resubmitted, achieving APPROVE
- The user explicitly overrides with documented rationale

### 5. Record the outcome

After an APPROVE verdict, note in the session:

```
Plan review: APPROVE (round N) — [one-line summary of what was checked]
```

After a user override of REJECT:

```
Plan review: OVERRIDE by user — [reason provided]
```

### 6. Clean up

Remove any temp files created in Step 1.

```bash
rm -f /tmp/plan-review-*.md
```

## Limits

- Maximum 3 review rounds before escalating to the user for a manual decision
- If the plan-reviewer agent is unavailable, notify the user and offer to proceed with a
  manual checklist review instead
- Do not invoke this skill from within an active plan mode session — exit plan mode first
