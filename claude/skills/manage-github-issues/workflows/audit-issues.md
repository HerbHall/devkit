<required_reading>
**Read these reference files NOW:**

1. references/label-conventions.md
2. references/issue-quality-standards.md
</required_reading>

<process>

**Step 1: Discover Project Context**

Check for project configuration:

1. Look for `.claude/github-issues-config.md` in the project root. If it exists, read it for:
   - Phase/milestone definitions and expected labels
   - Module/area labels
   - Roadmap file path
   - Label naming conventions

2. If no config file exists:
   - Run `gh label list --json name,description,color --limit 200` to discover existing labels
   - Read the project's CLAUDE.md for structure hints
   - Ask the user about their labeling and milestone conventions

**Step 2: Determine Scope**

Ask the user what to audit using AskUserQuestion:

<audit_options>

- **All open issues** - Full audit across all phases/milestones
- **Specific phase/milestone** - Audit issues for one phase or milestone only
- **Recent issues** - Audit issues created in the last 30 days
</audit_options>

**Step 3: Fetch Issues**

Based on scope, run the appropriate `gh` command:

For all open issues:

```bash
gh issue list --state open --limit 500 --json number,title,state,labels,milestone,createdAt,updatedAt,body,assignees
```

For a specific phase/milestone:

```bash
gh issue list --state open --label "{PHASE_LABEL}" --limit 200 --json number,title,state,labels,milestone,createdAt,updatedAt,body,assignees
```

**Step 4: Read Current Roadmap (if available)**

If the project has a roadmap file (from config or user), read it to understand which phase/milestone is current and what items should be tracked.

If no roadmap exists, skip this step and focus on issue quality checks only.

**Step 5: Run Audit Checks**

Analyze each issue against these checks:

<audit_checks>

**Labeling Completeness**

- [ ] Has at least one type label (feature, bug, enhancement, etc.)
- [ ] Has at least one phase/milestone label (if the project uses them)
- [ ] Has at least one area/module label (if the project uses them)
- [ ] Has a priority label (P0-P3) -- recommended for all active work

**Milestone Assignment**

- [ ] Has a milestone assigned (if the project uses milestones)
- [ ] Milestone is consistent with phase/milestone label

**Issue Quality**

- [ ] Title starts with an action verb
- [ ] Title is under 80 characters
- [ ] Body contains "Acceptance Criteria" section (or equivalent)
- [ ] Body contains at least one checkbox (`- [ ]`)
- [ ] Body references a planning/requirements doc (if the project has them)

**Staleness**

- [ ] Updated within the last 30 days (if open)
- [ ] Not blocked without explanation (has `blocked` label with comment)

**Duplicates**

- [ ] No other open issue has a substantially similar title
- [ ] Check for issues that could be merged

**Roadmap Coverage** (only if roadmap exists)

- [ ] Each outstanding roadmap item for the current phase has a matching issue
- [ ] No orphan issues exist that don't map to any roadmap item

</audit_checks>

**Step 6: Generate Audit Report**

Present findings organized by severity:

```text
## Issue Audit Report

### Issues Needing Attention (N issues)

**Missing Labels:**
- #12 "Add topology view" -- missing priority label, missing area label
- #15 "Fix login redirect" -- missing phase label

**Missing Milestone:**
- #18 "Implement rate limiting" -- no milestone assigned

**Quality Issues:**
- #20 "Dashboard stuff" -- vague title, no acceptance criteria
- #25 "Auth improvements" -- no requirements reference

**Stale Issues (no update in 30+ days):**
- #8 "Add WebSocket support" -- last updated 45 days ago

**Potential Duplicates:**
- #14 "Add device filtering" and #22 "Filter devices on list page"

### Roadmap Gaps (M items not tracked)
- "E2E browser tests" -- no matching issue
- "OpenAPI spec generation" -- no matching issue

### Summary
- Total open issues: X
- Issues with complete labeling: Y (Z%)
- Issues with acceptance criteria: Y (Z%)
- Stale issues: N
- Potential duplicates: N pairs
- Roadmap items without issues: M
```

**Step 7: Offer Fixes**

Ask the user which fixes to apply:

<fix_options>

1. **Add missing labels** - Apply suggested labels to under-labeled issues
2. **Assign milestones** - Set milestones based on phase labels
3. **Flag stale issues** - Add comment asking for status update
4. **Close duplicates** - Close one of each duplicate pair with cross-reference
5. **Create missing issues** - Generate issues for roadmap gaps (routes to generate-phase-issues workflow)
6. **Skip fixes** - Just report, don't change anything
</fix_options>

**Step 8: Apply Fixes**

For each approved fix, use the appropriate `gh` command:

Add labels:

```bash
gh issue edit {NUMBER} --add-label "{LABELS}"
```

Set milestone:

```bash
gh issue edit {NUMBER} --milestone "{MILESTONE}"
```

Flag stale:

```bash
gh issue comment {NUMBER} --body "This issue has had no activity for 30+ days. Is it still relevant? Please update with current status or close if no longer needed."
```

Close duplicate:

```bash
gh issue close {NUMBER} --comment "Closing as duplicate of #{OTHER}. See #{OTHER} for continued tracking."
```

**Step 9: Report Results**

Summarize all changes made:

```text
Applied N fixes:
- Added labels to M issues
- Assigned milestones to M issues
- Flagged N stale issues for review
- Closed N duplicate issues
```

</process>

<success_criteria>
This workflow is complete when:

- [ ] Project context discovered
- [ ] Issues fetched for the target scope
- [ ] All audit checks run against each issue
- [ ] Audit report presented to user
- [ ] User selected which fixes to apply (or skipped)
- [ ] Approved fixes applied via `gh` CLI
- [ ] Summary of changes reported
</success_criteria>
