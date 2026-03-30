---
name: autolearn
description: Reflect on the current session to extract learnings, update knowledge, and improve skills.
user_invocable: true
---

# Autolearn: Reflect

Deliberate retrospective analysis for continuous improvement. Extracts learnings from the current session and stores them in MCP Memory and rules files.

<essential_principles>

**Learning Hierarchy**

1. CORRECTIONS -- Mistakes made and fixed (highest value)
2. GOTCHAS -- Surprising behaviors or platform issues
3. PATTERNS -- Reusable approaches that work well
4. DECISIONS -- Architectural choices with rationale
5. PREFERENCES -- User workflow and style preferences

**Storage Targets**

- **MCP Memory**: All learnings (persistent knowledge graph across sessions)
- **Rules files** (`~/.claude/rules/`): Patterns, gotchas, and preferences (auto-loaded every session)
- Rules files are the fast path -- they're injected into every session automatically
- MCP Memory is the deep store -- searchable, relational, comprehensive

**Scope-Aware Routing**

Storage depends on WHERE the session is running:

- **In DevKit repo** (`.sync-manifest.json` present): Create a feature branch, write Tier 2 rules, commit, push, and open a PR. DevKit is the source of truth but all changes still go through branch/PR — never commit directly to main.
- **In any other project**: Write to MCP Memory only. For stack-specific or universal learnings, create a DevKit issue via the Samverk MCP `create_issue` tool (`project: devkit`) so the learning can be reviewed and promoted to rules files through a PR.

This prevents projects from modifying symlinked rules files directly. Symlinks provide READ access to DevKit rules; writing flows through issues.

**CRITICAL: Never commit to main.** Even Tier 2 autolearn entries must go through a branch and PR. This applies in DevKit itself and in every other project.

**Deduplication is Critical**

- Always search MCP Memory before creating entities: `search_nodes` with relevant keywords
- If an entity exists, add an observation instead of creating a duplicate
- Read rules files before appending to avoid duplicate entries

**Context Sensitivity**

- Only extract learnings that are genuinely reusable across sessions
- Don't store trivial or one-off observations
- Focus on knowledge that would have saved time if known earlier

</essential_principles>

<references>
- references/memory-schema.md -- Entity types, relation types, observation format
- references/learning-categories.md -- Classification guide with priority and confidence thresholds
- references/validation-pipeline.md -- Five-stage validation gate for proposed rules
</references>

<routing>

This skill runs **autonomously** -- no menu, no user input required. It selects
the appropriate workflow based on args (if provided) or session context analysis.

## Arg-Based Routing (explicit)

When invoked with an argument (`/autolearn <arg>`), route directly:

| Arg | Workflow |
|-----|----------|
| `reflect` | workflows/quick-reflect.md |
| `review` | workflows/session-review.md |
| `update` | workflows/update-knowledge.md |
| `improve` | workflows/skill-improvement.md |
| `audit` | workflows/audit-rules.md |

## Context-Based Routing (no args)

When invoked without args (bare `/autolearn` or triggered autonomously after
a task), analyze the session to select the best workflow:

| Session Signal | Workflow | Rationale |
|---------------|----------|-----------|
| Short session, 1-2 tasks, few corrections | `quick-reflect` | Fast capture, minimal overhead |
| Long session, multiple tasks, several corrections/gotchas | `session-review` | Comprehensive extraction justified |
| Many MCP Memory entries not yet in rules files (DevKit context) | `update-knowledge` | Rules files need sync |
| Recurring mistakes across session (same error type 2+ times) | `skill-improvement` | Systemic fix needed |
| No specific learnings but rules files are stale (DevKit context) | `audit-rules` | Maintenance opportunity |

**Default**: If signals are ambiguous, use `quick-reflect`. It is the lightest
workflow and always appropriate.

## Autonomous Trigger Guidelines

This skill may be triggered autonomously (not just by `/autolearn`) when:

- A task completes and corrections, gotchas, or notable patterns were encountered
- The session is ending (user signals they are done or conversation is long)
- A significant architectural decision was made with rationale worth preserving

When running autonomously, announce briefly what you are doing:
`"Capturing learnings from this task."` -- then proceed with the workflow.
Do not ask for permission. Do not show a menu.

**After selecting and reading the workflow, follow it exactly.**

</routing>

<tool_restrictions>

- MCP Memory tools: create_entities, create_relations, add_observations, search_nodes, read_graph
- File tools: Read, Edit, Write (for rules files only)
- Glob, Grep (for searching existing rules/skills)
</tool_restrictions>

<usage_recording>

After selecting a workflow, record the invocation per `claude/shared/record-usage.md`.

</usage_recording>
