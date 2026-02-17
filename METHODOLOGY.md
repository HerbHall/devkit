# Development Methodology

A standardized process for taking ideas from concept to release. Designed for a solo developer working with Claude Code across multiple concurrent projects.

## Principles

1. **Gate before you invest** — Each phase ends with a go/kill/pivot decision. Killing early saves weeks.
2. **Templates over memory** — Use the same artifacts every time so switching between projects is seamless.
3. **Learn forward** — Every session feeds the autolearn loop. Mistakes become patterns that prevent future mistakes.
4. **One tool per phase** — Don't combine tools that duplicate work. Pick the best fit for each phase and use it end-to-end.
5. **Minimum viable ceremony** — Only create artifacts that will actually be referenced. A concept brief can be 5 lines.

## Phases

### Phase 0: Concept

**Purpose**: Decide if an idea is worth researching.

**Time budget**: 30 minutes max.

**Artifact**: Concept brief (in project README or a `CONCEPT.md`)

**Template**:

```markdown
# [Project Name]

## Problem
What specific problem does this solve? Who has this problem?

## Proposed Solution
One paragraph describing the approach.

## Differentiator
Why would someone use this instead of existing alternatives?

## Kill Criteria
This project is NOT worth pursuing if:
- [ ] Criterion 1 (e.g., "an open-source tool already does this well")
- [ ] Criterion 2 (e.g., "requires a technology I can't learn in reasonable time")
- [ ] Criterion 3 (e.g., "market is too small to justify the effort")

## Effort Estimate
- Small (weekend project)
- Medium (2-4 weeks)
- Large (1+ months)
```

**Gate**: Review kill criteria honestly. If any are true, archive the concept. If effort exceeds your appetite, archive or scale down.

---

### Phase 1: Research

**Purpose**: Understand the landscape before committing to build.

**Time budget**: 1-4 hours depending on project size.

**Artifacts**:

- Competitive scan (who else does this, strengths/weaknesses)
- Technical feasibility check (can the core idea actually work?)
- User needs summary (what do real people say about this problem?)

**Tools**: `/research-mode` skill, GitHub search, blog aggregation, `gh api` for competitor analysis.

**Key questions**:

1. Who are the existing players? (Search GitHub by function, not product name)
2. What are their weaknesses? (Open issues sorted by comment count)
3. Is there a viable niche they don't cover?
4. What's the hardest technical challenge? Can I spike it?

**Gate**: Do you have a clear niche that isn't already well-served? Is the technical approach feasible? If no to either, kill or pivot.

---

### Phase 2: Specification

**Purpose**: Define what you're building precisely enough to implement without ambiguity.

**Time budget**: 2-8 hours depending on scope.

**Artifacts**:

- `REQUIREMENTS.md` — Functional and non-functional requirements
- `DECISIONS.md` — Design decisions with rationale (use ADR template for significant ones)
- `CLAUDE.md` — Project-specific build commands, architecture, conventions

**Tools**: `/requirements-generator` skill, ADR template from `.templates/`.

**Process**:

1. Write requirements as user-facing behaviors (Given/When/Then where helpful)
2. Identify open questions — anything ambiguous gets an explicit decision
3. Write decisions with rationale (future-you will thank present-you)
4. Set up CLAUDE.md so any Claude session can build and test the project

**Quality checklist** (borrowed from Spec Kit):

- [ ] Every requirement is testable (you can write a test for it)
- [ ] No implementation details in requirements (what, not how)
- [ ] Success criteria are measurable
- [ ] Scope is explicit (what's in MVP vs future phases)

**Gate**: Can you explain the MVP in one paragraph? Do you know what "done" looks like? If not, keep specifying.

---

### Phase 3: Prototype

**Purpose**: Validate the hardest technical risk before committing to full implementation.

**Time budget**: 1-3 days.

**Artifacts**:

- Working spike that proves the core concept
- Technical notes on what worked and what didn't
- Updated requirements if the prototype revealed new constraints

**Process**:

1. Identify the single hardest technical risk
2. Build the minimum code to prove or disprove it
3. Don't worry about code quality, tests, or architecture — this is throwaway
4. Document findings in a brief technical note

**Gate**: Did the prototype confirm the concept works? Three outcomes:

- **Continue**: Core idea works. Proceed to implementation.
- **Pivot**: Core idea doesn't work as planned, but a variation might. Return to Phase 2 with updated constraints.
- **Kill**: Fundamental blocker discovered. Archive the project.

---

### Phase 4: Implementation

**Purpose**: Build the product properly.

**Time budget**: Project-dependent.

**Artifacts**:

- Working software with tests
- CI/CD pipeline
- Feature-level specs (for complex features)

**Tools**: `/setup-github-actions` for CI, `/quality-control` for verification, subagent parallel execution for sprint waves.

**Process**:

1. Set up the project skeleton (git repo, CI, basic structure)
2. Break the MVP into features (3-7 features is typical)
3. For each feature:
   - Write a brief spec (what it does, acceptance criteria)
   - Implement with tests
   - Verify with `/quality-control`
   - Create PR, merge after CI passes
4. Use subagent parallel execution for independent features
5. Run Docker QC gate for significant features

**Conventions**:

- Branch-per-issue: `feature/issue-NNN-desc`
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- PR merge after CI passes
- Autolearn after each sprint wave

**Gate**: Does the MVP meet the success criteria from Phase 2? Run the full test suite, Docker QC, and manual verification.

---

### Phase 5: Release

**Purpose**: Ship it and capture learnings.

**Time budget**: 1-2 days.

**Artifacts**:

- README with installation, usage, and contributing instructions
- Release notes
- Session retrospective (autolearn)

**Process**:

1. Write/update README
2. Create GitHub release with changelog
3. Submit to relevant lists/directories (if applicable)
4. Run `/reflect` (session review) to capture all learnings
5. Update devkit repo if new patterns or skills were created

**Gate**: Is the README honest about what's shipped? Are the learnings captured? Ship it.

---

## Decision Framework

### When to Kill a Project

Kill if any of these are true:

- The kill criteria from Phase 0 were confirmed
- A well-maintained competitor covers 80%+ of your use case
- The core technical approach was disproven in prototyping
- You've lost interest and there's no external commitment

Killing is a success — you saved future time.

### When to Pivot

Pivot if:

- The problem is real but your solution approach doesn't work
- Research revealed a better niche than your original target
- The prototype worked but at a different scope than planned

Pivot means: return to Phase 1 or 2 with updated assumptions.

### When to Scale Back

Scale back if:

- The MVP is too large for your available time
- A smaller version still solves the core problem
- You're in Phase 4 and scope is creeping

IPScan is the cautionary example: a network scanner that grew into a full monitoring platform. The methodology prevents this by requiring explicit MVP scope in Phase 2.

## Cross-Project Learning

### How Patterns Accumulate

```text
Session work
  → /reflect captures learnings
    → MCP Memory (deep store, searchable)
    → Rules files (fast path, auto-loaded)
      → Next session starts with all accumulated knowledge
```

### Maintaining the devkit

After significant sessions, sync changes back:

```bash
# Copy updated rules
cp ~/.claude/rules/*.md /d/DevSpace/devkit/claude/rules/

# Copy new skills
cp -r ~/.claude/skills/new-skill /d/DevSpace/devkit/claude/skills/

# Commit
cd /d/DevSpace/devkit && git add -A && git commit -m "chore: sync patterns from [project]"
```

### When to Update the Methodology

Update METHODOLOGY.md when:

- A phase gate saved you from wasted work (document what triggered the kill/pivot)
- A phase was missing a useful artifact (add it)
- A phase had unnecessary ceremony (remove it)
- You discover a pattern that applies across all projects (add to principles)

The methodology should evolve. Version 1 is a starting point, not a final answer.

## Templates Reference

| Template | Location | Used In |
|----------|----------|---------|
| Concept brief | Inline above (Phase 0) | New project evaluation |
| ADR | `.templates/adr-template.md` | Significant design decisions |
| Design doc | `.templates/design-template.md` | Feature-level design |
| Test plan | `.templates/test-plan-template.md` | Complex testing scenarios |
| CLAUDE.md | `.templates/claude-md-template.md` | Every new project |
| Requirements | `/requirements-generator` skill | Phase 2 specification |

## Tool Selection Guide

| Need | Recommended Tool | Alternative |
|------|-----------------|-------------|
| Product-level planning (new project) | BMAD PM agent | Manual requirements writing |
| Feature specification | Manual spec with quality checklist | Spec Kit `/speckit.specify` |
| Implementation planning | Claude Code plan mode | Spec Kit `/speckit.plan` |
| Codebase investigation | BMAD Quick Spec (step 2) | Claude Code Explore agent |
| CI/CD setup | `/setup-github-actions` skill | Manual workflow writing |
| Code review | `/quality-control` skill | PR review plugins |
| Learning capture | `/reflect` (autolearn) | Manual rules file update |
| Competitive research | `/research-mode` skill | Manual GitHub/web research |

**Default**: Use Claude Code native capabilities (plan mode, subagents, skills) for most work. External tools (BMAD, Spec Kit) are optional supplements for complex scenarios.
