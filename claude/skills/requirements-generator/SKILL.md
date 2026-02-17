---
name: requirements-generator
description: Creates and maintains requirements.md files for programming projects using industry-standard practices. Optionally generates REQUIREMENTS_QUESTIONS.md to capture open decisions and trade-offs using ADR/RFC patterns. Use when starting a new project, updating requirements as scope changes, or reviewing existing requirements documents.
---

<essential_principles>

**MoSCoW Prioritization**

- **Must have**: Critical requirements without which the project fails
- **Should have**: Important but not critical; workarounds exist
- **Could have**: Nice-to-have features; include if time permits
- **Won't have (this release)**: Explicitly out of scope

**Requirements Quality Criteria**
Every requirement must be:

- **Specific**: Clear, unambiguous language
- **Measurable**: Verifiable through testing or observation
- **Achievable**: Technically feasible within constraints
- **Relevant**: Aligned with project goals
- **Traceable**: Linked to a business need or user story

**Version Control**

- Track all changes with version numbers (MAJOR.MINOR)
- MAJOR: Scope changes, new features, removed requirements
- MINOR: Clarifications, refinements, acceptance criteria updates
- Maintain changelog at top of document

**Document Structure**
All requirements.md files follow this structure:

1. Project Overview
2. Stakeholders and Constraints
3. Functional Requirements
4. Non-Functional Requirements
5. Technical Requirements
6. Acceptance Criteria
7. Out of Scope
8. Changelog

</essential_principles>

<intake>
What would you like to do?

1. **Create new requirements** - Start a new requirements.md from scratch
2. **Update requirements** - Modify existing requirements as scope changes
3. **Review requirements** - Audit requirements for completeness and quality

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "create", "new", "start" | workflows/create-requirements.md |
| 2, "update", "modify", "change" | workflows/update-requirements.md |
| 3, "review", "audit", "check" | workflows/review-requirements.md |

**After reading the workflow, follow it exactly.**
</routing>

<reference_index>
All domain knowledge in references/:

**Templates**:

- requirements-template.md
- requirements-questions-template.md (ADR/RFC-style decision capture)

**Checklists**:

- intake-checklist.md
- quality-checklist.md

**Patterns**:

- requirement-patterns.md
- requirements-questions-guide.md (How to create effective decision documents)
</reference_index>

<workflows_index>

| Workflow | Purpose |
|----------|---------|
| create-requirements.md | Gather info and create new requirements.md |
| update-requirements.md | Modify requirements with proper versioning |
| review-requirements.md | Audit requirements for completeness |

</workflows_index>

<success_criteria>
A complete requirements.md has:

- [ ] Valid version number and changelog
- [ ] All sections from document structure
- [ ] Every requirement prioritized (MoSCoW)
- [ ] Acceptance criteria for all Must/Should requirements
- [ ] Technical constraints identified
- [ ] Out-of-scope items explicitly listed

Optional REQUIREMENTS_QUESTIONS.md has:

- [ ] Open decisions prioritized (BLOCKER/HIGH/MEDIUM/LOW)
- [ ] Each question with clear context and options
- [ ] Recommended defaults for non-blockers
- [ ] Summary showing what blocks development vs can defer
- [ ] Response template for stakeholder input
</success_criteria>
