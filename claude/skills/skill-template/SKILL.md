---
name: SKILL_NAME
description: SKILL_DESCRIPTION
user_invocable: true
---

# SKILL_NAME

<essential_principles>

- Describe the core principles and best practices for this skill
- When to use it, what problems it solves

</essential_principles>

<intake>

What would you like to do?

1. FIRST_ACTION
2. SECOND_ACTION
3. THIRD_ACTION

Type a number, keyword, or **skip** to dismiss.

</intake>

<routing>

| Response | Workflow |
|----------|----------|
| 1, "first", "one" | workflows/first-action.md |
| 2, "second", "two" | workflows/second-action.md |
| 3, "third", "three" | workflows/third-action.md |

If the user types **skip** or **dismiss**, confirm cancellation and end the skill.
If the input does not match, respond: "SKILL_NAME was triggered but your input didn't match a workflow. Options: 1-3. Type skip to dismiss."

**After reading the workflow, follow it exactly.**

</routing>

<workflows_index>

- first-action.md: Description of first action
- second-action.md: Description of second action
- third-action.md: Description of third action

</workflows_index>

## Version

- v0.1.0 (YYYY-MM-DD): Initial template

## Changelog

- v0.1.0: Created initial template
