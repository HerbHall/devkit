---
phase: active-maintenance
updated: 2026-03-08T01:00:00Z
updated_by: claude-code
---

# DevKit -- Current State

## Phase

Active maintenance: AI tooling methodology, Claude Code configuration toolkit.
Latest: verify.ps1 implemented, skill-audit added, Gitea CI fallback.

## What Is Running

- Symlinked rules loaded by all Claude Code sessions via ~/.claude/
- 21 skills, 7 agents, 8 rules files, 135+ patterns
- SessionStart hook for context injection

## In Flight

- No active work

## Queued

- No open issues -- backlog driven by cross-project conformance needs

## Last Session Summary

Implemented verify.ps1 (Kit 4), added KG#101 (Edit tool CRLF),
KG#102 (dispatcher false-positive), skill-audit conformance tool,
and Gitea CI graceful fallback for quality-control.

## Start Here (Cold Start Protocol)

1. Read this file
2. Samverk MCP not yet configured for this project -- skip step 2
3. Read open issues if relevant to the task
4. Proceed -- do not ask the user to explain project state
