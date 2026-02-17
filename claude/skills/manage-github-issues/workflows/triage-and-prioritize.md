<required_reading>
**Read these reference files NOW:**

1. references/label-conventions.md
</required_reading>

<process>

**Step 1: Discover Project Context**

Check for project configuration:

1. Look for `.claude/github-issues-config.md` in the project root. If it exists, read it for:
   - Phase/milestone definitions and current active phase
   - Priority label conventions
   - Module/area labels

2. If no config file exists:
   - Run `gh label list --json name,description,color --limit 200` to discover existing labels
   - Read the project's CLAUDE.md for structure and priority conventions
   - Ask the user about their priority scheme if unclear

**Step 2: Fetch Issues Needing Triage**

Fetch open issues that lack a priority label:

```bash
gh issue list --state open --limit 200 --json number,title,labels,milestone,createdAt,body
```

Filter the results to find issues that:

- Have no priority label (none of P0-P3 or equivalent)
- Or have a `needs-design` label pending resolution
- Or have no milestone assigned

Also fetch recently created issues (last 14 days) that may need review:

```bash
gh issue list --state open --limit 50 --json number,title,labels,milestone,createdAt,body --sort created
```

**Step 3: Read Current Phase Context (if available)**

If the project has a roadmap file (from config), read it to understand:

- Which phase/milestone is currently active
- What the current goals are
- Which items are blocking progress

If no roadmap exists, proceed with triage based on issue content alone.

**Step 4: Analyze and Recommend Priorities**

For each untriaged issue, recommend a priority using this decision tree:

<priority_decision_tree>

```text
Is this a security vulnerability or data integrity issue?
  YES -> P0-critical or P1-high

Does this block other issues in the current phase/milestone?
  YES -> P1-high

Is this a core deliverable of the current phase/milestone?
  YES -> P2-medium

Is this a quality improvement (tests, docs, refactor)?
  YES -> P3-low (unless it blocks a P1/P2)

Is this for a future phase/milestone?
  YES -> P3-low (and verify phase label is correct)

Does this fix a user-facing bug?
  YES -> P1-high (current phase) or P2-medium (future phase)
```

</priority_decision_tree>

Also recommend:

- Area/module label if missing (based on title and body keywords)
- Milestone if missing (based on phase label or content)
- Whether the issue should be flagged as `blocked` or `needs-design`

**Step 5: Present Recommendations**

Show a table of recommendations for user review:

```text
## Triage Recommendations

| Issue | Title | Recommended Priority | Recommended Labels | Notes |
|-------|-------|---------------------|-------------------|-------|
| #30 | Add settings page | P2-medium | area:frontend | Core current phase UI |
| #31 | Research WebSocket libs | P3-low | area:api, needs-design | Tooling research |
| #32 | Fix auth token expiry | P1-high | area:auth | Security-adjacent |
| ...

**Summary:**
- P0-critical: 0 issues
- P1-high: N issues
- P2-medium: N issues
- P3-low: N issues
- Already triaged (skipped): N issues
```

Ask the user:

- "Should I apply all recommendations as shown?"
- "Do you want to adjust any priorities before I apply them?"

**Step 6: Apply Priority Updates**

For each approved recommendation:

```bash
gh issue edit {NUMBER} --add-label "{PRIORITY_LABEL}"
```

If a milestone is also needed:

```bash
gh issue edit {NUMBER} --milestone "{MILESTONE}"
```

If additional labels are needed:

```bash
gh issue edit {NUMBER} --add-label "{AREA_LABEL}"
```

**Step 7: Identify Blocking Chains**

After triage, check for blocking relationships:

- Issues labeled `blocked` -- do they reference what blocks them?
- P1-high issues -- are their dependencies also prioritized?
- Any circular dependencies?

If blocking chains are found, present them:

```text
## Dependency Chain
#32 (P1-high) -> blocked by #15 (P2-medium)
  Recommendation: Elevate #15 to P1-high since it blocks #32
```

**Step 8: Report Results**

Summarize all changes:

```text
Triage complete:
- Prioritized N issues
- Added area/module labels to N issues
- Assigned milestones to N issues
- Identified N blocking chains

Current phase backlog:
- P0-critical: 0
- P1-high: N (next to work on)
- P2-medium: N
- P3-low: N
- Blocked: N
```

</process>

<success_criteria>
This workflow is complete when:

- [ ] Project context discovered
- [ ] Untriaged issues identified and fetched
- [ ] Current phase context read (if roadmap exists)
- [ ] Priority recommendations generated for each issue
- [ ] Recommendations reviewed and approved by user
- [ ] Labels, milestones, and priorities applied via `gh` CLI
- [ ] Blocking chains identified and reported
- [ ] Summary with backlog breakdown presented
</success_criteria>
