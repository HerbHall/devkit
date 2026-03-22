# Propose Service Token Operation

Use this workflow to propose creating, rotating, or verifying a Cloudflare Access service token. You will produce a structured proposal and file it as an `agent:human` issue. You will NOT execute any changes.

## Step 1: Define the Operation

Determine:

- **Which operation?** Create new token, rotate existing token, or verify token is working
- **Which service token?** Name and which Access Application it belongs to
- **Why is this needed?** Token expired, compromised, new service needs access, or diagnostic

## Step 2: Identify Affected Services

Service tokens are used by programmatic callers. Identify:

- Which services currently use this token (MCP connectors, CI/CD, scripts)
- Where the token credentials are stored (env vars, secrets manager, config files)
- What breaks during rotation (services lose access until updated)

## Step 3: Write the Proposal

Use this template:

```markdown
## CF Access Service Token Proposal

**Operation:** [create / rotate / verify]
**Token name:** [name or "new"]
**Application:** [which CF Access Application]
**Priority:** [critical / high / normal]

### Current State

[Describe the current token status -- working, expired, unknown]

### Proposed Operation

[Exactly what should happen]

### Affected Services

| Service | Location | Credential Storage | Update Method |
|---------|----------|-------------------|---------------|
| [name] | [host/container] | [env var / secret] | [how to update] |

### Rollback Procedure

If the new/rotated token does not work:
1. [How to revert -- e.g., restore previous token from backup]
2. [Verify services recover]

### Post-Operation Checklist

After the token operation:
- [ ] Update credentials in all affected services (see table above)
- [ ] Verify each service can authenticate: `curl -s -o /dev/null -w "%{http_code}" -H "CF-Access-Client-Id: ..." -H "CF-Access-Client-Secret: ..." https://[endpoint]/healthz`
- [ ] Confirm old token (if rotated) no longer works
```

## Step 4: File the Issue

File an `agent:human` issue with:

- Title: `cf-access: [create/rotate/verify] service token [name] for [application]`
- Label: `agent:human`, `priority:[level]`
- Body: The proposal from Step 3

## STOP

Do NOT create or rotate tokens. Do NOT call the Cloudflare API. Your job is the proposal only.
