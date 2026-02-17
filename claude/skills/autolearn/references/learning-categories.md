# Learning Categories

Classification guide for categorizing learnings by type, priority, and storage action.

## Category Definitions

### CORRECTIONS (Highest Priority)

Mistakes made and subsequently fixed. These are the most valuable learnings because they prevent future errors.

**Store as:** `Correction` entity in MCP Memory + entry in `rules/autolearn-patterns.md`

**Examples:**
- Build failures and their fixes
- Lint errors and their solutions
- Test failures and root causes
- CI/CD configuration mistakes
- Incomplete refactoring (missed variable references)
- Wrong API usage corrected

**Confidence Threshold:** Always HIGH when a clear mistake-fix pair is identified.

### PATTERNS (High Priority)

Reusable approaches that work well. These speed up future work.

**Store as:** `Pattern` entity in MCP Memory + entry in `rules/autolearn-patterns.md`

**Examples:**
- Code patterns that work well in this ecosystem
- Testing patterns and fixture approaches
- Git workflow patterns (rebase strategy, PR flow)
- Tool usage patterns (CLI flags, configuration)
- Architecture patterns (interface design, dependency injection)

**Confidence Threshold:** HIGH if confirmed working in production/CI. MEDIUM if only tested locally.

### GOTCHAS (High Priority)

Surprising behaviors or platform-specific issues. These prevent wasted debugging time.

**Store as:** `Gotcha` entity in MCP Memory + entry in `rules/known-gotchas.md`

**Examples:**
- Platform-specific issues (Windows/MSYS, macOS, Linux differences)
- Library quirks and version incompatibilities
- CI environment differences from local dev
- Configuration pitfalls (YAML indentation, JSON escaping)
- Tool behavior differences across versions

**Confidence Threshold:** HIGH if reproducible. MEDIUM if intermittent or environment-dependent.

### DECISIONS (Medium Priority)

Architectural or design choices with their rationale. These maintain consistency.

**Store as:** `Decision` entity in MCP Memory (not in rules files -- too context-specific)

**Examples:**
- Architecture choices with rationale (why this pattern over alternatives)
- Library selection decisions (why library X over Y)
- Convention adoption reasons (why this commit format, branch naming)
- Trade-off resolutions (performance vs. readability, simplicity vs. flexibility)

**Confidence Threshold:** Always MEDIUM unless the decision has been validated in production.

### PREFERENCES (Store Once)

User workflow and style preferences. These ensure consistency across sessions.

**Store as:** `Preference` entity in MCP Memory + entry in `rules/workflow-preferences.md`

**Examples:**
- Coding style preferences (formatting, naming)
- Commit message format conventions
- Branch naming conventions
- Tool preferences (which CLI tools, which editors)
- Communication style preferences

**Confidence Threshold:** Always HIGH (user-stated preferences are definitive).

## Priority Matrix

| Category | Store in Memory? | Store in Rules? | Auto-detect? | Manual /reflect? |
|----------|-----------------|----------------|-------------|-----------------|
| Correction | Yes | Yes (patterns) | Yes (Stop hook) | Yes |
| Pattern | Yes | Yes (patterns) | Sometimes | Yes |
| Gotcha | Yes | Yes (gotchas) | Yes (Stop hook) | Yes |
| Decision | Yes | No | Sometimes | Yes |
| Preference | Yes | Yes (preferences) | No | Yes |

## Deduplication

Before storing any learning:
1. Search MCP Memory for existing entities with similar names/descriptions
2. If a match exists, add an observation instead of creating a new entity
3. If the existing entity is outdated, add a new observation noting the update
4. Use `SUPERSEDES` relation if a learning completely replaces an older one
