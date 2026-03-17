---
name: samverk-checkout
description: Samverk MCP work checkout/checkin protocol -- claim issues with worker_id tracking, heartbeat, complete, and release using the 5 coordination MCP tools.
user_invocable: true
---

# Samverk Checkout

Lightweight protocol layer for claiming and releasing Samverk-managed issues via MCP. Handles worker identity, heartbeat, resilience to server restarts, and batch processing. Use this when you need direct control over the checkout/checkin lifecycle without the full dispatch workflow.

<essential_principles>

**Samverk MCP is required.** This skill depends on Samverk MCP tools (`claim_issue`, `request_work`, `complete_issue`, `release_issue`, `heartbeat_issue`). If these tools are not in your available tools list, cancel immediately and inform the user.

**Worker ID is session-scoped.** Generate a `worker_id` once at the start of the session and pass it explicitly to every MCP tool call. The format is `interactive:<hostname>` (e.g., `interactive:HERB-DESKTOP`). Never rely on the server default -- each call without a `worker_id` generates a new timestamp-based ID, which breaks ownership verification.

**Claims are in-memory on the MCP server.** Claims do not survive server restarts. If any tool returns a "not claimed" error, re-claim the issue before retrying the operation.

**Clean exit is mandatory.** If you cannot complete an issue, always call `release_issue` with a descriptive reason. Never leave a claim dangling.

**Heartbeat periodically.** Call `heartbeat_issue` after every major step (exploration, implementation milestone, test run). Current server has no timeout enforcement, but this future-proofs the claim and provides activity tracking.

</essential_principles>

<intake>
**samverk-checkout triggered.** What would you like to do?

1. **Checkout** -- Claim a specific issue by number
2. **Request Next** -- Get the highest-priority queued issue and claim it
3. **Complete** -- Mark a claimed issue as done (with PR link)
4. **Release** -- Return a claimed issue to the queue
5. **Batch** -- Process multiple issues from the queue sequentially
6. **Status** -- Check current claim status and send heartbeat

Type a number, keyword, or **skip** to dismiss.

> Note: This skill blocks on user input. If triggered unintentionally,
> type **skip** or **dismiss** to cancel.
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "checkout", "claim", "claim #N", "check out", "pick up" | workflows/checkout.md |
| 2, "request", "next", "request next", "request work", "queue" | workflows/request-next.md |
| 3, "complete", "done", "finish", "close", "complete #N" | workflows/complete.md |
| 4, "release", "abort", "return", "unclaim", "release #N" | workflows/release.md |
| 5, "batch", "batch mode", "process queue", "work through" | workflows/batch.md |
| 6, "status", "heartbeat", "check", "ping" | workflows/status.md |

If the user types **skip** or **dismiss**, briefly confirm cancellation (e.g., "samverk-checkout cancelled.") and end the skill without running any workflow.

If the input does not clearly match any option above and is not "skip" or "dismiss", respond:
"samverk-checkout was triggered but your input didn't match a workflow. Options: 1-6 (listed above). Type **skip** to dismiss."

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>

Samverk MCP tools (required):

- `claim_issue(number, worker_id?)` -- Claim a specific issue
- `request_work(project?, labels?, priority?, complexity?, worker_id?)` -- Get next queued issue
- `complete_issue(number, pr_number?, summary?, worker_id?)` -- Mark issue done
- `release_issue(number, reason, worker_id?)` -- Return issue to queue
- `heartbeat_issue(number, worker_id?)` -- Reset heartbeat timer
- `get_issue(number)` -- Read issue details
- `set_project(project)` -- Set active project context

Other tools used:

- Bash (git commands, hostname lookup)

</tool_restrictions>

<usage_recording>

After selecting a workflow, record the invocation per `claude/shared/record-usage.md`.

</usage_recording>
