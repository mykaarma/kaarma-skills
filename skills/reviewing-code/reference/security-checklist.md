# Security Review Checklist

## Input Validation

- [ ] **All inputs validated**: API parameters, form data, file uploads
- [ ] **Whitelist validation**: Allow known-good, not block known-bad
- [ ] **Type checking**: Correct types enforced
- [ ] **Length limits**: Maximum length enforced
- [ ] **Format validation**: Email, URL, phone formats checked
- [ ] **Range validation**: Numbers within expected ranges
- [ ] **Server-side validation**: Never trust client-side only
- [ ] **Clear error messages**: Help users fix invalid inputs

## Authentication

- [ ] **Strong password policy**: Minimum length, complexity requirements
- [ ] **Password hashing**: Use bcrypt, argon2, or scrypt (not MD5/SHA1)
- [ ] **Account lockout**: After N failed attempts
- [ ] **Session management**: Secure session tokens, appropriate timeouts
- [ ] **Token rotation**: New token after login/privilege escalation
- [ ] **MFA support**: Two-factor authentication available
- [ ] **Password reset**: Secure reset flow with expiring tokens
- [ ] **Remember me**: Secure long-lived tokens if implemented

## Authorization

- [ ] **Permission checks**: Every request checks authorization
- [ ] **Resource-level permissions**: User can only access their own data
- [ ] **Role-based access control**: Roles properly enforced
- [ ] **Deny by default**: Explicit grants, not implicit allows
- [ ] **Vertical privilege escalation prevented**: Users can't elevate privileges
- [ ] **Horizontal privilege escalation prevented**: Users can't access others' resources
- [ ] **API authorization**: Not just UI-level checks

### Example Authorization Check

```python
@router.delete("/api/jobs/{job_id}")
async def delete_job(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    job = await get_job(db, job_id)
    
    # Check ownership or admin
    if job.user_id != current_user.id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    await delete_job(db, job_id)
    return {"status": "deleted"}
```

## SQL Injection Prevention

- [ ] **Parametrized queries**: Always use parameters, never string concatenation
- [ ] **ORM usage**: Use ORM with prepared statements
- [ ] **Input escaping**: If raw SQL needed, escape inputs
- [ ] **Least privilege**: Database user has minimal permissions
- [ ] **NoSQL injection**: Sanitize NoSQL queries too

### Safe vs Unsafe

```python
# ❌ UNSAFE: SQL injection vulnerability
query = f"SELECT * FROM users WHERE email = '{email}'"
result = await db.execute(query)

# ✅ SAFE: Parametrized query
query = "SELECT * FROM users WHERE email = :email"
result = await db.execute(query, {"email": email})

# ✅ SAFE: ORM usage
result = await db.execute(select(User).where(User.email == email))
```

## XSS Prevention

- [ ] **Output escaping**: Escape HTML in templates
- [ ] **Content Security Policy**: CSP headers configured
- [ ] **HTTPOnly cookies**: Session cookies not accessible to JavaScript
- [ ] **Sanitize user input**: For rich text editors
- [ ] **Validate content types**: Check Content-Type headers

## CSRF Protection

- [ ] **CSRF tokens**: For state-changing operations
- [ ] **SameSite cookies**: Set SameSite attribute
- [ ] **Custom headers**: Require custom headers for API calls
- [ ] **Origin validation**: Check Origin/Referer headers

## Secrets Management

- [ ] **No secrets in code**: No passwords, API keys, tokens in source
- [ ] **Environment variables**: Use env vars or secret managers
- [ ] **No secrets in logs**: Redact sensitive data from logs
- [ ] **No secrets in error messages**: Don't expose secrets in errors
- [ ] **No secrets in URLs**: Don't pass secrets as query parameters
- [ ] **Secrets rotation**: Plan for rotating secrets
- [ ] **Different secrets per environment**: Dev/staging/prod have different secrets

### Safe Secrets Handling

```python
# ✅ GOOD: From environment
API_KEY = os.getenv("API_KEY")
if not API_KEY:
    raise ValueError("API_KEY not set")

# ✅ GOOD: From secret manager
from google.cloud import secretmanager
client = secretmanager.SecretManagerServiceClient()
secret = client.access_secret_version(name=secret_name)
API_KEY = secret.payload.data.decode("UTF-8")

# ❌ BAD: Hard-coded
API_KEY = "sk-1234567890abcdef"  # Never do this!
```

## Data Encryption

- [ ] **HTTPS only**: Enforce HTTPS in production
- [ ] **TLS version**: Use TLS 1.2 or higher
- [ ] **Encryption at rest**: Sensitive data encrypted on disk
- [ ] **Field-level encryption**: For highly sensitive fields (SSN, credit cards)
- [ ] **Key management**: Proper key storage and rotation

## Rate Limiting

- [ ] **API rate limiting**: Prevent abuse
- [ ] **Login rate limiting**: Prevent brute force
- [ ] **Per-user limits**: Track by user, not just IP
- [ ] **Per-IP limits**: For unauthenticated endpoints
- [ ] **Exponential backoff**: For repeated failures

### Example Rate Limiting

```python
from fastapi_limiter.depends import RateLimiter

@router.post("/api/login")
@limiter.limit("5/minute")  # 5 attempts per minute
async def login(credentials: LoginCredentials):
    ...

@router.post("/api/jobs")
@limiter.limit("100/hour")  # 100 jobs per hour per user
async def create_job(current_user: User = Depends(get_current_user)):
    ...
```

## File Upload Security

- [ ] **File size limits**: Max file size enforced
- [ ] **File type validation**: Check actual content, not just extension
- [ ] **Virus scanning**: For user uploads
- [ ] **Unique filenames**: Prevent path traversal
- [ ] **Separate storage**: Don't serve uploads from application directory
- [ ] **Content-Type validation**: Verify Content-Type header

### Safe File Upload

```python
ALLOWED_EXTENSIONS = {".mp3", ".wav", ".m4a"}
MAX_FILE_SIZE = 500 * 1024 * 1024  # 500MB

async def save_upload(file: UploadFile):
    # Check extension
    ext = Path(file.filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(f"File type {ext} not allowed")
    
    # Check size
    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise ValueError("File too large")
    
    # Generate safe filename
    safe_filename = f"{uuid.uuid4()}{ext}"
    path = UPLOAD_DIR / safe_filename
    
    # Save
    async with aiofiles.open(path, 'wb') as f:
        await f.write(content)
    
    return path
```

## API Security

- [ ] **Authentication required**: For protected endpoints
- [ ] **API versioning**: Version your APIs
- [ ] **CORS configured**: Appropriate origin restrictions
- [ ] **Request size limits**: Prevent huge payloads
- [ ] **Timeout configuration**: All external calls have timeouts
- [ ] **Error messages**: Don't leak internal details

## Dependency Security

- [ ] **Dependencies updated**: No known vulnerabilities
- [ ] **Dependency scanning**: Use tools like Snyk, Dependabot
- [ ] **Minimal dependencies**: Remove unused packages
- [ ] **Lock files**: Pin dependency versions

### Scanning Commands

```bash
# Python
pip-audit
safety check

# Node.js
npm audit
yarn audit

# Check for outdated packages
pip list --outdated
npm outdated
```

## Audit Logging

- [ ] **Authentication events**: Login, logout, failed attempts
- [ ] **Authorization failures**: Attempted unauthorized access
- [ ] **Data changes**: Who changed what and when
- [ ] **Admin actions**: Privileged operations logged
- [ ] **Include context**: User ID, IP, timestamp, action
- [ ] **Tamper-proof logs**: Write-only log storage

### Example Audit Log

```python
audit_logger.info("User action", extra={
    "event_type": "job_deleted",
    "user_id": current_user.id,
    "resource_id": job_id,
    "ip_address": request.client.host,
    "timestamp": datetime.utcnow().isoformat(),
    "success": True
})
```

## Security Headers

- [ ] **Content-Security-Policy**: Restrict resource loading
- [ ] **X-Frame-Options**: Prevent clickjacking
- [ ] **X-Content-Type-Options**: Prevent MIME sniffing
- [ ] **Strict-Transport-Security**: Enforce HTTPS
- [ ] **X-XSS-Protection**: Browser XSS protection

### Example Security Headers

```python
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from starlette.middleware.cors import CORSMiddleware

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["example.com", "*.example.com"]
)

@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    response.headers["Strict-Transport-Security"] = "max-age=31536000"
    return response
```

## Critical Security Checks

Before approving code:
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Authorization checked on all protected operations
- [ ] No secrets in code or logs
- [ ] Input validation on all user inputs
- [ ] HTTPS enforced
- [ ] Rate limiting on sensitive endpoints
- [ ] Dependencies have no known vulnerabilities

---

## Cross-Reference

For implementation details on security patterns, see:
- [building-features/security-considerations.md](../../building-features/reference/security-considerations.md)

This checklist focuses on **reviewing** code for security issues.
The building-features security file focuses on **implementing** security correctly.
