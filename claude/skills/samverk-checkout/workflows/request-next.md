# Samverk Checkout: Request Next

Request the highest-priority queued issue from the dispatcher and auto-claim it.

## Prerequisites

- Samverk MCP tools must be available

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

### 3. Request work

```text
request_work(project: "<project>", worker_id: "<WORKER_ID>")
```

Optional filters (use if the user specified preferences):

- `labels` -- filter by label (e.g., `"agent:code-gen"`)
- `priority` -- filter by priority label (e.g., `"priority:high"`)
- `complexity` -- filter by complexity label

**If work is returned:** The issue is auto-claimed. Continue to step 4.

**If no work available:** Report to user: "No queued issues match the criteria. The queue may be empty or all issues are claimed." Then stop.

### 4. Read the issue

```text
get_issue(number: <returned_number>)
```

Display a brief summary:

- Issue number, title, and labels
- Acceptance criteria (if present)
- Priority and complexity indicators

### 5. Heartbeat

```text
heartbeat_issue(number: <N>, worker_id: "<WORKER_ID>")
```

### 6. Report to user

Confirm the checkout:

"Claimed issue #N: `<title>`. Worker ID: `<WORKER_ID>`. Use `/samverk-checkout complete` when done, or `/samverk-checkout release` to return it to the queue."
