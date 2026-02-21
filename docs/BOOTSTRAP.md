# Bootstrap: Setting Up a New Windows Machine

A step-by-step guide to set up a new Windows machine from scratch using devkit. Follows the six-phase automated bootstrap process, plus manual configuration steps.

## Prerequisites

- **Windows 11** (or Windows 10 Build 19041+)
- **Admin access** to your machine
- **Internet connection**
- **GitHub account** with a Personal Access Token
- **Anthropic account** with API key

All tools install via `winget` (built-in package manager). No external installers needed.

## Step 0: Get devkit

Clone the devkit repository to your workspace root. We recommend `D:\DevSpace`.

### Option A: Clone via git (if git is already installed)

```powershell
cd D:\DevSpace
git clone https://github.com/HerbHall/devkit.git
cd devkit
```

### Option B: Download as ZIP from GitHub

1. Go to [https://github.com/HerbHall/devkit](https://github.com/HerbHall/devkit)
2. Click **Code > Download ZIP**
3. Extract to `D:\DevSpace\devkit`
4. Open PowerShell in the extracted folder

## Step 1: Run Bootstrap

Execute the bootstrap script in PowerShell. **Execution Policy** must be relaxed temporarily to run unsigned scripts.

```powershell
pwsh -ExecutionPolicy Bypass -File D:\DevSpace\devkit\setup\bootstrap.ps1
```

### Why ExecutionPolicy Bypass?

By default, Windows blocks unsigned PowerShell scripts to prevent malware. The `-ExecutionPolicy Bypass` flag tells PowerShell: "For this invocation only, run this script." It does NOT change your machine's default policy. Once the script finishes, the default policy (usually `RemoteSigned`) is restored.

**Safe:** This is safe because you control the script -- you're running a script from a local directory you downloaded, not downloading and executing an arbitrary script from the internet.

### Expected Output

The bootstrap runs six phases:

1. **Phase 1: Pre-Flight Checks** — Windows version, virtualization, winget availability
2. **Phase 2: Core Tool Installs** — Git, Node.js, Go, Docker, VS Code, etc.
3. **Phase 3: Configuration** — Git user config, devspace directory, PowerShell profile
4. **Phase 4: Credentials** — GitHub PAT, Anthropic API key, Docker Hub (optional)
5. **Phase 5: AI Layer** — Claude Code, skills, rules, agents
6. **Phase 6: Verification** — Full table of all tools and features

Progress updates print to the console. Watch for any **FAIL** results in the summary table.

## Step 2: Manual Configuration (Required)

Three Windows features require manual action. Bootstrap will prompt you with instructions for each.

### Hyper-V (Required)

Docker Desktop and WSL2 need hardware-level virtualization via Hyper-V.

**If bootstrap prompts:**

1. Open **Settings > Apps > Optional Features > More Windows Features**
   - Or run: `OptionalFeatures.exe`
2. Check **Hyper-V** (both "Hyper-V Management Tools" and "Hyper-V Platform")
3. Click **OK** and reboot when prompted
4. Return to PowerShell and press Enter to continue bootstrap

**Alternative (command-line):**

In elevated PowerShell:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
# Reboot required
```

### WSL2 (Recommended)

Windows Subsystem for Linux v2 is the modern backend for Docker and enables running Linux tools natively.

**If bootstrap prompts:**

1. Open PowerShell as Administrator
2. Run: `wsl --install`
3. Reboot when prompted
4. After reboot, Ubuntu setup will launch — choose a username and password
5. Return to PowerShell and press Enter to continue bootstrap

**Verify afterward:**

```powershell
wsl --status
# Should show: Default Version: 2
```

### Developer Mode (Optional but Recommended)

Unlocks symlinks without elevation and sideloading for development tools.

**If bootstrap prompts:**

1. Open **Settings > Privacy & Security > For Developers**
   - Or search "Developer Mode" in Settings
2. Toggle **Developer Mode** to **On**
3. Accept the confirmation dialog
4. Return to PowerShell and press Enter to continue bootstrap

## Step 3: Provide Credentials

Bootstrap Phase 4 prompts for three credentials stored in Windows Credential Manager.

### GitHub Personal Access Token (Required)

Needed for:
- `gh` CLI (push code, manage PRs)
- Claude Code (fetch documentation)
- Git operations over HTTPS

**Create at:** [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new)

**Required scopes:**
- `repo` (read/write code)
- `workflow` (manage GitHub Actions)
- `read:org` (read organization metadata)

**No expiration recommended** for a development machine. If you choose expiration, renew before it expires.

When bootstrap prompts, paste the token. It should start with `ghp_`, `ghs_`, or `github_pat_`.

### Anthropic API Key (Required)

Needed for:
- Claude Code CLI operations
- Any Claude API calls from your scripts

**Create at:** [https://console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)

**Billing:** Set up a billing method on the Anthropic console. Free trial credits may be available.

When bootstrap prompts, paste the key. It should start with `sk-ant-`.

### Docker Hub Token (Optional)

Needed only if you pull private Docker images.

**Create at:** [https://hub.docker.com/settings/security](https://hub.docker.com/settings/security)

Click **New Access Token**, choose read/write access.

Bootstrap marks this as optional. Press Enter to skip if you don't need private Docker image access.

## Step 4: Claude Code Authentication

After Phase 5 completes, bootstrap checks if Claude Code is authenticated.

**If prompted to authenticate:**

1. Run: `claude auth login`
2. A browser window opens for authentication
3. Sign in with your Anthropic account
4. Return to PowerShell and press Enter to confirm

**Verify afterward:**

```powershell
claude --version
# Should print version number, not an error
```

## Step 5: Verify Installation

Phase 6 runs automatically and shows a pass/fail table for all tools and features.

**Expected results (all green):**

- ✅ git, gh, go, node, docker, code, claude, pwsh, rustup, cmake
- ✅ Hyper-V, WSL2, Virtualization, Developer Mode
- ✅ GitHub PAT, Anthropic Key, (Docker Hub optional)
- ✅ All Claude skills deployed

**If any items show FAIL:**

- For **Windows features** (Hyper-V, WSL2): Go back to Step 2 and rerun the manual steps
- For **tools** (git, node, docker): Run `winget upgrade <tool>` or re-run Phase 2
- For **credentials**: Run Phase 4 again (`pwsh -File D:\DevSpace\devkit\setup\bootstrap.ps1 -Phase 4`)
- For **Claude authentication**: Run `claude auth login` again

## Step 6: Next Steps

After bootstrap completes successfully:

### 1. Open a New Terminal

Close the current PowerShell window. Open a new PowerShell or Windows Terminal window. This picks up profile changes and environment variables.

### 2. Start a Claude Code Session

```powershell
claude
```

This opens an interactive Claude Code session. You can now use all devkit skills and rules.

### 3. Use the devkit Alias

Anytime you need to re-run bootstrap or access setup options:

```powershell
devkit
```

This is a shortcut to the main bootstrap script. Use `-Phase N` to run a single phase.

**Examples:**

```powershell
# Re-run Phase 4 (credentials)
devkit -Phase 4

# Re-run Phase 5 (Claude Code setup)
devkit -Phase 5

# Full bootstrap with all phases
devkit
```

### 4. Configure Docker Desktop

Phase 2 installs Docker Desktop, but you must configure it manually:

1. Open **Docker Desktop** (it appears in the system tray)
2. Click the gear icon (Settings)
3. Go to **General** — ensure "Use the WSL 2 based engine" is checked
4. Go to **Resources > Advanced** — set Memory to 8 GB (or half your total RAM)
5. Click **Apply & Restart**

### 5. Verify Docker Works

```powershell
docker run --rm hello-world
```

This pulls a test image and runs it. You should see "Hello from Docker!" message.

## Troubleshooting

### winget Not Found

`winget` comes with Windows 11 and recent Windows 10 builds. If it's missing:

1. Install via Microsoft Store: [App Installer](https://www.microsoft.com/en-us/p/app-installer/9nblggh4nns1)
2. Re-run bootstrap

**Or manually:** Search "App Installer" in Microsoft Store and install.

### Hyper-V Greyed Out

If the Hyper-V checkbox is disabled (greyed out):

- **Check Windows edition:** Hyper-V requires Windows **Pro**, **Enterprise**, or **Education**. Home edition doesn't support it.
- **Check BIOS:** Enter BIOS/UEFI and enable hardware virtualization:
  - Intel: Advanced > CPU Configuration > Intel Virtualization Technology (VT-x)
  - AMD: Advanced > CPU Configuration > SVM Mode
  - Reboot after enabling

If you're on Home edition and can't upgrade, Docker Desktop can fall back to WSL2 without Hyper-V, but performance will be degraded.

### Claude auth login Hangs or Opens Wrong Browser

If the browser doesn't open or gets stuck:

1. Press Ctrl+C to cancel
2. Copy the authentication URL manually
3. Paste it in your default browser
4. Sign in
5. Return to PowerShell and press Enter

Alternatively, set the `ANTHROPIC_API_KEY` environment variable directly:

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."
claude --version
```

This skips authentication and uses the API key directly. Verify it works before closing the terminal.

### PowerShell Execution Policy Error

If you get "cannot be loaded because running scripts is disabled":

- Verify you're running PowerShell 7+ (`pwsh`, not `powershell`)
- Try the command again with `-ExecutionPolicy Bypass` explicitly
- If the issue persists, check your machine's execution policy:

```powershell
Get-ExecutionPolicy
# If it shows "Restricted", you may need admin help to change it
# But -ExecutionPolicy Bypass should work regardless
```

### Bootstrap Fails on Phase 2 (winget packages)

**Common causes:**

1. **Network issue:** Make sure you're connected to the internet
2. **winget database corrupt:** Try `winget upgrade --all --include-unknown` first
3. **Specific package fails:** Check the error message and re-run Phase 2 only:

```powershell
devkit -Phase 2
```

The script skips packages that are already installed, so re-running is safe.

### Docker Desktop Hangs After Install

Docker Desktop may take 5-10 minutes to start after installation. Wait before moving on.

If it stays hung:

1. Reboot
2. Open Docker Desktop again from the Start menu
3. Wait for the whale icon to appear in the system tray

### Claude Not Found After Bootstrap

Verify Node.js installed correctly:

```powershell
node --version
npm --version
```

Then install Claude Code manually:

```powershell
npm install -g @anthropic-ai/claude-code
claude --version
```

## Getting Help

If bootstrap fails or you encounter issues:

1. **Check the summary table** at the end of Phase 6 — it shows exactly what failed
2. **Run individual phases** to isolate the problem:
   - `devkit -Phase 1` — just pre-flight checks
   - `devkit -Phase 2` — just tool installs
   - etc.
3. **Review the troubleshooting section above** for your specific error
4. **Check GitHub Issues:** [https://github.com/HerbHall/devkit/issues](https://github.com/HerbHall/devkit/issues)

## What's Installed

After bootstrap completes, you have:

| Category | What | Location |
|----------|------|----------|
| **Version Control** | Git 2.4+, GitHub CLI | via winget |
| **Languages** | Go 1.20+, Node.js 18+, Python 3, Rust | via winget |
| **Development** | VS Code, Docker Desktop, CMake | via winget |
| **Cloud** | Claude Code CLI, Anthropic API key | npm + manual config |
| **Workflow** | 5 rules files (70+ patterns), 15 skills, 6 agent templates | `~/.claude/` |
| **Configuration** | git user config, devspace root path, PowerShell aliases | `~/.gitconfig`, `~/.devkit-config.json`, PowerShell profile |

## Next: Create Your First Project

Now that your machine is set up, create your first project:

```powershell
cd D:\DevSpace
mkdir my-project
cd my-project
git init
```

Copy the CLAUDE.md template from devkit:

```powershell
cp D:\DevSpace\devkit\project-templates\workspace-claude-md-template.md CLAUDE.md
# Edit CLAUDE.md with your project-specific details
```

Start a Claude Code session:

```powershell
claude
```

You're ready to develop. See `METHODOLOGY.md` in devkit for a structured development process.
