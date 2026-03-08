# DevKit Sync: New Project

Scaffold a new project directory with DevKit templates and an optional stack profile.

## Steps

1. **Gather project info from the user:**

   Ask the user for:

   - **Project name** (kebab-case, e.g., `my-tool`)
   - **One-line description** (what does this project do?)
   - **Profile** -- one of: `go-cli`, `go-web`, `node-extension`, `go-extension`, `rust-cli`, `dotnet-desktop`, `react-frontend`, `iot-embedded`, or `none`
   - **Samverk managed?** [y/N] -- Add Samverk lifecycle overlay (phase tracking, agent labels,
     coordination). Can also be added later via `devkit-sync` -> Apply Samverk.

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

   Community health files (also always-included):

   ```bash
   mkdir -p <devspace>/<project-name>/.github/ISSUE_TEMPLATE
   ```

   - `project-templates/CONTRIBUTING.md` to `<project>/CONTRIBUTING.md`
     - Replace `{{PROJECT_NAME}}` with the project name
   - `project-templates/CODE_OF_CONDUCT.md` to `<project>/CODE_OF_CONDUCT.md`
   - `project-templates/SECURITY.md` to `<project>/SECURITY.md`
     - Replace `{{PROJECT_NAME}}` with the project name
   - `project-templates/CODEOWNERS` to `<project>/.github/CODEOWNERS`
     - Replace `{{OWNER}}` with the GitHub owner
   - `project-templates/pull_request_template.md` to `<project>/.github/pull_request_template.md`
   - `project-templates/bug_report.yml` to `<project>/.github/ISSUE_TEMPLATE/bug_report.yml`
     - Replace `{{PROJECT_NAME}}` with the project name
   - `project-templates/feature_request.yml` to `<project>/.github/ISSUE_TEMPLATE/feature_request.yml`
     - Replace `{{PROJECT_NAME}}` with the project name

   Use the Read tool to load each template, perform substitutions, then Write the result.

6. **Copy Copilot templates (always-included):**

   Create the directories:

   ```bash
   mkdir -p <devspace>/<project-name>/.github/instructions
   ```

   Copy with substitutions:

   - `project-templates/copilot-instructions.md` to `<project>/.github/copilot-instructions.md`
     - Replace `{{PROJECT_NAME}}` with the project name
     - Replace `{{PROJECT_DESCRIPTION}}` with the description
     - Replace `{{TECH_STACK_SECTION}}` with stack info based on profile
   - `project-templates/AGENTS.md` to `<project>/AGENTS.md`
     - Replace `{{PROJECT_NAME}}` with the project name
     - Replace `{{PROJECT_DESCRIPTION}}` with the description
     - Replace `{{TECH_STACK_SECTION}}` with stack info based on profile
     - Replace `{{PROJECT_STRUCTURE}}` with the project structure from CLAUDE.md

7. **Copy profile-specific templates (go-cli or go-web only):**

   If the user selected `go-cli` or `go-web`, copy these additional files:

   - `project-templates/golangci.yml` to `<project>/.golangci.yml`
   - `project-templates/Makefile.go` to `<project>/Makefile`
     - Replace `{{PROJECT_NAME}}` with the project name
     - Replace `{{OWNER}}` with the GitHub owner (from `gh api user --jq '.login'`)
   - `project-templates/ci.yml` to `<project>/.github/workflows/ci.yml`
     - Replace `{{PROJECT_NAME}}` with the project name
   - `project-templates/codeql.yml` to `<project>/.github/workflows/codeql.yml`
   - `project-templates/instructions/go.instructions.md` to `<project>/.github/instructions/go.instructions.md`

   If `go-web` profile, also copy:

   - `project-templates/instructions/react.instructions.md` to `<project>/.github/instructions/react.instructions.md`
     - Replace `{{FRONTEND_PATH}}` with `web` (or the project's frontend path)
   - `project-templates/copilot-setup-steps-fullstack.yml` to `<project>/.github/workflows/copilot-setup-steps.yml`
   - `project-templates/nightly-go.yml` to `<project>/.github/workflows/nightly.yml`
     - Replace `{{DOCKER_IMAGE}}`, `{{VERSION_PACKAGE}}`, `{{BINARY_NAME}}`, `{{BINARY_CMD}}`
     - Keep FRONTEND blocks (project has a frontend)

   If `go-cli` profile, copy:

   - `project-templates/copilot-setup-steps-go.yml` to `<project>/.github/workflows/copilot-setup-steps.yml`
   - `project-templates/nightly-go.yml` to `<project>/.github/workflows/nightly.yml`
     - Replace `{{DOCKER_IMAGE}}`, `{{VERSION_PACKAGE}}`, `{{BINARY_NAME}}`, `{{BINARY_CMD}}`
     - Remove all lines marked `# FRONTEND:` (CLI-only, no frontend)

   Create the `.github/workflows/` directory first:

   ```bash
   mkdir -p <devspace>/<project-name>/.github/workflows
   ```

   CodeQL, instructions, and setup-steps files are copied as-is unless noted.

   **Release gate (all profiles with release-please):**

   - `project-templates/release-gate.yml` to `<project>/.github/workflows/release-gate.yml`
     - No substitutions needed (language-agnostic)

   **Nightly builds for non-Go profiles:**

   - `node-extension` or `go-extension` profile: copy `project-templates/nightly-node.yml` to `<project>/.github/workflows/nightly.yml`
     - Replace `{{DOCKER_IMAGE}}`
   - `rust-cli` profile: copy `project-templates/nightly-rust.yml` to `<project>/.github/workflows/nightly.yml`
     - Replace `{{BINARY_NAME}}`

   **If `node-extension` profile**, copy these additional files:

   - `project-templates/Makefile.node-extension` to `<project>/Makefile`
     - Replace `{{DOCKER_IMAGE}}` with the Docker Hub image name
   - `project-templates/eslint.config.js` to `<project>/eslint.config.js`
   - `project-templates/tsconfig.json` to `<project>/tsconfig.json`
   - `project-templates/gitignore-node` to `<project>/.gitignore`
   - `project-templates/ci-node.yml` to `<project>/.github/workflows/ci.yml`
   - `project-templates/instructions/react.instructions.md` to `<project>/.github/instructions/react.instructions.md`
     - Replace `{{FRONTEND_PATH}}` with `ui`

   **If `go-extension` profile**, copy these additional files:

   - `project-templates/golangci.yml` to `<project>/.golangci.yml`
   - `project-templates/Makefile.node-extension` to `<project>/Makefile`
     - Replace `{{DOCKER_IMAGE}}` with the Docker Hub image name
   - `project-templates/eslint.config.js` to `<project>/eslint.config.js`
   - `project-templates/tsconfig.json` to `<project>/tsconfig.json`
   - `project-templates/gitignore-go` to `<project>/.gitignore`
   - `project-templates/ci.yml` to `<project>/.github/workflows/ci.yml`
     - Replace `{{PROJECT_NAME}}` with the project name
   - `project-templates/instructions/go.instructions.md` to `<project>/.github/instructions/go.instructions.md`
   - `project-templates/instructions/react.instructions.md` to `<project>/.github/instructions/react.instructions.md`
     - Replace `{{FRONTEND_PATH}}` with `ui`

   **If `rust-cli` profile**, copy these additional files:

   - `project-templates/Makefile.rust` to `<project>/Makefile`
     - Replace `{{BINARY_NAME}}` with the binary name
   - `project-templates/gitignore-rust` to `<project>/.gitignore`
   - `project-templates/ci-rust.yml` to `<project>/.github/workflows/ci.yml`

   **If `dotnet-desktop` profile**, copy these additional files:

   - `project-templates/gitignore-dotnet` to `<project>/.gitignore`
   - `project-templates/ci-dotnet.yml` to `<project>/.github/workflows/ci.yml`

   **If `react-frontend` profile**, copy these additional files:

   - `project-templates/Makefile.node` to `<project>/Makefile`
   - `project-templates/eslint.config.js` to `<project>/eslint.config.js`
   - `project-templates/tsconfig.json` to `<project>/tsconfig.json`
   - `project-templates/gitignore-node` to `<project>/.gitignore`
   - `project-templates/ci-node.yml` to `<project>/.github/workflows/ci.yml`

8. **Validate template substitutions:**

   Scan all files in the new project for unreplaced template placeholders:

   ```bash
   grep -rn '{{' <devspace>/<project-name>/ --include='*' || echo "All placeholders replaced"
   ```

   If any `{{PLACEHOLDER}}` patterns remain, report them with file path and line number. Do NOT proceed to GitHub repo creation or the summary until all placeholders are resolved.

   For each unreplaced placeholder, tell the user: "Replace `{{PLACEHOLDER}}` with the actual value in `<file>`"

9. **Optionally apply Samverk overlay (if requested in step 1):**

   If the user answered yes to "Samverk managed?", follow the same steps as
   `workflows/apply-samverk.md` but skip the confirmation prompt for existing overlays
   (this is a fresh project, so no overlay can exist yet).

   Edge case: if the Samverk overlay spec cannot be located (step 2 of apply-samverk.md
   fails), skip the overlay, note: "Samverk overlay requested but Samverk repo not found.
   Apply later with: devkit-sync -> Apply Samverk."

10. **Optionally create a GitHub repo:**

    Ask the user: "Create a GitHub repo for this project? [y/N]"

    If yes:

    ```bash
    cd <devspace>/<project-name>
    git add -A
    git commit -m "chore: initial project scaffolding"
    gh repo create <owner>/<project-name> --private --source=. --remote origin --push
    ```

    Determine `<owner>` from `gh api user --jq '.login'` or `git config --global user.name`.

11. **Report summary:**

    Display what was created:

    - Project directory path
    - Files created (list each one)
    - Git initialized (with or without template)
    - GitHub repo URL (if created)
    - Samverk overlay applied (if requested)

    Suggest next steps:

    - Edit `CLAUDE.md` to fill in remaining TODO sections
    - Edit `AGENTS.md` to add project-specific tech stack and structure
    - Edit `.github/copilot-instructions.md` to fill in tech stack details
    - Review `.claude/settings.json` and adjust permissions
    - If Samverk overlay applied: review `.samverk/status.md` and update with current state
    - Add source code and start building
    - Run `claude` in the project directory to begin development

## Edge Cases

- Project directory already exists: warn and confirm before continuing
- `.devkit-config.json` missing: ask user for DevSpace path
- `git-templates/` not found in DevKit: fall back to plain `git init`
- `gh` not authenticated: skip GitHub repo creation, tell user the manual command
- Profile `iot-embedded` or `none`: no extra templates are copied (only always-included files)
- Samverk overlay requested but Samverk repo not found: skip overlay, note the manual command
