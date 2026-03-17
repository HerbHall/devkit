# Samverk Dispatch: Planning Mode

Decompose complex work into well-structured, agent-ready issues suitable for automated dispatch.

## Prerequisites

- Samverk MCP tools must be available (check tools list before proceeding)
- Determine the planning target: a specific area/feature, or `status:needs-human` issues from the queue

## Steps

1. **Set project context**

   Call `set_project` with the current project name (read from `.samverk/project.yaml` or ask user).

2. **Identify work to plan**

   Either:

   - The user specifies an area, feature, or epic to decompose
   - Request planning tickets from the queue:

     ```text
     request_work(labels=["status:needs-human"])
     ```

   If working on a queued planning ticket, claim it first:

   ```text
   claim_issue(number)
   ```

3. **Research the area**

   - Read relevant source files and existing issues
   - Search Synapset for related patterns:

     ```text
     search_memory(pool: "devkit", query: "<area being planned>")
     ```

   - Check for existing issues that overlap (avoid duplicates):

     ```text
     list_issues(state="open", labels=["status:queued"])
     ```

4. **Heartbeat** -- if working on a claimed planning ticket, call `heartbeat_issue(number)`.

5. **Decompose into agent-ready issues**

   Each issue must be self-contained and completable by an autonomous agent. Structure each issue with:

   ```markdown
   ## Context

   Brief description of the problem or feature.

   ## Acceptance Criteria

   - [ ] Specific, testable criterion 1
   - [ ] Specific, testable criterion 2
   - [ ] All CI checks pass (build, test, lint)

   ## Implementation Hints

   - Key files: `path/to/file.go`, `path/to/other.ts`
   - Related patterns: SYN#<id> (if found in Synapset)
   - Dependencies: Requires #N to be merged first (if any)

   ## Labels

   - `agent:background` (can be processed without human input)
   - `priority:<level>` (high/medium/low)
   - `scope:<module>` (which part of the codebase)
   ```

   Guidelines for good decomposition:

   - Each issue should take one agent session (not more)
   - Avoid issues that modify the same files (prevents merge conflicts)
   - Order dependencies explicitly: "Requires #N merged first"
   - Include enough context that an agent does not need to ask questions
   - Label appropriately: `agent:background` for automatable, `agent:human` for decisions needed

6. **Heartbeat** -- call `heartbeat_issue(number)` if working on a claimed ticket.

7. **File the issues**

   For each decomposed issue:

   ```text
   create_issue(title, body, labels)
   ```

   Use conventional prefixes in titles: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`.

8. **Cross-project references**

   If the decomposition reveals work needed in another project:

   - File the issue in the correct project repo (use `gh issue create -R OWNER/REPO`)
   - Add a cross-reference comment on the parent issue linking to the new issue
   - Do NOT modify code in other projects from this context

9. **Complete the planning ticket**

   If working on a claimed planning ticket:

   ```text
   complete_issue(number, pr_number=null, summary="Decomposed into issues #A, #B, #C, #D")
   ```

   If this was user-directed planning (no ticket claimed), report the list of created issues to the user.

## Output Format

After filing all issues, display a summary:

```text
Planning Summary
  Source:  #N (or "user request: <area>")
  Created: N issues
    - #A: feat: <title> [agent:background, priority:high]
    - #B: feat: <title> [agent:background, priority:medium]
    - #C: refactor: <title> [agent:background, priority:low]
    - #D: docs: <title> [agent:human, priority:low]
  Dependencies:
    - #B depends on #A
  Cross-project:
    - Filed OWNER/other-repo#X for <reason>
```

## Error Recovery

### Duplicate detection

If `list_issues` shows an existing open issue that overlaps with a planned issue:

1. Do not create a duplicate
2. Note the overlap in the summary
3. If the existing issue needs updating, use `add_comment` to add context

### Planning ticket claim lost

If `heartbeat_issue` fails during planning:

1. Continue filing the remaining issues (they are valuable regardless of claim status)
2. Add a comment to the planning ticket listing what was created
3. Report the claim loss to the user
