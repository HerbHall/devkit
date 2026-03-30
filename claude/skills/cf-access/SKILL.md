---
name: cf-access
description: Cloudflare Access management with Tier 3 approval gate -- agents diagnose and propose, never execute
user_invocable: true
---

# cf-access

<essential_principles>

**Tier 3 -- Human Approval Required. No exceptions.**

Agents must NEVER execute Cloudflare Zero Trust API calls autonomously. This includes:

- Creating, modifying, or deleting Access policies
- Creating or rotating service tokens
- Modifying tunnel ingress routes
- Adding or removing WAF rules
- Any `curl` or API call to `api.cloudflare.com`

Agents CAN:

- Read diagnostic information (response headers, status codes)
- Run the check-auth diagnostic runbook
- Propose changes by filing `agent:human` issues with structured plans

**Why this exists:** Agents have repeatedly removed CF Access policies when encountering 302/403 responses, leaving MCP endpoints (samverk.herbhall.net, synapset.herbhall.net) open to the internet without authentication. Agents cannot distinguish "CF Access is blocking me incorrectly" from "CF Access is correctly blocking an unauthorized request."

**Canonical rule:** Synapset devkit pool memory #788 (CF Zero Trust Tier 3 policy).

**Cloudflare Zero Trust terminology:**

| Term | Meaning |
|------|---------|
| Access Application | A policy-protected hostname or path |
| Access Policy | Allow/block rule within an application (Google OAuth, service token, etc.) |
| Service Token | Client ID + Secret pair for programmatic (non-browser) access |
| Tunnel | Cloudflare Tunnel (cloudflared) connecting internal services to CF edge |
| Ingress Rule | Tunnel config mapping a public hostname to an internal origin |
| CF-Access-Client-Id | HTTP header carrying the service token client ID |
| CF-Access-Client-Secret | HTTP header carrying the service token secret |
| JWT | CF Access issues JWTs after successful authentication; validated by applications |

**Protected endpoints:**

| Endpoint | Internal Origin | Purpose |
|----------|----------------|---------|
| `samverk.herbhall.net` | `192.168.1.162:8080` | Samverk server (dashboard + MCP) |
| `synapset.herbhall.net` | `192.168.1.162:6464` | Synapset memory server (MCP) |

**Authentication layers:**

- **Browser (dashboard):** CF Access Google OAuth -> JWT auto-login
- **Programmatic (MCP, API):** Service token headers bypass CF Access OAuth
- **Internal (LAN):** Bearer token only, no CF Access involved

</essential_principles>

<intake>

What do you need help with?

1. **Diagnose auth failure** -- "I can't reach samverk/synapset" or getting 302/403
2. **Propose Access policy change** -- add, remove, or modify a policy
3. **Propose service token operation** -- create, rotate, or verify a token
4. **Propose tunnel route change** -- add, remove, or modify an ingress rule

Type a number, keyword, or **skip** to dismiss.

</intake>

<routing>

| Response | Workflow |
|----------|----------|
| 1, "diagnose", "auth", "failure", "can't reach", "302", "403", "blocked" | First read check-auth.md, then workflows/diagnose-auth-failure.md |
| 2, "policy", "access policy", "add policy", "remove policy" | workflows/propose-policy-change.md |
| 3, "token", "service token", "rotate", "create token" | workflows/propose-service-token.md |
| 4, "tunnel", "route", "ingress" | workflows/propose-tunnel-change.md |

If the user types **skip** or **dismiss**, confirm cancellation and end the skill.
If the input does not match, respond: "cf-access was triggered but your input didn't match a workflow. Options: 1-4. Type skip to dismiss."

**After reading the workflow, follow it exactly.**

**CRITICAL:** Every workflow ends with filing an `agent:human` issue. You must NEVER execute the proposed change yourself.

</routing>

<tool_restrictions>

**Forbidden:**

- `curl` to `api.cloudflare.com` (any method)
- Any MCP tool that modifies CF Zero Trust configuration
- `cloudflared` config changes
- Direct editing of tunnel config files

**Allowed:**

- `curl` to protected endpoints for diagnostic purposes (read-only, status code checks)
- Reading response headers (`CF-Access-*`, `CF-Ray`, `Location`)
- `gh issue create` or Samverk MCP `create_issue` to file proposals
- Reading existing tunnel config files (read-only)

</tool_restrictions>

<references>

- check-auth.md: Diagnostic runbook -- MUST be followed before assuming CF Access is misconfigured
- Synapset memory #788: Canonical CF Zero Trust Tier 3 policy

</references>

<workflows_index>

- diagnose-auth-failure.md: Triage "I can't reach X" problems without modifying CF config
- propose-policy-change.md: Structured proposal for Access policy add/remove/modify
- propose-service-token.md: Structured proposal for service token create/rotate
- propose-tunnel-change.md: Structured proposal for tunnel ingress route changes

</workflows_index>

## Version

- v1.0.0 (2026-03-22): Initial skill -- Tier 3 gate, 4 workflows, diagnostic runbook

## Changelog

- v1.0.0: Created skill per samverk#200. Covers policy, token, tunnel, and auth diagnosis workflows. Hard Tier 3 gate on all CF modifications.
