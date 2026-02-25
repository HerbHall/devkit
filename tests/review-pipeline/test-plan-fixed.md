# Plan: User Authentication Module

## Goal

Add username/password authentication to the API server with industry-standard security practices.

## Steps

### 1. Create user database table

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Implement registration endpoint

- `POST /api/register` accepts `{ username, password }`
- Validate input: username 3-50 chars alphanumeric, password minimum 12 chars
- Hash password with bcrypt (cost factor 12) before storing
- Return 201 on success, 400 on validation failure, 409 on duplicate username

### 3. Implement login endpoint

- `POST /api/login` accepts `{ username, password }`
- Compare password against stored bcrypt hash using constant-time comparison
- Return a JWT token on success (1-hour expiry, RS256 signing)
- Rate limit: 5 attempts per IP per minute, exponential backoff after 3 failures
- Return 401 on failure with generic "invalid credentials" message (no user enumeration)

### 4. Add auth middleware

- Extract token from `Authorization: Bearer <token>` header
- Verify JWT signature and expiration
- Reject expired tokens with 401
- Attach user claims to request context

### 5. Add refresh token flow

- Issue refresh token (7-day expiry) alongside access token
- `POST /api/refresh` exchanges a valid refresh token for a new access token
- Refresh tokens are single-use (rotated on each refresh)
- Store refresh token hashes in database for revocation support

## Security Considerations

- All passwords hashed with bcrypt before storage
- JWT tokens expire after 1 hour; refresh tokens after 7 days
- Rate limiting on login to prevent brute force
- Generic error messages prevent user enumeration
- Refresh token rotation prevents replay attacks

## Acceptance Criteria

- Users can register with validated input
- Users can log in and receive time-limited tokens
- Protected routes reject expired or invalid tokens
- Login endpoint is rate-limited
- No plaintext passwords stored anywhere
