# Manual Requirements

Items that cannot be automated by winget or PowerShell scripts. Each must be
configured by hand before or during bootstrap.

## Hardware Virtualization (BIOS)

**What:** Intel VT-x or AMD-V CPU virtualization extension.

**Why:** Required by Hyper-V, which is required by WSL2 and Docker Desktop.

**Steps:**

1. Reboot and enter BIOS/UEFI (usually Del, F2, or F10 during POST)
2. Find the virtualization setting (location varies by vendor):
   - Intel: Advanced > CPU Configuration > Intel Virtualization Technology
   - AMD: Advanced > CPU Configuration > SVM Mode
3. Set to **Enabled**
4. Save and exit

**Verify:** Open PowerShell and run `systeminfo | findstr /i "virtualization"` --
should show "Virtualization Enabled In Firmware: Yes".

## Hyper-V (Windows Feature)

**What:** Type-1 hypervisor built into Windows Pro/Enterprise/Education.

**Why:** WSL2 and Docker Desktop both run on the Hyper-V hypervisor layer.

**Steps:**

1. Open **Settings > Apps > Optional Features > More Windows Features**
   (or run `OptionalFeatures.exe`)
2. Check **Hyper-V** (both Management Tools and Platform)
3. Click OK and reboot when prompted

**Verify:** `Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V |
Select-Object State` should return `Enabled`.

**Note:** `bootstrap.ps1` attempts to enable this via `Enable-WindowsOptionalFeature`
but it requires elevation and a reboot, so manual confirmation is recommended.

## WSL2 (Windows Subsystem for Linux)

**What:** Linux kernel running natively on Windows via Hyper-V.

**Why:** Docker Desktop uses WSL2 as its default backend. Also useful for running
Linux dev tools natively.

**Steps:**

1. Open PowerShell as Administrator
2. Run `wsl --install` (installs WSL2 + Ubuntu by default)
3. Reboot when prompted
4. After reboot, Ubuntu will open and ask for a username/password

**Verify:** `wsl --status` should show "Default Version: 2".

## Docker Desktop Post-Install Configuration

**What:** Docker Desktop settings that cannot be set via CLI.

**Why:** Default settings may not use WSL2 backend or may have insufficient resources.

**Steps:**

1. Open Docker Desktop > Settings (gear icon)
2. **General:** Ensure "Use the WSL 2 based engine" is checked
3. **Resources > WSL Integration:** Enable integration with your default distro
4. **Resources > Advanced:** Set memory limit (recommended: 8 GB or half of RAM)
5. Click "Apply & Restart"

**Verify:** `docker info 2>&1 | findstr "Operating System"` should show
"Docker Desktop" and `docker run --rm hello-world` should succeed.

## Developer Mode (Windows Setting)

**What:** Windows developer mode that unlocks sideloading, symlinks, and
other dev-friendly OS behavior.

**Why:** Enables creating symlinks without elevation, sideloading apps, and
other developer conveniences.

**Steps:**

1. Open **Settings > Privacy & Security > For Developers**
   (or **Settings > Update & Security > For Developers** on older builds)
2. Toggle **Developer Mode** to On
3. Accept the confirmation dialog

**Verify:** `reg query
"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
/v AllowDevelopmentWithoutDevLicense` should return `0x1`.

## VS Code Settings Sync

**What:** Cloud sync of VS Code settings, keybindings, extensions, and snippets.

**Why:** Restores your full VS Code environment on any machine after sign-in.

**Steps:**

1. Open VS Code
2. Click the account icon (bottom-left) > **Turn on Settings Sync**
3. Choose what to sync (recommended: all)
4. Sign in with GitHub or Microsoft account
5. Wait for sync to complete (check the Sync status in the status bar)

**Verify:** Extensions, theme, and keybindings match your other machines.

## Claude Code Authentication

**What:** Anthropic API authentication for Claude Code CLI.

**Why:** Required for all Claude Code operations.

**Steps:**

1. Run `claude` in a terminal
2. Follow the authentication prompts (browser-based OAuth or API key)
3. Verify with `claude --version`

**Note:** `bootstrap.ps1` Phase 5 checks for Claude authentication but cannot
perform the interactive sign-in flow automatically.
