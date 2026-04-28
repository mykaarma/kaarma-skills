# Debugging Strategies

Systematic approaches for diagnosing errors efficiently.

## Binary Search Debugging

**When to use:** Large codebase, unclear where error originates.

**Strategy:**
1. Add log/breakpoint at midpoint of suspected code path
2. Determine if error occurs before or after
3. Repeat, halving the search space each time
4. Continue until error location is isolated

```python
async def complex_pipeline(data):
    logger.debug("Checkpoint 1: Start")
    step1_result = await step1(data)
    
    logger.debug("Checkpoint 2: After step1", extra={"result": step1_result})
    step2_result = await step2(step1_result)
    
    logger.debug("Checkpoint 3: After step2", extra={"result": step2_result})
    step3_result = await step3(step2_result)
    
    logger.debug("Checkpoint 4: After step3", extra={"result": step3_result})
    return await step4(step3_result)
```

**Efficiency:** O(log n) instead of O(n) for finding the problematic step.

## Rubber Duck Debugging

**When to use:** Logic errors, code that "should work."

**Strategy:**
1. Explain the code line-by-line to an imaginary listener (or rubber duck)
2. Articulate what each line is supposed to do
3. Compare what it's supposed to do vs. what it actually does
4. The act of explaining often reveals wrong assumptions

**Example internal monologue:**
> "This function takes a list of jobs and filters them by status. First, I get all jobs... wait, this returns a coroutine, not the actual jobs. I forgot to await it."

## Git Bisect for Regressions

**When to use:** "This used to work" - finding which commit broke it.

```bash
# Start bisect
git bisect start

# Mark current commit as broken
git bisect bad

# Mark a known-good commit
git bisect good abc1234

# Git checks out middle commit
# Test if it works, then mark:
git bisect good  # or
git bisect bad

# Repeat until culprit found
# Git will identify the first bad commit

# When done
git bisect reset
```

**Automated bisect:**
```bash
# Run a test script at each step
git bisect run pytest tests/test_specific.py -x
```

## Differential Debugging

**When to use:** Works in one environment, fails in another.

**Comparison checklist:**
```
Environment Differences:
- [ ] Environment variables
- [ ] Configuration files
- [ ] Dependency versions (pip freeze, package-lock.json)
- [ ] OS/platform (Linux vs macOS vs Windows)
- [ ] Python/Node version
- [ ] Database version and schema
- [ ] Time/timezone settings
- [ ] File permissions
- [ ] Network configuration (firewall, proxy)
- [ ] Resource limits (memory, file descriptors)
```

**Command comparison:**
```bash
# Compare environment variables
diff <(env | sort) <(ssh prod 'env | sort')

# Compare installed packages
diff <(pip freeze) <(ssh prod 'pip freeze')

# Compare configs
diff local.env prod.env
```

## Logging Strategy

### Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| DEBUG | Variable values, flow tracing | `logger.debug(f"Processing item {i}")` |
| INFO | Normal operations | `logger.info("Job completed", extra={"job_id": id})` |
| WARNING | Concerning but recoverable | `logger.warning("Retry 2 of 3")` |
| ERROR | Failures requiring attention | `logger.error("Failed", exc_info=True)` |
| CRITICAL | System failures | `logger.critical("Database down")` |

### Structured Logging

```python
# Good: Structured, searchable
logger.info("Job processed", extra={
    "job_id": job_id,
    "user_id": user_id,
    "duration_ms": int(duration * 1000),
    "status": "completed",
    "correlation_id": correlation_id,
})

# Bad: Unstructured, hard to parse
logger.info(f"Job {job_id} for user {user_id} completed in {duration}s")
```

### Stack Traces

```python
# Always include full stack trace for errors
try:
    await risky_operation()
except Exception as e:
    logger.error("Operation failed", exc_info=True)  # Includes stack trace
    # Or explicitly:
    logger.error(f"Operation failed: {e}\n{traceback.format_exc()}")
```

### Log Correlation

```python
# Generate correlation ID at entry point
correlation_id = str(uuid.uuid4())

# Include in all logs
logger = logging.getLogger(__name__)
logger = logging.LoggerAdapter(logger, {"correlation_id": correlation_id})

# Pass to downstream services
headers = {"X-Correlation-ID": correlation_id}
```

## Profiling for Performance Issues

### CPU Profiling

```python
import cProfile
import pstats

# Profile a function
with cProfile.Profile() as pr:
    result = slow_function()

# Analyze results
stats = pstats.Stats(pr)
stats.sort_stats('cumulative')
stats.print_stats(20)  # Top 20 time consumers
```

### Memory Profiling

```python
# Install: pip install memory-profiler
from memory_profiler import profile

@profile
def memory_intensive():
    data = []
    for i in range(1000000):
        data.append({"id": i, "value": "x" * 100})
    return data

# Run with: python -m memory_profiler script.py
```

### Async Task Profiling

```python
import asyncio

# List all pending tasks
for task in asyncio.all_tasks():
    print(f"Task: {task.get_name()}")
    print(f"Stack: {task.get_stack()}")

# Check if event loop is blocked
import time
async def monitor_loop():
    while True:
        start = time.monotonic()
        await asyncio.sleep(0.1)
        delay = time.monotonic() - start - 0.1
        if delay > 0.01:  # More than 10ms delay
            logger.warning(f"Event loop blocked for {delay*1000:.0f}ms")
```

### Line Profiling

```python
# Install: pip install line_profiler
# Decorate function
@profile
def slow_function():
    result = []
    for i in range(1000):
        result.append(expensive_operation(i))
    return result

# Run with: kernprof -l -v script.py
```

## Database Query Debugging

### PostgreSQL Query Analysis

```sql
-- See query execution plan
EXPLAIN ANALYZE 
SELECT * FROM jobs 
WHERE user_id = 123 
AND status = 'pending';

-- Find slow queries
SELECT query, calls, mean_time, total_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;  -- Unused indexes

-- Find missing indexes (tables with sequential scans)
SELECT schemaname, relname, seq_scan, idx_scan
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan
ORDER BY seq_scan DESC;
```

### Connection Pool Debugging

```sql
-- Count active connections
SELECT count(*) FROM pg_stat_activity;

-- Find long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

-- Find blocked queries
SELECT blocked.pid, blocked.query, blocking.pid AS blocking_pid
FROM pg_stat_activity blocked
JOIN pg_locks blocked_locks ON blocked.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocked_locks.locktype = blocking_locks.locktype
JOIN pg_stat_activity blocking ON blocking_locks.pid = blocking.pid
WHERE NOT blocked_locks.granted;
```

### SQLAlchemy Debugging

```python
# Enable SQL echo
engine = create_async_engine(url, echo=True)

# Log slow queries
import logging
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)
```

## Network Debugging

### Connectivity Tests

```bash
# Test HTTP endpoint
curl -v https://api.example.com/health

# With timing
curl -w "@curl-format.txt" -o /dev/null -s https://api.example.com/

# Check DNS
nslookup api.example.com
dig api.example.com

# Check if port is open
nc -zv api.example.com 443

# Trace route
traceroute api.example.com

# Check SSL certificate
openssl s_client -connect api.example.com:443 -servername api.example.com
```

### curl-format.txt for timing:
```
     time_namelookup:  %{time_namelookup}s\n
        time_connect:  %{time_connect}s\n
     time_appconnect:  %{time_appconnect}s\n
    time_pretransfer:  %{time_pretransfer}s\n
       time_redirect:  %{time_redirect}s\n
  time_starttransfer:  %{time_starttransfer}s\n
                     ----------\n
          time_total:  %{time_total}s\n
```

## The "5 Whys" Technique

Dig to root cause by asking "Why?" repeatedly.

**Example:**

```
Problem: API returning 500 errors

1. Why? → Database query is failing
2. Why? → Connection pool is exhausted
3. Why? → Connections aren't being returned
4. Why? → Exception handler doesn't close session
5. Why? → No code review caught the missing finally block

Root cause: Code review process gap + missing linter rule
```

**Template:**
```
Problem: [Describe the symptom]
1. Why? → [First-level cause]
2. Why? → [Second-level cause]
3. Why? → [Third-level cause]
4. Why? → [Fourth-level cause]
5. Why? → [Root cause - usually process/system issue]

Root cause: [Summary]
Action items:
- Fix immediate issue
- Address root cause
- Prevent recurrence
```

## Production Incident Checklist

```
Incident Response:
- [ ] Acknowledge the incident
- [ ] Assess impact (users affected, severity)
- [ ] Establish timeline (when did it start?)
- [ ] Identify recent changes (deployments, config changes)
- [ ] Collect evidence (logs, metrics, screenshots)
- [ ] Implement immediate mitigation (rollback, restart, scale)
- [ ] Communicate status to stakeholders
- [ ] Identify root cause
- [ ] Implement fix
- [ ] Verify fix in production
- [ ] Document incident
- [ ] Schedule post-mortem
```

### Post-Mortem Template

```markdown
# Incident Post-Mortem: [Title]

## Summary
- **Date:** YYYY-MM-DD
- **Duration:** X hours
- **Impact:** Y users affected, Z requests failed
- **Severity:** P1/P2/P3

## Timeline
- HH:MM - First alert
- HH:MM - Investigation started
- HH:MM - Root cause identified
- HH:MM - Fix deployed
- HH:MM - Incident resolved

## Root Cause
[Detailed explanation]

## Resolution
[What fixed it]

## Lessons Learned
- What went well
- What went poorly
- Where we got lucky

## Action Items
- [ ] [Action 1] - Owner - Due date
- [ ] [Action 2] - Owner - Due date
```

## Debugging Checklist Templates

### General Debugging
```
- [ ] Full error message and stack trace captured
- [ ] Reproduction steps documented
- [ ] Environment details noted
- [ ] Recent changes identified
- [ ] Similar past issues checked
- [ ] Logs collected with timestamps
- [ ] Root cause identified
- [ ] Fix verified
- [ ] Regression test added
```

### Async Debugging
```
- [ ] All coroutines awaited?
- [ ] Event loop not blocked by sync code?
- [ ] Context managers properly used?
- [ ] Connections being closed/returned?
- [ ] Timeouts configured?
- [ ] Tasks not being cancelled unexpectedly?
```

### Database Debugging
```
- [ ] Query execution plan checked (EXPLAIN)?
- [ ] Indexes being used?
- [ ] Connection pool not exhausted?
- [ ] No deadlocks?
- [ ] Transactions not too long?
- [ ] N+1 queries avoided?
```
