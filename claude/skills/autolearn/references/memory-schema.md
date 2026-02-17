# MCP Memory Schema for Autolearn

Standard entity types, relation types, and observation formats for the autolearn knowledge graph.

## Entity Types

| Type | Purpose | Example Name |
|------|---------|-------------|
| Pattern | Reusable code or workflow pattern | `go-range-index-iteration` |
| Gotcha | Surprising behavior or common mistake | `msys-path-translation` |
| Decision | Architectural or design choice with rationale | `consumer-side-interfaces` |
| Correction | Mistake made and how it was fixed | `incomplete-loop-var-replacement` |
| Preference | User workflow or style preference | `branch-per-issue-workflow` |
| SkillUpdate | Record of a skill being improved | `quality-control-ci-patterns-update` |
| Project | Project context for linking learnings | `netvantage` |

## Relation Types

| Relation | From -> To | Purpose |
|----------|-----------|---------|
| DISCOVERED_IN | Learning -> Project | Links a learning to the project where it was found |
| FIXES | Correction -> Error | Links a correction to the error type it addresses |
| PREVENTS | Pattern/Gotcha -> Error | Links knowledge that prevents a class of errors |
| IMPROVES | SkillUpdate -> Skill | Links a skill update to the skill it enhances |
| RELATED_TO | Any -> Any | General association between entities |
| SUPERSEDES | Learning -> Learning | Newer learning replaces older one |

## Observation Format

When adding observations to entities, use this structure:

```
[YYYY-MM-DD] (source: <project|global>) (confidence: HIGH|MEDIUM|LOW) (category: <type>)
<description of the observation>
```

Example:
```
[2026-02-02] (source: netvantage) (confidence: HIGH) (category: correction)
gosec G101 flags constants with "credential" in the name as hardcoded credentials.
Fix: add //nolint:gosec // G101: <reason> comment.
```

## Entity Creation Guidelines

### When to Create a NEW Entity
- First time encountering this type of issue/pattern
- No existing entity covers this specific topic
- Search MCP Memory first: `search_nodes` with relevant keywords

### When to Add an OBSERVATION to Existing Entity
- Same issue encountered again in different context
- Additional detail or nuance discovered
- Confirmation that the pattern still applies

### When to Create RELATIONS
- A correction directly fixes a known error type
- A pattern was discovered while working in a specific project
- A skill update was motivated by a recurring mistake

## Naming Conventions

- Use lowercase kebab-case for entity names: `go-range-index-iteration`
- Prefix project entities with the project name: `netvantage`
- Keep names descriptive but concise (3-5 words)
- Avoid version numbers or dates in entity names (use observations for temporal data)
