# Unit Testing Patterns

## Async Testing

### AsyncMock vs MagicMock

```python
from unittest.mock import AsyncMock, MagicMock

# Use AsyncMock for async methods
mock_response.json = AsyncMock(return_value={"data": "value"})

# Use MagicMock for sync methods
mock_response.raise_for_status = MagicMock()

# Context managers need both __aenter__ and __aexit__
mock_post.return_value.__aenter__.return_value = mock_response
mock_post.return_value.__aexit__.return_value = None
```

### HTTP Client Mocking with aioresponses

```python
from aioresponses import aioresponses

@pytest.mark.asyncio
async def test_external_api_call():
    with aioresponses() as mocked:
        mocked.post(
            "https://api.example.com/endpoint",
            payload={"result": "success"},
            status=200
        )
        
        result = await call_api()
        assert result["result"] == "success"
```

### Database Session Mocking

```python
@pytest.fixture
def mock_session():
    session = AsyncMock()
    session.commit = AsyncMock()
    session.rollback = AsyncMock()
    session.close = AsyncMock()
    return session

@pytest.mark.asyncio
async def test_database_operation(mock_session):
    # Mock query result
    mock_result = AsyncMock()
    mock_result.scalar_one_or_none.return_value = User(id=1)
    mock_session.execute.return_value = mock_result
    
    user = await get_user(mock_session, 1)
    assert user.id == 1
```

## Handling Concurrency

### Testing Race Conditions

```python
@pytest.mark.asyncio
async def test_concurrent_updates():
    """Test that concurrent operations don't cause conflicts."""
    resource = SharedResource()
    
    # Run updates concurrently
    results = await asyncio.gather(
        resource.update(1),
        resource.update(2),
        resource.update(3),
    )
    
    # Verify all succeeded
    assert all(r.success for r in results)
```

### Testing Deadlocks

```python
@pytest.mark.asyncio
async def test_no_deadlock():
    """Ensure operations don't deadlock."""
    async def operation():
        async with lock_a:
            await asyncio.sleep(0.01)
            async with lock_b:
                return "done"
    
    # This should complete without hanging
    result = await asyncio.wait_for(operation(), timeout=1.0)
    assert result == "done"
```

## Mocking Time and Randomness

### Time Mocking

```python
from unittest.mock import patch
import datetime

@patch('module.datetime')
def test_time_dependent_function(mock_datetime):
    mock_datetime.now.return_value = datetime.datetime(2024, 1, 1, 12, 0, 0)
    
    result = function_that_checks_time()
    assert result.hour == 12
```

### Random Mocking

```python
from unittest.mock import patch

@patch('random.random')
def test_random_behavior(mock_random):
    mock_random.return_value = 0.5
    
    result = function_using_randomness()
    assert result == expected_with_0_5
```

## Testing Retry Logic

```python
@pytest.mark.asyncio
async def test_retries_on_transient_error():
    attempts = []
    
    async def flaky_operation():
        attempts.append(1)
        if len(attempts) < 3:
            raise ConnectionError("Transient")
        return "success"
    
    result = await retry_with_backoff(flaky_operation)
    assert result == "success"
    assert len(attempts) == 3
```

## Testing Error Handling

### Validation Errors

```python
def test_validates_email_format():
    with pytest.raises(ValidationError) as exc_info:
        create_user(email="invalid-email")
    
    assert "email" in str(exc_info.value).lower()
```

### Exception Chaining

```python
def test_wraps_exception():
    with pytest.raises(ServiceError) as exc_info:
        call_service()
    
    # Check original exception is preserved
    assert exc_info.value.__cause__.__class__ == ConnectionError
```

## Parametrized Tests

```python
@pytest.mark.parametrize("input,expected", [
    ("valid@email.com", True),
    ("invalid", False),
    ("", False),
    (None, False),
])
def test_email_validation(input, expected):
    result = is_valid_email(input)
    assert result == expected
```

## Testing Configuration

```python
def test_loads_config_from_env(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql://test")
    
    config = load_config()
    assert config.database_url == "postgresql://test"
```

## Anti-Patterns

### Don't Test Implementation Details

```python
# Bad: Tests internal structure
def test_uses_specific_algorithm():
    result = sort_data(data)
    assert result.used_quicksort  # Implementation detail

# Good: Tests behavior
def test_sorts_data_correctly():
    result = sort_data([3, 1, 2])
    assert result == [1, 2, 3]
```

### Don't Use Sleep in Tests

```python
# Bad: Brittle and slow
def test_async_operation():
    start_operation()
    time.sleep(1)  # Hope it finishes
    assert operation_completed()

# Good: Wait for condition
async def test_async_operation():
    await start_operation()
    result = await wait_for_completion()
    assert result.success
```
