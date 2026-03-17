# Samverk Checkout: Claim Issue

Claim a specific issue by number with proper worker identity tracking.

## Prerequisites

- Samverk MCP tools must be available
- User must provide an issue number (or ask for one)

## Steps

### 1. Generate worker ID

Determine the hostname for the worker ID:

```bash
hostname
```

Set `WORKER_ID` to `interactive:<hostname>` (e.g., `interactive:HERB-DESKTOP`). Use this value for ALL subsequent MCP calls in this session.

### 2. Set project context

Read `.samverk/project.yaml` to get the project name, then:

```text
set_project(project)
```

### 3. Claim the issue

```text
claim_issue(number: <N>, worker_id: "<WORKER_ID>")
```

**If claim succeeds:** Continue to step 4.

**If claim fails (already claimed):** Report to user: "Issue #N is already claimed by another worker. Try a different issue or use **request next** to get the next available." Then stop.

### 4. Read the issue

```text
get_issue(number: <N>)
```

Display a brief summary to the user:

- Title and labels
- Acceptance criteria (if present)
- Referenced files or dependencies

### 5. Heartbeat

```text
heartbeat_issue(number: <N>, worker_id: "<WORKER_ID>")
```

### 6. Report to user

Confirm the checkout:

"Issue #N claimed as `<WORKER_ID>`. Ready to work. Use `/samverk-checkout complete` when done, or `/samverk-checkout release` to return it to the queue."

Remind the user to call `heartbeat_issue` periodically during long sessions (every 15 minutes or after major milestones).

## Error Recovery

### "Not claimed" on heartbeat after claim succeeded

The MCP server may have restarted between claim and heartbeat. Re-claim:

```text
claim_issue(number: <N>, worker_id: "<WORKER_ID>")
heartbeat_issue(number: <N>, worker_id: "<WORKER_ID>")
```

If re-claim also fails, report to user and stop.
