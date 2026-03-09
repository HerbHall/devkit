# Credentials Management

DevKit uses a centralized vault-based credential system. Secrets are stored once
in an encrypted vault and made available to all shells and tools via persistent
user-level environment variables.

## Architecture

```text
PowerShell SecretStore Vault (HomeLabVault)
    |
    |  sync-secrets (PS7 profile helper)
    v
User-level Environment Variables (HKCU\Environment)
    |
    |  Inherited automatically
    v
All shells: PowerShell 5/7, CMD, Git Bash, WSL, Claude Code
```

## Environment Variables

These user-level environment variables are set by the vault and available in
every shell session:

| Env Var | Vault Name | Purpose |
|---------|------------|---------|
| `ANTHROPIC_API_KEY` | `anthropic/api-key` | Anthropic Claude API key |
| `OPENAI_API_KEY` | `openai/api-key` | OpenAI API key |
| `GITHUB_TOKEN` | `github/pat-personal` | GitHub fine-grained PAT (repos, actions, gh CLI) |
| `GITHUB_MCP_TOKEN` | `github/pat-mcp` | GitHub classic PAT (MCP servers, Docker MCP) |
| `GITEA_TOKEN` | `gitea/pat-homelab` | Gitea PAT for gitea.herbhall.net |
| `GITEA_DISPATCHER_TOKEN` | `gitea/pat-dispatcher` | Gitea dispatcher service token |
| `CLOUDFLARE_API_TOKEN` | `cloudflare/api-token` | Cloudflare DNS API token |
| `HOME_ASSISTANT_TOKEN` | `homeassistant/token` | Home Assistant long-lived access token |
| `SAMVERK_AUTH_TOKEN` | `samverk/auth-token` | Samverk MCP bearer token |

## Common Operations

### Add a new secret

```powershell
# In PowerShell 7 (pwsh)
nvs 'category/secret-name' 'secret-value'
sync-secrets
```

This stores the secret in the vault and pushes it to a user-level environment
variable. New shell sessions pick it up automatically; existing sessions need
to restart or refresh their environment.

### Rotate a secret

```powershell
# In PowerShell 7 (pwsh)
nvs 'category/secret-name' 'new-secret-value'
sync-secrets
```

Same as adding -- `nvs` overwrites the existing value, then `sync-secrets`
updates the environment variable.

### Read a secret

```powershell
# From the vault directly (PS7 only)
gvs 'category/secret-name'

# From any shell via env var
echo $GITHUB_TOKEN        # bash
echo $env:GITHUB_TOKEN    # PowerShell
echo %GITHUB_TOKEN%       # CMD
```

### Distribute secrets to GitHub repos

DevKit's `Set-DevkitSecrets.ps1` pushes secrets to GitHub/Gitea repos as
Actions secrets. It reads from environment variables when the vault migration
marker is present in `~/.devkit-config.json`:

```powershell
# All repos
.\scripts\Set-DevkitSecrets.ps1

# Single repo
.\scripts\Set-DevkitSecrets.ps1 -Repo HerbHall/myproject
```

## How DevKit Scripts Consume Secrets

Scripts follow a priority chain:

1. **Vault migration detected** (`_note` field in `~/.devkit-config.json` `.Secrets`
   block) -- read from user-level environment variables
2. **Legacy `.Secrets` block** -- read directly from `~/.devkit-config.json`
   (pre-migration machines)
3. **Direct env var fallback** -- check environment variables as last resort

This means scripts work on both migrated and unmigrated machines without changes.

## Legacy Systems

### ~/.devkit-config.json .Secrets block

Before the vault migration, secrets were stored directly in this JSON file.
After migration, the block contains only a `_note` field:

```json
{
  "Secrets": {
    "_note": "Secrets moved to PowerShell SecretStore vault (HomeLabVault)...",
    "_migration_date": "2026-03-09"
  }
}
```

Scripts detect this marker and fall back to environment variables.

### Windows Credential Manager (setup/lib/credentials.ps1)

The `devkit/` prefixed entries in Windows Credential Manager (via `cmdkey`/P-Invoke)
are superseded by the vault. The module is retained for backward compatibility but
new secrets should use the vault.

### Plaintext files (~/.credentials/)

Removed during migration. Backups at `~/.credentials.bak-2026-03-09/`. Never
store secrets in plaintext files.

## Security Rules

- **Never** store secrets in code, config files, or plaintext
- **Never** commit `.devkit-config.json`, `.env`, or `*.local.json` (all gitignored)
- **Always** use environment variables in scripts (not hardcoded values)
- **Always** run `sync-secrets` after rotating a secret in the vault
- Template files use `<PLACEHOLDER>` markers or `${ENV_VAR}` references, never real values

## SSH Configuration

Host aliases are configured in `~/.ssh/config` for common targets:

```text
ssh proxmox    ssh samverk    ssh unraid
ssh gitea      ssh dns-proxy  ssh ollama    ssh ha
```

All use `id_ed25519` key with root user.
