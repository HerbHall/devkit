<template name="epic_issue">

Use this template for parent/epic issues that group related sub-tasks.
Replace all `{PLACEHOLDER}` values with actual content.

```markdown
## Overview

{High-level description of the epic. What capability does this deliver when all sub-tasks are complete?}

**Phase/Milestone:** {Phase or milestone name}
**Requirements Reference:** [{DOC_NAME}]({DOC_PATH})

## Task Checklist

- [ ] #{ISSUE_NUM} {Sub-task 1 title}
- [ ] #{ISSUE_NUM} {Sub-task 2 title}
- [ ] #{ISSUE_NUM} {Sub-task 3 title}
- [ ] #{ISSUE_NUM} {Sub-task 4 title}

## Acceptance Criteria

- [ ] All sub-tasks completed and merged
- [ ] Integration tested end-to-end
- [ ] Documentation updated if applicable

## Notes

{Dependencies between sub-tasks, suggested implementation order, or architectural context.}
```

</template>

<guidelines>

When using this template:

- Create the sub-task issues FIRST, then reference them by number in the checklist
- Keep epics to 3-8 sub-tasks; if more, create intermediate epics
- Sub-tasks should be independently mergeable
- Update the checklist as sub-tasks are completed (GitHub auto-tracks progress)
- Add the epic issue number to each sub-task's "Related Issues" section
- If the project has no formal requirements docs, reference the roadmap instead

</guidelines>
