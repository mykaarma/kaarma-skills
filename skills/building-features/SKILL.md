---
name: building-features
description: Implement production-ready features for high-reliability systems following industry best practices. Use when building APIs, services, background workers, data pipelines, or user-facing features where performance and maintainability are critical. Covers backend, frontend, security, observability, and deployment.
---

# Building Production-Ready Features

## When to Use This Skill

Use this skill when implementing:
- **APIs and services**: REST, GraphQL, gRPC endpoints
- **Background workers**: Queue consumers, scheduled jobs, data processing
- **Data pipelines**: ETL, streaming, batch processing
- **User-facing features**: UI components with backend integration
- **Infrastructure**: Deployment scripts, monitoring, observability

## Implementation Workflow

Copy this checklist and track your progress:

```
Feature Implementation Progress:
- [ ] Step 1: Research existing patterns (use researching-codebase skill)
- [ ] Step 2: Design the solution (API contracts, data models, error cases)
- [ ] Step 3: Implement core functionality
- [ ] Step 4: Add error handling and retry logic
- [ ] Step 5: Implement observability (logging, metrics, tracing)
- [ ] Step 6: Write comprehensive tests
- [ ] Step 7: Add documentation
- [ ] Step 8: Security review (use reviewing-code skill)
- [ ] Step 9: Performance testing
- [ ] Step 10: Deploy and monitor
```

## Core Implementation Checklist

> **Note**: This skill focuses on backend/infrastructure systems. For frontend-specific patterns, create a separate `building-frontend` skill.

### Backend Features

See [reference/checklist-backend.md](reference/checklist-backend.md) for detailed backend implementation patterns.

**Quick checklist**:
- [ ] API contract defined (request/response schemas)
- [ ] Input validation with clear error messages
- [ ] Business logic separated from HTTP/queue handling
- [ ] Database transactions handled correctly
- [ ] Async operations use proper patterns (await, connection pooling)
- [ ] Retry logic for transient failures
- [ ] Idempotency for non-GET operations
- [ ] Rate limiting and timeout configuration
- [ ] Structured logging with correlation IDs
- [ ] Metrics and traces instrumented


### Security

See [reference/security-considerations.md](reference/security-considerations.md) for comprehensive security guidance.

**Critical security checks**:
- [ ] Input sanitized and validated
- [ ] Authentication required where needed
- [ ] Authorization checked before operations
- [ ] Secrets not hard-coded or logged
- [ ] SQL injection prevented (use parametrized queries)
- [ ] XSS prevented (escape output)
- [ ] CSRF protection enabled
- [ ] Rate limiting on sensitive endpoints

## Common Patterns

### Pattern 1: Async Background Job

```python
async def process_job(ctx: dict, job_id: int):
    """Process job with proper error handling and observability."""
    logger = logging.getLogger(__name__)
    start_time = time.time()
    
    try:
        # 1. Fetch job data
        job = await get_job(ctx["db"], job_id)
        if not job:
            logger.error(f"Job {job_id} not found")
            return {"error": "Job not found"}
        
        # 2. Update status
        await update_job_status(ctx["db"], job_id, "processing")
        
        # 3. Do the work with retry logic
        result = await process_with_retry(job.data)
        
        # 4. Store result
        await update_job_result(ctx["db"], job_id, result, "completed")
        
        # 5. Metrics
        duration = time.time() - start_time
        logger.info(f"Job {job_id} completed", extra={
            "job_id": job_id,
            "duration_ms": duration * 1000,
            "status": "completed"
        })
        
        return {"job_id": job_id, "status": "completed"}
        
    except TransientError as e:
        # Let it retry
        logger.warning(f"Transient error for job {job_id}: {e}")
        raise
        
    except PermanentError as e:
        # Don't retry, mark as failed
        logger.error(f"Permanent error for job {job_id}: {e}")
        await update_job_status(ctx["db"], job_id, "failed", str(e))
        return {"job_id": job_id, "status": "failed", "error": str(e)}
```

### Pattern 2: API Endpoint with Validation

```python
@router.post("/api/jobs")
async def create_job(
    data: JobCreate,  # Pydantic model for validation
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),  # Auth
):
    """Create a new job with proper validation and error handling."""
    
    # 1. Authorization check
    if not current_user.can_create_jobs:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    
    # 2. Additional validation
    if not is_valid_audio_url(data.audio_url):
        raise HTTPException(status_code=400, detail="Invalid audio URL")
    
    # 3. Create job
    try:
        job = await create_job_in_db(db, data, current_user.id)
        await enqueue_job(job.id)  # Async task
        
        return {"job_id": job.id, "status": "pending"}
        
    except DatabaseError as e:
        logger.error(f"Failed to create job: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
```

### Pattern 3: Distributed System Transaction

```python
async def transfer_with_compensation(from_account, to_account, amount):
    """Transfer with compensation pattern for distributed transactions."""
    
    # Step 1: Reserve funds
    try:
        await reserve_funds(from_account, amount)
    except InsufficientFunds:
        return {"status": "failed", "reason": "insufficient_funds"}
    
    # Step 2: Transfer (may fail)
    try:
        await credit_account(to_account, amount)
    except Exception as e:
        # Compensation: Release reserved funds
        await release_funds(from_account, amount)
        raise
    
    # Step 3: Finalize
    await debit_account(from_account, amount)
    
    return {"status": "completed"}
```

## Observability Best Practices

### Structured Logging

```python
logger.info("Job processed", extra={
    "job_id": job_id,
    "duration_ms": duration * 1000,
    "status": "completed",
    "user_id": user_id,
    "correlation_id": correlation_id,  # Trace requests
})
```

### Metrics

```python
# Counter for requests
request_counter.inc({"endpoint": "/api/jobs", "method": "POST"})

# Histogram for duration
request_duration.observe(duration, {"endpoint": "/api/jobs"})

# Gauge for queue size
queue_size_gauge.set(queue.size())
```

### Health Checks

```python
@router.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)):
    """Health check with dependency verification."""
    try:
        # Check database
        await db.execute("SELECT 1")
        
        # Check queue
        queue_ok = await redis.ping()
        
        return {
            "status": "healthy",
            "database": "ok",
            "queue": "ok" if queue_ok else "degraded"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }, 503
```

## Integration with Project Documentation

**Always check project docs**:
- See CLAUDE.md for project-specific patterns
- Follow established conventions for error handling
- Use project testing patterns
- Match existing observability setup

**Example**: "Project uses arq for background jobs. See CLAUDE.md for worker patterns and retry configuration."

## When Feature is Complete

Feature is production-ready when:
- [ ] Core functionality works as specified
- [ ] Error cases handled gracefully
- [ ] Tests cover happy path and error cases
- [ ] Observability added (logs, metrics, traces)
- [ ] Security reviewed (input validation, auth, secrets)
- [ ] Documentation written (API docs, README updates)
- [ ] Deployed to staging and tested
- [ ] Monitoring dashboards configured
- [ ] Rollback plan documented
