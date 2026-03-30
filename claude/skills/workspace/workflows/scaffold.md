# Scaffold Workspace

Creates a new `.code-workspace` file for a project using the DevKit template with the correct stack fragment merged in.

## Steps

1. Determine the target project path:
   - If the user specified a path, use that.
   - Otherwise, use the current working directory as the project root.

2. Detect the project name from the directory name (e.g., `SubNetree` from `D:\DevSpace\SubNetree`).

3. Check whether `<project-root>/<project-name>.code-workspace` already exists:
   - If it exists and is valid, report it and ask whether to overwrite or abort.
   - If it exists but has issues (stale-path, no extensions), offer to repair instead.

4. Detect the stack profile from the project root:
   - `go.mod` present → `go`
   - `package.json` present → `typescript`
   - `Cargo.toml` present → `rust` (note: no fragment yet, falls back to base)
   - `*.csproj` present → `csharp` (note: no fragment yet, falls back to base)
   - None of the above → `base`

5. Load the matching settings fragment from `devspace/shared-vscode/<stack>.jsonc` (if available).

6. Load extension recommendations from `devspace/shared-vscode/extensions.jsonc` for the detected stack plus general extensions.

7. Create the workspace file at the canonical path:
   - `folders[0].path` = `.`
   - `settings` = merged from stack fragment (or empty object if no fragment)
   - `extensions.recommendations` = stack + general extensions

8. Update `~/.devkit-registry.json` to set:
   - `vscodeWorkspace.path` = absolute path to the new workspace file
   - `vscodeWorkspace.lastSynced` = current ISO 8601 timestamp
   - `vscodeWorkspace.stackProfile` = detected stack

9. Report the created file path and remind the user to:
   - Review settings in the workspace file
   - Remove any settings that duplicate VS Code User Settings
   - Open VS Code using the new workspace file: `code <project-name>.code-workspace`

## Notes

- For `rust` and `csharp` stacks, no settings fragment exists yet — the workspace is scaffolded with an empty settings block and general extensions only.
- The scaffolded file is a starting point. Projects own their copy and can diverge from the template as needed.
- If `devspace/shared-vscode/extensions.jsonc` is not found relative to the DevKit root, extensions are scaffolded as an empty array with a warning.
