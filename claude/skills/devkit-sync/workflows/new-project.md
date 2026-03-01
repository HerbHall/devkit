# DevKit Sync: New Project

Scaffold a new project directory with DevKit templates and an optional stack profile.

## Steps

1. **Gather project info from the user:**

   Ask the user for:

   - **Project name** (kebab-case, e.g., `my-tool`)
   - **One-line description** (what does this project do?)
   - **Profile** -- one of: `go-cli`, `go-web`, `iot-embedded`, or `none`

   Validate the project name: letters, numbers, and hyphens only, must start with a letter or number.

2. **Resolve the DevSpace path:**

   Read `.devkit-config.json` from the DevKit clone root directory. Use the `devspacePath` field to find the DevSpace directory.

   ```bash
   cat <devkit-root>/.devkit-config.json
   ```

   If the file does not exist or `devspacePath` is missing, ask the user for their DevSpace path (e.g., `D:\DevSpace` or `~/workspace`).

3. **Create the project directory:**

   ```bash
   mkdir -p <devspace>/<project-name>
   ```

   If the directory already exists, warn the user and ask whether to continue.

4. **Initialize git:**

   Check if `git-templates/` exists in the DevKit clone. If it does, use it as the template directory:

   ```bash
   git init --template=<devkit-root>/git-templates <devspace>/<project-name>
   ```

   If `git-templates/` does not exist, use a plain init:

   ```bash
   git init <devspace>/<project-name>
   ```

5. **Copy always-included templates:**

   These files are copied for every project regardless of profile.

   First, create the `.claude/` directory:

   ```bash
   mkdir -p <devspace>/<project-name>/.claude
   ```

   Then copy:

   - `project-templates/claude-md-template.md` to `<project>/CLAUDE.md`
     - Replace `{{PROJECT_NAME}}` with the project name
     - Replace `{{PROJECT_DESCRIPTION}}` with the description
     - Replace `{{PROFILE}}` with the selected profile (or `none`)
     - Replace `{{DEVSPACE}}` with the resolved DevSpace path
   - `project-templates/settings.json` to `<project>/.claude/settings.json`

   Use the Read tool to load each template, perform substitutions, then Write the result.

6. **Copy profile-specific templates (go-cli or go-web only):**

   If the user selected `go-cli` or `go-web`, copy these additional files:

   - `project-templates/golangci.yml` to `<project>/.golangci.yml`
   - `project-templates/Makefile.go` to `<project>/Makefile`
   - `project-templates/ci.yml` to `<project>/.github/workflows/ci.yml`

   Create the `.github/workflows/` directory first:

   ```bash
   mkdir -p <devspace>/<project-name>/.github/workflows
   ```

   These files are copied as-is without substitution.

7. **Optionally create a GitHub repo:**

   Ask the user: "Create a GitHub repo for this project? [y/N]"

   If yes:

   ```bash
   cd <devspace>/<project-name>
   git add -A
   git commit -m "chore: initial project scaffolding"
   gh repo create <owner>/<project-name> --private --source=. --remote origin --push
   ```

   Determine `<owner>` from `gh api user --jq '.login'` or `git config --global user.name`.

8. **Report summary:**

   Display what was created:

   - Project directory path
   - Files created (list each one)
   - Git initialized (with or without template)
   - GitHub repo URL (if created)

   Suggest next steps:

   - Edit `CLAUDE.md` to fill in remaining TODO sections
   - Review `.claude/settings.json` and adjust permissions
   - Add source code and start building
   - Run `claude` in the project directory to begin development

## Edge Cases

- Project directory already exists: warn and confirm before continuing
- `.devkit-config.json` missing: ask user for DevSpace path
- `git-templates/` not found in DevKit: fall back to plain `git init`
- `gh` not authenticated: skip GitHub repo creation, tell user the manual command
- Profile `iot-embedded`: no extra templates are copied (only always-included files)
- Profile `none`: no extra templates are copied (only always-included files)
