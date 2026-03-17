# Samverk Checkout: Status

Check the status of a claimed issue and send a heartbeat to keep the claim alive.

## Prerequisites

- Samverk MCP tools must be available
- User must provide an issue number (or confirm the currently claimed issue)

## Steps

### 1. Determine worker ID

Use the same `WORKER_ID` from the checkout step in this session (`interactive:<hostname>`). If the session started fresh, generate it:

```bash
hostname
```

Set `WORKER_ID` to `interactive:<hostname>`.

### 2. Send heartbeat

```text
heartbeat_issue(number: <N>, worker_id: "<WORKER_ID>")
```

The response includes:

- **Claim duration** -- how long the issue has been claimed
- **Status** -- current claim status

### 3. Read issue state

```text
get_issue(number: <N>)
```

Check current labels and status for any changes since checkout.

### 4. Report to user

Display:

- Issue #N: `<title>`
- Claim status: active / not claimed
- Claim duration: `<duration>`
- Current labels: `<labels>`

**If "not claimed" error on heartbeat:** The claim was lost (server restart or another worker). Report: "Issue #N is not currently claimed by `<WORKER_ID>`. The server may have restarted. Use `/samverk-checkout checkout` to re-claim it."
