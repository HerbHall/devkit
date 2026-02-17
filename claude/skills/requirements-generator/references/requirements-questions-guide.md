# Requirements Questions Guide

## Overview

The Requirements Questions document complements the main requirements.md file by capturing **open questions, design decisions, and implementation choices** that need stakeholder input. This approach is inspired by Architecture Decision Records (ADR) and Request for Comments (RFC) patterns.

## Why Use Requirements Questions?

**Benefits:**

1. **Reduces Ambiguity**: Forces explicit decisions on unclear points
2. **Enables Parallel Work**: Developers can start with defaults while stakeholders research answers
3. **Documents Decisions**: Creates a record of why choices were made
4. **Prioritizes Questions**: Clearly shows what blocks development vs. what can wait
5. **Prevents Rework**: Gets alignment before implementation, not after

## When to Create Requirements Questions

Create a REQUIREMENTS_QUESTIONS.md file when:

- Starting a new project with multiple implementation approaches
- Requirements have ambiguity or unclear areas
- Multiple stakeholders need to weigh in on decisions
- Project has phases and some decisions can be deferred
- Technical choices significantly impact architecture

Skip it when:

- Requirements are crystal clear with no ambiguity
- Project is a simple prototype or proof-of-concept
- Single developer making all decisions
- Following an existing, well-defined pattern

## Question Format (ADR-Inspired)

Each question follows this structure:

```markdown
### Q{Priority}.{Number}: {Short Title}

**Priority**: {BLOCKER|HIGH|MEDIUM|LOW}
**Status**: {OPEN|RESEARCHING|ANSWERED|DEFERRED}
**Impacts**: {Affected components/features}
**Phase**: {Which development phase needs this answer}

**QUESTION:**
{Clear, specific question}

**CONTEXT:**
{Background information, constraints, or why this matters}

**OPTIONS:**

A. **{Option Name}** ({descriptor})
   - Pro: {Advantage}
   - Con: {Disadvantage}
   - Implication: {What this means}

B. **{Option Name}** ({descriptor})
   - ...

**RECOMMENDED**: Option {X} - {Brief rationale}

**ANSWER:**
[Stakeholder fills this in]

**DECISION RATIONALE:**
[Stakeholder explains why they chose this]

**IMPLEMENTATION NOTES:**
[Any edge cases or special considerations]
```

## Priority Levels

### BLOCKER Questions (Priority 1)

**Must be answered before Phase 1 development begins**

Examples:

- What's the MVP scope? (Determines entire Phase 1)
- Which core technology/framework to use?
- Critical architectural decisions
- Essential security/compliance requirements

Characteristics:

- Blocks all development if unanswered
- Affects fundamental architecture
- Cannot proceed with reasonable defaults

### HIGH Priority Questions (Priority 2)

**Affects Phase 1 but can proceed with defaults**

Examples:

- Admin privileges required?
- File locking strategy
- IPv4 vs IPv6 support
- Error handling approach

Characteristics:

- Needed soon for Phase 1
- Has reasonable defaults to start with
- Can refactor later if needed
- Doesn't block beginning development

### MEDIUM Priority Questions (Priority 3)

**Enhances UX but can defer to Phase 2**

Examples:

- Notification preferences
- Background scanning behavior
- Export file formats
- UI enhancements

Characteristics:

- Improves user experience
- Not critical for MVP
- Can defer without major impact
- Phase 2 or 3 features

### LOW Priority Questions (Priority 4)

**Nice-to-have features for future phases**

Examples:

- Long-term data retention policies
- Advanced customization options
- Integration with future services
- Potential future features

Characteristics:

- Defer indefinitely
- Use suggested defaults
- Revisit if user requests
- Post-MVP enhancements

## Question Categories by Domain

### Technical Architecture

- Technology stack choices
- Deployment strategies
- Scalability approaches
- Integration patterns

### User Experience

- Workflow preferences
- Notification strategies
- Default behaviors
- UI/UX paradigms

### Security and Compliance

- Authentication requirements
- Authorization models
- Data retention policies
- Compliance needs

### Performance and Scale

- Expected user load
- Response time requirements
- Resource constraints
- Optimization priorities

### Data Management

- Storage strategies
- Backup requirements
- Export/import formats
- Migration approaches

## Writing Good Options

**DO:**

- Provide 2-4 concrete options
- Include pros/cons for each
- Explain implications clearly
- Recommend a default with rationale
- Show what can be changed later vs locked in

**DON'T:**

- Present false dichotomies
- Overwhelm with too many options (>4)
- Use jargon without explanation
- Hide your recommendation
- Make options obviously bad just to guide choice

## Example: Good vs Bad Questions

### BAD - Too Vague

**Q: How should we handle errors?**

No context, no options, no clear scope. Stakeholder doesn't know what you're asking.

### GOOD - Specific and Actionable

**Q: Storage Failure Fallback Strategy**

**QUESTION:**
If the application can't create/write to `%APPDATA%\AppName` (permissions, disk full, network drive), what should happen?

**OPTIONS:**

A. **Fall back to local directory** (graceful degradation)

- Stores data next to executable
- Pro: Application still works
- Con: Data not in standard location
- Implication: Need to check both locations on load

B. **Run in memory-only mode** (temporary)

- No persistence, all data lost on close
- Pro: Clear that data isn't saved
- Con: Confusing for users
- Implication: Need prominent warning banner

C. **Hard fail with error** (strict)

- Refuse to start, show error dialog
- Pro: Forces user to fix the issue
- Con: Application completely unusable
- Implication: May frustrate users

**RECOMMENDED**: Option A (fallback to local) - best balance of usability and clarity

Clear scope, concrete options with trade-offs, specific recommendation.

## Maintaining the Document

**Initial Creation:**

- Generate alongside requirements.md
- Focus on decisions needed for Phase 1
- Identify obvious blockers upfront

**During Development:**

- Update STATUS as decisions are made
- Add new questions as they arise
- Archive answered questions (or mark ANSWERED)

**Phase Transitions:**

- Review deferred questions before starting new phase
- Promote relevant questions to current priority
- Archive obsolete questions

## Integration with Requirements.md

The two documents work together:

| requirements.md | REQUIREMENTS_QUESTIONS.md |
|----------------|---------------------------|
| **What** to build | **How** to build it |
| Features and capabilities | Implementation decisions |
| Acceptance criteria | Trade-off analysis |
| Must/Should/Could/Won't | Priority 1/2/3/4 questions |
| Single source of truth | Discussion and decision log |

Think of it as:

- **requirements.md** = The contract (what success looks like)
- **REQUIREMENTS_QUESTIONS.md** = The design discussions (how to achieve it)

## Anti-Patterns to Avoid

- **Too Many Questions**: If you have 50+ questions, requirements are too vague
- **Analysis Paralysis**: Don't block all work on answering every question
- **Hidden Recommendations**: If you know the right answer, state it clearly
- **Fake Choices**: Don't present options if only one is viable
- **Premature Optimization**: Don't ask Phase 3 questions in Phase 1

## Success Criteria

A good Requirements Questions document:

- Clearly identifies what blocks development (Priority 1)
- Provides concrete, actionable options
- Has recommended defaults for non-blockers
- Shows what can be decided later
- Enables development to start while discussions continue
- Documents decisions with rationale

## Template Usage

Use `templates/requirements-questions-template.md` and customize:

1. Replace `{PROJECT_NAME}` with actual project name
2. Replace `{DATE}` with current date
3. Fill in actual questions based on requirements.md ambiguities
4. Group questions by priority (1-4)
5. Provide context and options for each
6. Recommend defaults where possible
7. Create summary section showing critical path

## Related Patterns

This approach draws from:

- **ADR (Architecture Decision Records)**: Document architectural choices with context and rationale
- **RFC (Request for Comments)**: Solicit feedback on proposals before implementation
- **Design Docs**: Explore trade-offs before committing to implementation
- **Decision Matrix**: Structured comparison of options
- **MoSCoW Prioritization**: Must/Should/Could/Won't prioritization framework
