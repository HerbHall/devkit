# MCP Memory Bootstrap

Key entities to create in a fresh MCP Memory instance. These represent foundational knowledge that should exist from the start. Create using `create_entities` and `create_relations` tools.

## Core Entities

### User Profile

```text
Entity: herb-dev-profile
Type: Person
Observations:
- Solo developer working on multiple concurrent projects
- Primary stack: Go + React (SubNetree), C#/.NET (IPScan), Rust (DigitalRain)
- Platform: Windows with MSYS/Git Bash
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
Entity: project-subnetree
Type: Project
Observations:
- Network monitoring platform (Go backend + React frontend)
- Most active project, production-grade CI/CD
- GitHub: HerbHall/SubNetree

Entity: project-ipscan
Type: Project
Observations:
- C# .NET 10 network scanner (WPF + CLI)
- Shelved, used as SDD research test bed
- GitHub: HerbHall/IPScan

Entity: project-runbooks
Type: Project
Observations:
- Docker Desktop extension for saved command scripts
- GitHub: HerbHall/Runbooks
```

### Key Patterns

```text
Entity: pattern-subagent-parallel-execution
Type: Pattern
Observations:
- Launch 2-3 background agents per wave for independent tasks
- All agents share working tree (gotcha #28)
- Sort changes into branches via git stash/pop after completion
- Proven on SubNetree sprints: 6 PRs from 2 waves

Entity: pattern-autolearn-feedback-loop
Type: Pattern
Observations:
- /reflect skill captures session learnings
- Stores in MCP Memory (deep) and rules files (fast)
- Rules files auto-load every session
- 70+ patterns accumulated across projects
```

## Relations

```text
herb-dev-profile -> USES -> dev-methodology
herb-dev-profile -> WORKS_ON -> project-subnetree
herb-dev-profile -> WORKS_ON -> project-ipscan
herb-dev-profile -> WORKS_ON -> project-runbooks
dev-methodology -> INCLUDES -> pattern-subagent-parallel-execution
dev-methodology -> INCLUDES -> pattern-autolearn-feedback-loop
```

## Notes

- Don't try to recreate the full knowledge graph from a previous machine
- These seeds provide enough context for a fresh Claude session to understand who you are and how you work
- The autolearn loop will rebuild detailed patterns over time
- Project-specific knowledge accumulates naturally through development sessions
