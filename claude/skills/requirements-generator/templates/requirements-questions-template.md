# {PROJECT_NAME} Requirements Questions

**Document Purpose**: Capture open questions and decisions needed for implementation
**Status**: Awaiting Response
**Created**: {DATE}
**Last Updated**: {DATE}

---

## How to Use This Document

1. Read each question in priority order
2. Fill in your answer in the `**ANSWER:**` section
3. Mark status as `ANSWERED` when complete
4. Reference this document when implementing related features

**Status Values:**

- `OPEN` - Not yet answered
- `RESEARCHING` - Investigating options
- `ANSWERED` - Decision made
- `DEFERRED` - Will decide later, use default for now

---

## Priority 1: BLOCKERS (Needed for Phase 1 Development)

These questions must be answered before implementing core functionality.

---

### Q1.1: {BLOCKER_QUESTION_TITLE}

**Priority**: BLOCKER
**Status**: OPEN
**Impacts**: {AFFECTED_COMPONENTS}
**Phase**: 1

**QUESTION:**

{QUESTION_DESCRIPTION}

**OPTIONS:**

A. **{OPTION_A_NAME}** ({pros/cons})

- {Description}
- {Implications}

B. **{OPTION_B_NAME}** ({pros/cons})

- {Description}
- {Implications}

C. **{OPTION_C_NAME}** ({pros/cons})

- {Description}
- {Implications}

**RECOMMENDED**: Option {X} - {Brief rationale}

**ANSWER:**

[Your answer here - A, B, C, or custom approach]

**DECISION RATIONALE:**

[Why you chose this approach]

**IMPLEMENTATION NOTES:**

[Any specific requirements or edge cases to handle]

---

## Priority 2: HIGH (Needed Soon, Can Start with Defaults)

These questions affect Phase 1 implementation but can proceed with reasonable defaults.

---

### Q2.1: {HIGH_PRIORITY_QUESTION}

**Priority**: HIGH
**Status**: OPEN
**Impacts**: {AFFECTED_COMPONENTS}
**Phase**: 1 or 2

**QUESTION:**

{QUESTION_DESCRIPTION}

**CONTEXT:**
{Additional context or background information}

**OPTIONS:**

A. **{OPTION_A}** ({simple/safe/recommended})

- {Description}

B. **{OPTION_B}** ({alternative approach})

- {Description}

**RECOMMENDED**: Option {X} with {rationale}

**ANSWER:**

[Your answer here]

**DECISION RATIONALE:**

[Why you chose this approach]

---

## Priority 3: MEDIUM (Improve UX, Can Defer to Phase 2)

These questions enhance user experience but aren't blocking for MVP.

---

### Q3.1: {MEDIUM_PRIORITY_QUESTION}

**Priority**: MEDIUM
**Status**: OPEN
**Impacts**: {AFFECTED_FEATURES}
**Phase**: 2

**QUESTION:**

{QUESTION_DESCRIPTION}

**OPTIONS:**

A. **{SIMPLE_OPTION}** (MVP approach)

- {Description}

B. **{ENHANCED_OPTION}** (better UX)

- {Description}

C. **{FULL_FEATURED_OPTION}** (most flexible)

- {Description}

**RECOMMENDED**: Option {X} for MVP, add {Y} in Phase 2

**ANSWER:**

[Your answer here or "Defer"]

---

## Priority 4: LOW (Nice to Have, Defer to Phase 3+)

These questions are lower priority and can use reasonable defaults.

---

### Q4.1: {LOW_PRIORITY_QUESTION}

**Priority**: LOW
**Status**: OPEN
**Impacts**: {FUTURE_FEATURES}
**Phase**: 3 or Later

**QUESTION:**

{QUESTION_DESCRIPTION}

**OPTIONS:**

A. **{DEFAULT_OPTION}**
B. **{ALTERNATIVE_OPTION}**

**RECOMMENDED**: Defer to Phase {N}, then use Option {X}

**ANSWER:**

[Defer or specify preference]

---

## Summary and Next Steps

### To Unblock Development Immediately

Please answer these questions first (in order):

1. **Q1.1**: {Most critical question}
2. **Q1.2**: {Second most critical}
3. **Q1.3**: {Third most critical}

### Can Proceed with Defaults

These have recommended defaults that allow development to continue:

- Q{N}: {Question} (default: {suggested default})

### Defer to Later Phases

All Priority 3 and 4 questions can be deferred or use suggested defaults.

---

## Response Template

You can copy this template to respond:

```markdown
## My Responses - [Date]

### Q1.1: {Question Title}
**ANSWER:** Option {X}
**RATIONALE:** {Brief explanation}
**NOTES:** {Any additional context}

[Continue for other questions...]
```

---

**Document Maintained By**: Development Team
**Review Frequency**: Update as decisions are made
**Related Documents**: [{PROJECT_NAME}_requirements.md](requirements.md), [README.md](README.md)
