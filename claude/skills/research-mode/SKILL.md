---
name: research-mode
description: Activate competitive analysis and market research mode. Loads HomeLab research context, coordination protocol, and provides structured workflows for competitor deep-dives, market validation, and research need processing.
---

<essential_principles>

**Purpose**
This skill activates research mode for competitive analysis, market research, and integration feasibility studies. It bridges SubNetree development needs with HomeLab research output through the cross-project coordination system at `D:/DevSpace/.coordination/`.

**When to Use**
- Analyzing a competitor's codebase, releases, or community
- Validating market positioning or feature priorities
- Assessing integration feasibility for third-party tools
- Processing open research needs (RN-NNN) from SubNetree development
- Mapping the competitive ecosystem or adjacent tool landscape

**Context Loading**
At invocation, read these files (minimal context -- do NOT read all at once unless doing full sync):
1. `D:/DevSpace/.coordination/research-needs.md` -- Open RN-NNN requests from development
2. `D:/DevSpace/.coordination/priorities.md` -- Current priority stack
3. `D:/DevSpace/research/HomeLab/tracking/research-tracker.md` -- If it exists, research progress tracking

**Coordination Protocol**
- Research needs flow from SubNetree -> `research-needs.md` (RN-NNN format)
- Research findings flow from HomeLab -> `research-findings.md` (RF-NNN format)
- Decisions that span both projects go in `decisions.md` (D-NNN format)
- After publishing findings, remind user to run `/coordination-sync` to propagate

**Research Quality Standards**
1. **Evidence over opinion.** Every claim must cite a source (GitHub repo, issue, commit, community post).
2. **Quantify where possible.** Stars, forks, issue counts, release frequency, contributor count.
3. **Actionable output.** Every finding must include a recommended action for SubNetree.
4. **Recency matters.** Note dates on all data. A 2024 analysis may be stale by 2026.
5. **Search by function, not name.** Projects rename. Search "network topology visualization self-hosted" not "NetVisor".

</essential_principles>

<intake>
What research activity would you like to perform?

1. **Competitor deep-dive** -- Analyze a specific competitor's codebase, releases, issues, and community
2. **Market validation** -- Validate a feature idea or positioning against community demand and competitors
3. **Integration feasibility** -- Assess how feasible it is to integrate with a specific tool or protocol
4. **Process research needs** -- Work through open RN-NNN requests from SubNetree development
5. **Ecosystem mapping** -- Map the competitive landscape for a specific capability area

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "competitor", "deep-dive", "analyze", "compare" | workflows/competitor-deep-dive.md |
| 2, "market", "validate", "demand", "positioning" | workflows/market-validation.md |
| 3, "integration", "feasibility", "protocol", "compatible" | workflows/integration-feasibility.md |
| 4, "process", "research needs", "RN-", "open needs" | workflows/process-research-needs.md |
| 5, "ecosystem", "landscape", "mapping", "competitors" | workflows/ecosystem-mapping.md |

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>
- Bash: `gh` CLI for GitHub API queries, `git log` for local analysis
- Read, Edit, Write: For coordination files in `D:/DevSpace/.coordination/`
- Read: For HomeLab research files in `D:/DevSpace/research/HomeLab/`
- WebSearch, WebFetch: For community research
- MCP Memory: For storing research findings and competitor knowledge
- Grep, Glob: For searching existing research and coordination files
</tool_restrictions>
