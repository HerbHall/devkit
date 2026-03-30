---
name: pipeline-evaluation
description: Regular Samverk dispatcher pipeline health audit. Evaluates queue depth, idle workers, MCP tool availability, stale in-progress issues, and auto-merge backlog. Produces a structured PASS/WARN/FAIL report with remediation steps.
user_invocable: true
---

# Pipeline Evaluation

Dispatcher pipeline health audit for Samverk. Evaluates queue depth, worker status,
MCP tool availability, stale in-progress items, and auto-merge gaps.

<essential_principles>

**Purpose**: Catch pipeline degradation early — stuck agents, missed auto-merges,
and MCP tool outages — before they accumulate into a blocked queue.

**When to use**: Run periodically (weekly or after any sprint) or when the dispatcher
seems slow, workers appear idle, or auto-merge is not firing.

**Thresholds**:

- Stale in-progress: issues open in `in-progress` status for more than 48 hours
- Auto-merge gap: PRs with green CI that have been open longer than 2 hours

**Tools required**:

- Samverk MCP: `list_issues`, `list_workers`, `list_open_prs`
- Synapset MCP: `pool_stats` (optional — skip if unavailable)

</essential_principles>

<intake>

**pipeline-evaluation triggered.** Running pipeline health audit now.

This skill runs immediately with no options required. Output format:

```text
Pipeline Health -- YYYY-MM-DD HH:MM

Queue depth:       N queued | N in-progress | N blocked | N needs-human | N needs-qc
Idle workers:      N (list names or "all active")
MCP tools:         Samverk OK/FAIL | Synapset OK/FAIL
Stale in-progress: N items over 48h threshold
Auto-merge gap:    N PRs with green CI open >2h

Overall: PASS / WARN / FAIL -- reason
```

Type **skip** to cancel without running the audit.

</intake>

<routing>

| Response | Workflow |
|----------|----------|
| Any non-skip input, no input (auto-run), "run", "go", "evaluate", "health check" | workflows/run-evaluation.md |
| "skip", "dismiss", "cancel" | Cancel — confirm cancellation and end |

If the user types **skip** or **dismiss**, briefly confirm (e.g.,
"pipeline-evaluation cancelled.") and end without running the workflow.

**After reading the workflow, follow it exactly.**

</routing>

<evaluation_steps>

## Step 1 — Queue Depth

Use Samverk MCP `list_issues` to count issues by status label:

- `status:queued` — ready to dispatch
- `status:in-progress` — actively being worked
- `status:blocked` — waiting on dependency or decision
- `status:needs-human` — requires human interaction
- `status:needs-qc` — implementation done, awaiting verification

Report counts for each bucket. WARN if in-progress >= 5 without corresponding
open PRs (possible stuck agents).

## Step 2 — Idle Workers

Use Samverk MCP `list_workers` to list all registered workers.

A worker is idle if it has no corresponding `status:in-progress` issue assigned to it.
Report the count and names of idle workers. WARN if all workers are idle while the
queue has items.

## Step 3 — MCP Tool Availability

Test each MCP tool with a lightweight call:

- Samverk: `list_issues` with `limit=1` — OK if response arrives
- Synapset: `pool_stats` — OK if response arrives (skip if tool not available)

Report OK or FAIL for each. FAIL on any tool outage.

## Step 4 — Stale In-Progress

From the issues retrieved in Step 1, filter `status:in-progress` items.
Compare `updated_at` against the current time. Flag any issue not updated
in the last 48 hours as stale.

Report stale issue numbers and titles. WARN if any stale items exist.

## Step 5 — Auto-merge Backlog

Use Samverk MCP `list_open_prs` to list open pull requests.

For each PR, check:

- Has green CI (all checks passed)
- Has been open longer than 2 hours

Flag any such PRs — they likely have a missed auto-merge trigger.
Report PR numbers and titles. WARN if any such PRs exist.

## Step 6 — Overall Verdict

Aggregate all findings into a single verdict:

| Verdict | Criteria |
|---------|----------|
| PASS | No warnings or failures across all steps |
| WARN | At least one threshold exceeded but no tool outages or critical failures |
| FAIL | MCP tool outage, all workers idle with non-empty queue, or 3+ stale in-progress items |

</evaluation_steps>

<remediation>

## Remediation by Finding

| Finding | Action |
|---------|--------|
| Queue depth high (>10 queued) | Use Samverk MCP `request_work` to dispatch more agents |
| All workers idle with queue > 0 | Check worker health via `list_workers`; re-queue blocked items |
| Samverk MCP FAIL | Check Samverk service health; restart if needed |
| Synapset MCP FAIL | Check `https://synapset.herbhall.net/mcp` availability |
| Stale in-progress (>48h) | Investigate stuck agents; use `release_issue` to reset if abandoned |
| Auto-merge gap (green CI, open >2h) | Manually trigger merge or investigate branch protection settings |

</remediation>

<tool_restrictions>

- Samverk MCP: `list_issues`, `list_workers`, `list_open_prs`, `request_work`, `release_issue`
- Synapset MCP: `pool_stats` (optional)
- Bash: `date` for timestamp formatting

</tool_restrictions>

<usage_recording>

After completing the evaluation, record the invocation per `claude/shared/record-usage.md`.

</usage_recording>
