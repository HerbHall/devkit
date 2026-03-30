# Samverk Issue Creation Guide

## Required Title Format

`<type>(<scope>): <description>`

Valid types: `feat`, `fix`, `chore`, `docs`, `test`, `ci`, `style`, `refactor`

## Agent Routing by Title Prefix

| Prefix | Assigned agent_type |
|--------|-------------------|
| `feat:` / `fix:` | `code-gen` |
| `docs:` / `chore:` | `docs` |
| `test:` | `test` |
| `ci:` | `code-gen` |

## Required Schema Block

Every issue body must begin with:

````yaml
---
schema_version: 1.1.0
type: task
agent_type: <code-gen|docs|test|human>
priority: <critical|high|normal|low>
---
````

## Required Body Sections

- **## Summary** — 1-3 sentences describing what the issue accomplishes
- **## Background** — why this is needed (omit if self-evident from title)
- **## Acceptance Criteria** — checklist of what "done" means

## Dispatcher-Ready Checklist

- [ ] Title follows `<type>(<scope>): <description>` format
- [ ] Schema block present with `agent_type` and `priority`
- [ ] `## Acceptance Criteria` section present with verifiable items
- [ ] No unresolved blockers (`status:blocked` issues are excluded from dispatch)
- [ ] Labels applied: `agent:code-gen` / `agent:human` / `agent:docs` / `agent:test`

## Label Reference

| Label | Meaning |
|-------|---------|
| `priority:critical` | Must ship before any other work |
| `priority:high` | Schedule next available slot |
| `priority:normal` | Standard queue |
| `priority:low` | Nice to have |
| `status:needs-qc` | Implementation done, awaiting verification |
| `status:needs-human` | Requires human interaction |
| `status:blocked` | Waiting on dependency or decision |
| `complexity:local` | Runs on local Claude Code agent |
| `complexity:cloud` | Requires cloud agent or remote execution |
