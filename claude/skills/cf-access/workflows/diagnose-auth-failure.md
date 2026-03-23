# Diagnose Auth Failure

Use this workflow when an agent or user reports "I can't reach samverk/synapset" or is getting 302/403 responses from a CF-protected endpoint.

## Prerequisites

You MUST have read `check-auth.md` before starting this workflow. If you skipped it, go back and read it now.

## Step 1: Gather Context

Ask or determine:

- Which endpoint is failing? (samverk.herbhall.net, synapset.herbhall.net, or internal IP)
- What HTTP status code is returned? (302, 403, timeout, connection refused)
- Is this a browser request or programmatic (MCP/API) request?
- Is the caller on the LAN or external?

## Step 2: Run Diagnostic Checks

Follow the check-auth.md runbook steps 1-6. Record the results of each step.

For each check, note:

- What you tested
- What the result was
- What it means

## Step 3: Classify the Problem

Based on your diagnostics, classify into one of these categories:

| Category | Symptoms | Agent Action |
|----------|----------|-------------|
| **Missing credentials** | Token env vars empty/unset | Fix the caller's config, no CF change needed |
| **Invalid credentials** | 302 with correct headers | File issue: token may need rotation |
| **Policy gap** | 403 with valid token | File issue: policy review needed |
| **Tunnel down** | Connection refused/timeout | File issue: infrastructure, not CF Access |
| **DNS issue** | Cannot resolve hostname | Check Cloudflare DNS, file if broken |
| **Application error** | 200 from CF but 500 from app | Debug the application, CF Access is fine |

## Step 4: Resolve or File

**If the problem is in the caller's config** (missing credentials, wrong endpoint, using external URL from LAN): fix it directly. No CF change needed.

**If the problem requires a CF change** (policy, token, tunnel): file an `agent:human` issue using the template from check-auth.md Step 7.

**STOP.** Do not attempt to fix CF Access configuration. Your job is diagnosis and filing only.
