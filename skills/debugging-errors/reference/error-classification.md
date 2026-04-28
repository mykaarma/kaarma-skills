# Error Classification

Proper error classification is critical for deciding how to handle errors: retry, fail fast, alert, or ignore.

## Error Categories by Persistence

### Transient Errors (Retryable)

These errors may succeed on retry. Implement exponential backoff.

```python
TRANSIENT_EXCEPTIONS = (
    # Network errors
    ConnectionError,
    ConnectionRefusedError,
    ConnectionResetError,
    TimeoutError,
    
    # HTTP client errors
    aiohttp.ClientError,
    aiohttp.ServerDisconnectedError,
    httpx.ConnectError,
    httpx.ReadTimeout,
    
    # Database transient errors
    asyncpg.DeadlockDetectedError,
    asyncpg.TooManyConnectionsError,
    
    # I/O errors (sometimes transient)
    IOError,
    OSError,
)
```

**Common transient scenarios:**
- Network timeout (service slow but healthy)
- Connection refused (service restarting)
- Database deadlock (concurrent transactions)
- Rate limiting (429 Too Many Requests)
- Temporary resource exhaustion
- DNS resolution failure (transient network issue)

**Handling pattern:**
```python
async def with_retry(func, max_attempts=3):
    for attempt in range(max_attempts):
        try:
            return await func()
        except TRANSIENT_EXCEPTIONS as e:
            if attempt == max_attempts - 1:
                raise
            delay = 60 * (3 ** attempt)  # Exponential backoff
            logger.warning(f"Transient error, retry {attempt + 1}: {e}")
            await asyncio.sleep(delay)
```

### Permanent Errors (Non-Retryable)

These errors will not succeed on retry. Fail immediately.

```python
PERMANENT_EXCEPTIONS = (
    # Validation errors
    ValueError,
    ValidationError,
    pydantic.ValidationError,
    
    # Resource errors
    FileNotFoundError,
    KeyError,
    
    # Permission errors
    PermissionError,
    AuthenticationError,
    AuthorizationError,
    
    # Data integrity
    IntegrityError,
    ConstraintViolationError,
    
    # Logic errors
    TypeError,
    AttributeError,
)
```

**Common permanent scenarios:**
- Invalid input data (validation failure)
- Missing required field
- Resource doesn't exist (404)
- Authentication failure (401)
- Authorization failure (403)
- Schema mismatch
- Unique constraint violation

**Handling pattern:**
```python
try:
    result = await process_job(data)
except PERMANENT_EXCEPTIONS as e:
    logger.error(f"Permanent error, not retrying: {e}")
    await mark_job_failed(job_id, str(e))
    return  # Don't retry
```

## Error Categories by Source

### Application Errors

Bugs in your code. Fix the code.

| Error Type | Example | Fix Approach |
|------------|---------|--------------|
| Logic error | Wrong algorithm, off-by-one | Review logic, add tests |
| Type error | `None.attribute` | Add null checks, type hints |
| State error | Invalid state transition | State machine validation |
| Race condition | Concurrent modification | Locks, transactions |

### Infrastructure Errors

Problems with underlying systems. Usually transient.

| Error Type | Example | Fix Approach |
|------------|---------|--------------|
| Network | Connection timeout | Retry with backoff |
| Database | Connection pool exhausted | Increase pool, fix leaks |
| Disk | Out of space | Alert, cleanup |
| Memory | OOM killed | Profile, optimize |

### External Service Errors

Third-party API issues. Handle gracefully.

| Error Type | Example | Fix Approach |
|------------|---------|--------------|
| Unavailable | 503 Service Unavailable | Retry, circuit breaker |
| Rate limited | 429 Too Many Requests | Backoff, queue requests |
| Changed API | Unexpected response format | Version check, graceful degradation |
| Timeout | Slow response | Timeout config, fallback |

## Error Categories by Scope

### Single Request Errors

Affects one user/job. Usually data-related.

**Symptoms:**
- One user reports issue
- Specific job fails
- Error contains user-specific data

**Investigation:**
- Check the specific input data
- Look for edge cases
- Verify data integrity

### Multiple Request Errors

Affects subset of users. Configuration or permission issue.

**Symptoms:**
- Reports from specific user group
- Failures in specific region/time
- Pattern in affected requests

**Investigation:**
- Compare working vs failing requests
- Check user segments (plan, region, etc.)
- Review recent configuration changes

### System-Wide Errors

Affects all requests. Infrastructure or deployment issue.

**Symptoms:**
- All requests failing
- Monitoring alerts firing
- Recent deployment

**Investigation:**
- Check infrastructure status
- Review recent deployments
- Rollback if necessary

## HTTP Status Code Guide

| Status | Meaning | Error Type | Debugging Approach |
|--------|---------|------------|-------------------|
| 400 | Bad Request | Permanent | Check request body, validate input |
| 401 | Unauthorized | Permanent | Check auth token, credentials |
| 403 | Forbidden | Permanent | Check user permissions |
| 404 | Not Found | Permanent | Verify resource exists, check URL |
| 408 | Request Timeout | Transient | Check slow operations |
| 409 | Conflict | Permanent | Check concurrent modifications |
| 422 | Unprocessable | Permanent | Check validation rules |
| 429 | Too Many Requests | Transient | Implement backoff, check rate limits |
| 500 | Internal Error | Application | Check logs, stack trace |
| 502 | Bad Gateway | Transient | Check upstream services |
| 503 | Unavailable | Transient | Check service health, capacity |
| 504 | Gateway Timeout | Transient | Check upstream timeouts |

### Handling HTTP Errors

```python
async def handle_response(response):
    if response.status_code < 400:
        return await response.json()
    
    if response.status_code == 429:
        retry_after = int(response.headers.get("Retry-After", 60))
        raise RateLimitError(f"Rate limited, retry after {retry_after}s")
    
    if response.status_code >= 500:
        raise TransientError(f"Server error: {response.status_code}")
    
    if response.status_code == 401:
        raise AuthenticationError("Invalid credentials")
    
    if response.status_code == 403:
        raise AuthorizationError("Permission denied")
    
    # 4xx errors are usually permanent
    raise PermanentError(f"Client error: {response.status_code}")
```

## Exception Hierarchy Patterns

### Custom Exception Hierarchy

```python
class AppError(Exception):
    """Base application error."""
    pass

class TransientError(AppError):
    """Error that may succeed on retry."""
    pass

class PermanentError(AppError):
    """Error that will not succeed on retry."""
    pass

class ValidationError(PermanentError):
    """Input validation failed."""
    pass

class NotFoundError(PermanentError):
    """Resource not found."""
    pass

class ExternalServiceError(TransientError):
    """External service failure."""
    pass
```

### Using the Hierarchy

```python
try:
    result = await process_request(data)
except TransientError as e:
    # Retry with backoff
    await enqueue_retry(job_id, delay=60)
except PermanentError as e:
    # Fail immediately, no retry
    await mark_failed(job_id, str(e))
except Exception as e:
    # Unexpected error - log and investigate
    logger.error("Unexpected error", exc_info=True)
    raise
```

## Error Decision Tree

```
Is the error in your code?
├── Yes → Application Error
│   ├── Can it be fixed with input validation? → Add validation
│   ├── Is it a logic bug? → Fix the code, add test
│   └── Is it a race condition? → Add locking/transactions
└── No → External Error
    ├── Is the service healthy?
    │   ├── No → Infrastructure Error (transient)
    │   └── Yes → Continue...
    ├── Is it a network issue?
    │   ├── Yes → Retry with backoff
    │   └── No → Continue...
    ├── Is it a permission issue?
    │   ├── Yes → Permanent, check config
    │   └── No → Continue...
    └── Is the response format unexpected?
        ├── Yes → API changed, update code
        └── No → Investigate further
```

## Quick Classification Checklist

When encountering an error:

```
Error Classification:
- [ ] Is this transient or permanent?
- [ ] Can I reproduce it consistently?
- [ ] Does it affect one request or many?
- [ ] Is it in my code or external?
- [ ] What's the appropriate action? (retry/fail/alert)
```
