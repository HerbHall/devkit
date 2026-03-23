# CF Access Authentication Diagnostic Runbook

Follow these steps IN ORDER before concluding that CF Access is misconfigured. Most auth failures are caused by missing or invalid credentials, not policy problems.

## Step 1: Identify the Request Type

Determine which authentication path applies:

| If you are... | Auth method | Expected headers |
|---------------|-------------|-----------------|
| A browser user accessing the dashboard | CF Access Google OAuth | None (CF handles redirect) |
| An agent/script calling MCP or API | Service token | `CF-Access-Client-Id` + `CF-Access-Client-Secret` |
| On the LAN calling internal IP directly | Bearer token | `Authorization: Bearer <token>` |

**If you are on the LAN (192.168.1.x):** You do not go through CF Access at all. Use the internal IP directly (e.g., `192.168.1.162:8080`). If this fails, the problem is NOT CF Access.

## Step 2: Verify Service Token Headers Are Present

For programmatic access through CF Access, check that BOTH headers are in the outbound request:

```bash
# Check that the environment variables exist and are non-empty
echo "Client ID length: ${#CF_ACCESS_CLIENT_ID}"
echo "Client Secret length: ${#CF_ACCESS_CLIENT_SECRET}"
```

- If either is empty or unset, the token is not configured. This is a **configuration problem**, not a CF Access problem.
- Do NOT attempt to fix this by modifying CF Access policies.

## Step 3: Test With Token

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -H "CF-Access-Client-Id: ${CF_ACCESS_CLIENT_ID}" \
  -H "CF-Access-Client-Secret: ${CF_ACCESS_CLIENT_SECRET}" \
  https://samverk.herbhall.net/healthz
```

| Result | Meaning | Action |
|--------|---------|--------|
| 200 | Token is valid, CF Access is working | No CF change needed. Debug your application. |
| 302 | Token not recognized, redirecting to OAuth | Token may be expired or wrong. See Step 4. |
| 403 | Token recognized but denied by policy | See Step 5. |
| Connection refused / timeout | Tunnel is down or DNS issue | See Step 6. |

## Step 4: Token Not Recognized (302)

The service token exists but CF Access is redirecting to OAuth. Possible causes:

1. **Wrong token for this application** -- each CF Access Application has its own service token
2. **Token was rotated** -- the stored credentials are from a previous rotation
3. **Typo in headers** -- header names are case-sensitive: `CF-Access-Client-Id` (not `Client-ID`)

**Action:** File an `agent:human` issue requesting token verification. Include which endpoint and which token name you are using. Do NOT create a new token yourself.

## Step 5: Token Denied (403)

The token is recognized but the Access Policy does not allow it. Possible causes:

1. **Service token policy was removed** from this Access Application
2. **Policy was narrowed** to exclude this token's scope

**Action:** File an `agent:human` issue with:

- Which endpoint returned 403
- Which service token name was used
- The full response headers (especially `CF-Ray` for CF support lookup)

Do NOT modify the Access Policy yourself.

## Step 6: Connection Failure

If `curl` cannot connect at all:

1. **Check DNS:** `nslookup samverk.herbhall.net` -- should resolve to Cloudflare IPs
2. **Check tunnel:** The tunnel runs on CT 202. If the tunnel is down, the endpoint is unreachable regardless of Access policies
3. **Check internal service:** `curl http://192.168.1.162:8080/healthz` from a LAN host

**Action:** If DNS resolves but connection times out, the tunnel may be down. This is an infrastructure issue, not a CF Access issue. File accordingly.

## Step 7: File the Issue

If you reached this step, you have diagnostic evidence. File an `agent:human` issue with:

```markdown
## CF Access Auth Failure Report

**Endpoint:** [which URL]
**Request type:** [browser / service token / LAN]
**HTTP status:** [200 / 302 / 403 / timeout]
**Token present:** [yes/no, which token name]
**Diagnostic output:** [paste relevant curl output]
**Conclusion:** [token missing / token invalid / policy issue / tunnel down]

## Requested Action

[What you believe needs to happen -- but do NOT execute it yourself]
```

## What You Must NOT Do

- Remove or modify any Access Policy
- Create or rotate service tokens
- Edit tunnel configuration
- Bypass CF Access by switching to internal IPs in production config
- Assume CF Access is wrong -- it is more likely that your request is wrong
