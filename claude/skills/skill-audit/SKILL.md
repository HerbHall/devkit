---
name: skill-audit
description: Audit all DevKit skills for quality issues — silent wait states, missing dismiss routing, broken file references, frontmatter problems, and rules file metadata drift. Use standalone or as part of conformance-audit.
user_invocable: true
---

# Skill Audit

Quality checklist for DevKit skill files. Detects structural issues that cause stalls, broken routing, or silent failures.

<essential_principles>

**What This Detects**

1. **Silent wait states** — An `<intake>` section that blocks on user input without visible acknowledgment text before the prompt
2. **Missing skip/dismiss routing** — Intake mentions "skip" or "dismiss" but the `<routing>` table has no cancel entry
3. **Overly broad triggers** — `description` field contains generic words that match on pasted content (e.g., "code", "fix", "help")
4. **Broken cross-references** — Workflow files referenced in `<routing>` tables that do not exist on disk
5. **YAML frontmatter issues** — Missing `name`, `description`, or `user_invocable` fields
6. **Rules file entry_count drift** — `entry_count` in YAML frontmatter does not match actual entry count in rules files

</essential_principles>

<intake>
**skill-audit triggered.** What would you like to audit?

1. **All skills** — Run the full checklist against every skill in `claude/skills/`
2. **Single skill** — Audit one specific skill by name
3. **Rules metadata** — Check entry_count and frontmatter in rules files only

Type a number, skill name, or **skip** to dismiss.
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "all skills", "full audit", "all" | workflows/audit-all.md |
| 2, a skill name, "single" | workflows/audit-single.md |
| 3, "rules", "metadata", "entry_count" | workflows/audit-rules-metadata.md |

If the user types **skip** or **dismiss**, briefly confirm cancellation (e.g., "skill-audit cancelled.") and end the skill without running any workflow.

If the input does not clearly match any option above and is not "skip" or "dismiss", respond:
"skill-audit was triggered but your input didn't match a workflow. Options: 1-3 (listed above). Type **skip** to dismiss."

**After reading the workflow, follow it exactly.**
</routing>

<workflows_index>

| Workflow | Purpose |
|----------|---------|
| audit-all.md | Run all checks against every skill in `claude/skills/` |
| audit-single.md | Run all checks against a single named skill |
| audit-rules-metadata.md | Verify entry_count frontmatter in rules files |

</workflows_index>
