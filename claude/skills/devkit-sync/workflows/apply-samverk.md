# DevKit Sync: Apply Samverk

Add the Samverk lifecycle overlay to an existing DevKit-configured project.

## Steps

1. **Check for existing overlay:**

   ```bash
   ls <project-root>/.samverk/ 2>/dev/null
   ```

   If `.samverk/` already exists, warn the user:
   "This project already has a Samverk overlay (`.samverk/` exists). Re-applying will
   overwrite `project.yaml` and re-apply overlay labels. Continue? [y/N]"

   If the user declines, end the workflow.

2. **Locate the Samverk overlay spec:**

   Try in order:

   a. Check sibling DevSpace directory: `<devspace-path>/Samverk/overlay/`
      (read `devspacePath` from `.devkit-config.json`)

   b. Check known absolute path: `D:\DevSpace\Samverk\overlay\` (Windows)
      or `~/DevSpace/Samverk/overlay/` (Unix)

   c. Fetch via Samverk MCP `read_file` tool:
      `project: samverk`, `path: overlay/labels.json`

   If none of the above succeed, report: "Samverk overlay spec not found. Clone
   Samverk into your DevSpace directory, or ensure the Samverk MCP is configured."

3. **Gather project info:**

   Auto-detect from the current project directory:

   - **Project name**: use the directory name as default, confirm with user
   - **Forge URL**: `git remote get-url origin`
   - **Forge type**: detect from URL (`github.com` -> `github`, `gitea` hostname -> `gitea`)
   - **Owner**: extract from forge URL

   If `git remote get-url origin` fails (no remote configured), set forge to `none`
   and repo to empty string.

4. **Create the `.samverk/` directory:**

   ```bash
   mkdir -p <project-root>/.samverk
   ```

5. **Generate `project.yaml`:**

   Write `.samverk/project.yaml` with this template:

   ```yaml
   # Samverk project overlay -- managed by Samverk lifecycle system
   project:
     name: PROJECT_NAME
     description: ""
     forge: FORGE_TYPE
     repo: OWNER/REPO
     registered: YYYY-MM-DD

   lifecycle:
     phase: intake
     started: YYYY-MM-DD
     last_updated: YYYY-MM-DD

   agents:
     orchestrator: enabled
     dispatcher: enabled
     code_gen: enabled
   ```

   Substitute `PROJECT_NAME`, `FORGE_TYPE`, `OWNER/REPO`, and today's date for all
   date fields.

6. **Generate `status.md`:**

   Write `.samverk/status.md` with this template:

   ```markdown
   # PROJECT_NAME -- Samverk Status

   **Phase**: intake
   **Last updated**: YYYY-MM-DD
   **Session summary**: Initial overlay applied.

   ## Current State

   - Overlay applied. Update this file with current project state.

   ## In-Flight Issues

   None yet.

   ## Next Session

   - Review open issues and assign to phase
   - Update phase if intake complete
   ```

   Substitute `PROJECT_NAME` and today's date.

7. **Apply overlay labels:**

   Read the `labels.json` from the Samverk overlay spec located in step 2.
   For each label entry, run:

   ```bash
   gh label create "LABEL_NAME" \
     --color "COLOR" \
     --description "DESCRIPTION" \
     --force
   ```

   The `--force` flag updates existing labels without error.

   If `gh` is not authenticated or the repo has no remote (`forge: none`), skip this
   step and tell the user: "Skipped label application -- no GitHub remote configured.
   Apply labels manually using the Samverk overlay spec."

8. **Update DevKit registry (if available):**

   Check if `~/.devkit-registry.json` exists and contains this project:

   ```bash
   cat ~/.devkit-registry.json
   ```

   If the project entry exists, add or update the `samverk` field:

   ```json
   "samverk": {
     "managed": true,
     "phase": "intake"
   }
   ```

   Use Python to update the JSON to avoid `jq` dependency:

   ```bash
   python3 -c "
   import json, sys
   with open('$HOME/.devkit-registry.json') as f:
       reg = json.load(f)
   for p in reg['projects']:
       if p['path'] == 'PROJECT_PATH':
           p['samverk'] = {'managed': True, 'phase': 'intake'}
           break
   with open('$HOME/.devkit-registry.json', 'w') as f:
       json.dump(reg, f, indent=2)
   print('Registry updated.')
   "
   ```

   If the registry doesn't exist or the project isn't registered, skip silently.

9. **Commit overlay files:**

   ```bash
   cd <project-root>
   git add .samverk/project.yaml .samverk/status.md
   git commit -m "chore: apply Samverk lifecycle overlay

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

10. **Report summary:**

    Display:

    - Overlay applied to: `<project-path>`
    - Files created: `.samverk/project.yaml`, `.samverk/status.md`
    - Overlay labels applied: N labels (or "skipped -- no GitHub remote")
    - Registry updated: yes/no

    Suggest next steps:

    - Edit `.samverk/status.md` to reflect current project state
    - Review `.samverk/project.yaml` and update `description` and `lifecycle.phase`
    - Open the Samverk dispatcher to begin routing issues: `/dashboard` in Samverk context
    - If labels were skipped, apply manually:
      `gh label create ...` using `Samverk/overlay/labels.json`

## Edge Cases

- **Existing overlay**: warn and confirm before overwriting
- **No git remote**: skip label application and registry update; note manual steps
- **`gh` not authenticated**: skip label application; tell user the manual command
- **Gitea forge**: `gh` targets GitHub only; skip label application for Gitea repos
- **Samverk repo not found**: report clearly, provide manual clone command
- **Project not in registry**: skip registry update silently (not an error)
