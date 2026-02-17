# Pick Priority

User selected a numbered priority (1-3) from This Week's SubNetree Dev priorities.

## Steps

### 1. Identify the Priority

Map the number to the corresponding entry in `D:/DevSpace/.coordination/priorities.md` under `## This Week > ### SubNetree Development`.

### 2. Check for GitHub Issue

If the priority references a GitHub issue number (e.g., `#278`):

```bash
gh issue view {number} -R HerbHall/subnetree --json title,body,labels,assignees
```

Present the issue details.

### 3. Check for Existing Branch

```bash
git -C /d/DevSpace/SubNetree branch --list "*issue-{number}*"
```

If a branch exists, offer to switch to it. If not, offer to create one.

### 4. Create Branch (if needed)

```bash
git -C /d/DevSpace/SubNetree checkout main
git -C /d/DevSpace/SubNetree pull --ff-only
git -C /d/DevSpace/SubNetree checkout -b feature/issue-{number}-{short-desc}
```

### 5. Begin Implementation

Present the task scope and ask the user how they want to proceed:

- **Plan first**: "Run `/create-plan` to design the implementation"
- **Jump in**: Start coding directly with guidance from the issue description
- **Research first**: "Need more context? Check relevant requirement docs or run an Explore agent"

### 6. Proceed

Follow the user's choice. Standard development workflow applies from here.
