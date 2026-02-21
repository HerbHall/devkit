# Design Decisions

Rationale for non-obvious architectural choices. Read this before making changes that touch
the overall structure, the lib layer, or the Kit 1–3 flow.

---

## Profile Format: Markdown + YAML Frontmatter

**Decision:** Stack profiles (`profiles/*.md`) use Markdown files with YAML frontmatter,
not JSON, TOML, or pure YAML.

**Rationale:**

- PowerShell parses the YAML frontmatter to drive automation (winget IDs, extension lists, skill names)
- Claude reads the Markdown body as project context when generating CLAUDE.md or advising on tooling
- A single file serves both machines — no parallel JSON+docs files to keep in sync
- The body can include gotchas, post-install notes, and rationale that only a human or LLM would use

**Constraint:** YAML parser is custom (no external module). The frontmatter schema is simple enough
that a targeted ~50 line parser handles it: string scalars, string arrays, and one level of nested
objects (for the `winget` array). If the schema needs to grow beyond this, revisit.

---

## No External PowerShell Modules in lib/

**Decision:** `setup/lib/*.ps1` files have zero external module dependencies. All functionality
uses built-in PowerShell cmdlets, .NET APIs, and WinRT APIs.

**Rationale:**

- Bootstrap runs on a bare machine before any package manager configuration
- `Install-Module` requires NuGet provider registration that may prompt for admin approval
- `powershell-yaml` module is a common suggestion but adds a dependency that complicates
  first-run scenarios
- The YAML subset used in profiles is small enough to parse without a full YAML library
- Windows Credential Manager access uses the built-in WinRT PasswordVault API available in PS5.1+

**Constraint:** If a lib function genuinely needs something that can't be done without a module,
add a comment explaining why and gate it behind a version/availability check.

---

## Kit 3 CLAUDE.md: Claude-Generated with Graceful Fallback

**Decision:** Kit 3 calls `claude --print` to generate the project CLAUDE.md, but falls back
to `project-templates/claude-md-template.md` if Claude Code is not authenticated.

**Rationale:**

- The AI-generated path produces richer, project-specific context from the concept brief
- But requiring Claude auth as a hard dependency makes Kit 3 fail on new machines mid-setup
- The template fallback still produces a useful, token-substituted CLAUDE.md
- The fallback path shows a visible warning and explains how to regenerate with Claude auth later

**Implementation note:** `Test-ClaudeAuth` from `checks.ps1` gates which path runs. The auth
check is skippable in bootstrap (issue #12) precisely so Kit 3 can still work without it.
The fallback is not "degraded" — it's a fully functional output; AI generation is the enhancement.

---

## Secrets: Windows Credential Manager, Not .env Files

**Decision:** All credentials (GitHub PAT, Anthropic key, Docker Hub token) are stored in
Windows Credential Manager via the WinRT PasswordVault API. No `.env` files, no `secrets.json`.

**Rationale:**

- `.env` files get accidentally committed despite `.gitignore` — an unacceptable risk
- Windows Credential Manager is encrypted at rest, protected by the Windows login
- Credentials are retrievable by script (`Get-DevkitCredential`) for use in git config,
  environment variable injection, etc.
- The `devkit/` prefix on all credential names isolates them from system credentials
- `cmdkey` (used for storage) is built into Windows — no additional tools needed

**Constraint:** `Get-DevkitCredential` returns plaintext for script use. Call sites should
not log or display the returned value. The function is documented as "returns plaintext — handle
with care."

---

## Entry Point: Menu Dispatches to Independent Scripts

**Decision:** `setup.ps1` is a thin menu that calls `setup/bootstrap.ps1`, `setup/stack.ps1`,
etc. Each kit script is also independently invokable without going through the menu.

**Rationale:**

- Independent invocability enables automation, testing, and CI
- `bootstrap.ps1 -Phase 1` should work without a human at the menu
- `stack.ps1 -List` should work in scripts that need to enumerate profiles
- The menu is a convenience for interactive use; it's not the only entry point
- This matches the `-Kit` parameter on `setup.ps1` (e.g., `setup.ps1 -Kit bootstrap`)

---

## Issue-First, Then Implement

**Decision:** All 22 implementation issues (#3–#24) were created before any PowerShell was
written.

**Rationale:**

- Forces complete thinking of the architecture before getting into implementation details
- Issues serve as acceptance criteria — clear definition of done before starting
- Allows planning across all five phases to identify dependencies and sequencing
- Provides a record of what was decided and why, separate from code comments

**Current status:** All issues exist, no PowerShell has been written yet. Phase 5 issues
(#21–#23) are standalone fixes to existing files and have no implementation dependencies — good
place to start. Phase 1 is the prerequisite for everything else.

---

## Idempotency as a First-Class Requirement

**Decision:** All three kit scripts must be safe to run on an already-configured machine.
Re-running bootstrap on a machine where everything is installed should produce "all already done"
with zero failures and no side effects.

**Rationale:**

- Users will re-run after adding new tools to `machine/winget.json`
- CI should be able to run verification passes
- "Already installed" detection is faster than letting winget figure it out
- The verify-before-install pattern (using `Test-Tool` before calling `Install-WingetPackage`)
  also prevents winget's sometimes-slow "already installed" detection from blocking fast runs

**Implementation:** `Install-WingetPackage` checks `Test-Tool` first — returns
`@{ AlreadyInstalled=$true }` without calling winget if the tool is already present.

---

## devspace Path Stored in ~/.devkit-config.json

**Decision:** The user's devspace root path (e.g., `D:\devspace`) is stored in
`~/.devkit-config.json` by bootstrap Phase 3, and read by Kit 3 when scaffolding new projects.

**Rationale:**

- Kit 3 needs to know where to create new project directories without asking every time
- Storing in a user-home config file (not the repo) means it's machine-specific without being
  in a committed file
- JSON is simpler than the registry for a single value; readable by any script
- The file is explicitly gitignored

**Schema:** `{ "devspace": "D:\\devspace", "username": "Herb", "machine": "DESKTOP-ABC" }`

---

## Phase 5 Fixes Are Independent of New Implementation

**Decision:** Issues #21–#23 (fixes to existing files) are tracked as Phase 5 but have zero
dependencies on the new PowerShell implementation. They should be done first or in parallel.

**Rationale:**

- `YOUR_PLATFORM` placeholder (#21) affects every new Code session that opens this repo
- BMAD contradiction (#21) will mislead anyone following METHODOLOGY.md on Windows
- Agent workflow Python pseudo-code (#22) will actively mislead a Code session trying to create agents
- These are quick, self-contained changes — no reason to wait for Phase 1

**Suggested order for a new Code session:**
1. Fix #21 (platform placeholder, BMAD warning, skill contamination, gotcha renumber)
2. Fix #22 (agent workflow guide)
3. Fix #23 (deprecate bash, document Chat skills)
4. Then Phase 1: #3 (repo structure) → #4–#7 (lib functions) → #8 (menu)

---

## Legacy Bash Scripts: Deprecated, Not Deleted

**Decision:** `setup/install-tools.sh`, `setup/setup.sh`, and `setup/verify.sh` are moved to
`setup/legacy/` with deprecation headers. They are not deleted.

**Rationale:**

- They still work for Git Bash users who haven't moved to PowerShell
- Deleting them would break anyone cloning the repo and following the old README
- Deprecation headers (`# ⚠ DEPRECATED`) make the status visible without removing the safety net
- The legacy scripts will be removed in v2.0 once the PowerShell system is stable

---

## Credential Name Prefix: devkit/

**Decision:** All credential names stored in Windows Credential Manager are prefixed `devkit/`
(e.g., `devkit/github-pat`, `devkit/anthropic-key`).

**Rationale:**

- Prevents accidental collision with OS or application credentials that happen to use the same key name
- Makes it easy to list or clean up all devkit credentials with `cmdkey /list | Select-String devkit`
- Consistent prefix makes `Test-DevkitCredential` fast — checks for prefix rather than full match
