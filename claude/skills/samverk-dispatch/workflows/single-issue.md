# Samverk Dispatch: Single Issue

Pick up a specific issue by number, implement the solution, and mark it complete.

## Prerequisites

- Samverk MCP tools must be available (check tools list before proceeding)
- If the user provided an issue number, use it. Otherwise, ask for one.

## Steps

1. **Set project context**

   Call `set_project` with the current project name (read from `.samverk/project.yaml` or ask user).

2. **Claim the issue**

   ```text
   claim_issue(number)
   ```

   If the claim fails (already claimed by another agent), report to the user:
   "Issue #N is already claimed. Use batch mode to get the next available issue, or specify a different number."
   Then stop.

3. **Read the issue**

   ```text
   get_issue(number)
   ```

   Parse the issue body for:
   - Acceptance criteria
   - Referenced files or modules
   - Labels (especially `agent:background`, `agent:human`, `status:queued`)
   - Linked issues or dependencies

4. **Heartbeat** -- call `heartbeat_issue(number)` after reading.

5. **Explore the codebase**

   Based on the issue description, search for relevant files:

   - Use Glob/Grep to find files referenced in the issue
   - Read key files to understand current implementation
   - Check for existing tests that cover the area

6. **Search Synapset for patterns**

   If Synapset MCP tools are available:

   ```text
   search_memory(pool: "devkit", query: "<5-10 word description of the task>")
   ```

   Look for gotchas, corrections, and patterns that apply. Cite relevant results as `SYN#<id>` in commit messages or PR descriptions.

7. **Heartbeat** -- call `heartbeat_issue(number)` after exploration.

8. **Implement the solution**

   Follow the standard workflow:

   - Create a feature branch: `git checkout -b feature/issue-N-description`
   - Make changes methodically
   - Run stack-appropriate CI checks (see `subagent-ci-checklist.md`):
     - Go: `go build ./...`, `go test ./...`, lint self-check
     - Frontend: `npx tsc --noEmit`, `npx eslint src/<files>`
     - Markdown: `npx markdownlint-cli2 "<paths>"`
   - Fix any issues found

9. **Heartbeat** -- call `heartbeat_issue(number)` after implementation.

10. **Push and create PR**

    ```bash
    git push -u origin feature/issue-N-description
    gh pr create --title "feat: <description>" --body "Closes #N\n\n<summary>"
    ```

    Capture the PR number from the output.

11. **Complete the issue**

    ```text
    complete_issue(number, pr_number, summary)
    ```

    The summary should be 1-3 sentences describing what was done.

## Error Recovery

### Partial failure during implementation

If an error prevents completing the work:

1. Commit any partial progress to the branch
2. Push the branch (even if incomplete)
3. Call `release_issue(number, "Partial implementation on branch feature/issue-N-desc. Remaining: <what's left>.")`
4. Report to user what was completed and what remains

### Lost claim (heartbeat failure)

If `heartbeat_issue` returns an error:

1. Stop implementation immediately
2. Report to user: "Claim on issue #N was lost (likely expired). Work so far is on branch `feature/issue-N-desc`. The issue may have been reassigned."
3. Do NOT call `complete_issue` or `release_issue` -- the claim is no longer yours

### Build/test/lint failure

If CI checks fail after implementation:

1. Diagnose and fix the failures
2. Call `heartbeat_issue(number)` (fixing takes time)
3. Re-run checks to confirm the fix
4. Continue to step 10 (push and PR)
