# Common Error Patterns

Language and framework-specific error patterns with fixes.

## Python Async Errors

### RuntimeWarning: coroutine was never awaited

**Error:**
```
RuntimeWarning: coroutine 'async_function' was never awaited
```

**Cause:** Called async function without `await`.

```python
# Bug
result = async_function()  # Returns coroutine, not result
print(result)  # <coroutine object async_function at 0x...>

# Fix
result = await async_function()
```

### Event loop is already running

**Error:**
```
RuntimeError: This event loop is already running
```

**Cause:** Using `asyncio.run()` inside async context.

```python
# Bug
async def handler():
    result = asyncio.run(other_async())  # Wrong!

# Fix: Just await
async def handler():
    result = await other_async()

# If you need to run from sync code inside async:
import nest_asyncio
nest_asyncio.apply()  # Only as last resort
```

### Event loop is closed

**Error:**
```
RuntimeError: Event loop is closed
```

**Cause:** Trying to use a closed event loop.

```python
# Bug
loop = asyncio.get_event_loop()
loop.run_until_complete(task1())
loop.close()
loop.run_until_complete(task2())  # Error!

# Fix: Use asyncio.run() for main entry
async def main():
    await task1()
    await task2()

asyncio.run(main())  # Handles loop lifecycle
```

### Task was destroyed but pending

**Error:**
```
Task was destroyed but it is pending!
```

**Cause:** Program exited before task completed.

```python
# Bug
async def main():
    asyncio.create_task(long_running())
    # Returns immediately, task abandoned

# Fix: Await or gather tasks
async def main():
    task = asyncio.create_task(long_running())
    await task

# Or for fire-and-forget with cleanup:
async def main():
    tasks = set()
    task = asyncio.create_task(long_running())
    tasks.add(task)
    task.add_done_callback(tasks.discard)
    
    # At shutdown:
    for task in tasks:
        task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)
```

## Database Errors

### Connection Pool Exhausted

**Error:**
```
sqlalchemy.exc.TimeoutError: QueuePool limit of 5 overflow 10 reached
```

**Cause:** Connection leak - connections not returned to pool.

```python
# Bug: Connection leak
async def query():
    session = sessionmaker()
    result = await session.execute(query)
    return result  # Session never closed!

# Fix: Always use context manager
async def query():
    async with async_session() as session:
        result = await session.execute(query)
        return result  # Automatically closed

# Or explicit try/finally
async def query():
    session = async_session()
    try:
        result = await session.execute(query)
        return result
    finally:
        await session.close()
```

### Deadlock Detected

**Error:**
```
asyncpg.exceptions.DeadlockDetectedError: deadlock detected
```

**Cause:** Two transactions waiting for each other's locks.

```python
# Bug: Inconsistent lock ordering
# Transaction 1: UPDATE users, then UPDATE orders
# Transaction 2: UPDATE orders, then UPDATE users

# Fix 1: Consistent lock ordering
async def transfer():
    # Always lock in same order: orders first, then users
    await session.execute("SELECT ... FROM orders FOR UPDATE")
    await session.execute("SELECT ... FROM users FOR UPDATE")

# Fix 2: Retry with backoff
import random
async def safe_update():
    for attempt in range(3):
        try:
            async with session.begin():
                await execute_updates()
            return
        except asyncpg.DeadlockDetectedError:
            await asyncio.sleep(random.uniform(0.1, 0.5))
    raise Exception("Failed after retries")
```

### Integrity Error (Duplicate Key)

**Error:**
```
asyncpg.exceptions.UniqueViolationError: duplicate key value violates unique constraint
```

**Cause:** Race condition with concurrent inserts.

```python
# Bug: Check-then-insert race
if not await exists(id):
    await insert(id, data)  # Another process might insert between check and insert

# Fix: Use ON CONFLICT (upsert)
from sqlalchemy.dialects.postgresql import insert

stmt = insert(Job).values(id=job_id, data=data)
stmt = stmt.on_conflict_do_update(
    index_elements=['id'],
    set_=dict(data=data, updated_at=func.now())
)
await session.execute(stmt)
```

### N+1 Query Problem

**Symptoms:** Slow page load, many similar queries in logs.

```python
# Bug: N+1 queries
jobs = await session.execute(select(Job))
for job in jobs:
    # Each iteration makes a new query!
    user = await session.execute(select(User).where(User.id == job.user_id))

# Fix: Eager loading
from sqlalchemy.orm import selectinload

jobs = await session.execute(
    select(Job).options(selectinload(Job.user))
)
for job in jobs:
    user = job.user  # Already loaded, no query
```

## HTTP Client Errors

### Connection Refused

**Error:**
```
aiohttp.client_exceptions.ClientConnectorError: Cannot connect to host api.example.com:443
```

**Causes:**
- Service is down
- Wrong host/port
- Firewall blocking
- DNS resolution failure

```python
# Debug steps
# 1. curl -v https://api.example.com/health
# 2. Check if service is running
# 3. Check network/firewall

# Handle gracefully
try:
    async with session.get(url) as response:
        return await response.json()
except aiohttp.ClientConnectorError:
    logger.warning(f"Cannot connect to {url}")
    raise TransientError("Service unavailable")
```

### Timeout Error

**Error:**
```
asyncio.TimeoutError
```

**Causes:**
- Server is slow
- Network latency
- Timeout too short

```python
# Set appropriate timeouts
timeout = aiohttp.ClientTimeout(
    total=30,        # Total request timeout
    connect=5,       # Connection timeout
    sock_read=10     # Read timeout
)

async with aiohttp.ClientSession(timeout=timeout) as session:
    try:
        async with session.get(url) as response:
            return await response.json()
    except asyncio.TimeoutError:
        logger.warning(f"Request timed out: {url}")
        raise TransientError("Request timeout")
```

### SSL Certificate Error

**Error:**
```
aiohttp.client_exceptions.ClientConnectorCertificateError: Cannot connect to host
```

**Causes:**
- Self-signed certificate
- Expired certificate
- Wrong hostname in certificate

```python
# For development only (never in production!)
import ssl
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

connector = aiohttp.TCPConnector(ssl=ssl_context)
async with aiohttp.ClientSession(connector=connector) as session:
    ...

# Production: Fix the certificate!
```

## Queue/Worker Errors

### Jobs Stuck in Processing

**Symptoms:** Jobs never complete, stay in "processing" forever.

**Causes:**
- Worker crashed mid-job
- Infinite loop
- External dependency hanging

```python
# Fix: Add job timeout
async def process_job(job_id: int):
    try:
        await asyncio.wait_for(
            do_processing(job_id),
            timeout=300  # 5 minute max
        )
    except asyncio.TimeoutError:
        logger.error(f"Job {job_id} timed out")
        await mark_job_failed(job_id, "Processing timeout")

# Fix: Health check for stuck jobs
async def cleanup_stuck_jobs():
    stuck = await get_jobs_stuck_in_processing(older_than_minutes=30)
    for job in stuck:
        logger.warning(f"Resetting stuck job {job.id}")
        await mark_job_pending(job.id)  # Reset for retry
```

### Jobs Retrying Infinitely

**Cause:** Wrong error classification - transient error that's actually permanent.

```python
# Bug: Retrying validation errors
except Exception as e:
    raise Retry()  # Wrong! ValidationError will never succeed

# Fix: Classify errors
except Exception as e:
    if isinstance(e, (ValueError, ValidationError)):
        await mark_job_failed(job_id, str(e))  # Permanent
        return
    if job.attempts >= MAX_RETRIES:
        await mark_job_failed(job_id, "Max retries exceeded")
        return
    raise Retry(defer=60)  # Transient, retry
```

## Memory Errors

### Out of Memory

**Error:**
```
MemoryError
# Or process killed by OOM killer
```

**Cause:** Loading large data into memory at once.

```python
# Bug: Loading entire file into memory
def process_large_file(path):
    data = open(path).read()  # 10GB file = 10GB memory
    return process(data)

# Fix: Stream/chunk processing
async def process_large_file(path):
    async with aiofiles.open(path, 'rb') as f:
        while chunk := await f.read(8192):  # 8KB chunks
            process_chunk(chunk)

# Fix: Generator for large datasets
def process_records(records):
    for record in records:  # Don't convert to list!
        yield transform(record)
```

### Memory Leak

**Symptoms:** Memory grows over time, eventually crashes.

```python
# Bug: Unbounded list growth
cache = []
def process(item):
    result = compute(item)
    cache.append(result)  # Never cleared!
    return result

# Fix: Use LRU cache or size limit
from functools import lru_cache

@lru_cache(maxsize=1000)
def process(item):
    return compute(item)

# Or manual size limiting
from collections import deque
cache = deque(maxlen=1000)  # Auto-evicts oldest
```

## Import and Module Errors

### Circular Import

**Error:**
```
ImportError: cannot import name 'X' from partially initialized module 'Y'
```

**Cause:** Module A imports B, B imports A.

```python
# Bug: Circular import
# models.py
from services import UserService  # Imports services
class User: ...

# services.py
from models import User  # Imports models -> circular!
class UserService: ...

# Fix 1: Import inside function
# services.py
class UserService:
    def get_user(self):
        from models import User  # Lazy import
        return User.query.first()

# Fix 2: Restructure modules
# Create separate module for shared types/interfaces
```

### Module Not Found

**Error:**
```
ModuleNotFoundError: No module named 'mypackage'
```

**Causes:**
- Package not installed
- Wrong virtual environment
- Missing `__init__.py`
- PYTHONPATH not set

```bash
# Debug steps
pip list | grep mypackage
which python
echo $PYTHONPATH

# Check if in correct venv
source .venv/bin/activate
pip install mypackage
```

## Type Errors

### NoneType Has No Attribute

**Error:**
```
AttributeError: 'NoneType' object has no attribute 'name'
```

**Cause:** Expected object, got None.

```python
# Bug
user = await get_user(user_id)
name = user.name  # user might be None!

# Fix: Explicit null check
user = await get_user(user_id)
if user is None:
    raise ValueError(f"User {user_id} not found")
name = user.name

# Fix: Use Optional type hints
from typing import Optional

async def get_user(user_id: int) -> Optional[User]:
    ...

# IDE will warn about potential None
```

### Type Mismatch

**Error:**
```
TypeError: can only concatenate str (not "int") to str
```

**Cause:** Wrong type passed to function.

```python
# Bug
message = "Count: " + count  # count is int

# Fix
message = f"Count: {count}"
# Or
message = "Count: " + str(count)
```

## Encoding Errors

### UnicodeDecodeError

**Error:**
```
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0
```

**Cause:** Binary data decoded with wrong encoding.

```python
# Bug
with open(path, 'r') as f:  # Assumes UTF-8
    content = f.read()

# Fix: Specify encoding
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Fix: Detect encoding
import chardet
raw = open(path, 'rb').read()
detected = chardet.detect(raw)
content = raw.decode(detected['encoding'] or 'utf-8')

# Fix: Read as binary
with open(path, 'rb') as f:
    raw_bytes = f.read()
```

## JSON Errors

### JSONDecodeError

**Error:**
```
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

**Cause:** Empty response or invalid JSON.

```python
# Bug
data = response.json()  # Fails if empty or invalid

# Fix: Check before parsing
if response.status_code == 204 or not response.text:
    return None

try:
    data = response.json()
except json.JSONDecodeError as e:
    logger.error(f"Invalid JSON: {response.text[:100]}")
    raise ValueError("Invalid response format")
```

### Unexpected JSON Structure

**Error:**
```
KeyError: 'data'
TypeError: list indices must be integers, not str
```

**Cause:** API response structure changed.

```python
# Bug: Assumes structure
data = response["data"]["items"][0]["id"]

# Fix: Defensive access
data = response.get("data", {})
items = data.get("items", [])
if items:
    item_id = items[0].get("id")
else:
    item_id = None

# Fix: Validate with Pydantic
from pydantic import BaseModel

class ApiResponse(BaseModel):
    data: dict
    items: list

response = ApiResponse.parse_obj(raw_response)
```

## File System Errors

### FileNotFoundError

**Error:**
```
FileNotFoundError: [Errno 2] No such file or directory: '/path/to/file'
```

**Causes:**
- Wrong path
- File deleted
- Race condition

```python
# Fix: Check existence
from pathlib import Path

path = Path(file_path)
if not path.exists():
    raise FileNotFoundError(f"File not found: {path}")

# Fix: Handle race condition
try:
    with open(path) as f:
        content = f.read()
except FileNotFoundError:
    logger.warning(f"File disappeared: {path}")
    return None
```

### Permission Denied

**Error:**
```
PermissionError: [Errno 13] Permission denied: '/path/to/file'
```

**Causes:**
- File owned by different user
- Read-only file system
- SELinux/AppArmor blocking

```bash
# Debug
ls -la /path/to/file
stat /path/to/file
getenforce  # Check SELinux

# Fix permissions
chmod 644 /path/to/file
chown user:group /path/to/file
```

### Disk Full

**Error:**
```
OSError: [Errno 28] No space left on device
```

**Fix:**
```bash
# Find large files
du -sh /* | sort -h | tail -20
df -h  # Check disk usage

# Clean up
# Delete old logs, temp files, docker images
docker system prune -a
```

## Quick Reference: Error to Solution

| Error Message | Likely Cause | Quick Fix |
|---------------|--------------|-----------|
| `coroutine was never awaited` | Missing `await` | Add `await` |
| `Event loop is already running` | `asyncio.run()` in async | Use `await` |
| `QueuePool limit reached` | Connection leak | Use context manager |
| `deadlock detected` | Lock ordering | Consistent order + retry |
| `Cannot connect to host` | Service down | Check health, retry |
| `TimeoutError` | Slow operation | Increase timeout, retry |
| `NoneType has no attribute` | Null not handled | Add null check |
| `JSONDecodeError` | Invalid JSON | Validate before parse |
| `FileNotFoundError` | Missing file | Check existence |
| `MemoryError` | Large data in memory | Stream/chunk processing |
