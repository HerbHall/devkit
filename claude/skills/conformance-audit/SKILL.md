---
name: conformance-audit
description: Cross-project conformance auditing against DevKit standards. Full audits, single-project checks, and auto-fix of common gaps.
user_invocable: true
---

# Conformance Audit

Cross-project conformance auditing against DevKit standards. Run a 16-point checklist across all projects, audit a single project, or auto-fix common gaps.

<essential_principles>

**The 16-point checklist is the single source of truth for conformance.** All audit workflows reference `references/checklist.md` for check definitions, pass criteria, and fix references. Do not invent checks outside this list.

**Stack detection determines which checks apply.** Go projects need `.golangci.yml`, Rust needs clippy in CI, Node needs `eslint.config.js`, etc. Checks that do not apply to the detected stack are reported as "skip", not "fail".

**Audits are read-only by default.** The full-audit and single-project workflows only read files and report findings. The fix-gaps workflow is the only one that writes files.

**DevSpace path comes from `.devkit-config.json`.** Read the `devspacePath` field from `~/.devkit-config.json` (or the DevKit project root) to locate the workspace root. All project discovery starts from this path.

</essential_principles>

<intake>
**conformance-audit triggered.** What kind of conformance audit do you need?

1. **Full audit** -- Run 16-point conformance check across all projects
2. **Single project** -- Audit one specific project
3. **Fix gaps** -- Auto-fix common conformance gaps for a project

Type a number, project name, or **skip** to dismiss.

> Note: This skill blocks on user input. If triggered unintentionally,
> type **skip** or **dismiss** to cancel.
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "full audit", "all projects", "cross-project" | workflows/full-audit.md |
| 2, "single project", "check project", a project name | workflows/single-project.md |
| 3, "fix gaps", "remediate", "apply fixes", "scaffold" | workflows/fix-gaps.md |

If the input does not clearly match any option above, respond:
"conformance-audit was triggered but your input didn't match a workflow. Options: 1-3 (listed above). Type **skip** to dismiss."

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>

- Read, Glob, Grep (for file inspection and discovery)
- Bash (gh, git, ls, cat, grep, cp, mkdir)

</tool_restrictions>
