---
name: testing-code
description: Write comprehensive tests for production systems including unit, integration, and E2E tests. Use when implementing new features, fixing bugs, or improving test coverage. Covers async testing, mocking strategies, test organization, and CI/CD integration for high-reliability systems.
---

# Testing Production Systems

## When to Use This Skill

Use this skill when:
- **Implementing features**: Write tests alongside new code
- **Fixing bugs**: Write failing test first, then fix
- **Refactoring**: Ensure tests pass before and after
- **Improving coverage**: Identify and fill coverage gaps
- **Code review**: Verify tests are comprehensive

## Testing Pyramid (Martin Fowler)

```
        /\
       /E2E\        Few, slow, expensive (10%)
      /------\
     /  Integ \     Some, medium speed (20%)
    /----------\
   /    Unit    \   Many, fast, cheap (70%)
  /--------------\
```

**Golden rule**: Write tests with different granularity; the higher level, the fewer tests.

## Quick Reference

| Type | Speed | What's Real | What's Mocked |
|------|-------|-------------|---------------|
| Unit | <10ms | Business logic | DB, APIs, I/O |
| Integration | <1s | DB, Queue, API | External services |
| E2E | <30s | Everything | Nothing |

## Test Organization

```
tests/
├── unit/                # Fast, isolated tests
├── integration/         # Tests with real dependencies  
├── e2e/                 # End-to-end workflows (minimal)
├── conftest.py          # Shared fixtures
└── constants.py         # Test data constants
```

### Naming Convention

```python
def test_<what>_<scenario>():
    """Descriptive docstring."""
    pass

# Examples
def test_create_job_success():
def test_create_job_invalid_url_raises_error():
def test_process_job_retries_on_transient_failure():
```

## Core Patterns

### AAA Pattern: Arrange, Act, Assert

```python
def test_create_job():
    # Arrange
    job_data = {"audio_url": "https://example.com/audio.mp3"}
    
    # Act
    job = create_job(job_data, user_id=1)
    
    # Assert
    assert job.status == "pending"
```

### Async Testing

```python
import pytest

@pytest.mark.asyncio
async def test_async_operation():
    result = await my_async_function()
    assert result.success
```

### HTTP Mocking (aioresponses)

```python
from aioresponses import aioresponses

@pytest.mark.asyncio
async def test_external_api():
    with aioresponses() as mocked:
        mocked.post("http://api.example.com/endpoint", 
                    payload={"result": "success"}, status=200)
        
        result = await call_external_api()
        assert result["result"] == "success"
```

### Exception Testing

```python
def test_invalid_input_raises_error():
    with pytest.raises(ValidationError) as exc_info:
        process_data(invalid_data)
    assert "audio_url" in str(exc_info.value)
```

## Test Data Management

### Use Constants (Single Source of Truth)

```python
# tests/constants.py
TEST_API_BASE_URL = "http://localhost:8000"
MOCK_TRANSCRIPTION_RESPONSE = {"text": "Test transcription"}

# tests/test_api.py
from tests.constants import MOCK_TRANSCRIPTION_RESPONSE
```

### Factory Functions

```python
def create_test_user(**overrides):
    defaults = {"email": f"test-{uuid4()}@example.com", "name": "Test"}
    defaults.update(overrides)
    return User(**defaults)
```

### Fixtures

```python
@pytest.fixture
def test_user():
    return create_test_user()

@pytest.fixture
async def db():
    async with get_test_session() as session:
        yield session
```

## What to Test

### Unit Tests (70%)
- Business logic functions
- Validation and parsing
- Error handling paths
- Edge cases and boundaries

### Integration Tests (20%)
- Database CRUD operations
- API endpoints (full stack)
- Queue enqueue/process cycles
- Configuration loading

### E2E Tests (10%)
- Critical user journeys only
- Keep minimal (slow and brittle)

## Coverage Guidelines

- **Target**: 80-90% (not 100%)
- **Focus on**: Business logic, error handling, edge cases
- **Skip**: Boilerplate, getters/setters, framework code

```bash
pytest --cov=src --cov-report=html
```

## Common Anti-Patterns

### Don't Test Implementation Details

```python
# Bad: Tests internal structure
assert result.used_quicksort == True

# Good: Tests behavior
assert result == [1, 2, 3]
```

### Don't Use Sleep

```python
# Bad: Brittle timing
time.sleep(1)
assert completed

# Good: Wait for condition
await asyncio.wait_for(operation(), timeout=5.0)
```

### Don't Swallow Errors in Tests

```python
# Bad: Hides failures
try:
    result = operation()
except:
    pass

# Good: Let it fail
result = operation()  # Will fail visibly if broken
```

## Integration with Project Docs

**Always check project docs first**:
- See CLAUDE.md for project-specific testing patterns
- Use established fixtures from conftest.py
- Import constants from tests/constants.py
- Follow project mocking conventions

## Quick Commands

```bash
pytest tests/unit/              # Unit tests only
pytest tests/integration/       # Integration tests
pytest -v -k "test_name"        # Specific test
pytest --cov=src               # With coverage
```

## Testing Checklist

- [ ] Unit tests cover business logic
- [ ] Error conditions tested
- [ ] Async uses @pytest.mark.asyncio
- [ ] Mocks used appropriately
- [ ] Test data uses constants/fixtures
- [ ] Tests are deterministic (not flaky)
- [ ] Coverage adequate (80%+)

## Deep Dive References

For detailed patterns, see:
- [Unit Testing Patterns](reference/unit-testing-patterns.md): AsyncMock vs MagicMock, concurrency testing
- [Integration Testing Patterns](reference/integration-testing-patterns.md): Database, API, queue testing
- [Test Data Management](reference/test-data-management.md): Factories, fixtures, cleanup strategies
