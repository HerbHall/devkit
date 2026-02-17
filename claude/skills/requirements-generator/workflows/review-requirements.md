<required_reading>
**Read these reference files NOW:**
1. references/quality-checklist.md
</required_reading>

<process>

**Step 1: Read Requirements Document**

Read the requirements.md file to review.

**Step 2: Structure Audit**

Check for required sections:
- [ ] Project Overview present and complete
- [ ] Stakeholders identified
- [ ] Constraints documented
- [ ] Functional requirements section exists
- [ ] Non-functional requirements section exists
- [ ] Technical requirements section exists
- [ ] Acceptance criteria present
- [ ] Out of scope section exists
- [ ] Changelog with valid version

**Step 3: Quality Audit**

For each requirement, verify using quality checklist:
- **Specific**: Is the language clear and unambiguous?
- **Measurable**: Can this be verified through testing?
- **Achievable**: Is this technically feasible?
- **Relevant**: Does this align with project goals?
- **Traceable**: Is there a clear business need?

**Step 4: Priority Audit**

Check MoSCoW assignments:
- Are Must-haves truly critical?
- Are Should-haves correctly prioritized?
- Are there too many Must-haves? (typical ratio: 60% Must, 20% Should, 20% Could)
- Is anything missing priority assignment?

**Step 5: Completeness Audit**

Check for gaps:
- Do all Must/Should requirements have acceptance criteria?
- Are edge cases considered?
- Are error handling requirements defined?
- Are security requirements addressed (if applicable)?
- Are performance requirements specified (if applicable)?

**Step 6: Generate Report**

Present findings organized by severity:

**Critical Issues** (must fix)
- Missing required sections
- Requirements without priorities
- Must-haves without acceptance criteria

**Warnings** (should fix)
- Vague or ambiguous requirements
- Missing non-functional requirements
- Unbalanced priority distribution

**Suggestions** (could improve)
- Requirements that could be more specific
- Potential missing edge cases
- Documentation improvements

**Step 7: Offer to Fix**

Ask user:
"Would you like me to help fix any of these issues?"

If yes, switch to update-requirements workflow for each fix.

</process>

<success_criteria>
This workflow is complete when:
- [ ] Document structure audited
- [ ] Each requirement quality-checked
- [ ] Priority distribution analyzed
- [ ] Completeness gaps identified
- [ ] Report presented to user
- [ ] User has actionable next steps
</success_criteria>
