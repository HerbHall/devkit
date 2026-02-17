<overview>
Quality criteria for auditing individual requirements. Each requirement should pass these checks.
</overview>

<smart_criteria>
**SMART Criteria**

<criterion name="specific">
**Specific** - Clear, unambiguous language

Questions to ask:

- Can this be interpreted in only one way?
- Are there vague words like "fast", "easy", "user-friendly"?
- Are quantities and boundaries defined?

Red flags:

- "The system should be fast" (how fast?)
- "Users can easily navigate" (what makes it easy?)
- "Support multiple formats" (which formats?)

Better:

- "API response time < 200ms at 95th percentile"
- "Navigation requires max 3 clicks to any feature"
- "Support JSON, XML, and CSV formats"
</criterion>

<criterion name="measurable">
**Measurable** - Verifiable through testing

Questions to ask:

- Can we write a test for this?
- What would a pass/fail look like?
- Is there a concrete acceptance criterion?

Red flags:

- "The UI should look professional"
- "The system should be reliable"
- "Users should be satisfied"

Better:

- "UI follows Material Design guidelines v3"
- "System maintains 99.9% uptime monthly"
- "User satisfaction score > 4.0 in post-release survey"
</criterion>

<criterion name="achievable">
**Achievable** - Technically feasible

Questions to ask:

- Do we have the technology to build this?
- Do we have the skills/resources?
- Are there known solutions to similar problems?

Red flags:

- Requirements that contradict each other
- Requirements needing unavailable technology
- Requirements exceeding physical limitations

Action:

- Flag unrealistic requirements for discussion
- Suggest alternatives if possible
</criterion>

<criterion name="relevant">
**Relevant** - Aligned with project goals

Questions to ask:

- Does this support the core problem statement?
- Who asked for this and why?
- What happens if we don't include it?

Red flags:

- Feature creep (nice-to-haves disguised as must-haves)
- Gold plating (over-engineering)
- Requirements without clear stakeholder need

Action:

- Challenge relevance of suspicious requirements
- Consider moving to Could-have or Out-of-scope
</criterion>

<criterion name="traceable">
**Traceable** - Linked to business need

Questions to ask:

- Why does this requirement exist?
- What user story or business need does it address?
- Can we trace it back to a stakeholder request?

Red flags:

- "We've always done it this way"
- Requirements without clear origin
- Technical preferences disguised as requirements

Better:

- Link requirements to user stories: "As a [user], I need [feature] so that [benefit]"
- Reference stakeholder interviews or feedback
</criterion>

</smart_criteria>

<priority_guidelines>
**Priority Distribution Guidelines**

Typical healthy distribution:

- **Must have**: ~60% of requirements
- **Should have**: ~20% of requirements
- **Could have**: ~15% of requirements
- **Won't have**: ~5% (explicitly documented exclusions)

Warning signs:
>
- > 80% Must-haves: Everything can't be critical; reassess
- < 40% Must-haves: Is the core unclear?
- No Could-haves: Missing opportunity for stretch goals
- No Won't-haves: Scope boundaries undefined
</priority_guidelines>

<common_issues>
**Common Quality Issues**

<issue name="compound_requirements">
**Compound Requirements**
One requirement doing too much.

Bad: "The system shall authenticate users and log all activities and send notifications"

Better: Split into three separate requirements, each testable independently.
</issue>

<issue name="implementation_details">
**Implementation in Requirements**
Specifying HOW instead of WHAT.

Bad: "Use PostgreSQL to store user data in a users table"

Better: "User data must be persisted with ACID compliance"
</issue>

<issue name="missing_edge_cases">
**Missing Edge Cases**
Happy path only, no error handling.

Questions to ask:

- What if the input is invalid?
- What if the service is unavailable?
- What if the user cancels mid-operation?
</issue>

<issue name="assumed_knowledge">
**Assumed Knowledge**
Requirements that assume reader context.

Bad: "Support the standard export format"

Better: "Export data in CSV format per RFC 4180"
</issue>
</common_issues>
