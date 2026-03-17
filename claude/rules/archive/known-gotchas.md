# Archived Known Gotchas

Deprecated, consolidated, and project-specific entries from `../known-gotchas.md`.
Full text stored in Synapset (pool: devkit). Query by entry ID tag to recover.

## Archived 2026-03-07: Rules compaction (below 35k threshold)

### Infrastructure/ops (not dev methodology)

## KG#52 (archived 2026-03-07)

Physical Drive Migration Preserves Old User SID on Windows.
Synapset: pool=devkit, ID=533

## KG#68 (archived 2026-03-07)

Proxmox Installer Injects noapic Which Blocks IOMMU.
Synapset: pool=devkit, ID=534

## KG#69 (archived 2026-03-07)

Proxmox VM Re-Boots Into ISO Installer After Guest OS Install.
Synapset: pool=devkit, ID=535

## KG#70 (archived 2026-03-07)

Ubuntu Point Release URLs 404 When Superseded.
Synapset: pool=devkit, ID=535

## KG#71 (archived 2026-03-07)

NVIDIA Driver Package Names Vary by Ubuntu PPA.
Synapset: pool=devkit, ID=535

### Project-specific or one-off

## KG#21 (archived 2026-03-07)

VS Code YAML Extension Conflict: jumpToSchema. Remove Codecov extension.
Synapset: pool=devkit, ID=536

## KG#36 (archived 2026-03-07)

Go uint64 Subtraction Wraps Instead of Going Negative. Guard with pre-subtraction comparison.
Synapset: pool=devkit, ID=537

## KG#40 (archived 2026-03-07)

User Manual Commits During Context Compaction Gap. Superseded by error policy.
Synapset: pool=devkit, ID=538

## KG#53 (archived 2026-03-07)

VS Code CLI Opens Editor Tabs When Stdin Not Redirected. Covered by AP#73.
Synapset: pool=devkit, ID=539

### Consolidation victims -- Parallel agent cluster (consolidated into KG#25)

## KG#76 (archived 2026-03-07, consolidated into KG#25)

go build Compiles Untracked Files in Working Tree.
Synapset: pool=devkit, ID=540

### Consolidation victims -- Swagger cluster (consolidated into KG#12)

## KG#57 (archived 2026-03-07, consolidated into KG#12)

Swagger x-enum-descriptions Blocks Differ Between Windows and Linux.
Synapset: pool=devkit, ID=541

## KG#59 (archived 2026-03-07, consolidated into KG#12)

Perl Regex for Stripping Swagger YAML Corrupts Line Boundaries.
Synapset: pool=devkit, ID=541

### Consolidation victims -- PowerShell duplicates

## KG#19 (archived 2026-03-07, consolidated into KG#18)

PowerShell 5.1 ConvertFrom-Json Drops Empty Arrays.
Synapset: pool=devkit, ID=542

## KG#75 (archived 2026-03-07, consolidated into KG#54)

Branch Protection Requires Pre-Existing CI Check Names.
Synapset: pool=devkit, ID=543

### Consolidation victims -- Docker Desktop extension cluster (consolidated into KG#77)

## KG#78 (archived 2026-03-07, consolidated into KG#77)

hadolint False Positives on Docker Desktop Extension Dockerfiles.
Synapset: pool=devkit, ID=544

## KG#81 (archived 2026-03-07, consolidated into KG#77)

@docker/extension-api-client Vitest Resolve Alias Needed.
Synapset: pool=devkit, ID=544

## KG#82 (archived 2026-03-07, consolidated into KG#77)

Version Drift Across Release Files with Git Tag Workflows.
Synapset: pool=devkit, ID=544

## KG#83 (archived 2026-03-07, consolidated into KG#77)

Docker Extension Dockerfile Label Format Requirements.
Synapset: pool=devkit, ID=544

## KG#84 (archived 2026-03-07, consolidated into KG#77)

Multi-Arch Buildx Required for Docker Desktop Extensions.
Synapset: pool=devkit, ID=544

## KG#85 (archived 2026-03-07, consolidated into KG#77)

MUI v5 Pinned via @docker/docker-mui-theme.
Synapset: pool=devkit, ID=544

### Consolidation victims -- GitHub rulesets/protection (consolidated into KG#23)

## KG#98 (archived 2026-03-07, consolidated into KG#23)

Rulesets and Branch Protection Review Requirements Conflict.
Synapset: pool=devkit, ID=545

## KG#99 (archived 2026-03-07, consolidated into KG#23)

Split Rulesets Break Copilot Auto-Merge Pipeline.
Synapset: pool=devkit, ID=545

### Consolidation victims -- React refs (consolidated into KG#6)

## KG#114 (archived 2026-03-07)

Note: This entry number does not exist in KG. The callback ref pattern is documented in AP#114.

## Archived 2026-03-14: Rules compaction round 2 (below 35k threshold)

### Trivial, covered elsewhere, or too specific

## KG#3 (archived 2026-03-14)

Git stash before PR merge. Trivial workflow tip, covered by AP#22.
Synapset: pool=devkit, ID=551

## KG#4 (archived 2026-03-14)

Force push to already-merged branch creates orphan. General git safety.
Synapset: pool=devkit, ID=551

## KG#9 (archived 2026-03-14)

jq not available on Windows MSYS. Covered by AP#11/AP#122.
Synapset: pool=devkit, ID=551

## KG#10 (archived 2026-03-14)

UserPromptSubmit hooks block slash commands. Use matcher regex.
Synapset: pool=devkit, ID=551

## KG#22 (archived 2026-03-14)

Project renames create competitive research blind spots. Covered by AP#33.
Synapset: pool=devkit, ID=551

## KG#24 (archived 2026-03-14)

cla-assistant.io blocks Dependabot PRs. No longer relevant.
Synapset: pool=devkit, ID=551

## KG#30 (archived 2026-03-14)

Background agents can't prompt for tool permissions.
Synapset: pool=devkit, ID=551

## KG#31 (archived 2026-03-14)

Reddit blocks WebFetch. Append `.json` to URL.
Synapset: pool=devkit, ID=551

## KG#32 (archived 2026-03-14)

SessionStart hook must use type:command not type:prompt.
Synapset: pool=devkit, ID=551

## KG#33 (archived 2026-03-14)

Claude Code hooks cannot initiate conversation. UI limitation.
Synapset: pool=devkit, ID=551

## KG#34 (archived 2026-03-14)

Chrome ignores autocomplete=off. Generic web knowledge.
Synapset: pool=devkit, ID=552

## KG#39 (archived 2026-03-14)

Docker Extension update fails after rebuild. Covered in KG#77.
Synapset: pool=devkit, ID=552

## KG#42 (archived 2026-03-14)

BMAD Method generates 42 slash commands. Tool trivia.
Synapset: pool=devkit, ID=552

## KG#43 (archived 2026-03-14)

Spec Kit specify init hangs on Windows MSYS. Tool-specific.
Synapset: pool=devkit, ID=552

## KG#44 (archived 2026-03-14)

BMAD npm package name is bmad-method. Tool naming quirk.
Synapset: pool=devkit, ID=552

## KG#45 (archived 2026-03-14)

markdownlint-cli2 config must be at repo root for CI.
Synapset: pool=devkit, ID=552

## KG#46 (archived 2026-03-14)

markdownlint MD060 auto-enabled by default:true. Add MD060:false to config.
Synapset: pool=devkit, ID=552

## KG#55 (archived 2026-03-14)

VS 2022 bundled Node.js as fallback. Covered by AP#76.
Synapset: pool=devkit, ID=552

## KG#60 (archived 2026-03-14)

Go binary permission denied on MSYS. Covered by AP#91.
Synapset: pool=devkit, ID=552

## KG#63 (archived 2026-03-14)

Lipgloss emoji variation selector width mismatch. Niche TUI issue.
Synapset: pool=devkit, ID=552

## KG#64 (archived 2026-03-14)

lipgloss.Place output not safely ANSI-strippable. Niche TUI issue.
Synapset: pool=devkit, ID=552

## KG#93 (archived 2026-03-14)

Git init template CLAUDE.md breaks markdownlint. Add #.git to exclusions.
Synapset: pool=devkit, ID=552

## KG#102 (archived 2026-03-14)

Samverk dispatcher false-positive on issues without frontmatter.
Synapset: pool=devkit, ID=552

### Consolidation victims (2026-03-14)

## KG#41 (archived 2026-03-14, consolidated into KG#61)

settings.local.json should be gitignored. Merged into KG#61.
Synapset: pool=devkit, ID=552

## KG#51 (archived 2026-03-14, consolidated into KG#50)

Winget installs update registry PATH but current session is stale. Merged into KG#50.
Synapset: pool=devkit, ID=552

## KG#58 (archived 2026-03-14, consolidated into KG#20)

Local main diverges after squash-merge with merge commits. Merged into KG#20.
Synapset: pool=devkit, ID=552

## KG#101 (archived 2026-03-14, consolidated into KG#62)

Claude Code Edit tool CRLF matching failure. Merged into KG#62.
Synapset: pool=devkit, ID=552

## KG#103 (archived 2026-03-14, consolidated into KG#99)

Copilot sub-PRs target feature branch not main. Merged into KG#99.
Synapset: pool=devkit, ID=552

## KG#105 (archived 2026-03-14, consolidated into KG#104)

PowerShell 2>&1 mixes stderr into parsed output. Merged into KG#104.
Synapset: pool=devkit, ID=552

## KG#106 (archived 2026-03-14, consolidated into KG#111)

Inserting into numbered markdown list requires full renumbering. Merged into KG#111.
Synapset: pool=devkit, ID=552

## KG#108 (archived 2026-03-14, consolidated into KG#107)

gh issue create --milestone takes title not number. Merged into KG#107.
Synapset: pool=devkit, ID=552

## KG#109 (archived 2026-03-14, consolidated into KG#62)

GitHub REST API returns CRLF in issue body text fields. Merged into KG#62.
Synapset: pool=devkit, ID=552

## Archived 2026-03-15: Rules compaction (batch ingest + consolidation)

### Low-value or unreferenced entries

## KG#2 (archived 2026-03-15)

gh pr merge --admin bypasses protection for solo maintainers.
Synapset: pool=devkit, ID=546

## KG#5 (archived 2026-03-15)

Go for-range to index-based: easy to miss variable references in loop body.
Synapset: pool=devkit, ID=546

## KG#11 (archived 2026-03-15)

GitHub REST API requires User-Agent header. Returns empty or 403 without it.
Synapset: pool=devkit, ID=546

## KG#14 (archived 2026-03-15)

Go nil check with logging that accesses nil field panics. Split into two if blocks.
Synapset: pool=devkit, ID=546

## KG#15 (archived 2026-03-15)

After squash-merge, git branch --merged won't list the branch. Use git branch -D.
Synapset: pool=devkit, ID=546

## KG#16 (archived 2026-03-15)

Closes #1, #2, #3 only auto-closes #1. Need keyword before each number.
Synapset: pool=devkit, ID=546

## KG#37 (archived 2026-03-15)

rm -rf fails on directories VS Code has open. File watcher holds handles.
Synapset: pool=devkit, ID=547

## KG#38 (archived 2026-03-15)

Playwright getByLabel matches both input and companion toggle button. Use locator('#id').
Synapset: pool=devkit, ID=547

## KG#47 (archived 2026-03-15)

PowerShell [Mandatory][string[]] validates each element. Add [AllowEmptyString()].
Synapset: pool=devkit, ID=547

## KG#48 (archived 2026-03-15)

Win32_Processor virtualization returns false when Hyper-V already active.
Synapset: pool=devkit, ID=547

## KG#49 (archived 2026-03-15)

Get-ChildItem skips dotfiles on Windows. Use -Force flag.
Synapset: pool=devkit, ID=547

## KG#54 (archived 2026-03-15)

PowerShell param() must be first executable statement. Branch protection needs pre-existing CI checks.
Synapset: pool=devkit, ID=548

## KG#56 (archived 2026-03-15)

Subagent adds deps to package.json but can't run pnpm install. CI fails with OUTDATED_LOCKFILE.
Synapset: pool=devkit, ID=548

## KG#72 (archived 2026-03-15)

react-hooks/set-state-in-effect does NOT support eslint-disable-next-line. Config-level only.
Synapset: pool=devkit, ID=548

## KG#73 (archived 2026-03-15)

ESLint 10.x breaks eslint-plugin-react-hooks (requires eslint@^9). Pin versions.
Synapset: pool=devkit, ID=548

## KG#79 (archived 2026-03-15)

GitHub repo secrets are under Settings > Secrets and variables > Actions. Use gh secret set.
Synapset: pool=devkit, ID=549

## KG#80 (archived 2026-03-15)

PowerShell StrictMode: accessing nonexistent PSCustomObject property throws.
Synapset: pool=devkit, ID=549

## KG#86 (archived 2026-03-15)

grep -c outputs 0 AND exits code 1. Use || true instead of || echo "0".
Synapset: pool=devkit, ID=549

## KG#100 (archived 2026-03-15)

CC displays large input as text instead of executing after multi-step task. Kill session.
Synapset: pool=devkit, ID=549

## KG#139 (archived 2026-03-15)

WASM SQLite driver panics on concurrent goroutine access. Use sync.Mutex or SetMaxOpenConns(1).
Synapset: pool=devkit, ID=550

### Consolidation victims (2026-03-15)

## KG#7 (archived 2026-03-15, consolidated into KG#6)

React Compiler Lint: Recursive useCallback Self-Reference. Merged into KG#6.

## KG#13 (archived 2026-03-15, consolidated into KG#12)

Swagger Drift After Any Handler/Model Change. Merged into KG#12.

## KG#66 (archived 2026-03-15, consolidated into KG#65)

golangci-lint-action v7 Runs config verify. Merged into KG#65.

## KG#67 (archived 2026-03-15, consolidated into KG#111)

Agent-Generated Markdown Tables: Pipes in Cells. Merged into KG#111.

## KG#112 (archived 2026-03-15, consolidated into KG#104)

Invoke-ScriptAnalyzer Has No -Include Parameter. Merged into KG#104.

## KG#113 (archived 2026-03-15, consolidated into KG#104)

PowerShell $args Is an Automatic Variable. Merged into KG#104.

## KG#124 (archived 2026-03-15, consolidated into KG#123)

Gitea PR Merge After Rebase Needs Pause. Merged into KG#123.

## KG#130 (archived 2026-03-15, consolidated into KG#25)

git worktree Operations Can Flip core.bare=true. Merged into KG#25.

## KG#137 (archived 2026-03-15, consolidated into KG#127)

sqlite-vec vec0 Virtual Tables Do Not Support UPDATE. Merged into KG#127.

## KG#138 (archived 2026-03-15, consolidated into KG#123)

Gitea Reserves GITEA_ Prefix for Actions Secret Names. Merged into KG#123.

## Archived 2026-03-17: Synapset-backed compaction (infrastructure/ops entries)

### Infrastructure and project-specific entries (Samverk/Synapset ops)

## KG#127 (archived 2026-03-17)

sqlite-vec virtual table gotchas: dimension mismatch and no UPDATE support.
Synapset: pool=devkit, ID=515

## KG#128 (archived 2026-03-17)

Claude Code user-scope MCP config location is ~/.claude.json.
Synapset: pool=devkit, ID=516

## KG#129 (archived 2026-03-17)

Claude Code --dangerously-skip-permissions blocked as root on Linux.
Synapset: pool=devkit, ID=517

## KG#131 (archived 2026-03-17)

git init defaults to master on CI runners; use --initial-branch=main.
Synapset: pool=devkit, ID=518

## KG#132 (archived 2026-03-17)

systemd ProtectSystem=strict blocks git worktree in /tmp.
Synapset: pool=devkit, ID=519

## KG#133 (archived 2026-03-17)

LXC unprivileged container resize requires stop on Proxmox.
Synapset: pool=devkit, ID=520

## KG#134 (archived 2026-03-17)

Dispatcher restart requires SIGKILL with in-flight claude CLI subprocesses.
Synapset: pool=devkit, ID=521

## KG#140 (archived 2026-03-17)

nologin shell masks real errors for Linux service users.
Synapset: pool=devkit, ID=522

## KG#141 (archived 2026-03-17, consolidated with KG#144)

SQLite BUSY with two-process sharing without WAL mode.
Synapset: pool=devkit, ID=523 (consolidated with KG#144)

## KG#143 (archived 2026-03-17)

stdout fsync EINVAL on Linux breaks zap Sync() on os.Stdout.
Synapset: pool=devkit, ID=524

## KG#144 (archived 2026-03-17, consolidated with KG#141)

SQLite PRAGMA only applies to one pooled connection; use DSN query params.
Synapset: pool=devkit, ID=523 (consolidated with KG#141)

## KG#145 (archived 2026-03-17)

Gitea assign API requires repo collaborator; GitHub silently ignores.
Synapset: pool=devkit, ID=525

## KG#146 (archived 2026-03-17)

Ollama models overwrite CLAUDE.md instead of following issue instructions.
Synapset: pool=devkit, ID=526

## KG#147 (archived 2026-03-17)

Ollama on Windows requires full process restart after OLLAMA_HOST env change.
Synapset: pool=devkit, ID=527

## KG#148 (archived 2026-03-17)

Trivy binary accumulation fills disk on host-mode Gitea runners.
Synapset: pool=devkit, ID=528
