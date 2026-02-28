---
name: reflect
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

- **In DevKit repo** (`.sync-manifest.json` present): Write Tier 2 rules directly. DevKit is the source of truth.
- **In any other project**: Write to MCP Memory only. For stack-specific or universal learnings, create a DevKit issue (`gh issue create -R HerbHall/devkit`) so the learning can be reviewed and promoted to rules files through a PR.

This prevents projects from modifying symlinked rules files directly. Symlinks provide READ access to DevKit rules; writing flows through issues.

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
</references>

<intake>
What would you like to reflect on?

1. **Quick reflect** -- Fast end-of-task assessment (what worked, what didn't, store key learnings)
2. **Session review** -- Comprehensive session retrospective with full MCP Memory sync
3. **Update knowledge** -- Merge accumulated learnings into rules files
4. **Skill improvement** -- Analyze past mistakes and improve existing skills/agents

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "quick", "fast", "brief" | workflows/quick-reflect.md |
| 2, "session", "review", "comprehensive", "full" | workflows/session-review.md |
| 3, "update", "knowledge", "rules", "merge" | workflows/update-knowledge.md |
| 4, "skill", "improve", "agent", "fix" | workflows/skill-improvement.md |

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>

- MCP Memory tools: create_entities, create_relations, add_observations, search_nodes, read_graph
- File tools: Read, Edit, Write (for rules files only)
- Glob, Grep (for searching existing rules/skills)
</tool_restrictions>
