# Agent Team Coordination Rules

## When to Use Agent Teams

**Use teams for:**
- Parallel code review (security + performance + tests)
- Research with competing hypotheses
- Feature development (frontend + backend + tests simultaneously)
- Large refactoring across multiple modules
- Cross-layer changes (API + DB + UI)

**Don't use teams for:**
- Simple single-file edits
- Sequential dependent work (step B needs step A's output)
- Tasks under 5 tool calls
- Same-file modifications (conflict risk)

## Six Core Rules

### 1. Shared Files First
Before spawning ANY teammates, create these in the project root:
- `team_plan.md` — Goal, phases, ownership, status
- `team_findings.md` — All discoveries logged here
- `team_progress.md` — Activity and session tracking

### 2. Re-Read Before Decide
After many tool calls, context drifts. Each teammate must re-read `team_plan.md` before making major decisions to realign with the objective.

### 3. Write Findings Immediately
After ANY discovery (code found, error hit, decision made), edit `team_findings.md` immediately. Don't wait. Context is volatile. Disk is persistent.

### 4. The 2-Action Rule (Per Teammate)
After every 2 view/browser/search operations, IMMEDIATELY save findings to `team_findings.md`. Applies to each teammate individually.

### 5. No Duplicate Work
Before starting work, teammates check `team_findings.md` — has someone already found this?

### 6. Message on Phase Complete
When a teammate finishes their phase, message lead:
"Phase X complete. Key findings in team_findings.md section Y. Ready for next phase or need review."

## The 3-Strike Error Protocol

```
STRIKE 1: Teammate diagnoses & fixes
  → Log error to team_findings.md
  → Try alternative approach

STRIKE 2: Teammate tries different method
  → Update team_findings.md with attempt
  → If still failing, message lead

STRIKE 3: Escalate to lead
  → Lead reviews team_findings.md
  → Lead may reassign or intervene

AFTER 3 STRIKES: Lead escalates to user
  → Explain all attempts made
  → Share specific blockers
  → Ask for guidance
```

## File Ownership

Assign clear ownership to prevent merge conflicts:

| Teammate | Owned Files |
|----------|-------------|
| Lead | team_plan.md, team_progress.md |
| Agent-1 | Files in their assigned scope |
| Agent-2 | Files in their assigned scope |

Rule: Only the owner edits their files. Others read only.

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Let teammates work in isolation | Require shared file updates |
| Give vague teammate instructions | Assign specific phases with clear deliverables |
| Skip the planning phase | Always create team_plan.md first |
| Have teammates edit same files | Assign file ownership |
| Run many teammates for simple tasks | Use single agent for small work |
| Forget to clean up team | Always cleanup when done |

## Competing Hypothesis Pattern

For debugging or research tasks:
1. Spawn 2-3 investigators with different theories
2. Each documents evidence FOR and AGAINST their hypothesis in team_findings.md
3. Lead reviews and converges through elimination
4. Surviving hypothesis gets implementation phase

## Token Economics

Agent Teams are expensive. Track approximate usage:
- Each teammate consumes tokens independently
- Haiku teammates for research/reading tasks
- Sonnet teammates for implementation/complex reasoning
- Minimize teammate count — 2-3 is usually optimal
