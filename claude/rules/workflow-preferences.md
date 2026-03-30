---
description: User workflow preferences and conventions. Read at session start for context.
tier: 1
last_updated: "2026-03-01"
entry_count: 16
---

# Workflow Preferences

Conventions and preferences established by the user across sessions.

## 1. Branch-per-Issue Workflow

Every GitHub issue gets its own branch. Never commit directly to main.

- Branch naming: `feature/issue-NNN-desc`, `fix/issue-NNN-desc`, `refactor/issue-NNN-desc`
- Create PR via `gh pr create` after work is complete
- Merge only after CI passes

## 2. Conventional Commits

Commit messages use conventional commit format:

- `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- Co-author tag: `Co-Authored-By: Claude <noreply@anthropic.com>`
- Use HEREDOC for multi-line commit messages

## 3. Explore-Plan-Code-Commit Flow

Always follow: Explore (read files) -> Plan (design approach) -> Code (implement) -> Commit (with clear messages).

- Use `/create-plan` for multi-file features
- Get plan approval before implementing
- Use subagents for exploration to conserve context

## 4. Context Conservation

- Read ONE requirement file at a time (never multiple)
- Use Explore agents for codebase questions (not direct Glob/Grep from main context)
- Delegate research to subagents
- Store cross-session knowledge in MCP Memory

## 5. Testing Approach

- Table-driven tests in Go
- Use `testutil.NewStore(t)` for in-memory SQLite test databases
- Use fixture builders (e.g., `testutil.NewDevice()`)
- Run `go test -race ./...` for race detection
- Verify with `go build ./...` and `go vet ./...` before committing

## 6. Pre-PR Docker QC Gate

For significant features (new modules, API changes, UI additions):

- Run `make docker-qc` to build from local source with seed data
- Browse `http://localhost:8080` and verify the feature works in a container
- Run `make docker-qc-smoke` for automated endpoint verification
- Run `make docker-qc-down` to tear down
- Skip for docs-only, test-only, or lint-fix changes

This catches runtime issues (missing embeds, config collisions, broken routes) that unit tests and CI can't. Faster feedback loop than waiting for CI.

## 7. CI Verification

- Always verify CI passes after pushing
- Use `/quality-control` skill for PR health checks
- Fix shared/pre-existing failures first (unblocks multiple PRs)
- Reference `ci-failure-patterns.md` for known CI issues

## 8. Autonomous Subagent Plan Execution

- Split features into 2-3 atomic plans (2-3 tasks each)
- Execute each plan via autonomous subagent (`Task` tool, `subagent_type=general-purpose`)
- Each subagent gets fresh 200k context -- no bleed between plans
- Main context reserved for orchestration only (~5-10% usage per plan)
- Proven on Phase 01-topology: 3 plans, 7 tasks, 10 new files + 5 modified, 37 tests -- all clean on first pass
- **Wave execution**: Launch up to 3 agents in parallel per wave when files don't overlap. Sort changes into correct branches via stash/pop after all agents complete (see gotcha #25). Proven: v0.4.1 sprint, 2 waves x 3 agents = 6 PRs, 12 issues, all CI-green first pass.
- **Pre-wave hot-file audit**: Before launching parallel agents, read each issue's acceptance criteria and predict which files each agent will touch. Files that appear in 2+ agents' expected changes are "hot". Pass `[HOT-FILES]` block (from `subagent-ci-checklist.md`) to ALL agents listing hot files -- agents report bugs in hot files but do NOT fix them. Also run tests on current main and tell agents which tests are already failing so multiple agents don't independently fix the same pre-existing failure.
- **Post-wave worktree cleanup**: After all parallel agents complete, run `git worktree list` and `git worktree remove <path> --force` for each stale entry, then `git worktree prune` -- BEFORE any git push. Stale worktrees from agent isolation cause pre-push hooks to fail (see AP#127).

## 9. Global CLAUDE.md Scope

- Keep references to all MCP tools/services that might be available in any project setup, even if not currently active in this session
- Only remove references that are definitively retired
- Mark optional services with "(when authorized)" or similar availability notes
- Project-specific MCP docs go in the project's `.claude/CLAUDE.md`, not global

## 10. Shared Workspace Configuration

Use shared config files at `D:\DevSpace\` for cross-project consistency:

- `D:\DevSpace\.editorconfig` (`root = true`) -- cascades formatting rules to all projects and editors
- `D:\DevSpace\.markdownlint.json` -- shared markdown linting rules for all projects
- `D:\DevSpace\dev.code-workspace` -- multi-root VS Code workspace with shared settings
- Project-level `.editorconfig` uses `root = false` to inherit from `D:\DevSpace\` with optional overrides
- Archive inactive projects under `D:\archive\` to reduce clutter

## 11. Context Compaction Continuations

When resuming after context compaction with "continue where we left off":

- The compaction summary captures pending state -- trust it for file names, branch names, and agent outputs
- Check the todo list first -- it reflects current progress accurately
- Check `git status` and `git branch` to confirm actual working tree state before acting
- The plan file (if any) in system reminders provides the overall scope

## 12. Cross-Project Workspace Isolation

When working on cross-project tasks (e.g., DevKit sync from a SubNetree session):

- Verify no files are created or modified in the wrong project's repo
- Create GitHub issues in the correct repo (not the currently-open project)
- Check `git status` in both repos before closing the session
- Plan files and MCP Memory are global (not project-scoped) -- this is fine
- If the user asks to verify isolation, run `git status` in both project directories

## 13. Zero-Tolerance Error Policy

Once found, always fix, never leave. Every error is an opportunity to improve the system:

- No "pre-existing" bypass -- all errors get fixed or tracked with an issue immediately
- Every error triggers a systemic assessment: why didn't our rules prevent this?
- Learnings feed back to DevKit via `/autolearn` for all-project benefit
- Agents own every error they find, regardless of who introduced it

## 14. Mandatory Subagent Checklists

Every Task tool invocation for code-writing agents MUST include:

- Relevant CI checklist from `subagent-ci-checklist.md` ([GO-CI], [FE-CI], or [COMBO-CI])
- Git Safety block ([GIT-SAFE])
- Shared File Guard ([SHARED-FILE]) if running parallel agents
- Hot File Guard ([HOT-FILES]) if any files are touched by 2+ parallel agents -- fill in the file list before pasting
- Core principles reminder (Tier 0 rules are unconditional)
- Failure to include checklists is a DevKit policy violation

## 15. Autolearn Abstraction Assessment

After fixing errors or discovering patterns, assess abstraction level:

- Project-specific: stays in project rules
- Stack-specific (Go, React, etc.): promote to DevKit stack rules
- Universal development principle: promote to DevKit core rules
- Template-worthy: update project templates so future projects inherit it
- Run `/autolearn` to capture and propose promotion

## 16. Cross-Project Boundary: Issues Not Edits

When working in a project context (e.g., Samverk), do NOT directly edit files in other projects (e.g., DevKit). Instead:

- Create an issue in the other repo via the Samverk MCP `create_issue` tool (`project: <name>`, e.g. `devkit`, `samverk`, `synapset`)
- Include enough detail to reproduce/implement the fix
- The fix gets implemented when actively working in that project's context
- This prevents projects from becoming coupled and keeps sessions focused

## 17. Cross-Project Agent Boundary Protocol

When running parallel CC agents (one per project) in separate VS Code windows:

- **Read** across projects is always OK
- **Write** requires explicit user direction
- Three modes: (1) Issue (default) -- create in target repo, (2) Handoff -- provide summary for user to relay, (3) Direct access -- only when user confirms other agent is free
