# Security Considerations

## OWASP Top 10

### 1. Injection (SQL, NoSQL, Command)

**Prevention**:
- Use parametrized queries, never string concatenation
- Use ORMs with prepared statements
- Validate and sanitize all inputs
- Escape special characters
- Use least-privilege database accounts

**Example (safe)**:
```python
# Good: Parametrized query
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# Bad: String concatenation (vulnerable)
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

### 2. Broken Authentication

**Prevention**:
- Use battle-tested auth libraries (don't roll your own)
- Enforce strong password policies
- Implement MFA where possible
- Use secure session management
- Implement account lockout after failed attempts
- Rotate session tokens after login
- Set appropriate session timeouts

### 3. Sensitive Data Exposure

**Prevention**:
- Encrypt data at rest (disk encryption, field-level encryption)
- Encrypt data in transit (HTTPS, TLS)
- Don't log sensitive data (passwords, tokens, PII)
- Use environment variables for secrets
- Implement proper key management
- Mask sensitive data in responses

### 4. XML External Entities (XXE)

**Prevention**:
- Disable XML external entity processing
- Use JSON instead of XML where possible
- Validate and sanitize XML inputs
- Use safe XML parsers

### 5. Broken Access Control

**Prevention**:
- Deny by default, allow explicitly
- Check permissions on every request
- Don't rely on client-side checks
- Use role-based access control (RBAC)
- Implement resource-level permissions
- Log authorization failures

**Example**:
```python
@router.put("/api/jobs/{job_id}")
async def update_job(job_id: int, current_user: User = Depends(get_current_user)):
    job = await get_job(job_id)
    
    # Check ownership
    if job.user_id != current_user.id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Proceed with update
    ...
```

### 6. Security Misconfiguration

**Prevention**:
- Remove default accounts and passwords
- Disable directory listing
- Keep software updated
- Use security headers (CSP, HSTS, X-Frame-Options)
- Minimize exposed services
- Regular security audits

### 7. Cross-Site Scripting (XSS)

**Prevention**:
- Escape output in templates
- Use Content Security Policy
- Sanitize user inputs
- Use frameworks that auto-escape by default
- Validate input types

### 8. Insecure Deserialization

**Prevention**:
- Validate serialized objects
- Use safe serialization formats (JSON over pickle)
- Implement integrity checks (signatures, hashes)
- Isolate deserialization in low-privilege environments

### 9. Using Components with Known Vulnerabilities

**Prevention**:
- Keep dependencies updated
- Use dependency scanning tools (Snyk, Dependabot)
- Subscribe to security advisories
- Remove unused dependencies
- Pin dependency versions

**Tools**:
```bash
# Python
pip-audit
safety check

# Node.js
npm audit
yarn audit
```

### 10. Insufficient Logging and Monitoring

**Prevention**:
- Log authentication and authorization events
- Log input validation failures
- Include correlation IDs
- Don't log sensitive data
- Set up alerts for suspicious patterns
- Implement rate limiting

## Additional Security Practices

### Input Validation

- Whitelist validation (allow known-good, not block known-bad)
- Validate type, length, format, range
- Reject, don't sanitize (when possible)
- Validate on server-side (never trust client)

### Rate Limiting

```python
from fastapi_limiter import FastAPILimiter
from fastapi_limiter.depends import RateLimiter

@router.post("/api/login")
@limiter.limit("5/minute")  # 5 requests per minute
async def login(credentials: LoginCredentials):
    ...
```

### Secrets Management

- Never commit secrets to version control
- Use environment variables or secret managers
- Rotate secrets regularly
- Use different secrets for each environment
- Implement least-privilege access

### API Security

- Use API keys or OAuth tokens
- Implement rate limiting
- Validate Content-Type headers
- Use HTTPS only
- Implement CORS appropriately
- Version your APIs

## Security Review Checklist

Before deploying:
- [ ] All inputs validated and sanitized
- [ ] Authentication required where needed
- [ ] Authorization checked before operations
- [ ] Secrets not in code or logs
- [ ] SQL injection prevented (parametrized queries)
- [ ] XSS prevented (output escaping)
- [ ] CSRF protection enabled
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] Dependencies updated
- [ ] Error messages don't leak internals
- [ ] Logging doesn't include sensitive data
- [ ] Rate limiting on sensitive endpoints
