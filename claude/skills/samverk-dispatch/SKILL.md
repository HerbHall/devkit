---
name: samverk-dispatch
description: Participate in Samverk dispatcher work protocol -- claim issues, process queues, and decompose work into agent-ready tickets using Samverk MCP tools.
user_invocable: true
---

# Samverk Dispatch

Work protocol for Claude Code agents participating in Samverk-managed issue dispatch. Provides structured workflows for claiming issues, processing batch queues, and decomposing complex work into agent-ready tickets.

<essential_principles>

**Samverk MCP is required.** This skill depends on Samverk MCP tools (`claim_issue`, `request_work`, `complete_issue`, `release_issue`, `heartbeat_issue`). If Samverk MCP tools are not in your available tools list, cancel immediately and inform the user.

**Heartbeat keeps claims alive.** Long-running work requires periodic heartbeats. After every major step (codebase exploration, implementation milestone, test run), call `heartbeat_issue(number)`. If you forget, the dispatcher may reclaim the issue and assign it to another agent.

**Cross-project awareness.** Before claiming an issue, verify you are targeting the correct project with `set_project`. If an issue references another project, file a cross-reference issue in that project rather than making changes directly.

**Clean exit on failure.** If you cannot complete an issue, always call `release_issue(number, reason)` with a descriptive reason. Never leave a claim dangling -- the dispatcher cannot reassign orphaned claims.

**Error handling priorities:**

- **Already claimed**: Another agent owns this issue. Report to user and suggest `request_work` for the next available issue.
- **Partial failure**: If implementation is incomplete when an error occurs, `release_issue` with details of what was done and what remains.
- **Lost claim**: If `heartbeat_issue` returns an error (claim expired), stop work immediately. The issue may have been reassigned. Report to user.

</essential_principles>

<intake>
**samverk-dispatch triggered.** How would you like to work?

1. **Single Issue** -- Pick up and work on a specific issue by number
2. **Batch Mode** -- Process the next N issues from the dispatch queue
3. **Planning Mode** -- Decompose work into well-structured agent-ready issues

Type a number, keyword, or **skip** to dismiss.

> Note: This skill blocks on user input. If triggered unintentionally,
> type **skip** or **dismiss** to cancel.
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "single issue", "pick up issue", "work on #N", "claim #N" | workflows/single-issue.md |
| 2, "batch mode", "pick up next", "work through queue", "process queue" | workflows/batch-mode.md |
| 3, "planning mode", "plan work", "decompose", "agent-ready issues" | workflows/planning-mode.md |

If the user types **skip** or **dismiss**, briefly confirm cancellation (e.g., "samverk-dispatch cancelled.") and end the skill without running any workflow.

If the input does not clearly match any option above and is not "skip" or "dismiss", respond:
"samverk-dispatch was triggered but your input didn't match a workflow. Options: 1-3 (listed above). Type **skip** to dismiss."

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>

Samverk MCP tools (required):

- `claim_issue(number)` -- Claim an issue for work
- `request_work(project?, priority?)` -- Get highest priority issue from queue
- `complete_issue(number, pr_number, summary)` -- Mark work done
- `release_issue(number, reason)` -- Release a claim
- `heartbeat_issue(number)` -- Keep claim alive during long sessions
- `set_project(project)` -- Set active project context
- `create_issue(title, body, labels?)` -- File new issues (planning mode)
- `get_issue(number)` -- Read issue details
- `list_issues(state?, labels?)` -- List issues with filters

Other tools used:

- Bash (git commands, build/test/lint)
- Read, Edit, Write (codebase changes)
- Glob, Grep (codebase exploration)
- Synapset MCP (pattern lookup before implementation)

</tool_restrictions>

<usage_recording>

After selecting a workflow, record the invocation per `claude/shared/record-usage.md`.

</usage_recording>
