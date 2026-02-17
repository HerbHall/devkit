# Agent Workflow Guide: Context Management Strategies

This guide shows how to utilize agents effectively to keep your context window manageable and work more efficiently.

## Core Concept: Delegate to Keep Context Lean

The main Claude instance should act as a **coordinator**, delegating specialized work to subagents. This keeps your main context focused on high-level decisions while subagents handle detailed exploration, research, and implementation.

## When to Use Subagents

### ✅ USE Subagents For

**1. Codebase Exploration**

```text
❌ DON'T: Run Grep/Glob directly in main context
✅ DO: Use Task tool with subagent_type=Explore

User: "Where is error handling implemented?"
Main Claude: [Spawns Explore agent to search codebase]
Explore Agent: [Searches, reads files, analyzes]
Main Claude: [Receives summary, stays lean]
```

**2. Research Tasks**

```text
User: "What's the best library for date parsing?"
Main Claude: [Spawns research agent]
Research Agent: [WebSearch, WebFetch, compares options]
Main Claude: [Receives recommendation with reasoning]
```

**3. Independent Verification**

```text
User: "Implement feature X"
Main Claude: [Implements feature]
Main Claude: [Spawns code-reviewer agent for verification]
Review Agent: [Analyzes code, finds issues]
Main Claude: [Applies feedback]
```

**4. Parallel Independent Tasks**

```text
User: "Update docs, run tests, and check dependencies"
Main Claude: [Spawns 3 agents in parallel]
  - docs-agent: Updates documentation
  - test-agent: Runs test suite
  - deps-agent: Checks for updates
Main Claude: [Aggregates results when all complete]
```

### ❌ DON'T Use Subagents For

- Single file reads (use Read tool directly)
- Simple edits (use Edit tool directly)
- Tasks requiring tight coordination (keep in main context)
- When you already know the exact file/location

## Available Subagent Types

Based on your system instructions, these are the available subagent types:

### **Explore Agent**

**Use for**: Codebase exploration, finding files, understanding structure

```text
Tasks:
- "How does authentication work?"
- "Find all API endpoints"
- "Where is logging configured?"
- "What's the project structure?"
```

**Tools**: All tools except Task, ExitPlanMode, Edit, Write, NotebookEdit

**Thoroughness levels**: "quick", "medium", "very thorough"

### **Plan Agent**

**Use for**: Designing implementation strategies before coding

```text
Tasks:
- "Plan how to add authentication"
- "Design a refactoring approach for the data layer"
- "Create implementation strategy for feature X"
```

**Tools**: All tools except Task, ExitPlanMode, Edit, Write, NotebookEdit

### **General-Purpose Agent**

**Use for**: Complex multi-step tasks, research, autonomous work

```text
Tasks:
- "Research best practices for error handling in Node.js"
- "Find and summarize all TODOs in the codebase"
- "Investigate performance bottlenecks"
```

**Tools**: All tools

### **Bash Agent**

**Use for**: Git operations, command execution, terminal tasks

```text
Tasks:
- "Check git history for changes to auth module"
- "Run npm audit and summarize vulnerabilities"
- "Execute the test suite and analyze failures"
```

**Tools**: Bash only (specialized for command execution)

### **Custom Agents**

You can define specialized agents for recurring tasks:

```text
- code-reviewer: Reviews code for quality and security
- test-runner: Runs tests and analyzes results
- docs-updater: Updates documentation based on code changes
- dependency-auditor: Checks and updates dependencies
```

## Workflow Integration

### Pattern 1: Explore → Plan → Code → Commit (with Agents)

**Traditional approach (high context usage):**

```text
1. User asks for feature
2. Main Claude searches entire codebase (fills context)
3. Main Claude plans (adding to context)
4. Main Claude codes (more context)
5. Main Claude commits
```

**Agent-optimized approach (lean context):**

```text
1. User asks for feature
2. Main Claude spawns Explore agent → receives summary
3. Main Claude spawns Plan agent → receives plan
4. Main Claude implements (focused context)
5. Main Claude commits
```

### Pattern 2: Parallel Verification

```bash
# Instead of sequential in main context:
User: "Implement feature, run tests, update docs"

# Use parallel agents:
Main Claude spawns in ONE message:
  - [Task: implement-agent] → Writes code
  - [Task: test-agent] → Runs tests in parallel
  - [Task: docs-agent] → Updates docs in parallel

Main Claude aggregates results and handles any conflicts
```

### Pattern 3: Research Before Implementation

```bash
# Avoid filling main context with research:
User: "Add rate limiting to the API"

Main Claude:
  1. Spawn research-agent: "Find best rate limiting libraries for Express"
  2. Receive summary: "Recommendations: express-rate-limit vs rate-limiter-flexible"
  3. Ask user which to use
  4. Implement with focused context
```

### Pattern 4: Multi-Checkout Workflow (Advanced)

For truly large tasks, use git worktrees:

```bash
# Create 3-4 git worktrees in separate folders
git worktree add ../feature-branch-1 feature-1
git worktree add ../feature-branch-2 feature-2
git worktree add ../feature-branch-3 feature-3

# Run separate Claude sessions in each:
# Terminal 1: cd ../feature-branch-1 && claude
# Terminal 2: cd ../feature-branch-2 && claude
# Terminal 3: cd ../feature-branch-3 && claude

# Each works independently on different features
# Main branch coordinator merges completed work
```

## Practical Examples

### Example 1: Adding a New Feature

```text
User: "Add user authentication with JWT"

❌ Bad (fills main context):
Main: [Searches entire codebase for auth patterns]
Main: [Reads 10 files to understand structure]
Main: [Plans implementation]
Main: [Implements]

✅ Good (lean context):
Main: [Spawns Explore agent: "How is authentication currently handled?"]
Explore: [Returns summary: "No auth, uses Express, has user routes in /routes/users.js"]
Main: [Spawns Plan agent: "Design JWT auth for Express app"]
Plan: [Returns implementation plan]
Main: [Asks user to approve plan]
Main: [Implements based on plan with focused context]
```

### Example 2: Bug Investigation

```text
User: "The login endpoint returns 500, investigate"

✅ Good approach:
Main: [Spawns Explore agent: "Find login endpoint and trace error handling"]
Explore: [Searches, reads relevant files, identifies issue]
Explore: [Returns: "Found in /routes/auth.js:42 - missing error handler for DB connection"]
Main: [Fixes the specific issue with minimal context]
Main: [Spawns test-agent: "Verify login endpoint works"]
```

### Example 3: Parallel Code Review

```text
User: "Review this PR"

✅ Parallel approach (use ONE message with multiple Task calls):
Main spawns in parallel:
  - [security-reviewer]: Check for vulnerabilities
  - [style-reviewer]: Check code style and patterns
  - [test-reviewer]: Check test coverage

Main: [Aggregates all feedback]
Main: [Presents consolidated review]
```

## Context Management Best Practices

### 1. Keep Main Context for Coordination Only

Main Claude should:

- Make high-level decisions
- Coordinate between agents
- Interact with user
- Implement final changes after receiving summaries

Main Claude should NOT:

- Do extensive file searching
- Read dozens of files
- Perform deep research
- Run exploratory analysis

### 2. Use `/clear` Between Major Tasks

```text
User: "Add authentication" → Complete
User: "Now add rate limiting" → /clear first!

The authentication context isn't needed for rate limiting.
Clear between unrelated tasks.
```

### 3. Session Management

For related multi-step work that spans multiple sessions:

- Agents can capture session IDs
- Resume sessions to maintain context
- Fork sessions to explore different approaches

### 4. Delegate Research to Agents

```text
❌ Don't fill main context with research:
Main: [WebSearch for 5 different libraries]
Main: [WebFetch documentation for each]
Main: [Compare all options]
Main: [Finally, implement]

✅ Delegate research:
Main: [Spawn research-agent with specific question]
Research: [Does all the searching and comparison]
Main: [Receives concise recommendation]
Main: [Implements with clean context]
```

## Setting Up Custom Agents

Create specialized agents for your common workflows by defining them in the Task tool options:

**Example: Code Review Agent**

```python
AgentDefinition(
    description="Expert code reviewer for quality and security",
    prompt="Review code for: security vulnerabilities, best practices, performance issues, test coverage",
    tools=["Read", "Glob", "Grep"]
)
```

**Example: Documentation Agent**

```python
AgentDefinition(
    description="Documentation specialist",
    prompt="Update documentation to match code changes. Follow existing doc patterns.",
    tools=["Read", "Glob", "Edit", "Write"]
)
```

**Example: Test Runner Agent**

```python
AgentDefinition(
    description="Test execution and analysis specialist",
    prompt="Run tests, analyze failures, provide actionable debugging info",
    tools=["Bash", "Read", "Grep"]
)
```

## Measuring Success

You're using agents effectively when:

✅ Main context stays focused and readable
✅ You can summarize the main conversation in a few sentences
✅ Most exploration/research happens in subagents
✅ Parallel work happens via parallel agents
✅ Sessions complete faster (parallel work)
✅ Less scrolling through context to find information

You're NOT using agents effectively when:

❌ Main context is filled with file searches
❌ Dozens of files read into main context
❌ Research and implementation mixed together
❌ Sequential work that could be parallelized
❌ Context window warnings
❌ Losing track of the main task

## Quick Reference Commands

```bash
# Ask for exploration (triggers Explore agent)
"How does the authentication system work?"
"Where are API endpoints defined?"

# Ask for planning (triggers Plan agent)
"Create a plan to add rate limiting"
"Design the approach for refactoring the data layer"

# Request parallel work
"Run tests and update docs in parallel"
"Review code for security and style simultaneously"

# Request research
"Research the best library for [task]"
"Find examples of [pattern] in open source projects"

# Clear context between tasks
/clear
```

## Integration with Your Automation

Your SessionStart hook and templates already support this workflow:

- CLAUDE.md files can specify preferred agent strategies
- Hooks can log agent usage for analysis
- Templates can include agent delegation patterns

**Add to project CLAUDE.md:**

```markdown
## Agent Usage Patterns

For this project, prefer:
- Explore agent for finding files (large codebase)
- Test runner agent after any logic changes
- Documentation agent after public API changes
```

## Summary

**Golden Rule**: Main Claude = Coordinator. Agents = Specialists.

1. **Explore before implementing** → Use Explore agent
2. **Plan before coding** → Use Plan agent
3. **Parallelize independent work** → Multiple Task calls in one message
4. **Research before deciding** → Use general-purpose agent
5. **Clear between unrelated tasks** → Use `/clear`

This keeps your context window lean, your work parallelized, and your main conversation focused on what matters: delivering value.

---

**Next Steps:**

1. Try the Explore agent next time you ask "where is X?"
2. Use parallel agents for your next multi-task request
3. Add agent delegation patterns to project CLAUDE.md files
4. Monitor context usage and adjust agent strategy
