---
name: doc-review
description: Documentation review and governance. Audit document structure against schemas, check link integrity, detect staleness, find cross-document contradictions, and auto-fix formatting. Machine-first -- validates structure and accuracy, not prose quality.
user_invocable: true
---

# Documentation Review

Review documentation quality against `doc-schemas.yaml` write contracts. Audit structure, verify links, detect staleness, find contradictions, and auto-fix formatting.

<essential_principles>

**Documents are machine-first.** Written by and consumed by agents. Structure and semantic accuracy matter. Prose quality, readability, and tone do not. Never flag style issues.

**Schemas are write contracts, not just validators.** `doc-schemas.yaml` defines what agents must produce, not just what validators check. A missing required section means the producing agent failed its contract.

**Severity determines action.** Critical/High findings block. Medium findings accumulate (3+ triggers REVISE). Low findings are informational. See the doc-reviewer agent for the full severity guide.

**Fresh context for deep review.** Single-file and audit workflows spawn the `doc-reviewer` agent with no conversation history. The agent evaluates documents independently.

**Graceful degradation.** If Synapset is unavailable, consistency checks fall back to structural comparison. If lychee is not installed, link checks use grep-based fallback. The skill never fails because an optional tool is missing.

</essential_principles>

<intake>
**doc-review triggered.** What kind of documentation review do you need?

1. **Audit** -- Full project scan against doc-schemas.yaml
2. **Single file** -- Deep review of one document
3. **Fix formatting** -- Auto-correct markdown formatting issues
4. **Stale check** -- Find docs not updated while code changed
5. **Summary** -- Human digest of documentation health
6. **Consistency** -- Cross-document contradiction scan

Type a number, a file path (for single-file review), or **skip** to dismiss.

> Note: This skill blocks on user input. If triggered unintentionally,
> type **skip** or **dismiss** to cancel.
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "audit", "full audit", "scan", "all docs" | workflows/audit.md |
| 2, "single", "review", a file path ending in `.md` | workflows/single-file.md |
| 3, "fix", "format", "fix formatting", "auto-fix" | workflows/fix-formatting.md |
| 4, "stale", "freshness", "outdated", "old docs" | workflows/stale.md |
| 5, "summary", "digest", "overview", "health" | workflows/summary.md |
| 6, "consistency", "contradictions", "conflicts", "cross-doc" | workflows/consistency.md |

If the user provides a file path (contains `/` or `\` and ends with `.md`), route to `workflows/single-file.md` with the path as context.

If the user types **skip** or **dismiss**, briefly confirm cancellation (e.g., "doc-review cancelled.") and end the skill without running any workflow.

If the input does not clearly match any option above and is not "skip" or "dismiss", respond:
"doc-review was triggered but your input didn't match a workflow. Options: 1-6 (listed above), or provide a file path. Type **skip** to dismiss."

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>

- Read, Glob, Grep (for file inspection and discovery)
- Bash (git log, markdownlint-cli2, lychee, grep, find)
- Agent (for spawning doc-reviewer agent in single-file and audit workflows)

</tool_restrictions>

<schema_location>

The document type schemas are at: `D:\DevSpace\Toolkit\devkit\devspace\templates\doc-schemas.yaml`

Read this file at the start of any workflow that needs type detection or structure validation. The schema defines `filename_patterns` for auto-detection and `sections` arrays for structure validation.

</schema_location>

<usage_recording>

After selecting a workflow, record the invocation per `claude/shared/record-usage.md`.

</usage_recording>
