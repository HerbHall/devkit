# Archived Known Gotchas

Deprecated, consolidated, and project-specific entries from `../known-gotchas.md`.

## Archived 2026-03-07: Rules compaction (below 35k threshold)

### Infrastructure/ops (not dev methodology)

## 52. Physical Drive Migration Preserves Old User SID

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Platform:** Windows 11
**Issue:** Moving a physical drive from one PC to another preserves the old user's SID on all files and directories. Windows shows security warnings about untrusted files. Applications may fail to read/write files they previously owned. Copying files (via network share or Explorer) creates new ownership; moving/migrating the physical drive does not.
**Fix:** Take ownership recursively and reset ACLs:

```powershell
# Run as Administrator
takeown /F D:\ /R /A          # Assign ownership to Administrators group
icacls D:\* /reset /T /C /Q   # Reset ACLs to inherited defaults
```

**Gotcha:** `icacls <drive>:\` on the drive root may fail with "un-usable ACL" -- use `<drive>:\*` instead to skip the root directory's special system ACLs. Stale symlinks (e.g., old pnpm links) will fail -- these are harmless.

## 68. Proxmox Installer Injects noapic Which Blocks IOMMU

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Platform:** Proxmox VE (all versions)
**Issue:** The Proxmox installer writes `noapic` to `/etc/default/grub.d/installer.cfg` which is silently appended to `GRUB_CMDLINE_LINUX`. This blocks IOMMU even when `intel_iommu=on iommu=pt` is correctly set in `/etc/default/grub`. The main grub file looks clean, so you don't suspect a drop-in config.
**Fix:** Check and fix the drop-in config:

```bash
cat /etc/default/grub.d/installer.cfg
# If it contains 'noapic', remove it:
sed -i 's/nomodeset noapic/nomodeset/' /etc/default/grub.d/installer.cfg
update-grub && reboot
```

**Also required:** VT-d (Intel) or AMD-Vi must be enabled in BIOS. Check after fixing grub.
**Prevention:** When setting up GPU passthrough on Proxmox, always check ALL grub configs: `cat /etc/default/grub /etc/default/grub.d/*.cfg | grep -E 'noapic|iommu'`

## 69. Proxmox VM Re-Boots Into ISO Installer After Guest OS Install

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Platform:** Proxmox VE (QEMU/KVM)
**Issue:** After a guest OS (Ubuntu, Debian) finishes installing in a Proxmox VM, clicking "Reboot" in the installer boots back into the ISO installer instead of the installed OS. The ISO is still attached to ide2 and has higher boot priority.
**Fix:** Detach the ISO and set boot order to the installed disk:

```bash
qm set <vmid> --ide2 none --boot order=scsi0
qm reboot <vmid>
```

## 70. Ubuntu Point Release URLs 404 When Superseded

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Platform:** Ubuntu / Proxmox ISO downloads
**Issue:** Ubuntu ISO download URLs include the point release version (e.g., `ubuntu-24.04.2-live-server-amd64.iso`). When a newer point release ships (24.04.4), the old URL returns 404.
**Fix:** Check the current filename before downloading:

```bash
curl -s https://releases.ubuntu.com/24.04/ | grep -oP 'ubuntu-24\.04\.\d+-live-server-amd64\.iso' | head -1
```

## 71. NVIDIA Driver Package Names Vary by Ubuntu PPA

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Platform:** Ubuntu (Proxmox VMs)
**Issue:** `apt install nvidia-driver-560` may fail with "package not found" because the exact driver version depends on which PPA is enabled and the Ubuntu release.
**Fix:** Add the PPA and search for available versions:

```bash
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt update
apt-cache search nvidia-driver | grep -E '^nvidia-driver-[0-9]' | sort -t- -k3 -n
```

### Project-specific or one-off

## 21. VS Code YAML Extension Conflict: jumpToSchema

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Platform:** VS Code (all)
**Issue:** Codecov VS Code extension (v0.1.1) and Red Hat YAML both bundle `yaml-language-server` internally. Both try to register the `jumpToSchema` command at startup. The second to load crashes with `command 'jumpToSchema' already exists`, preventing the Codecov extension from initializing.
**Fix:** Remove the Codecov extension. Red Hat YAML covers YAML schema validation comprehensively (including Codecov schemas via SchemaStore). Also remove redundant `yamllint-ts` and `yamllint-fix` extensions if installed -- one YAML language server is sufficient.
**General rule:** Avoid multiple extensions that embed the same language server. Prefer one comprehensive extension over several specialized ones for the same language.

## 36. Go uint64 Subtraction Wraps Instead of Going Negative

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07

**Platform:** Go (all)
**Issue:** `uint64` subtraction wraps around to a huge positive number when the result would be negative (e.g., `50 - 100` becomes `~2^64 - 50`). A subsequent `float64()` conversion produces a huge positive float, not a negative one. This means `if float64(a - b) < 0` is **always false** for uint64 values -- the check is dead code.
**Fix:** Guard with pre-subtraction comparison on the raw uint64 values:

```go
if newUsage < oldUsage { return 0.0 }
cpuDelta := float64(newUsage - oldUsage)
```

**Scope:** Any metric calculation using uint64 counters that can decrease (container restarts, system reboots, counter wraps). Common in Docker stats, network byte counters, and CPU tick counters.

## 40. User Manual Commits During Context Compaction Gap

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07 (superseded by error policy)

**Platform:** Claude Code (all)
**Issue:** When context compacts and the session is continued, the user may have made manual git commits between the old session ending and the new session starting. The continuation summary says "files need committing" but the working tree is clean -- the user already committed.
**Fix:** On any continuation session, run `git log --oneline main..HEAD` and `git diff --stat main..HEAD` BEFORE attempting to commit. If changes are already committed, skip to push/PR creation. Don't try to amend the user's commit unless asked.

## 53. VS Code CLI Opens Editor Tabs When Stdin Not Redirected

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07 (covered by AP#73)

**Platform:** Windows (PowerShell)
**Issue:** `Start-Process -FilePath 'code' -RedirectStandardOutput ... -RedirectStandardError ...` (without `-RedirectStandardInput`) still opens `code-stdin-*` editor tabs. VS Code's CLI wrapper inherits the parent process's stdin handle and interprets pending input as a file to open.
**Fix:** Always redirect ALL THREE streams when invoking `code` from a script. The empty temp file provides immediate EOF on stdin, preventing VS Code from reading anything. See AP#73 for the full three-stream redirect pattern.

### Consolidation victims -- Parallel agent cluster (consolidated into KG#25)

**Note:** KG#48 (Win32_Processor virtualization) and KG#67 (markdown tables) were initially targeted for this cluster but are unrelated to parallel agents. They remain in the main file as standalone entries.

## 76. go build Compiles Untracked Files in Working Tree

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07 (consolidated into KG#25)

**Platform:** Go (all)
**Issue:** `go build ./...` compiles ALL `.go` files in the module directory tree, including untracked files. When parallel agents create files for different branches (gotcha #25), untracked files from Agent B can reference symbols that only exist on Agent A's branch. Pre-push hooks running `go build` fail with "undefined" errors even though the committed code on the current branch is correct.
**Fix:** Before pushing a branch, stash untracked files belonging to other agents:

```bash
git stash push -u -m "other-agent-files" -- internal/dispatcher/*.go
git push -u origin feature/profile-store
git stash pop
```

### Consolidation victims -- Swagger cluster (consolidated into KG#12)

## 57. Swagger x-enum-descriptions Blocks Differ Between Windows and Linux

**Added:** 2026-02-24 | **Source:** SubNetree | **Status:** archived-2026-03-07 (consolidated into KG#12)
**See also:** AP#17, AP#35, KG#12, KG#59

**Platform:** Go (swaggo/swag, cross-platform)
**Issue:** Windows `swag init` generates `x-enum-descriptions` array blocks for Go enums with comment annotations. Linux CI's `swag init` (same version) omits these blocks entirely.
**Fix:** After running `swag init` locally on Windows, manually remove all `x-enum-descriptions` blocks from all three swagger files before committing.

```bash
grep -c "x-enum-descriptions" api/swagger/*
# Should be 0 for CI compatibility
```

## 59. Perl Regex for Stripping Swagger YAML Corrupts Line Boundaries

**Added:** 2026-02-24 | **Source:** SubNetree | **Status:** archived-2026-03-07 (consolidated into KG#12)
**See also:** AP#17, AP#35, KG#12, KG#57

**Platform:** Windows (MSYS_NT) / swaggo/swag
**Issue:** The perl one-liner used to strip `x-enum-descriptions` from `swagger.yaml` can concatenate adjacent lines. When a YAML enum description value is immediately followed by an `x-enum-descriptions` block, the regex removes the block AND the newline, joining the description with the next YAML key on one line.
**Fix:** After running the perl strip regex, verify YAML integrity:

```bash
perl -0777 -i -pe 's/\n\s*x-enum-descriptions:\n(?:\s+-\s+.*\n)*//g' api/swagger/swagger.yaml
grep "x-enum-varnames" api/swagger/swagger.yaml | grep -v "^\s*x-enum-varnames"
```

### Note on KG#90

KG#90 (release-please node type) was initially targeted for consolidation into KG#65 (golangci-lint v2), but these are unrelated entries. KG#90 remains in the main file as a standalone entry.

### Consolidation victims -- PowerShell duplicates

## 19. PowerShell 5.1 ConvertFrom-Json Drops Empty Arrays

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07 (consolidated into KG#18)

**Platform:** Windows (PowerShell 5.1)
**Issue:** `ConvertFrom-Json` on an empty JSON array `[]` returns `$null` instead of an empty PowerShell array `@()`. This means `$null -ne $result` evaluates to `$false` even when the API returned HTTP 200 with a valid empty response.
**Fix:** For endpoints where you only need to confirm "responds 200", use `Invoke-WebRequest` directly and check `$resp.StatusCode` instead of parsing JSON.

## 75. Branch Protection Requires Pre-Existing CI Check Names

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07 (consolidated into KG#54)

**Platform:** GitHub
**Issue:** `required_status_checks.contexts` in branch protection must reference job names that have already appeared in at least one CI run on the repo. Setting protection before the CI workflow runs with those job names causes all PRs to be blocked with "Expected -- Waiting for status to be reported."
**Fix:** Merge the CI workflow PR first, verify the job names appear in the Actions tab, THEN apply branch protection.

### Consolidation victims -- Docker Desktop extension cluster (consolidated into KG#77)

## 78. hadolint False Positives on Docker Desktop Extension Dockerfiles

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-07 (consolidated into KG#77)

**Platform:** Docker / hadolint
**Issue:** Docker Desktop extension Dockerfiles use vendor-specific labels and `COPY` without `WORKDIR` as standard patterns. hadolint flags these as DL3048 and DL3045.
**Fix:** Create `.hadolint.yaml` with `ignored: [DL3048, DL3045]`.

## 81. @docker/extension-api-client Vitest Resolve Alias Needed

**Added:** 2026-03-02 | **Source:** RunNotes | **Status:** archived-2026-03-07 (consolidated into KG#77)

**Platform:** Docker Desktop Extensions (Vitest)
**Issue:** `@docker/extension-api-client` declares `"type": "commonjs"` but uses ESM exports. Vitest cannot resolve the module.
**Fix:** Add a resolve alias in `vitest.config.ts` pointing to a manual mock file `src/__mocks__/@docker/extension-api-client.ts`.
**See also:** KG#87 (general pattern for browser-only package exports in Vitest).

## 82. Version Drift Across Release Files with Git Tag Workflows

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** archived-2026-03-07 (consolidated into KG#77)

**Platform:** Docker Desktop Extensions / Any multi-file version project
**Issue:** Git tag-based release workflows cause version drift when multiple files reference the version independently.
**Fix:** Designate one file as the version source of truth. CI reads version from source. Dockerfile ARG defaults become fallbacks only.

## 83. Docker Extension Dockerfile Label Format Requirements

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** archived-2026-03-07 (consolidated into KG#77)

**Platform:** Docker Desktop Extensions (all)
**Issue:** Docker Desktop extension Dockerfiles require specific label formats. Labels must be valid JSON strings with escaped quotes.
**Fix:** Use exact formats: screenshots (JSON array, min 3, 2400x1600px), changelog (HTML), additional-urls (JSON array), icon (local file reference).
**Reference:** [Docker extension labels documentation](https://docs.docker.com/extensions/extensions-sdk/extensions/labels/)

## 84. Multi-Arch Buildx Required for Docker Desktop Extensions

**Added:** 2026-03-02 | **Source:** Runbooks | **Status:** archived-2026-03-07 (consolidated into KG#77)

**Platform:** Docker Desktop Extensions (all)
**Issue:** Extensions must provide multi-arch images for `linux/amd64` and `linux/arm64`. Single-arch images fail on other architectures.
**Fix:** `docker buildx build --push --platform=linux/amd64,linux/arm64 --tag=IMAGE:VERSION .`

## 85. MUI v5 Pinned via @docker/docker-mui-theme

**Added:** 2026-03-02 | **Source:** RunNotes | **Status:** archived-2026-03-07 (consolidated into KG#77)

**Platform:** Docker Desktop Extensions (React/MUI)
**Issue:** `@docker/docker-mui-theme` pins MUI to v5. MUI v6+ changed several APIs. Copying current MUI docs examples produces TypeScript errors.
**Fix:** Always reference MUI v5 documentation. TextField adornments: `InputProps={{ startAdornment }}` (not `slotProps.input`). Check MUI version: `npm ls @mui/material` should show 5.x.

### Consolidation victims -- GitHub rulesets/protection (consolidated into KG#23)

## 98. Rulesets and Branch Protection Review Requirements Conflict

**Added:** 2026-03-05 | **Source:** Runbooks | **Status:** archived-2026-03-07 (consolidated into KG#23)

**Platform:** GitHub
**Issue:** GitHub rulesets and classic branch protection are separate systems that can both require PR reviews independently. If both require 1 review, the effective requirement becomes 2 reviews. For solo maintainers, this blocks all PRs.
**Fix:** Use rulesets for review requirements (enables Copilot auto-review) and branch protection only for CI status checks. Remove `required_pull_request_reviews` from branch protection.

**Protection architecture:**

| Concern | System | Reason |
|---------|--------|--------|
| CI status checks | Branch protection | API-configurable, well-supported |
| PR review requirement | Ruleset | Enables Copilot auto-review |
| Copilot auto-review | Ruleset (UI toggle) | Only available in rulesets |
| Auto-merge | Repo setting | Required for release-gate workflow |

## 99. Split Rulesets Break Copilot Auto-Merge Pipeline

**Added:** 2026-03-06 | **Source:** DevKit | **Status:** archived-2026-03-07 (consolidated into KG#23)

**Platform:** GitHub
**Issue:** Using two separate rulesets -- one for PR review and one for Copilot review -- prevents Copilot auto-merge from working. Copilot reviews with COMMENTED instead of APPROVED.
**Fix:** Replace split rulesets with a single combined "Copilot PR Review" ruleset containing both `pull_request` (with `required_approving_review_count: 1`) and `copilot_code_review` (with `review_on_push: true`) rules. Template: `project-templates/copilot-ruleset.json`. Audit: `scripts/copilot-review-setup.sh audit OWNER/REPO`.
**Anti-revert policy:** See `claude/rules/review-policy.md`.

### Consolidation victims -- React refs (consolidated into KG#6)

## 114. (Note: This entry number does not exist in the original file -- KG#114 was referenced in the task instructions but the callback ref pattern for MUI Popper anchors is documented in AP#114 in autolearn-patterns.md, not in known-gotchas.md. No action needed.)

## Archived 2026-03-14: Rules compaction round 2 (below 35k threshold)

### Trivial, covered elsewhere, or too specific

## KG#3 (archived 2026-03-14)

Git stash before PR merge. Trivial workflow tip, covered by AP#22.

## KG#4 (archived 2026-03-14)

Force push to already-merged branch creates orphan. General git safety, covered by core principles.

## KG#9 (archived 2026-03-14)

jq not available on Windows MSYS. Problem statement only; AP#11/AP#122 has the full solution.

## KG#10 (archived 2026-03-14)

UserPromptSubmit hooks block slash commands. Config detail -- use `matcher` regex `"^(?!/)(?!\\d{1,2}$)"`.

## KG#22 (archived 2026-03-14)

Project renames create competitive research blind spots. Research methodology, covered by AP#33.

## KG#24 (archived 2026-03-14)

cla-assistant.io blocks Dependabot PRs. Tool-specific, no longer relevant.

## KG#30 (archived 2026-03-14)

Background agents can't prompt for tool permissions. Ensure tools are approved before launching.

## KG#31 (archived 2026-03-14)

Reddit blocks WebFetch. Workaround: append `.json` to URL and use `gh api -X GET`.

## KG#32 (archived 2026-03-14)

SessionStart hook must use `type: "command"` not `type: "prompt"`. Config detail.

## KG#33 (archived 2026-03-14)

Claude Code hooks cannot initiate conversation. UI limitation, not technical gotcha.

## KG#34 (archived 2026-03-14)

Chrome ignores autocomplete="off". Generic web knowledge.

## KG#39 (archived 2026-03-14)

Docker Extension update fails after image rebuild. Already covered in KG#77 consolidated entry.

## KG#42 (archived 2026-03-14)

BMAD Method generates 42 slash commands. Tool trivia.

## KG#43 (archived 2026-03-14)

Spec Kit `specify init` hangs on Windows MSYS. Tool-specific workaround.

## KG#44 (archived 2026-03-14)

BMAD npm package name is `bmad-method`. Tool naming quirk.

## KG#45 (archived 2026-03-14)

markdownlint-cli2 config must be at repo root for CI. Config detail.

## KG#46 (archived 2026-03-14)

markdownlint MD060 auto-enabled by `"default": true`. Add `"MD060": false` to config.

## KG#55 (archived 2026-03-14)

VS 2022 bundled Node.js as fallback. Covered by AP#76.

## KG#60 (archived 2026-03-14)

Go binary permission denied on MSYS. Covered by AP#91 (use `go run` instead).

## KG#63 (archived 2026-03-14)

Lipgloss emoji variation selector width mismatch. Niche TUI library issue.

## KG#64 (archived 2026-03-14)

lipgloss.Place output not safely ANSI-strippable. Niche TUI library issue.

## KG#93 (archived 2026-03-14)

Git init template CLAUDE.md breaks markdownlint. Add `"#.git"` to exclusion patterns.

## KG#102 (archived 2026-03-14)

Samverk dispatcher false-positive on issues without frontmatter. Samverk-specific, belongs in Samverk project rules. See Samverk issue #180.

### Consolidation victims (2026-03-14)

## KG#41 (archived 2026-03-14, consolidated into KG#61)

`.claude/settings.local.json` should be gitignored. Merged into KG#61 (Claude Code Settings Scope).

## KG#51 (archived 2026-03-14, consolidated into KG#50)

Winget installs update registry PATH but current session is stale. Merged into KG#50 (Winget Installation Gotchas).

## KG#58 (archived 2026-03-14, consolidated into KG#20)

Local main diverges after squash-merge when merge commits exist. Merged into KG#20.

## KG#101 (archived 2026-03-14, consolidated into KG#62)

Claude Code Edit tool CRLF matching failure on Windows. Merged into KG#62 (Windows CRLF Breaks Tool String Matching).

## KG#103 (archived 2026-03-14, consolidated into KG#99)

Copilot sub-PRs target feature branch, not main. Merged into KG#99 as subsection.

## KG#105 (archived 2026-03-14, consolidated into KG#104)

PowerShell 2>&1 mixes stderr into parsed output. Merged into KG#104 (PowerShell Output Capture Gotchas).

## KG#106 (archived 2026-03-14, consolidated into KG#111)

Inserting into numbered markdown list requires full renumbering. Merged into KG#111 (Markdown Editing Gotchas).

## KG#108 (archived 2026-03-14, consolidated into KG#107)

gh issue create --milestone takes title, not number. Merged into KG#107 (gh CLI Parameter Gotchas).

## KG#109 (archived 2026-03-14, consolidated into KG#62)

GitHub REST API returns CRLF in issue body text fields. Merged into KG#62 (Windows CRLF Breaks Tool String Matching).

## Archived 2026-03-15: Rules compaction (batch ingest + consolidation)

### Low-value or unreferenced entries

## KG#2 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** GitHub
**Fix:** `gh pr merge --admin` bypasses protection when you're the only maintainer.

## KG#5 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** Go (all)
**Issue:** Changing `for _, v := range slice` to `for i := range slice` -- easy to miss `v` references deeper in the loop body.
**Fix:** Search the entire loop body for the old variable name. Replace ALL occurrences with `slice[i]`.

## KG#11 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** All (curl, fetch)
**Issue:** GitHub REST API requires a `User-Agent` header. Requests without it return empty or 403.
**Fix:** Always include `User-Agent: <app-name>` in GitHub API requests.

## KG#14 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** Go (all)
**Issue:** `if obj.Field == nil || obj.Field.Sub == 0` with logging that accesses `obj.Field.X` panics when `obj.Field` is nil.
**Fix:** Split into two separate `if` blocks -- check nil first, then check the field.

## KG#15 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** Git (all)
**Issue:** After squash-merge, `git branch --merged main` won't list the branch (different hashes).
**Fix:** Use `git branch -D` (force delete). Verify safety with `git remote prune origin` first.

## KG#16 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** GitHub
**Issue:** `Closes #1, #2, #3` only auto-closes #1. GitHub requires the keyword before each number.
**Fix:** Use `Closes #1, Closes #2, Closes #3` or one per line.

## KG#37 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** Windows (VS Code)
**Issue:** `rm -rf` fails on directories VS Code has open as workspace roots. File watcher holds handles.
**Fix:** Remove contents first, then reload VS Code with updated workspace config. Or close VS Code first.

## KG#38 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** Playwright (all)
**Issue:** `getByLabel('Password')` matches both the input and companion toggle button.
**Fix:** Use `page.locator('#password')` to target by ID instead.

## KG#47 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** PowerShell 7+
**Issue:** `[Mandatory] [string[]]` validates each element. Empty strings `''` fail validation.
**Fix:** Add `[AllowEmptyString()]` alongside `[Mandatory]`.

## KG#48 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** Windows (Hyper-V)
**Issue:** Returns `$false` when Hyper-V is already active (hypervisor claimed VT-x).
**Fix:** Use Hyper-V state as fallback: `if ($virtCheck.Met -or $hyperVMet) { # confirmed }`.

## KG#49 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** PowerShell (all)
**Issue:** `Get-ChildItem` skips dotfiles (hidden on Windows). Filter `credentials*` won't match `.credentials*`.
**Fix:** Use `-Force` flag AND add separate `.credentials*` filter.

## KG#54 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** PowerShell 7+ / GitHub

### param() must be first executable statement

**Issue:** `Set-StrictMode` before `param()` causes confusing error.
**Fix:** Only comments and `#Requires` before `param()`.

### Branch protection requires pre-existing CI check names

**Issue:** `required_status_checks.contexts` must reference jobs that have already run.
**Fix:** Merge CI workflow first, verify job names in Actions tab, then apply protection.

## KG#56 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** Claude Code (Windows)
**Issue:** Subagent adds deps to `package.json` but can't run `pnpm install`. CI fails with `ERR_PNPM_OUTDATED_LOCKFILE`.
**Fix:** Run `pnpm install` after merging subagent changes to update lockfile.

## KG#72 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** React / ESLint
**Issue:** This rule does NOT support `// eslint-disable-next-line`. Adding it produces "Unused directive".
**Fix:** Config-level override only: `"react-hooks/set-state-in-effect": "warn"` in `eslint.config.js`.

## KG#73 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** npm / React
**Issue:** ESLint 10.x breaks `eslint-plugin-react-hooks` which requires `eslint@^9`.
**Fix:** Pin: `npm install --save-dev eslint@^9 @eslint/js@^9`.

## KG#79 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** GitHub
**Issue:** Repo secrets are under Settings > Secrets and variables > Actions (expandable submenu).
**Fix:** Use CLI: `gh secret set SECRETNAME`. `gh secret list` to verify.

## KG#80 (archived 2026-03-15)

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** archived-2026-03-15

**Platform:** PowerShell 7+
**Issue:** Under StrictMode, accessing nonexistent property on PSCustomObject throws -- even in conditionals.
**Fix:** Use `$obj.PSObject.Properties.Match('prop').Count -gt 0`. Does NOT affect hashtables.

## KG#86 (archived 2026-03-15)

**Added:** 2026-03-02 | **Source:** DevKit | **Status:** archived-2026-03-15

**Platform:** Bash (all, especially CI)
**Issue:** `grep -c` outputs "0" AND exits code 1. `$(grep -c ... || echo "0")` captures "0\n0", breaking arithmetic.
**Fix:** Use `|| true` instead of `|| echo "0"`.

## KG#100 (archived 2026-03-15)

**Added:** 2026-03-07 | **Source:** DevKit | **Status:** archived-2026-03-15

**Platform:** Claude Code (all)
**Issue:** After completing a multi-step task, CC displays a pasted large input block as text rather than executing it. Context saturation at task boundaries.
**Fix:** Kill session and open fresh. Do NOT attempt multiple `?` prompts -- if it fails twice, session is unrecoverable.
**Prevention:** Keep handoff prompts under 40 lines. Run `/rules-compact` if rules files approach 40k.

## KG#139 (archived 2026-03-15)

**Added:** 2026-03-15 | **Source:** Synapset | **Status:** archived-2026-03-15

**Platform:** Go (all)
**Issue:** WASM-based SQLite driver has single linear memory space. Concurrent goroutine access causes `panic: wasm error: out of bounds memory access`.
**Fix:** Use `sync.Mutex` or `*sql.DB` with `SetMaxOpenConns(1)`. Alternative: switch to CGO-based driver (`mattn/go-sqlite3`) which supports SQLite threading modes.

### Consolidation victims (2026-03-15)

## KG#7 (archived 2026-03-15, consolidated into KG#6)

React Compiler Lint: Recursive useCallback Self-Reference. Merged into KG#6 (React Compiler Lint: Refs During Render).

## KG#13 (archived 2026-03-15, consolidated into KG#12)

Swagger Drift After Any Handler/Model Change. Merged into KG#12 (Swagger Cross-Platform Drift).

## KG#66 (archived 2026-03-15, consolidated into KG#65)

golangci-lint-action v7 Runs config verify (Schema Enforcement). Merged into KG#65 (golangci-lint v2 Config and Schema).

## KG#67 (archived 2026-03-15, consolidated into KG#111)

Agent-Generated Markdown Tables: Pipes in Cells and Missing Columns. Merged into KG#111 (Markdown Editing Gotchas).

## KG#112 (archived 2026-03-15, consolidated into KG#104)

Invoke-ScriptAnalyzer Has No -Include Parameter. Merged into KG#104 (PowerShell Tool and Variable Gotchas).

## KG#113 (archived 2026-03-15, consolidated into KG#104)

PowerShell $args Is an Automatic Variable. Merged into KG#104 (PowerShell Tool and Variable Gotchas).

## KG#124 (archived 2026-03-15, consolidated into KG#123)

Gitea PR Merge After Rebase Needs Pause. Merged into KG#123 (Gitea API and Actions Gotchas).

## KG#130 (archived 2026-03-15, consolidated into KG#25)

git worktree Operations Can Flip core.bare=true. Merged into KG#25 (Parallel Background Agents Share Working Tree).

## KG#137 (archived 2026-03-15, consolidated into KG#127)

sqlite-vec vec0 Virtual Tables Do Not Support UPDATE. Merged into KG#127 (sqlite-vec Virtual Table Gotchas).

## KG#138 (archived 2026-03-15, consolidated into KG#123)

Gitea Reserves GITEA_ Prefix for Actions Secret Names. Merged into KG#123 (Gitea API and Actions Gotchas).

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
