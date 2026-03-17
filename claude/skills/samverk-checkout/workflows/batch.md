# Samverk Checkout: Batch Mode

Process multiple issues from the queue sequentially. Claims one at a time, completes or releases each before claiming the next.

## Prerequisites

- Samverk MCP tools must be available
- User should specify how many issues to process (default: 3)

## Steps

### 1. Generate worker ID

```bash
hostname
```

Set `WORKER_ID` to `interactive:<hostname>`. Use for ALL calls in this batch.

### 2. Set project context

Read `.samverk/project.yaml` to get the project name, then:

```text
set_project(project)
```

### 3. Confirm batch parameters

Ask the user (or use defaults):

- **Count** -- how many issues to process (default: 3, max: 10)
- **Filters** -- optional label, priority, or complexity filters

### 4. Process loop

For each issue in the batch:

#### 4a. Request next issue

```text
request_work(project: "<project>", worker_id: "<WORKER_ID>")
```

If no work available, report "Queue empty after N of M issues processed" and stop.

#### 4b. Read and assess

```text
get_issue(number: <N>)
```

Display the issue title and labels. Assess whether it can be completed in this session.

If the issue is too complex or blocked, release immediately:

```text
release_issue(number: <N>, reason: "Skipped in batch: <reason>", worker_id: "<WORKER_ID>")
```

Then continue to the next iteration (4a).

#### 4c. Heartbeat

```text
heartbeat_issue(number: <N>, worker_id: "<WORKER_ID>")
```

#### 4d. Implement

Follow the standard implementation workflow (explore, code, test, lint). Call `heartbeat_issue` after each major step.

#### 4e. Push and create PR

```bash
git push -u origin feature/issue-N-description
gh pr create --title "feat: <description>" --body "Closes #N"
```

#### 4f. Complete

```text
complete_issue(number: <N>, pr_number: <PR>, summary: "<summary>", worker_id: "<WORKER_ID>")
```

#### 4g. Report progress

"Completed issue #N (M of total). Moving to next issue."

### 5. Batch summary

After all issues are processed (or the queue is empty), report:

- Issues completed: list with PR numbers
- Issues skipped/released: list with reasons
- Issues remaining in queue (if known)

## Error Recovery

### "Not claimed" during batch

Re-claim the current issue and retry. If re-claim fails, skip to the next issue:

```text
claim_issue(number: <N>, worker_id: "<WORKER_ID>")
```

### Implementation failure mid-batch

Release the current issue with details of what was done, then continue to the next:

```text
release_issue(number: <N>, reason: "Failed during batch: <error details>", worker_id: "<WORKER_ID>")
```

Do not abort the entire batch for a single issue failure.
