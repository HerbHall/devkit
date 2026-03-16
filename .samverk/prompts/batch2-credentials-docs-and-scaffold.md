# Next Priority Work

All PRs merged — nice work. Here are the remaining items from the credentials migration plus new work from the roadmap.

## Job 1: Credentials Documentation

**Branch:** `docs/credentials-management`

Create `docs/credentials.md` documenting the new vault-based system:

### Content to include:

**Architecture overview:**
- Source of truth: PowerShell SecretStore vault (HomeLabVault, PS7 only)
- Universal access: all secrets are also persistent user-level env vars (HKCU\Environment)
- Every shell (PS5, PS7, CMD, Git Bash, WSL) inherits env vars automatically
- Diagram: vault → user env vars → all shells → application code

**Env var reference table:**

| Env Var | Vault Name | Used By |
|---------|-----------|---------|
| ANTHROPIC_API_KEY | anthropic/api-key | Claude API, ai-review |
| OPENAI_API_KEY | openai/api-key | OpenAI API |
| GITHUB_TOKEN | github/pat-personal | gh CLI, GitHub Actions, release-please |
| GITHUB_MCP_TOKEN | github/pat-mcp | GitHub MCP server (Docker) |
| GITEA_TOKEN | gitea/pat-homelab | Gitea API, Samverk Gitea forge |
| GITEA_DISPATCHER_TOKEN | gitea/pat-dispatcher | Gitea Actions dispatcher |
| CLOUDFLARE_API_TOKEN | cloudflare/api-token | Caddy DNS challenge, Cloudflare Pages |
| HOME_ASSISTANT_TOKEN | homeassistant/token | HA API, hass-mcp |
| SAMVERK_AUTH_TOKEN | samverk/auth-token | Samverk MCP bearer auth |

**How-to sections:**
- Add a new secret: `nvs 'category/name' 'value'` in PS7, then `sync-secrets`
- Rotate a secret: update vault with `nvs`, run `sync-secrets`, restart shells, run `Set-DevkitSecrets.ps1` for GitHub Actions
- How Set-DevkitSecrets.ps1 vault fallback works (detects `_note` field, reads env vars)
- Claude Desktop MCP config: secrets come from env vars, not manual entry

## Job 2: Update MCP Template

**Branch:** `chore/update-mcp-template`

Update `mcp/claude-desktop.template.json`:
- Replace all `<PLACEHOLDER>` values with comments explaining which env var provides each secret
- Add a header comment block explaining that secrets come from the vault system via env vars
- Document that after running `sync-secrets`, env vars are available to all MCP servers automatically
- Add the new `ollama-local` entry (localhost:11435) alongside the existing ollama VM entry

Also update `mcp/memory-seeds.md` if it references the old credential system.

## Job 3: Clean Up Stale Files

**Branch:** `chore/cleanup-stale-files`

- Delete `devspace/templates/handoff-OpenBrain.md` — project renamed to Synapset, this is stale
- Check `.gitignore` covers: `.devkit-config.json.bak`, `.credentials.bak-*`, `auth.yaml`
- Check for any other references to "OpenBrain" in the codebase and update to "Synapset" if found

## Job 4: Scaffold Improvements for Gitea Projects

**Branch:** `feat/gitea-scaffold-support`

The `setup/new-project.ps1` currently assumes GitHub as the forge. We need it to support Gitea for Samverk-managed projects. Review the script and:

1. **Add a `-Gitea` switch** (or `-Forge gitea`) parameter that:
   - Creates the repo on gitea.herbhall.net instead of GitHub
   - Uses the Gitea API with `GITEA_TOKEN` env var
   - Skips GitHub-specific steps (gh CLI, GitHub labels)
   - Applies Gitea-specific labels from `project-templates/gitea-labels.json` (create this file if missing, base it on `github-labels.json`)

2. **Add Gitea Actions workflow template** to `project-templates/`:
   - `ci-go-gitea.yml` — Go build/test/lint for Gitea Actions
   - Based on the existing `ci.yml` but adapted for Gitea Actions syntax

3. **Update `setup/lib/forge-wrappers.ps1`** — verify that `New-ForgeRepo` and `New-ForgeLabel` have Gitea implementations (they may already from the recent forge migration work). If not, add them.

4. **Test:** Run `new-project.ps1 -Name test-gitea -Profile go-cli -Gitea -Samverk -NoGitHub` in a dry-run or with a test project name to verify the flow works.

## Rules
- Never commit to main. Branch per job.
- Conventional commits. Push and create PRs via `gh pr create`.
- Keep each job as a separate branch/PR so they can be reviewed independently.
