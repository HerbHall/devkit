# Plan: User Authentication Module

## Goal

Add username/password authentication to the API server.

## Steps

### 1. Create user database table

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Implement registration endpoint

- `POST /api/register` accepts `{ username, password }`
- Store password directly in the database
- Return 201 on success

### 3. Implement login endpoint

- `POST /api/login` accepts `{ username, password }`
- Compare password with stored value
- Return a JWT token on success
- Token never expires

### 4. Add auth middleware

- Extract token from `Authorization` header
- Verify JWT signature
- Attach user to request context

## Acceptance Criteria

- Users can register and log in
- Protected routes require a valid token
