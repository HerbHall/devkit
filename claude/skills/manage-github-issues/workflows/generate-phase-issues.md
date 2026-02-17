<required_reading>
**Read these reference files NOW:**

1. references/label-conventions.md
2. references/issue-quality-standards.md
</required_reading>

<process>

**Step 1: Discover Project Context**

Check for project configuration:

1. Look for `.claude/github-issues-config.md` in the project root. If it exists, read it for:
   - Phase/milestone definitions
   - Module/area labels
   - Roadmap file path
   - Requirements directory
   - Phase-to-documentation mapping

2. If no config file exists:
   - Read the project's CLAUDE.md for structure hints
   - Run `gh label list --json name,description,color --limit 200` to discover existing labels
   - Look for common roadmap files (README.md, ROADMAP.md, docs/roadmap.md, PLAN.md, etc.)
   - Ask the user: "Where is your project roadmap or planning document?"

**Step 2: Select Phase/Milestone**

Ask the user which phase or milestone to generate issues for using AskUserQuestion.

If the project config defines phases, present them as options. Otherwise, ask the user to describe the scope:

- A specific milestone name
- A section of the roadmap
- A set of features or requirements

If the user already specified a phase/milestone, skip this step.

**Step 3: Read the Roadmap**

Read the project's roadmap file (from config or user input) and extract ONLY the section for the selected phase/milestone. Identify:

- All checklist items (lines starting with `- [ ]` or `- [x]`)
- Which items are already completed (`[x]`) vs outstanding (`[ ]`)
- Any sub-sections or groupings within the phase

**Step 4: Read Relevant Requirements (if applicable)**

If the project config maps phases to specific requirements/design docs, read ONLY the primary doc relevant to the current batch of issues.

**IMPORTANT**: Read ONE doc at a time. If the phase spans multiple docs, read only the one relevant to the current batch.

If the project has no separate requirements docs, use the roadmap content from Step 3 as the source of truth.

**Step 5: Fetch Existing Issues**

Run this command to get current issues for the phase:

```bash
gh issue list --label "{PHASE_LABEL}" --state all --limit 200 --json number,title,state,labels
```

If the project doesn't use phase labels, fetch all open issues:

```bash
gh issue list --state open --limit 200 --json number,title,state,labels
```

Parse the output to build a list of existing issue titles and their states (open/closed).

**Step 6: Diff Roadmap vs Existing Issues**

For each outstanding roadmap checklist item (`- [ ]`):

1. Search existing issues for a matching title (fuzzy match on key terms)
2. If a match exists and is open, skip it (already tracked)
3. If a match exists and is closed, check if it was completed or won't-fix'd
4. If no match exists, add it to the "issues to create" list

**Step 7: Draft Issues**

For each item in the "issues to create" list, draft an issue using the appropriate template from `templates/`:

- Use `templates/feature-issue.md` for features and enhancements
- Use `templates/epic-issue.md` for items that need multiple sub-tasks
- Use `templates/bug-issue.md` only if the item describes a known defect

For each issue, determine:

- **Title**: Action verb + specific description (see `references/issue-quality-standards.md`)
- **Body**: Fill template with description, acceptance criteria from docs, and references
- **Labels**: Type + priority + area/module + phase/milestone (from project config or user)
- **Milestone**: From project config or user input

**Priority assignment heuristic:**

- Items that block other items in the phase: `P1-high`
- Core functionality for the phase's goal: `P2-medium`
- Quality improvements, docs, nice-to-haves: `P3-low`
- Security or data integrity items: `P1-high`

**Step 8: Present Batch for Review**

Present ALL drafted issues to the user in a summary table:

```text
| # | Title | Labels | Priority |
|---|-------|--------|----------|
| 1 | Add user list page with sorting | feature, area:frontend, phase:1 | P2-medium |
| 2 | Implement WebSocket notifications | feature, area:api, phase:1 | P1-high |
| ...
```

Ask the user:

- "Should I create all of these issues?"
- "Do you want to modify any titles, priorities, or labels?"
- "Should any items be skipped or combined?"

Wait for approval before proceeding.

**Step 9: Create Issues**

For each approved issue, run:

```bash
gh issue create \
  --title "Issue title here" \
  --body "$(cat <<'EOF'
Issue body here...
EOF
)" \
  --label "feature,P2-medium,area:frontend,phase:1" \
  --milestone "Phase 1: Foundation"
```

Create issues sequentially and collect the issue numbers.

**Step 10: Report Results**

Present a summary of created issues:

```text
Created N issues for {PHASE/MILESTONE}:
- #101: Add user list page with sorting
- #102: Implement WebSocket notifications
- ...

Skipped M items (already tracked):
- #45: Implement JWT authentication (open)
- ...
```

If any epic issues were created, remind the user to update the task checklists with the sub-issue numbers.

</process>

<success_criteria>
This workflow is complete when:

- [ ] Project context discovered (config file, CLAUDE.md, or user input)
- [ ] Phase/milestone selected and roadmap section read
- [ ] Relevant docs read for context (if available)
- [ ] Existing issues fetched and deduplication performed
- [ ] Issue drafts reviewed and approved by user
- [ ] Issues created via `gh issue create` with proper labels and milestones
- [ ] Summary of results presented
</success_criteria>
