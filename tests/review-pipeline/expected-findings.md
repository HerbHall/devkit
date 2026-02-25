# Expected Findings

What the reviewers should catch in the intentionally flawed test artifacts.

## Plan Review (`test-plan.md`)

### Critical

| Finding | Section | Description |
|---------|---------|-------------|
| Plaintext password storage | Step 1, Step 2 | Column is `password TEXT`, step says "store password directly" -- no hashing |
| No token expiration | Step 3 | "Token never expires" is an explicit security flaw |

### High

| Finding | Section | Description |
|---------|---------|-------------|
| SQL injection risk | Step 1 | Schema stores password as TEXT with no indication of parameterized queries |
| No input validation | Step 2 | No mention of username/password validation rules |
| No rate limiting | Step 3 | Login endpoint has no brute-force protection |
| User enumeration | Implied | No mention of generic error messages |

### Medium

| Finding | Section | Description |
|---------|---------|-------------|
| Missing refresh token flow | All | No mechanism to refresh expired tokens (if expiry were added) |
| Vague acceptance criteria | Acceptance Criteria | "Users can register and log in" has no measurable definition |

## Code Review (`test-code/handler.go`)

### Critical

| Finding | Location | Description |
|---------|----------|-------------|
| SQL injection | `handler.go:19` | `fmt.Sprintf` with user input in SQL query |
| Command injection | `handler.go:35` | `exec.Command("ping", ... host)` with unsanitized user input |

### High

| Finding | Location | Description |
|---------|----------|-------------|
| Credentials in query string | `handler.go:13-14` | Username and password via `r.URL.Query().Get()` -- logged in access logs, browser history |
| Plaintext password comparison | `handler.go:25` | Direct string comparison, not bcrypt |
| Hardcoded secret in token | `handler.go:42` | Static secret key in source code |
| User enumeration | `handler.go:21` | Error message reveals whether username exists |

### Medium

| Finding | Location | Description |
|---------|----------|-------------|
| No Content-Type on response | `handler.go:29` | Returns `text/plain` for auth token, should be `application/json` |
| Missing method check | `handler.go:12` | No validation that request is POST |

## Fixed Versions

- `test-plan-fixed.md` addresses all Critical and High findings from the plan review
- `test-code/handler-fixed.go` addresses all Critical and High findings from the code review

Reviewers should return APPROVE (or REQUEST_CHANGES with only Medium/Low findings) on the fixed versions.
