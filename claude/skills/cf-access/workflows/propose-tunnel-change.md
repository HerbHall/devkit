# Propose Tunnel Route Change

Use this workflow to propose adding, removing, or modifying a Cloudflare Tunnel ingress rule. You will produce a structured proposal and file it as an `agent:human` issue. You will NOT execute any changes.

## Step 1: Define the Change

Determine:

- **Which tunnel?** (e.g., tunnel ID `e86ba6e3` on CT 202)
- **What type of change?** Add new ingress rule, remove existing rule, or modify origin
- **Which hostname?** The public hostname being routed (e.g., `samverk.herbhall.net`)
- **Which origin?** The internal service and port (e.g., `http://localhost:8080`)

## Step 2: Assess Impact

Before proposing, evaluate:

- **Is an Access Application needed?** New public hostnames MUST have a CF Access Application protecting them. Never expose an origin without auth.
- **Does DNS exist?** The hostname needs a CNAME record pointing to the tunnel
- **What about the catch-all rule?** Tunnel configs have a catch-all (`*` or `http_status:404`). New rules must be placed ABOVE it.
- **Existing services on this hostname?** Changing an ingress rule redirects ALL traffic for that hostname.

## Step 3: Write the Proposal

Use this template:

````markdown
## CF Tunnel Route Change Proposal

**Tunnel:** [tunnel ID or name]
**Change type:** [add / remove / modify]
**Hostname:** [public hostname]
**Origin:** [internal service URL]
**Priority:** [critical / high / normal]

### Current Ingress Rules

[List current ingress rules for this tunnel, in order]

### Proposed Change

[Exactly what should change -- include the full ingress rule YAML]

```yaml
# Example: adding a new route
ingress:
  - hostname: newservice.herbhall.net
    service: http://localhost:9090
  # ... existing rules ...
  - service: http_status:404
```

### Prerequisites

- [ ] DNS CNAME record for [hostname] pointing to [tunnel-id].cfargotunnel.com
- [ ] CF Access Application protecting [hostname] (or justification for no auth)
- [ ] Internal service running and healthy at [origin]

### Justification

[Why this change is needed]

### Rollback Procedure

To revert:

1. [Remove/restore the ingress rule]
2. [Restart cloudflared: `systemctl restart cloudflared`]
3. [Verify with: `curl -s -o /dev/null -w "%{http_code}" https://[hostname]/healthz`]
````

## Step 4: File the Issue

File an `agent:human` issue with:

- Title: `cf-access: [add/remove/modify] tunnel route for [hostname]`
- Label: `agent:human`, `priority:[level]`
- Body: The proposal from Step 3

## STOP

Do NOT modify tunnel configuration. Do NOT edit cloudflared config files. Do NOT restart cloudflared. Your job is the proposal only.
