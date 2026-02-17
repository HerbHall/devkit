# Quick Reference

Displays the skill quick reference card and project workflow guide inline.

## Skill Quick Reference Card

Display this when the user picks option 13:

```text
=== Skill Quick Reference ===

Session Management
  /dashboard              This control station (start here)
  /coordination-sync      Sync coordination files between projects
  /reflect                End-of-session learning capture
  /whats-next             Generate handoff document for next session

Project Management
  /pm-view                Weekly review, sprint planning, roadmap
  /coordination-sync 5    Check for stale coordination data

Development
  /create-plan            Plan multi-file features before coding
  /run-plan <path>        Execute a plan file via subagent
  /quality-control        CI/PR health checks after pushing
  /debug                  Systematic debugging with hypothesis testing

Research
  /research-mode          Competitive analysis, market validation
  /research-mode 4        Process open research needs (RN-NNN)

Utilities
  /ask-me-questions       Gather requirements before implementing
  /requirements_generator Update requirements documentation
  /eisenhower-matrix      Prioritize when overwhelmed
  /first-principles       Rigorous reasoning for architecture decisions
  /check-todos            See outstanding work items
  /add-to-todos           Capture context for future sessions
```

## Project Workflow Guide

Display this when the user picks option 14:

```text
=== Project Workflow ===

Daily Session Flow
  1. Start:  /dashboard (auto-shows status + priorities)
  2. Pick:   Choose a numbered task or describe what you need
  3. Plan:   /create-plan for multi-file features (optional)
  4. Code:   Implement on feature branch
  5. Test:   make test && make lint
  6. PR:     gh pr create (CI runs automatically)
  7. End:    Option 11 to update status, then /reflect

Coordination Flow (run periodically)
  1. Sync:   /coordination-sync 1 (full bidirectional sync)
  2. Review: /pm-view 1 (weekly review)
  3. Plan:   /pm-view 2 (sprint planning)
  4. Stale:  /coordination-sync 5 (check freshness)

Research Flow
  1. Check:  /dashboard option 4 (process findings)
  2. Need:   /dashboard option 10 (file research request)
  3. Deep:   /research-mode (full research workflows)

Key Paths
  Coordination hub:  D:/DevSpace/.coordination/
  SubNetree:         D:/DevSpace/SubNetree/
  HomeLab:           D:/DevSpace/research/HomeLab/
  Skills:            C:/Users/Herb/.claude/skills/
  Plans:             C:/Users/Herb/.claude/plans/
```

## After Display

```text
Press any number to return to an action, or type what you need:
```
