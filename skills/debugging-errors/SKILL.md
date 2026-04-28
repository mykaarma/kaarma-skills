---
name: debugging-errors
description: Systematically diagnose and resolve errors in production systems. Use when facing exceptions, unexpected behavior, performance issues, or system failures. Provides structured debugging workflows, error classification, and resolution strategies for async, distributed, and database systems.
---

# Debugging Errors in Production Systems

## When to Use This Skill

Use systematic debugging when:
- **Runtime exceptions**: Stack traces, crashes, unhandled errors
- **Unexpected behavior**: Code runs but produces wrong results
- **Performance issues**: Timeouts, slow responses, resource exhaustion
- **Intermittent failures**: Flaky tests, random crashes, race conditions
- **Integration failures**: API errors, database issues, queue problems
- **Production incidents**: User-reported issues, monitoring alerts

**Don't use when**:
- Writing new code (use **building-features** skill)
- Reviewing code for issues (use **reviewing-code** skill)
- Understanding existing code (use **researching-codebase** skill)

## The Debugging Workflow

Copy this checklist to track your debugging progress:

```
Debugging Progress:
- [ ] Step 1: Gather evidence (logs, stack traces, reproduction steps)
- [ ] Step 2: Classify the error (transient vs permanent, scope, category)
- [ ] Step 3: Isolate the problem (narrow to component/function/line)
- [ ] Step 4: Identify root cause (why is this happening?)
- [ ] Step 5: Fix and verify (implement fix, add regression test)
```

### Step 1: Gather Evidence

**Essential information to collect:**
- Full stack trace (not just the error message)
- Relevant log entries (before and after the error)
- Input data that triggered the error
- Environment details (dev/staging/prod, versions)
- Timeline (when did it start? what changed?)

```bash
# Find errors around a timestamp
grep -A5 -B5 "2024-01-15 10:30" logs/app.log | grep -i error

# Find by correlation ID
grep "req-abc123" logs/*.log

# Count error frequency
grep -c "ERROR" logs/app.log
```

### Step 2: Classify the Error

See [reference/error-classification.md](reference/error-classification.md) for detailed taxonomy.

**Quick classification:**

| Symptom | Likely Category | First Check |
|---------|-----------------|-------------|
| Connection refused | Network/Infrastructure | Service health, ports, DNS |
| Timeout | Resource exhaustion | Connection pool, slow query, external API |
| NoneType error | Data integrity | Null checks, missing required data |
| Permission denied | Authorization | User permissions, file permissions |
| Out of memory | Resource leak | Memory profiling, connection leaks |
| 500 Internal Error | Application bug | Stack trace, recent deployments |
| Intermittent failure | Race condition | Timing, concurrent access, locks |

### Step 3: Isolate the Problem

**Binary search debugging:**
```python
async def complex_operation(data):
    logger.debug("Step 1: Starting")  # Does this print?
    result_a = await step_a(data)
    
    logger.debug("Step 2: After step_a")  # Does this print?
    result_b = await step_b(result_a)
    
    logger.debug("Step 3: After step_b")  # Error before or after?
    result_c = await step_c(result_b)
    
    return result_c
```

**Minimal reproduction:**
- Strip away unrelated code
- Use hardcoded test data
- Write a failing test that reproduces the issue

### Step 4: Identify Root Cause

**The "5 Whys" technique:**
```
Problem: API returns 500 error
Why? -> Database query failed
Why? -> Connection pool exhausted
Why? -> Connections not being released
Why? -> Missing context manager for session
Why? -> Developer didn't follow project pattern

Root cause: Missing code review + documentation gap
```

### Step 5: Fix and Verify

- Implement the fix
- Write a regression test that would have caught it
- Verify the fix in the same environment where error occurred
- Update documentation if pattern was unclear
- Consider if similar issues exist elsewhere

## Quick Diagnosis Patterns

### Pattern 1: Reading Stack Traces

```python
Traceback (most recent call last):
  File "/app/worker.py", line 45, in process_job      # Start here (your code)
    result = await transcribe(audio_file)
  File "/app/services/transcription.py", line 23, in transcribe
    response = await client.post(url, data=data)      # Trace the call chain
  File "/usr/lib/python3.11/aiohttp/client.py", line 520, in _request
    raise ClientConnectorError(...)                   # Exception origin
aiohttp.ClientConnectorError: Cannot connect to host api.example.com:443
```

**Reading order:**
1. Read exception type and message (bottom)
2. Find first line in YOUR code (not libraries)
3. Check what arguments/state led there
4. Work backwards through the call chain

### Pattern 2: Log Analysis

**Structured logging makes debugging easier:**
```python
# Good: Structured with context
logger.error("Job failed", extra={
    "job_id": job_id,
    "task_id": task_id,
    "error": str(e),
    "audio_url": audio_url,
}, exc_info=True)  # Include full stack trace

# Bad: Unstructured, missing context
logger.error(f"Error: {e}")
```

**Log correlation:**
```bash
# Follow a request through the system
grep "correlation_id=abc123" logs/*.log | sort

# Find all errors for a specific job
grep "job_id=456" logs/worker.log | grep -i error
```

### Pattern 3: Reproduction

**Reproduction checklist:**
```
- [ ] Can reproduce locally?
- [ ] Can reproduce with test?
- [ ] Exact input data captured?
- [ ] Environment differences identified?
- [ ] Timing/load factors considered?
```

## Async-Specific Debugging

### Missing `await`

**Error:** `RuntimeWarning: coroutine 'function' was never awaited`

```python
# Bug: Missing await
result = async_function()  # Returns coroutine object, not result
print(type(result))  # <coroutine object ...>

# Fix
result = await async_function()
```

### Event Loop Issues

**Error:** `RuntimeError: This event loop is already running`

```python
# Bug: asyncio.run() inside async context
async def handler():
    result = asyncio.run(other_async())  # Wrong!

# Fix: Just await
async def handler():
    result = await other_async()
```

**Error:** `RuntimeError: Event loop is closed`

```python
# Bug: Reusing closed loop
loop = asyncio.get_event_loop()
loop.run_until_complete(task())
loop.close()
loop.run_until_complete(another())  # Error!

# Fix: Use asyncio.run() or create new loop
asyncio.run(main())  # Handles loop lifecycle
```

### Blocking Sync Code in Async

```python
# Bug: Blocking the event loop
async def process():
    data = open(large_file).read()  # Blocks!
    result = requests.get(url)       # Blocks!

# Fix: Use async equivalents
async def process():
    async with aiofiles.open(large_file) as f:
        data = await f.read()
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            result = await response.json()
```

### Connection Pool Exhaustion

**Error:** `QueuePool limit of X overflow Y reached`

```python
# Bug: Connection leak
async def query():
    session = await get_session()
    result = await session.execute(query)
    return result  # Session never closed!

# Fix: Always use context manager
async def query():
    async with db.get_session() as session:
        result = await session.execute(query)
        return result  # Automatically closed
```

## Database Debugging

### Query Performance

```sql
-- Analyze query execution plan
EXPLAIN ANALYZE SELECT * FROM jobs WHERE user_id = 123;

-- Find slow queries (PostgreSQL)
SELECT query, calls, mean_time, total_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Check for missing indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;  -- Unused indexes
```

### Connection Issues

```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Find blocked queries
SELECT * FROM pg_locks WHERE NOT granted;

-- Kill stuck connection
SELECT pg_terminate_backend(pid);
```

### Deadlock Detection

```python
# Handle deadlock with retry
from asyncpg import DeadlockDetectedError
import random

async def safe_transaction():
    for attempt in range(3):
        try:
            async with db.transaction():
                await execute_operations()
            return
        except DeadlockDetectedError:
            await asyncio.sleep(random.uniform(0.1, 0.5))
    raise Exception("Transaction failed after retries")
```

## Distributed System Debugging

### Correlation IDs

**Essential for tracing requests across services:**

```python
# Generate at entry point
import uuid
correlation_id = str(uuid.uuid4())

# Include in all logs
logger.info("Processing request", extra={"correlation_id": correlation_id})

# Pass to downstream services
headers = {"X-Correlation-ID": correlation_id}
await client.post(url, headers=headers)
```

### Network Debugging

```bash
# Test connectivity
curl -v https://api.example.com/health

# Check DNS
nslookup api.example.com

# Check if port is open
nc -zv api.example.com 443

# Trace network path
traceroute api.example.com
```

### Service Health Checks

```python
# Comprehensive health check
async def health_check():
    checks = {
        "database": await check_database(),
        "redis": await check_redis(),
        "external_api": await check_external_api(),
    }
    
    healthy = all(checks.values())
    return {
        "status": "healthy" if healthy else "degraded",
        "checks": checks
    }
```

## Error Handling Patterns

### Transient vs Permanent Errors

```python
# Categorize errors for retry decisions
TRANSIENT_ERRORS = (
    ConnectionError,
    TimeoutError,
    aiohttp.ClientError,
)

PERMANENT_ERRORS = (
    ValueError,
    ValidationError,
    AuthenticationError,
)

def is_transient(error: Exception) -> bool:
    return isinstance(error, TRANSIENT_ERRORS)
```

### Retry with Exponential Backoff

```python
async def retry_with_backoff(func, max_attempts=3):
    for attempt in range(max_attempts):
        try:
            return await func()
        except TRANSIENT_ERRORS as e:
            if attempt == max_attempts - 1:
                raise
            delay = 60 * (3 ** attempt)  # 60s, 180s, 540s
            logger.warning(f"Retry {attempt + 1}/{max_attempts} after {delay}s")
            await asyncio.sleep(delay)
```

### Graceful Degradation

```python
async def get_data_with_fallback():
    try:
        return await fetch_from_primary()
    except TransientError:
        logger.warning("Primary unavailable, using cache")
        return await fetch_from_cache()
    except Exception as e:
        logger.error("All sources failed", exc_info=True)
        raise
```

## Integration with Other Skills

- **researching-codebase**: Use to understand code context before debugging
- **testing-code**: Write regression tests after fixing bugs
- **reviewing-code**: Check if bug indicates systemic issues
- **thinking-first-principles**: For complex root cause analysis
- **building-features**: After fixing, improve the implementation

## When Debugging is Complete

Debugging is done when:
- [ ] Root cause is identified and documented
- [ ] Fix is implemented and verified
- [ ] Regression test added to prevent recurrence
- [ ] Similar issues checked elsewhere in codebase
- [ ] Documentation updated if pattern was unclear
- [ ] Monitoring/alerting improved if needed
- [ ] Post-mortem documented (for production incidents)

## Reference Materials

For detailed information, see:
- [Error Classification](reference/error-classification.md) - Categorizing error types
- [Debugging Strategies](reference/debugging-strategies.md) - Systematic approaches
- [Common Error Patterns](reference/common-error-patterns.md) - Language-specific fixes
