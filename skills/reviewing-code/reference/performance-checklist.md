# Performance Review Checklist

## Database Performance

### N+1 Query Problem

- [ ] **No N+1 queries**: Check for queries inside loops
- [ ] **Eager loading**: Use joins or select_related/prefetch_related
- [ ] **Batch queries**: Load multiple records at once

```python
# ❌ BAD: N+1 queries
users = await db.execute(select(User))
for user in users:
    jobs = await db.execute(select(Job).where(Job.user_id == user.id))  # N queries!

# ✅ GOOD: Single query with join
users = await db.execute(
    select(User).options(joinedload(User.jobs))
)
```

### Database Indexes

- [ ] **Indexes on WHERE clauses**: Fields in WHERE need indexes
- [ ] **Indexes on JOIN columns**: Foreign keys should be indexed
- [ ] **Indexes on ORDER BY**: Sorting columns need indexes
- [ ] **Composite indexes**: For multi-column queries
- [ ] **Not over-indexed**: Too many indexes slow writes

```python
# In your model
class Job(Base):
    __tablename__ = "jobs"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)  # ✅ Indexed
    status = Column(String, index=True)  # ✅ Frequently queried
    created_at = Column(DateTime, index=True)  # ✅ For sorting
    
    # Composite index for common query
    __table_args__ = (
        Index('idx_user_status', 'user_id', 'status'),
    )
```

### Query Optimization

- [ ] **SELECT only needed columns**: Don't SELECT *
- [ ] **LIMIT results**: Paginate large result sets
- [ ] **Avoid subqueries**: Use JOINs when possible
- [ ] **Analyze query plans**: Use EXPLAIN to check queries
- [ ] **Connection pooling**: Reuse database connections

```python
# ❌ BAD: Fetches all columns
users = await db.execute(select(User))

# ✅ GOOD: Fetches only needed columns
users = await db.execute(select(User.id, User.email))

# ✅ GOOD: Paginated
users = await db.execute(
    select(User).limit(100).offset(page * 100)
)
```

### Transaction Management

- [ ] **Keep transactions short**: Long transactions lock tables
- [ ] **Read-only transactions**: Use read replicas when possible
- [ ] **Isolation level**: Use appropriate isolation level
- [ ] **Avoid deadlocks**: Consistent lock ordering

## Caching

### What to Cache

- [ ] **Expensive computations**: Cache results of slow operations
- [ ] **External API calls**: Cache responses with TTL
- [ ] **Database queries**: Cache frequently accessed data
- [ ] **Rendered content**: Cache HTML/JSON responses

### Cache Strategy

- [ ] **Cache key design**: Unique, predictable keys
- [ ] **TTL set**: Appropriate expiration times
- [ ] **Cache invalidation**: Clear cache when data changes
- [ ] **Cache warming**: Pre-populate cache for critical data
- [ ] **Fallback on cache miss**: Handle cache failures gracefully

```python
from redis import asyncio as aioredis

async def get_user(user_id: int):
    # Try cache first
    cache_key = f"user:{user_id}"
    cached = await redis.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Cache miss: fetch from database
    user = await db.get(User, user_id)
    
    # Store in cache (1 hour TTL)
    await redis.setex(cache_key, 3600, json.dumps(user.dict()))
    
    return user
```

## Async Performance

### Proper Async Usage

- [ ] **await used correctly**: All async calls await'd
- [ ] **No blocking operations**: No sync I/O in async functions
- [ ] **Concurrent operations**: Use asyncio.gather for parallel work
- [ ] **Connection pooling**: Reuse connections
- [ ] **Semaphores for concurrency limits**: Prevent resource exhaustion

```python
# ❌ BAD: Blocking I/O
async def process_files(files):
    results = []
    for file in files:
        data = open(file).read()  # Blocks!
        results.append(await process(data))
    return results

# ✅ GOOD: Async I/O with concurrency
async def process_files(files):
    async def process_one(file):
        async with aiofiles.open(file) as f:
            data = await f.read()
        return await process(data)
    
    return await asyncio.gather(*[process_one(f) for f in files])
```

### Connection Pooling

- [ ] **Database pool configured**: Min/max pool size set
- [ ] **HTTP session pooling**: Reuse HTTP connections
- [ ] **Pool size tuning**: Based on expected load

```python
# Database connection pool
engine = create_async_engine(
    database_url,
    pool_size=20,  # Normal connections
    max_overflow=40,  # Extra connections under load
    pool_pre_ping=True,  # Verify connections
)

# HTTP connection pool
async with httpx.AsyncClient(
    limits=httpx.Limits(max_connections=100, max_keepalive_connections=20)
) as client:
    ...
```

### Timeout Configuration

- [ ] **All external calls have timeouts**: HTTP, database, cache
- [ ] **Timeout values reasonable**: Not too short, not too long
- [ ] **Cascading timeouts**: Inner timeout < outer timeout

```python
# ✅ GOOD: Timeouts configured
response = await httpx.get(url, timeout=10.0)
result = await db.execute(query).with_timeout(5.0)
cached = await redis.get(key, timeout=1.0)
```

## Algorithm Efficiency

### Time Complexity

- [ ] **Avoid O(n²)**: No nested loops over large datasets
- [ ] **Use appropriate data structures**: Dict for lookups, set for membership
- [ ] **Avoid repeated work**: Cache intermediate results

```python
# ❌ BAD: O(n²) complexity
for item in list1:
    if item in list2:  # list2 is searched for each item
        ...

# ✅ GOOD: O(n) complexity
list2_set = set(list2)  # O(n) to create set
for item in list1:
    if item in list2_set:  # O(1) lookup
        ...
```

### Memory Usage

- [ ] **Stream large data**: Don't load everything into memory
- [ ] **Generators for iteration**: Use yield instead of building lists
- [ ] **Clean up resources**: Close files, connections, clear caches

```python
# ❌ BAD: Loads all data into memory
def process_large_file(path):
    lines = open(path).readlines()  # Loads entire file
    return [process_line(line) for line in lines]

# ✅ GOOD: Streams data
def process_large_file(path):
    with open(path) as f:
        for line in f:  # Yields one line at a time
            yield process_line(line)
```

## Network Performance

### API Design

- [ ] **Pagination**: Limit response sizes
- [ ] **Field selection**: Allow clients to request only needed fields
- [ ] **Batch endpoints**: Support batching multiple requests
- [ ] **Compression**: Enable gzip compression
- [ ] **ETags**: Support conditional requests

### Request Optimization

- [ ] **Minimize round trips**: Batch requests when possible
- [ ] **Use HTTP/2**: Multiplexing for parallel requests
- [ ] **Connection reuse**: Keep-alive connections
- [ ] **Retry with backoff**: For transient failures

## Monitoring Performance

### Instrumentation

- [ ] **Timing metrics**: Measure operation duration
- [ ] **Database query times**: Track slow queries
- [ ] **External API latency**: Measure third-party call times
- [ ] **Queue depth**: Monitor queue sizes
- [ ] **Cache hit rate**: Track cache effectiveness

```python
import time

async def timed_operation(operation_name):
    start = time.time()
    try:
        result = await some_operation()
        duration = time.time() - start
        metrics.histogram(f"{operation_name}.duration", duration)
        return result
    except Exception as e:
        duration = time.time() - start
        metrics.histogram(f"{operation_name}.error_duration", duration)
        raise
```

### Performance Budgets

- [ ] **API latency budget**: P50 < 100ms, P99 < 500ms
- [ ] **Database query budget**: Queries < 50ms
- [ ] **External API budget**: Calls < 1s
- [ ] **Page load budget**: Time to interactive < 3s

## Performance Anti-Patterns

### Common Issues

```python
# ❌ BAD: Loading all data then filtering
all_users = await db.execute(select(User))
active_users = [u for u in all_users if u.is_active]

# ✅ GOOD: Filter in database
active_users = await db.execute(select(User).where(User.is_active == True))

# ❌ BAD: Repeated database calls
for user_id in user_ids:
    user = await get_user(user_id)

# ✅ GOOD: Batch query
users = await db.execute(select(User).where(User.id.in_(user_ids)))

# ❌ BAD: No connection pooling
for _ in range(100):
    conn = await asyncpg.connect(dsn)  # New connection each time!
    await conn.fetch(query)
    await conn.close()

# ✅ GOOD: Use connection pool
async with pool.acquire() as conn:
    await conn.fetch(query)
```

## Performance Review Checklist

Before approving:
- [ ] No N+1 queries
- [ ] Database indexes on frequently queried fields
- [ ] Caching used for expensive operations
- [ ] Async operations use await correctly
- [ ] Connection pooling configured
- [ ] Timeouts set on external calls
- [ ] No blocking operations in async code
- [ ] Metrics instrumented for monitoring
