# MCP Memory Bootstrap

> **Example content**: Replace entity names, GitHub handles, project names, and
> observations with your own before loading into MCP Memory. These are examples
> showing the structure, not values to use verbatim.

Key entities to create in a fresh MCP Memory instance. These represent foundational knowledge that should exist from the start. Create using `create_entities` and `create_relations` tools.

## Core Entities

### User Profile

```text
Entity: your-dev-profile
Type: Person
Observations:
- Solo developer working on multiple concurrent projects
- Primary stack: <your languages and frameworks>
- Platform: <your OS and shell>
- Editor: VS Code with Claude Code extension
- Prefers: concise communication, no emojis, conventional commits
- Workflow: Explore -> Plan -> Code -> Commit
- Uses branch-per-issue with PR merge workflow
```

### Development Methodology

```text
Entity: dev-methodology
Type: Process
Observations:
- Six phases: Concept -> Research -> Specification -> Prototype -> Implementation -> Release
- Each phase has explicit gate criteria (go/kill/pivot)
- Standardized templates for each phase artifact
- Cross-project learning via autolearn feedback loop
- MCP Memory for persistent knowledge, rules files for auto-loaded patterns
```

### Project Registry

Create one entity per active project:

```text
Entity: project-one
Type: Project
Observations:
- <description of the project>
- GitHub: <your-handle>/<repo-name>

Entity: project-two
Type: Project
Observations:
- <description of the project>
- GitHub: <your-handle>/<repo-name>
```

### Key Patterns

```text
Entity: pattern-subagent-parallel-execution
Type: Pattern
Observations:
- Launch 2-3 background agents per wave for independent tasks
- All agents share working tree (see known-gotchas.md)
- Sort changes into branches via git stash/pop after completion

Entity: pattern-autolearn-feedback-loop
Type: Pattern
Observations:
- /reflect skill captures session learnings
- Stores in MCP Memory (deep) and rules files (fast)
- Rules files auto-load every session
```

## Relations

```text
your-dev-profile -> USES -> dev-methodology
your-dev-profile -> WORKS_ON -> project-one
your-dev-profile -> WORKS_ON -> project-two
dev-methodology -> INCLUDES -> pattern-subagent-parallel-execution
dev-methodology -> INCLUDES -> pattern-autolearn-feedback-loop
```

## Notes

- Don't try to recreate the full knowledge graph from a previous machine
- These seeds provide enough context for a fresh Claude session to understand who you are and how you work
- The autolearn loop will rebuild detailed patterns over time
- Project-specific knowledge accumulates naturally through development sessions
