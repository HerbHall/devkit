# Samverk Checkout: Complete Issue

Mark a claimed issue as done, transitioning it to `status:needs-qc`.

## Prerequisites

- Samverk MCP tools must be available
- User must provide the issue number (or confirm the currently claimed issue)
- A PR number is recommended but optional

## Steps

### 1. Determine worker ID

Use the same `WORKER_ID` from the checkout step in this session (`interactive:<hostname>`). If the session started fresh (no prior checkout), generate it:

```bash
hostname
```

Set `WORKER_ID` to `interactive:<hostname>`.

### 2. Gather completion details

Ask the user (or infer from context) for:

- **Issue number** (required)
- **PR number** (optional -- pass if a PR was created)
- **Summary** (optional -- 1-3 sentences describing what was done)

### 3. Complete the issue

```text
complete_issue(number: <N>, pr_number: <PR>, summary: "<summary>", worker_id: "<WORKER_ID>")
```

**If success:** Continue to step 4.

**If "not claimed" error:** The server may have restarted. Re-claim and retry:

```text
claim_issue(number: <N>, worker_id: "<WORKER_ID>")
complete_issue(number: <N>, pr_number: <PR>, summary: "<summary>", worker_id: "<WORKER_ID>")
```

If re-claim fails (another worker claimed it), report to user and stop.

### 4. Confirm to user

"Issue #N marked complete. Status transitioned to `needs-qc`."

If a PR was linked: "PR #P associated with the completion."
