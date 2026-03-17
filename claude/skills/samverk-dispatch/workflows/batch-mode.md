# Samverk Dispatch: Batch Mode

Process multiple issues from the dispatch queue sequentially.

## Prerequisites

- Samverk MCP tools must be available (check tools list before proceeding)
- Ask the user how many issues to process (default: 3) and any filters (project, priority, labels)

## Steps

1. **Set project context**

   Call `set_project` with the current project name (read from `.samverk/project.yaml` or ask user).

2. **Initialize batch tracking**

   Track results for the end-of-batch summary:

   ```text
   completed = []
   failed = []
   skipped = []
   ```

3. **Request work from queue**

   ```text
   request_work(project?, priority?)
   ```

   If no work is available, report "Queue is empty for the given filters." and stop.

4. **Process via single-issue flow**

   For each issue returned by `request_work`:

   - **Claim**: `claim_issue(number)`
   - **Read**: `get_issue(number)` -- parse acceptance criteria
   - **Heartbeat**: `heartbeat_issue(number)`
   - **Explore**: Search codebase for relevant files
   - **Synapset lookup**: `search_memory(pool: "devkit", query: "<task description>")`
   - **Heartbeat**: `heartbeat_issue(number)`
   - **Implement**: Create branch, make changes, run CI checks
   - **Heartbeat**: `heartbeat_issue(number)`
   - **Push + PR**: Push branch, create PR with `Closes #N`
   - **Complete**: `complete_issue(number, pr_number, summary)`
   - Add to `completed` list

   On failure at any step:

   - If claim fails (already claimed): add to `skipped`, continue to next
   - If implementation fails: `release_issue(number, reason)`, add to `failed`, continue to next
   - If heartbeat fails (lost claim): add to `failed` with "claim lost", continue to next

5. **Request next issue**

   After completing (or failing/skipping) an issue, call `request_work` again. Repeat until:

   - The requested count is reached, OR
   - The queue is empty, OR
   - The user interrupts

6. **Report batch summary**

   Display a structured summary:

   ```text
   Batch Summary
     Processed: N issues
     Completed: N (list PR numbers)
     Failed:    N (list issue numbers + reasons)
     Skipped:   N (list issue numbers + reasons)
     Queue:     empty / N remaining
   ```

   Include each completed issue with its PR link for easy review.

## Error Recovery

### Queue returns unsuitable issues

If an issue requires human intervention (labeled `agent:human` or `status:needs-human`):

1. Skip the issue -- do not claim it
2. Add to `skipped` with reason "requires human intervention"
3. Continue to next `request_work`

### Context window pressure

Batch mode consumes significant context. If you notice degraded performance or are approaching context limits:

1. Complete or release the current issue
2. Report the partial batch summary
3. Suggest the user start a new session to continue

### Cross-project issues

If `request_work` returns an issue for a different project than expected:

1. Verify with `set_project` that the correct project is active
2. If the issue genuinely belongs to another project, skip it
3. Add to `skipped` with reason "wrong project context"
