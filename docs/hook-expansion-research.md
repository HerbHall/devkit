# Hook Expansion Research

Research document for issue #184: evaluating Claude Code hook types
beyond the current SessionStart implementation.

## Current State

### SessionStart.sh

The existing `SessionStart.sh` hook performs five functions:

1. **DevKit auto-pull** -- fetches latest DevKit commits from origin,
   rate-limited to once per hour. Skips when git lock file is present,
   working tree is dirty, or network is unavailable (5s timeout). Logs
   last 10 pull results to `~/.claude/.devkit-pull.log`.

2. **Version check** -- compares local `VERSION` file against
   `origin/main:VERSION`. Prints a notification only when a newer
   version is available.

3. **Symlink health check** -- validates that critical DevKit files
   (CLAUDE.md, 7 rules files) exist in `~/.claude/`. Reports broken
   symlinks and missing files with a remediation command.

4. **Rules drift detection** -- compares entry counts in
   `autolearn-patterns.md`, `known-gotchas.md`, and
   `workflow-preferences.md` between `~/.claude/rules/` and the DevKit
   clone. Warns when local and DevKit copies have diverged.

5. **CLAUDE.md detection** -- for project directories (identified by
   `.git`, `package.json`, `go.mod`, etc.), prompts the user once if
   `CLAUDE.md` or `.claude/settings.json` is missing.

### UserPromptSubmit Matcher

The current `UserPromptSubmit` hook uses the regex
`^(?!/)(?!\d{1,2}$)` to skip slash commands and bare numeric menu
selections (KG#10). It fires a `type: "prompt"` hook that passively
monitors for autolearn opportunities and suggests `/autolearn` when
notable patterns are discovered.

### Known Gotchas

Three existing gotchas document hook behavior:

- **KG#10**: `UserPromptSubmit` hooks block slash commands and menu
  selections. The matcher regex prevents this.
- **KG#32**: `SessionStart` hooks must use `type: "command"` (not
  `type: "prompt"`) to inject instructions. Prompts go to a small
  model that cannot interpret instructions.
- **KG#33**: Hooks cannot initiate conversation. Claude only sees hook
  output after the user sends their first message.

## Available Hook Types

| Hook Event | When It Fires | Current DevKit Usage |
|---|---|---|
| `SessionStart` | At session start | Auto-pull, version check, symlink health, drift detection, CLAUDE.md detection |
| `UserPromptSubmit` | When user submits a prompt | Autolearn nudge (passive) |
| `PreToolUse` | Before a tool is executed | None |
| `PostToolUse` | After a tool completes | None |
| `Notification` | On notifications | None |
| `Stop` | When the agent stops | None |
| `SubagentStop` | When a subagent stops | None |

Five of seven hook types are unused. The following sections evaluate
expansion opportunities for each.

## Evaluation of Each Opportunity

### a. Pre-Commit Hook Template

**Effort:** S | **Priority:** Medium

DevKit already provides a `pre-push` hook in `git-templates/hooks/`
that runs full CI checks (build, test, lint, markdownlint). A
pre-commit hook would serve a different purpose: lightweight checks
that run on every commit without the overhead of a full build.

**Candidate checks:**

- **Conventional commit message validation** -- verify the message
  matches `type(scope): description` format. Can be done with a
  simple regex in bash.
- **File size guard** -- reject files over a threshold (e.g., 10MB)
  to prevent accidental binary commits.
- **Secret scanning** -- grep for patterns like `AKIA`, `-----BEGIN
  RSA PRIVATE KEY`, API key formats. Lightweight regex-based, not a
  full secret scanner.
- **Trailing whitespace / CRLF check** -- catch formatting issues
  before they enter the repo.

**Analysis:** This is a git hook (not a Claude Code hook), so it
belongs in `git-templates/hooks/pre-commit`. It complements the
existing pre-push hook by catching simple issues early. The checks
must be fast (under 2 seconds) to avoid disrupting commit flow.

**Recommendation:** Implement as a separate issue. Add a
`git-templates/hooks/pre-commit` file with conventional commit
validation and secret scanning. File size guard is optional.

### b. UserPromptSubmit Patterns

**Effort:** M | **Priority:** High

The `UserPromptSubmit` hook fires before Claude processes the user's
input. Beyond the current autolearn nudge, several prompt-time checks
could add value.

**Candidate patterns:**

- **Library mention detection** -- when the user mentions a library
  name (e.g., "use recharts", "add MUI component"), a `type: "prompt"`
  hook could inject a reminder to check Context7 for current docs.
  Challenge: the small model evaluating the prompt must reliably detect
  library names, which requires a well-crafted prompt.

- **Large refactor detection** -- when the prompt suggests broad
  changes ("refactor all handlers", "rewrite the auth module"), inject
  a reminder to create a plan first via `/create-plan` or
  `/plan-review`. This aligns with the Explore-Plan-Code workflow.

- **Commit/push keyword detection** -- when the user says "commit
  this" or "push to remote", inject a reminder about verification
  (build, test, lint must pass first). This reinforces Core
  Principle #2.

- **Dangerous operation detection** -- when the prompt contains "force
  push", "reset hard", or "delete branch", inject a safety warning.
  This reinforces Core Principle #4.

**Analysis:** Multiple prompt-time hooks can coexist under
`UserPromptSubmit` as separate entries in the hooks array, each with
its own `matcher` regex and prompt. The main risk is over-triggering:
too many injected reminders create noise and train the user to ignore
them. Start with one high-value pattern (commit/push verification
reminder) and measure adoption before adding more.

**Recommendation:** Implement commit/push keyword detection first.
The matcher `(?i)(commit|push|merge)` with a prompt reminding about
pre-commit verification is high-value and low-risk. Library detection
is interesting but harder to get right with the small model.

### c. Notification Hooks

**Effort:** M | **Priority:** Medium

The `Notification` hook fires when Claude Code generates notifications.
This includes context window pressure warnings.

**Candidate uses:**

- **Context pressure detection** -- when a notification indicates the
  context window is nearing capacity, a hook could inject a reminder
  to run `/autolearn` before compaction erases learnings. This directly
  addresses the compaction recovery rules.

- **Coordination context surfacing** -- inject relevant coordination
  context (e.g., pending research needs from `.coordination/`) when
  notifications indicate a topic change or new task. Challenge: the
  notification content may not contain enough semantic information to
  determine relevance.

**Analysis:** The value of notification hooks depends heavily on what
notification content is available. If context window pressure
notifications include a clear signal (e.g., percentage used), the
`/autolearn` reminder is straightforward and high-value. Coordination
context surfacing is speculative without knowing the notification
payload format.

**Recommendation:** Investigate what notification events Claude Code
actually emits. If context pressure notifications exist, implement
the `/autolearn` reminder. Defer coordination surfacing until the
notification payload is better understood.

### d. SubagentStop Hooks

**Effort:** M | **Priority:** High

The `SubagentStop` hook fires when a subagent (launched via `Task`
tool) completes. This is a natural verification checkpoint.

**Candidate uses:**

- **Automatic lint check** -- after a subagent finishes writing code,
  run `golangci-lint` or `eslint` on modified files. This catches
  violations before the main context reviews the output.

- **Unstaged file inventory** -- run `git status` and report new or
  modified files, helping the main context sort parallel agent output
  (see KG#25 on parallel agents sharing working tree).

- **Build verification** -- run `go build ./...` or `npx tsc --noEmit`
  to verify the subagent's output compiles. This catches issues before
  the main context wastes time reviewing broken code.

**Analysis:** SubagentStop is one of the highest-value expansion
points. Subagent output quality is a known pain point (AP#84: agents
skip lint despite CI checklists). Automated post-agent verification
catches issues that advisory rules do not. The `type: "command"` hook
would run a shell script that detects the project type and runs
appropriate checks.

**Challenge:** The hook fires for ALL subagents, including research
and exploration agents that produce no code. The verification script
must detect whether code was actually modified before running lint
and build checks.

**Recommendation:** Implement a `SubagentStop` command hook that:
(1) checks `git diff --name-only` for modified source files, (2)
runs stack-appropriate lint if code was changed, (3) reports results
as hook output injected into the main context.

### e. Stop Hooks

**Effort:** S | **Priority:** Medium

The `Stop` hook fires when the agent stops (end of conversation or
explicit stop). This is the last opportunity to inject context before
the session ends.

**Candidate uses:**

- **Reflect reminder** -- inject a brief reminder to run `/autolearn`
  if the session involved substantial work. This complements the
  autolearn pattern in CLAUDE.md that asks Claude to suggest
  `/autolearn` proactively.

- **Uncommitted changes warning** -- run `git status` and warn if
  there are uncommitted changes that might be lost.

- **Session summary** -- output a brief summary of what was
  accomplished (files changed, commits made, PRs created) for the
  user's reference.

**Analysis:** The Stop hook is low-effort and low-risk. A simple
`type: "command"` hook running `echo` with a reflect reminder costs
nothing and provides a safety net for the cases where the in-context
autolearn nudge was missed. The uncommitted changes warning is also
valuable -- it prevents the user from closing a session with work
in progress.

**Recommendation:** Implement both the `/autolearn` reminder and the
uncommitted changes check. These are independent, small, and
immediately useful.

### f. PreToolUse Hooks

**Effort:** L | **Priority:** Low

The `PreToolUse` hook fires before a tool is executed. This enables
blocking or warning before dangerous operations.

**Candidate uses:**

- **Force push guard** -- detect `git push --force` or
  `git push -f` in Bash tool calls and block or warn. This reinforces
  Core Principle #4 (never force-push main).

- **Destructive command guard** -- detect `rm -rf`, `git reset --hard`,
  `git clean -fd` and require confirmation. DevKit already has
  permission deny rules for some of these, but a hook adds a second
  layer.

- **Main branch commit guard** -- detect `git commit` when on the
  `main` branch and warn about the branch-per-issue workflow
  (WP#1).

**Analysis:** PreToolUse hooks are powerful but complex. The
`type: "prompt"` variant asks a small model to evaluate whether the
tool call is safe, which introduces latency on every tool invocation.
The `type: "command"` variant could inspect the tool arguments but
requires parsing the tool call format. Additionally, Claude Code
already has a permission system (`allow`/`deny` in settings.json)
that handles many of these cases. A PreToolUse hook adds defense in
depth but overlaps with existing controls.

**Challenge:** Running a hook before EVERY tool call adds latency to
the session. The hook must be highly selective (via `matcher`) to
avoid impacting performance. False positives (blocking legitimate
force pushes to feature branches) would be frustrating.

**Recommendation:** Defer PreToolUse hooks. The existing permission
system and in-context rules (Core Principle #4, Git Safety block in
subagent checklists) provide adequate coverage. Revisit if specific
incidents demonstrate that the current controls are insufficient.

## Priority Ranking

1. **SubagentStop: post-agent verification** (High, M) -- directly
   addresses the known gap of subagents skipping lint (AP#84). Catches
   code quality issues before main context review.

2. **UserPromptSubmit: commit/push verification reminder** (High, M)
   -- reinforces Core Principle #2 at the moment the user is most
   likely to skip verification.

3. **Stop: reflect reminder + uncommitted changes warning** (Medium,
   S) -- low-effort safety net for session-end hygiene.

4. **Pre-commit hook template** (Medium, S) -- complements existing
   pre-push hook with lightweight per-commit checks. Not a Claude Code
   hook but fills a gap in the git hooks story.

5. **Notification: context pressure /autolearn reminder** (Medium, M)
   -- valuable but depends on notification payload investigation.

6. **PreToolUse: dangerous operation guard** (Low, L) -- overlaps with
   existing permission system. Defer unless incidents justify it.

## Implementation Plan

### Phase 1: Quick Wins (S effort each)

- **Stop hook** -- add `Stop` entry to `settings.template.json` with
  a `type: "command"` hook that runs a bash script. The script checks
  `git status --porcelain` for uncommitted changes and echoes a
  `/autolearn` reminder. Create the script at
  `claude/hooks/SessionStop.sh`.

- **Pre-commit hook template** -- add
  `git-templates/hooks/pre-commit` with conventional commit message
  validation (regex check on `.git/COMMIT_EDITMSG`) and a basic secret
  pattern scan on staged files.

### Phase 2: High-Value Automation (M effort each)

- **SubagentStop hook** -- add `SubagentStop` entry to
  `settings.template.json` with a `type: "command"` hook running
  `claude/hooks/SubagentVerify.sh`. The script detects modified files
  via `git diff --name-only`, identifies the stack (Go files present?
  TS files present?), and runs appropriate lint commands. Output is
  injected into the main context.

- **UserPromptSubmit: commit/push reminder** -- add a second
  `UserPromptSubmit` entry with matcher
  `(?i)\b(commit|push|merge|ship)\b` and a `type: "prompt"` hook
  that reminds about pre-commit verification. Keep separate from the
  existing autolearn hook to avoid interference.

### Phase 3: Investigation Required (M effort, deferred)

- **Notification hooks** -- investigate what notification events
  Claude Code emits. If context pressure notifications are available,
  implement a `/autolearn` reminder. Document findings for future
  implementation.

### Phase 4: Deferred (L effort, low priority)

- **PreToolUse guards** -- only implement if specific incidents show
  that the permission system and in-context rules are insufficient.
  Track such incidents in known-gotchas.md and reassess quarterly.
