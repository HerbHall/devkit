# CLAUDE.md Automation Setup

Your Claude Code environment is now configured to automatically suggest and create CLAUDE.md files for all projects!

## What Was Installed

### 1. SessionStart Hook
**Location**: [~/.claude/hooks/SessionStart.sh](~/.claude/hooks/SessionStart.sh)

Automatically runs when you start Claude Code in a project directory. It:
- Detects if you're in a project (checks for `.git`, `package.json`, etc.)
- Checks if `CLAUDE.md` exists
- Prompts you once per project to create CLAUDE.md
- Never prompts again after you've seen the message (creates `.claude-init-prompted` flag)

### 2. Git Template Directory
**Location**: [~/.git-templates/](~/.git-templates/)

Configured git to automatically include CLAUDE.md when you run `git init`:
- Includes starter CLAUDE.md template
- Includes .gitignore entries for CLAUDE.local.md

**Configuration**: `git config --global init.templateDir '~/.git-templates'`

### 3. Shell Helper Functions
**Location**: [~/.claude/claude-functions.sh](~/.claude/claude-functions.sh)

Provides convenient commands for managing CLAUDE.md files.

## How to Activate Shell Functions

Add this line to your `~/.bashrc` or `~/.bash_profile`:

```bash
source ~/.claude/claude-functions.sh
```

Then reload your shell:
```bash
source ~/.bashrc
```

## Available Commands

Once activated, you'll have these commands:

### `claude-init-project <name> [directory]`
Initialize a new project with CLAUDE.md from scratch.

```bash
# Initialize in current directory
claude-init-project my-app

# Initialize in a new directory
claude-init-project my-api ./backend
```

### `claude-add-config`
Add CLAUDE.md to an existing project.

```bash
cd /path/to/existing/project
claude-add-config
```

### `claude-edit`
Quick edit current project's CLAUDE.md.

```bash
claude-edit
```

### `claude-edit-global`
Edit your global CLAUDE.md configuration.

```bash
claude-edit-global
```

### `claude-status`
Check configuration status (global config, templates, hooks, current project).

```bash
claude-status
```

### `claude-help`
Show available commands.

```bash
claude-help
```

## How It Works

### For New Projects

**Option 1: Using git init**
```bash
mkdir my-project
cd my-project
git init  # CLAUDE.md is automatically created!
```

**Option 2: Using claude-init-project**
```bash
claude-init-project my-project
cd my-project
```

### For Existing Projects

**Option 1: SessionStart Hook (Automatic)**
- Just start Claude Code in the project directory
- You'll see a message suggesting to create CLAUDE.md
- Ask Claude to create it, or use the template

**Option 2: Manual with Helper Function**
```bash
cd /path/to/project
claude-add-config
```

**Option 3: Ask Claude**
Just tell Claude: "Create a CLAUDE.md for this project"

## Files Created

### Templates
- `~/.claude/CLAUDE.md` - Global configuration (active for all sessions)
- `~/.claude/CLAUDE.md.template` - Full project template
- `~/.claude/CLAUDE.local.md.template` - Personal preferences template

### Automation
- `~/.claude/hooks/SessionStart.sh` - Auto-detection hook
- `~/.claude/claude-functions.sh` - Helper commands
- `~/.git-templates/CLAUDE.md` - Git template starter
- `~/.git-templates/.gitignore` - Git template gitignore

## File Hierarchy

When Claude Code starts, it reads CLAUDE.md files in this order:

1. **Global**: `~/.claude/CLAUDE.md` (your high-level defaults)
2. **Project**: `./CLAUDE.md` (project-specific details)
3. **Personal**: `./CLAUDE.local.md` (your personal preferences, gitignored)

## Disabling the SessionStart Hook

If you don't want the automatic prompts:

```bash
# Temporarily disable
chmod -x ~/.claude/hooks/SessionStart.sh

# Re-enable
chmod +x ~/.claude/hooks/SessionStart.sh

# Delete entirely
rm ~/.claude/hooks/SessionStart.sh
```

## Per-Project Opt-Out

To stop prompts in a specific project:

```bash
# The hook creates this file after first prompt
touch .claude-init-prompted
```

## Next Steps

1. **Activate shell functions** (add to ~/.bashrc):
   ```bash
   source ~/.claude/claude-functions.sh
   ```

2. **Test with a new project**:
   ```bash
   claude-init-project test-project
   ```

3. **Add to existing projects**:
   ```bash
   cd /path/to/existing/project
   claude-add-config
   ```

4. **Start Claude Code** in any project and see the automation in action!

## Troubleshooting

**SessionStart hook not running?**
- Check Claude Code documentation for hook configuration
- Ensure hook is executable: `chmod +x ~/.claude/hooks/SessionStart.sh`

**Git template not working?**
- Verify config: `git config --global --get init.templateDir`
- Should show: `~/.git-templates`

**Shell functions not available?**
- Ensure you sourced the file: `source ~/.claude/claude-functions.sh`
- Add to ~/.bashrc to make permanent

**Check overall status:**
```bash
claude-status
```

---

Your Claude Code workflow is now fully automated! 🎉
