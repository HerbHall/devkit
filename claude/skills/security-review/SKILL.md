---
name: security-review
description: Use this skill when adding authentication, handling user input, working with secrets, creating API endpoints, or implementing sensitive features. Provides comprehensive security checklist and patterns.
---

# Security Review Skill

This skill ensures all code follows security best practices and identifies potential vulnerabilities.

## When to Activate

- Implementing authentication or authorization
- Handling user input or file uploads
- Creating new API endpoints
- Working with secrets or credentials
- Storing or transmitting sensitive data
- Integrating third-party APIs

## Security Checklist

### 1. Secrets Management

Never hardcode secrets — use environment variables:

```go
// Go example
apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    log.Fatal("API_KEY not configured")
}
```

Verification:
- [ ] No hardcoded API keys, tokens, or passwords
- [ ] All secrets in environment variables
- [ ] .env files in .gitignore
- [ ] No secrets in git history

### 2. Input Validation

Always validate and sanitize user input before processing. Use strict schemas. Reject anything that doesn't conform. Never trust client-supplied data.

- [ ] All user inputs validated
- [ ] File uploads restricted (size, type, extension)
- [ ] No direct use of user input in queries
- [ ] Whitelist validation (not blacklist)
- [ ] Error messages don't leak sensitive info

### 3. SQL / Query Injection Prevention

Always use parameterized queries or an ORM. Never concatenate user data into query strings.

- [ ] All database queries use parameterized queries
- [ ] No string concatenation in queries
- [ ] ORM/query builder used correctly

### 4. Authentication & Authorization

- [ ] Tokens stored securely (httpOnly cookies, not localStorage)
- [ ] Authorization checks before every sensitive operation
- [ ] Role-based access control implemented
- [ ] Session management secure

### 5. Sensitive Data Exposure

```go
// Don't log sensitive data
// BAD:
log.Printf("User login: email=%s password=%s", email, password)

// GOOD:
log.Printf("User login: email=%s", email)
```

- [ ] No passwords, tokens, or secrets in logs
- [ ] Error messages are generic for end users
- [ ] Detailed errors only in server-side logs
- [ ] No stack traces exposed to users

### 6. Rate Limiting

- [ ] Rate limiting on all API endpoints
- [ ] Stricter limits on expensive operations (search, auth)
- [ ] IP-based rate limiting in place

### 7. Dependency Security

```bash
# Check for vulnerabilities
go list -m all | nancy sleuth
# or for Node.js projects
npm audit
```

- [ ] Dependencies up to date
- [ ] No known vulnerabilities
- [ ] Lock files committed

### 8. Network / API Security

- [ ] HTTPS enforced in production
- [ ] CORS properly configured
- [ ] Security headers configured (CSP, X-Frame-Options)
- [ ] Only needed ports exposed

## Pre-Deployment Security Checklist

Before ANY production deployment:

- [ ] **Secrets**: No hardcoded secrets, all in env vars
- [ ] **Input Validation**: All user inputs validated
- [ ] **Injection**: All queries parameterized
- [ ] **Authentication**: Proper token handling
- [ ] **Authorization**: Role checks in place
- [ ] **Rate Limiting**: Enabled on all endpoints
- [ ] **HTTPS**: Enforced in production
- [ ] **Error Handling**: No sensitive data in errors
- [ ] **Logging**: No sensitive data logged
- [ ] **Dependencies**: Up to date, no vulnerabilities

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Web Security Academy](https://portswigger.net/web-security)

---

**Remember:** Security is not optional. One vulnerability can compromise the entire system.
