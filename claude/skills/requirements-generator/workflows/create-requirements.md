<required_reading>
**Read these reference files NOW:**

1. references/intake-checklist.md
2. references/requirements-template.md
3. references/requirements-questions-guide.md
</required_reading>

<process>

**Step 1: Smart Hybrid Intake**

Ask these key questions using AskUserQuestion:

<key_questions>

1. **Project name and one-sentence description** - What are we building?
2. **Project type** - CLI tool, library/API, Windows GUI app, or other?
3. **Primary users** - Who will use this? (developers, end users, admins)
4. **Core problem** - What specific problem does this solve?
5. **Key constraints** - Budget, timeline, technology restrictions?
</key_questions>

**Step 2: Present Remaining Checklist**

After key questions, present the intake checklist from `references/intake-checklist.md` and ask user to fill in what they know. Skip items already answered.

**Step 3: Draft Requirements Document**

Using `templates/requirements-template.md`, create the requirements.md file:

1. Fill in Project Overview from answers
2. Document stakeholders and constraints
3. Convert user needs into functional requirements with MoSCoW priority
4. Identify non-functional requirements (performance, security, usability)
5. List technical requirements (dependencies, platforms, integrations)
6. Write acceptance criteria for all Must/Should items
7. Explicitly list what's out of scope
8. Initialize changelog with version 1.0

**Step 4: Review with User**

Present the draft and ask:

- "Are any requirements missing?"
- "Are priorities correct?"
- "Should anything move to out-of-scope?"

Iterate until user approves.

**Step 5: Identify Open Questions**

Review the requirements.md draft and identify areas where:

- Multiple implementation approaches exist
- Technical decisions affect architecture
- User preferences aren't yet known
- Trade-offs need stakeholder input
- Ambiguity remains after initial requirements

Group questions by priority:

1. **BLOCKER**: Must decide before Phase 1 (MVP scope, core architecture, critical tech choices)
2. **HIGH**: Affects Phase 1 but has reasonable defaults (permissions, error handling, formats)
3. **MEDIUM**: UX enhancements for Phase 2 (notifications, background behavior, export formats)
4. **LOW**: Nice-to-have for future phases (retention policies, advanced features)

**Step 6: Generate Requirements Questions Document**

Using `templates/requirements-questions-template.md`, create REQUIREMENTS_QUESTIONS.md:

1. Replace `{PROJECT_NAME}` with actual project name
2. Replace `{DATE}` with current date
3. For each open question identified:
   - Write clear, specific question with context
   - Provide 2-4 concrete options with pros/cons
   - Explain implications of each choice
   - Recommend a default option with rationale
   - Note which components are impacted
4. Group by priority (1-4)
5. Create summary section showing what blocks development vs what can defer
6. Include response template for stakeholder to fill in

**Guidelines from `references/requirements-questions-guide.md`:**

- Focus on "how" to implement, not "what" to build (that's in requirements.md)
- Provide actionable options, not open-ended questions
- Show what can be changed later vs locked in
- Recommend defaults for non-blockers so development can start
- Link questions to requirements.md sections

**Step 7: Review with User**

Present both documents and ask:

For requirements.md:

- "Are any requirements missing?"
- "Are priorities correct?"
- "Should anything move to out-of-scope?"

For REQUIREMENTS_QUESTIONS.md:

- "Do these questions capture the key decision points?"
- "Are there other implementation questions I'm missing?"
- "Which questions can you answer now vs research later?"

Iterate until user approves both documents.

**Step 8: Write Files**

Write both files to the project directory:

1. `requirements.md` - The "what" (features, acceptance criteria, scope)
2. `REQUIREMENTS_QUESTIONS.md` - The "how" (decisions, trade-offs, options)

**Note**: Some projects may not need a questions document if:

- Requirements are crystal clear with no ambiguity
- Simple prototype/proof-of-concept
- Single developer making all decisions
- Following well-defined existing pattern

Ask user: "Do you want me to generate a REQUIREMENTS_QUESTIONS.md document alongside requirements.md? This captures open decisions and trade-offs that need your input. (Recommended for complex projects with multiple phases.)"

</process>

<success_criteria>
This workflow is complete when:

- [ ] Key questions answered
- [ ] Checklist items captured
- [ ] requirements.md created with all sections
- [ ] REQUIREMENTS_QUESTIONS.md created (if needed)
- [ ] User has approved both documents
- [ ] Files written to project directory
</success_criteria>
