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
