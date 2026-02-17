# Process Research Needs

Work through open RN-NNN requests from SubNetree development.

## Steps

### 1. List Open Needs

Read `D:/DevSpace/.coordination/research-needs.md` and list all entries under `## Open`:
- Display: RN-NNN, priority, one-line context
- Sort by priority (High > Medium > Low)

### 2. Select Scope

Ask user:
- "Process a specific RN-NNN?" (enter number)
- "Process all open needs?" (start from highest priority)

### 3. Research Each Need

For each selected RN-NNN:

1. Read the full entry (context, expected deliverable)
2. Conduct the research using appropriate methods:
   - **GitHub analysis**: `gh` CLI for repo data, issues, releases
   - **Community research**: WebSearch for Reddit, forums, blog posts
   - **Code analysis**: `gh api` for file contents and architecture
3. Compile findings into the expected deliverable format

### 4. Update Research Need Status

Edit `D:/DevSpace/.coordination/research-needs.md`:
- Move the RN-NNN entry from `## Open` to `## Completed`
- Add completion date

### 5. Publish Finding

For each actionable finding, create an RF-NNN entry:
1. Read `D:/DevSpace/.coordination/research-findings.md`
2. Count existing entries to determine next number
3. Write new entry under `## Unprocessed` with:
   - Source: reference to the RN-NNN that triggered it
   - Impact: High/Medium/Low
   - Summary: key findings in 2-3 sentences
   - Action: specific recommendation for SubNetree
   - Processed: No
   - Created: today's date

### 6. Update Priorities

If findings affect priority order:
1. Read `D:/DevSpace/.coordination/priorities.md`
2. Suggest re-ranking based on new evidence
3. Ask user to confirm changes
4. Update if approved

## Output

- List of processed RN-NNN entries with completion status
- RF-NNN entries created for actionable findings
- Priority changes suggested (if applicable)
- Reminder: "Run `/coordination-sync` to propagate changes."
