# Test Data Management

## Constants File Pattern

```python
# tests/constants.py
"""Centralized test constants and mock data."""

# API Configuration
TEST_API_BASE_URL = "http://localhost:8000"
TEST_VLLM_BASE_URL = "http://localhost:8001"

# Model Names
TEST_VOXTRAL_MODEL = "mistralai/Voxtral-Mini-3B-2507"
TEST_LLM_MODEL = "mistralai/Mistral-7B-Instruct-v0.3"

# Mock Responses
MOCK_TRANSCRIPTION_RESPONSE = {
    "text": "This is a test transcription.",
    "language": "en",
    "duration": 300.0
}

MOCK_LLM_RESPONSE = {
    "choices": [
        {
            "message": {
                "content": "This is a test summary."
            }
        }
    ]
}

# Test Data
TEST_USER_EMAIL = "test@example.com"
TEST_AUDIO_URL = "https://example.com/test.mp3"
```

Usage:
```python
from tests.constants import TEST_VOXTRAL_MODEL, MOCK_TRANSCRIPTION_RESPONSE

def test_transcribe():
    with aioresponses() as mocked:
        mocked.post(
            f"{TEST_VLLM_BASE_URL}/v1/audio/transcriptions",
            payload=MOCK_TRANSCRIPTION_RESPONSE
        )
        result = await transcribe(model=TEST_VOXTRAL_MODEL)
        assert result["text"] == MOCK_TRANSCRIPTION_RESPONSE["text"]
```

## Factory Pattern

```python
# tests/factories.py
import uuid
from datetime import datetime

def create_test_user(**overrides):
    """Create test user with defaults."""
    defaults = {
        "id": uuid.uuid4(),
        "email": f"test-{uuid.uuid4()}@example.com",
        "name": "Test User",
        "is_active": True,
        "created_at": datetime.utcnow(),
    }
    defaults.update(overrides)
    return User(**defaults)

def create_test_job(user_id=None, **overrides):
    """Create test job with defaults."""
    if user_id is None:
        user_id = create_test_user().id
    
    defaults = {
        "id": uuid.uuid4(),
        "user_id": user_id,
        "status": "pending",
        "data": {"audio_url": "https://example.com/test.mp3"},
        "created_at": datetime.utcnow(),
    }
    defaults.update(overrides)
    return Job(**defaults)
```

Usage:
```python
def test_job_processing():
    user = create_test_user(name="Custom Name")
    job = create_test_job(user_id=user.id, status="processing")
    
    result = process_job(job)
    assert result.success
```

## Pytest Fixtures

### Shared Fixtures

```python
# tests/conftest.py
import pytest

@pytest.fixture
def test_user():
    """Provide test user."""
    return create_test_user()

@pytest.fixture
async def db():
    """Provide database session."""
    engine = create_async_engine("postgresql://localhost/test_db")
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = sessionmaker(engine, class_=AsyncSession)
    
    async with async_session() as session:
        yield session
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()

@pytest.fixture
def mock_transcription_response():
    """Provide mock transcription response."""
    return {
        "text": "Test transcription",
        "language": "en",
        "duration": 120.0
    }
```

### Fixture Scopes

```python
# Function scope (default): New instance per test
@pytest.fixture
def function_fixture():
    return create_object()

# Class scope: Shared within test class
@pytest.fixture(scope="class")
def class_fixture():
    return create_expensive_object()

# Module scope: Shared within module
@pytest.fixture(scope="module")
def module_fixture():
    return create_very_expensive_object()

# Session scope: Shared across entire test session
@pytest.fixture(scope="session")
def session_fixture():
    return create_database_connection()
```

## Test Database Strategies

### Strategy 1: Fresh Database Per Test

```python
@pytest.fixture
async def db():
    """Fresh database for each test."""
    engine = create_async_engine("postgresql://localhost/test_db")
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = sessionmaker(engine, class_=AsyncSession)
    async with async_session() as session:
        yield session
    
    # Drop everything
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```

### Strategy 2: Transactions with Rollback

```python
@pytest.fixture
async def db(db_engine):
    """Use transaction that rolls back."""
    connection = await db_engine.connect()
    transaction = await connection.begin()
    session = AsyncSession(bind=connection)
    
    yield session
    
    await transaction.rollback()
    await connection.close()
```

### Strategy 3: Fixtures with Cleanup

```python
@pytest.fixture
async def test_job(db):
    """Create job and clean up after test."""
    job = Job(data={"audio_url": "https://example.com/test.mp3"})
    db.add(job)
    await db.commit()
    
    yield job
    
    # Cleanup
    await db.delete(job)
    await db.commit()
```

## Managing Test Files

```python
@pytest.fixture
def test_audio_file(tmp_path):
    """Provide temporary audio file."""
    file_path = tmp_path / "test_audio.mp3"
    file_path.write_bytes(b"fake audio data")
    yield file_path
    # tmp_path automatically cleaned up by pytest
```

## Parametrized Fixtures

```python
@pytest.fixture(params=["small", "medium", "large"])
def file_size(request):
    """Test with different file sizes."""
    sizes = {
        "small": 1024,
        "medium": 1024 * 1024,
        "large": 100 * 1024 * 1024
    }
    return sizes[request.param]

def test_file_processing(file_size):
    """Runs 3 times with different sizes."""
    result = process_file(size=file_size)
    assert result.success
```

## Best Practices

- **Use constants for configuration**: Centralize in `tests/constants.py`
- **Use factories for complex objects**: DRY principle for test data
- **Use fixtures for setup/teardown**: Automatic cleanup
- **Scope fixtures appropriately**: Balance speed vs isolation
- **Clean up after tests**: Don't leave test data
- **Make tests independent**: Order shouldn't matter
- **Use meaningful test data**: Not just "foo", "bar"
