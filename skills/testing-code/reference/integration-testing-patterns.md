# Integration Testing Patterns

## Database Testing

### Setup and Teardown

```python
@pytest.fixture
async def db():
    """Provide a clean database for each test."""
    # Create test database
    engine = create_async_engine("postgresql://localhost/test_db")
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        yield session
    
    # Cleanup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()
```

### Testing Transactions

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_transaction_rollback(db):
    """Test that errors trigger rollback."""
    try:
        async with db.begin():
            user = User(email="test@example.com")
            db.add(user)
            raise ValueError("Simulated error")
    except ValueError:
        pass
    
    # User should not exist due to rollback
    result = await db.execute(select(User))
    assert result.scalar_one_or_none() is None
```

### Testing Concurrent Updates

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_optimistic_locking(db):
    """Test version-based concurrency control."""
    # Create resource
    resource = Resource(value=100, version=1)
    db.add(resource)
    await db.commit()
    
    # Simulate concurrent updates
    resource1 = await db.get(Resource, resource.id)
    resource2 = await db.get(Resource, resource.id)
    
    # First update succeeds
    resource1.value = 150
    await db.commit()
    
    # Second update should fail (stale version)
    resource2.value = 200
    with pytest.raises(StaleDataError):
        await db.commit()
```

## API Testing

### Full Stack API Tests

```python
@pytest.fixture
async def app():
    """Provide test application."""
    from main import create_app
    app = create_app(testing=True)
    yield app

@pytest.fixture
async def async_client(app):
    """Provide async HTTP client."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.mark.integration
@pytest.mark.asyncio
async def test_create_job_endpoint(async_client, db):
    response = await async_client.post(
        "/api/jobs",
        json={"audio_url": "https://example.com/audio.mp3"}
    )
    assert response.status_code == 201
    data = response.json()
    assert "job_id" in data
```

### Authentication Testing

```python
@pytest.fixture
async def auth_headers(async_client):
    """Get authentication headers."""
    response = await async_client.post(
        "/api/login",
        json={"email": "test@example.com", "password": "password"}
    )
    token = response.json()["token"]
    return {"Authorization": f"Bearer {token}"}

@pytest.mark.integration
@pytest.mark.asyncio
async def test_protected_endpoint(async_client, auth_headers):
    response = await async_client.get("/api/protected", headers=auth_headers)
    assert response.status_code == 200
```

## Queue Testing

### Testing Job Enqueue and Processing

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_job_processing(redis, db):
    """Test full job lifecycle."""
    # Enqueue job
    job_data = {"audio_url": "https://example.com/test.mp3"}
    job_id = await enqueue_job(redis, job_data)
    
    # Verify job in database
    job = await get_job(db, job_id)
    assert job.status == "pending"
    
    # Process job (simulate worker)
    ctx = {"db": db, "redis": redis}
    await process_job(ctx, job_id)
    
    # Verify completion
    job = await get_job(db, job_id)
    assert job.status == "completed"
```

### Testing Retry Logic

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_job_retry_on_failure(redis, db):
    """Test that failed jobs retry."""
    job_id = await enqueue_job(redis, {"will_fail": True})
    
    # First attempt fails
    with pytest.raises(TransientError):
        await process_job({"db": db}, job_id)
    
    job = await get_job(db, job_id)
    assert job.attempts == 1
    assert job.status == "pending"  # Ready for retry
```

## External Service Testing

### Using Test Doubles

```python
@pytest.fixture
async def mock_external_service(aioresponses):
    """Mock external API."""
    aioresponses.post(
        "https://api.external.com/endpoint",
        payload={"result": "success"},
        status=200
    )

@pytest.mark.integration
@pytest.mark.asyncio
async def test_external_integration(async_client, mock_external_service):
    response = await async_client.post("/api/process")
    assert response.status_code == 200
```

### Testing Timeouts

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_external_call_timeout():
    """Test that timeouts are respected."""
    with pytest.raises(asyncio.TimeoutError):
        await call_external_api(timeout=0.1)
```

## File System Testing

```python
@pytest.fixture
def temp_dir(tmp_path):
    """Provide temporary directory."""
    yield tmp_path
    # Cleanup handled by pytest

@pytest.mark.integration
def test_file_processing(temp_dir):
    test_file = temp_dir / "test.txt"
    test_file.write_text("test content")
    
    result = process_file(test_file)
    assert result.success
```

## Testing with Docker Compose

```python
import pytest
import asyncpg

@pytest.fixture(scope="session")
async def database_url():
    """Start database in Docker."""
    # Assumes docker-compose.yml exists
    subprocess.run(["docker-compose", "up", "-d", "postgres"])
    
    # Wait for database to be ready
    for _ in range(30):
        try:
            conn = await asyncpg.connect("postgresql://localhost:5432/test")
            await conn.close()
            break
        except:
            await asyncio.sleep(0.5)
    
    yield "postgresql://localhost:5432/test"
    
    subprocess.run(["docker-compose", "down"])
```

## Performance Testing

```python
import time

@pytest.mark.integration
@pytest.mark.asyncio
async def test_api_performance(async_client):
    """Ensure API meets performance requirements."""
    start = time.time()
    response = await async_client.get("/api/endpoint")
    duration = time.time() - start
    
    assert response.status_code == 200
    assert duration < 0.1  # Must respond in < 100ms
```

## Integration Test Best Practices

- Use real databases (not mocks)
- Clean up between tests (fixtures)
- Test cross-component interactions
- Use Docker for external dependencies
- Mark with `@pytest.mark.integration`
- Run separately from unit tests
- Keep slower than unit tests, faster than E2E
