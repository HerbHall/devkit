# Samverk Checkout: Release Issue

Return a claimed issue to the queue so another worker can pick it up.

## Prerequisites

- Samverk MCP tools must be available
- User must provide the issue number and a reason for releasing

## Steps

### 1. Determine worker ID

Use the same `WORKER_ID` from the checkout step in this session (`interactive:<hostname>`). If the session started fresh, generate it:

```bash
hostname
```

Set `WORKER_ID` to `interactive:<hostname>`.

### 2. Gather release details

Ask the user (or infer from context) for:

- **Issue number** (required)
- **Reason** (required -- why the issue is being returned to the queue)

Good reasons include:

- "Blocked on dependency #M"
- "Out of scope for current session"
- "Needs human decision on architecture"
- "Partial implementation on branch `feature/issue-N-desc` -- remaining: <what's left>"

### 3. Release the issue

```text
release_issue(number: <N>, reason: "<reason>", worker_id: "<WORKER_ID>")
```

**If success:** Continue to step 4.

**If "not claimed" error:** The claim was already lost (server restart or expiry). Report to user: "Issue #N was not claimed -- the server may have restarted. No action needed; the issue is already in the queue."

### 4. Confirm to user

"Issue #N released back to the queue. Reason: `<reason>`. Status transitioned to `queued`."

If partial work exists on a branch, remind the user: "Partial work is on branch `<branch>`. The next worker will see the release reason in the issue comments."
