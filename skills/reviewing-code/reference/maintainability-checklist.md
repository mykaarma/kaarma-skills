# Maintainability Review Checklist

## Code Clarity

### Naming

- [ ] **Descriptive names**: Variables/functions clearly describe purpose
- [ ] **Consistent naming**: Follow project conventions
- [ ] **Avoid abbreviations**: Use full words (except common ones like `id`, `url`)
- [ ] **Boolean names**: Use `is_`, `has_`, `can_` prefixes
- [ ] **Function names**: Verbs for actions, nouns for getters

```python
# ❌ BAD: Unclear names
def proc(d):
    r = []
    for i in d:
        if i[0] > 100:
            r.append(i[1])
    return r

# ✅ GOOD: Clear names
def get_high_value_transactions(transactions):
    high_value = []
    for transaction in transactions:
        if transaction.amount > 100:
            high_value.append(transaction.id)
    return high_value
```

### Function Size

- [ ] **Small functions**: < 50 lines per function
- [ ] **Single responsibility**: Each function does one thing
- [ ] **Few parameters**: < 4 parameters (use objects for more)
- [ ] **One level of abstraction**: Don't mix high and low-level code

```python
# ❌ BAD: Function does too much
def process_order(order_id, user_id, items, payment_info, shipping_address):
    # Validate order
    # Calculate total
    # Process payment
    # Update inventory
    # Send confirmation email
    # Log transaction
    ...  # 200 lines

# ✅ GOOD: Broken into smaller functions
def process_order(order_id):
    order = get_order(order_id)
    validate_order(order)
    total = calculate_total(order.items)
    process_payment(order.payment_info, total)
    update_inventory(order.items)
    send_confirmation(order.user_id, order)
    log_transaction(order_id)
```

### Complexity

- [ ] **Low cyclomatic complexity**: < 10 per function
- [ ] **Shallow nesting**: Max 3 levels deep
- [ ] **Early returns**: Use guard clauses to reduce nesting
- [ ] **Extract complex conditions**: Give them names

```python
# ❌ BAD: Deep nesting
def process(data):
    if data:
        if data.is_valid:
            if data.user:
                if data.user.is_active:
                    return do_processing(data)
    return None

# ✅ GOOD: Guard clauses
def process(data):
    if not data:
        return None
    if not data.is_valid:
        return None
    if not data.user or not data.user.is_active:
        return None
    
    return do_processing(data)

# ✅ BETTER: Extract condition
def can_process(data):
    return (data and data.is_valid and 
            data.user and data.user.is_active)

def process(data):
    if not can_process(data):
        return None
    return do_processing(data)
```

## Code Organization

### DRY (Don't Repeat Yourself)

- [ ] **No code duplication**: Extract repeated code into functions
- [ ] **Shared utilities**: Common operations in utils module
- [ ] **Constants for magic numbers**: Named constants, not literals

```python
# ❌ BAD: Repeated code
def send_welcome_email(user):
    subject = "Welcome!"
    body = f"Hello {user.name}, welcome to our service!"
    send_email(user.email, subject, body, from_email="noreply@example.com")

def send_password_reset(user):
    subject = "Password Reset"
    body = f"Hello {user.name}, click here to reset your password."
    send_email(user.email, subject, body, from_email="noreply@example.com")

# ✅ GOOD: Extracted common logic
DEFAULT_FROM_EMAIL = "noreply@example.com"

def send_user_email(user, subject, body):
    send_email(user.email, subject, body, from_email=DEFAULT_FROM_EMAIL)

def send_welcome_email(user):
    send_user_email(user, "Welcome!", 
                    f"Hello {user.name}, welcome to our service!")

def send_password_reset(user):
    send_user_email(user, "Password Reset",
                    f"Hello {user.name}, click here to reset your password.")
```

### SOLID Principles

- [ ] **Single Responsibility**: Class/function has one reason to change
- [ ] **Open/Closed**: Open for extension, closed for modification
- [ ] **Liskov Substitution**: Subtypes can replace parent types
- [ ] **Interface Segregation**: Many specific interfaces > one general
- [ ] **Dependency Inversion**: Depend on abstractions, not concretions

### Module Organization

- [ ] **Logical grouping**: Related code together
- [ ] **Clear imports**: Imports at top, organized
- [ ] **No circular dependencies**: Modules don't depend on each other circularly
- [ ] **Public API clear**: What's meant to be used is obvious

## Error Handling

### Consistent Error Handling

- [ ] **Specific exceptions**: Don't catch bare `Exception`
- [ ] **Appropriate error types**: Use or create specific exception types
- [ ] **Error context**: Include relevant information in errors
- [ ] **Don't swallow errors**: Log or re-raise exceptions
- [ ] **Fail fast**: Detect errors early, fail loudly

```python
# ❌ BAD: Swallows all errors
try:
    result = risky_operation()
except:
    pass  # What went wrong? We'll never know!

# ✅ GOOD: Specific error handling with context
try:
    result = risky_operation()
except ValueError as e:
    logger.error(f"Invalid input to risky_operation: {e}")
    raise
except ConnectionError as e:
    logger.warning(f"Connection failed, will retry: {e}")
    raise RetryableError(f"Connection failed: {e}") from e
```

### Error Messages

- [ ] **Clear messages**: Explain what went wrong
- [ ] **Actionable**: Tell user what to do
- [ ] **Include context**: Relevant variables/state
- [ ] **No sensitive data**: Don't leak secrets in errors

```python
# ❌ BAD: Unclear error
raise ValueError("Invalid input")

# ✅ GOOD: Clear, actionable error
raise ValueError(
    f"Audio URL must be HTTPS. Got: {audio_url}. "
    "Please provide a valid HTTPS URL."
)
```

## Documentation

### Code Comments

- [ ] **"Why" not "what"**: Explain reasoning, not obvious code
- [ ] **Complex logic**: Comment non-obvious algorithms
- [ ] **Workarounds**: Explain why hack is needed
- [ ] **TODOs**: With context and owner

```python
# ❌ BAD: States the obvious
# Increment counter by 1
counter += 1

# ✅ GOOD: Explains why
# Retry with exponential backoff to avoid thundering herd problem
# when service recovers from outage
await asyncio.sleep(2 ** attempt)

# ✅ GOOD: Explains workaround
# WORKAROUND: API sometimes returns 200 with error in body.
# Check body for error field until API is fixed (ticket #1234)
if response.status_code == 200 and "error" in response.json():
    raise APIError(response.json()["error"])
```

### Docstrings

- [ ] **All public functions**: Have docstrings
- [ ] **Parameters documented**: Types and meaning
- [ ] **Return value documented**: What's returned
- [ ] **Exceptions documented**: What can be raised

```python
async def process_transcription_job(
    job_id: int,
    db: AsyncSession,
    vllm_client: VLLMClient
) -> dict[str, any]:
    """
    Process transcription job asynchronously.
    
    Args:
        job_id: Database ID of job to process
        db: Database session for queries
        vllm_client: Client for transcription API
    
    Returns:
        Dict with keys:
            - job_id: The processed job ID
            - status: "completed" or "failed"
            - result: Transcription result if successful
            - error: Error message if failed
    
    Raises:
        JobNotFoundError: If job_id doesn't exist
        TransientError: For retryable failures (network, timeout)
        PermanentError: For non-retryable failures (invalid input)
    """
    ...
```

## Testing

### Testability

- [ ] **Pure functions**: Functions without side effects are easier to test
- [ ] **Dependency injection**: Pass dependencies, don't create them
- [ ] **Small functions**: Easier to test
- [ ] **Seams for testing**: Interfaces for mocking

```python
# ❌ BAD: Hard to test (creates dependencies internally)
def process_job(job_id):
    db = create_db_connection()  # Hard-coded
    job = db.get_job(job_id)
    # ...

# ✅ GOOD: Easy to test (dependencies injected)
def process_job(job_id, db):
    job = db.get_job(job_id)
    # ...

# In tests, pass mock db
def test_process_job():
    mock_db = MagicMock()
    mock_db.get_job.return_value = test_job
    result = process_job(123, mock_db)
    assert result.success
```

### Test Coverage

- [ ] **Core logic tested**: Business logic has tests
- [ ] **Edge cases tested**: Boundary conditions covered
- [ ] **Error paths tested**: Exception handling tested
- [ ] **Integration points tested**: Database, API, queue tested

## Observability

### Logging

- [ ] **Structured logging**: JSON format with context
- [ ] **Appropriate levels**: DEBUG, INFO, WARNING, ERROR used correctly
- [ ] **Correlation IDs**: Trace requests across services
- [ ] **No sensitive data**: PII, passwords, tokens redacted

```python
# ✅ GOOD: Structured logging with context
logger.info("Job completed", extra={
    "job_id": job_id,
    "user_id": user_id,
    "duration_ms": duration * 1000,
    "status": "completed",
    "correlation_id": request_id
})
```

### Metrics

- [ ] **Key metrics instrumented**: Latency, errors, throughput
- [ ] **Business metrics**: Jobs processed, users signed up, etc.
- [ ] **Labels for dimensions**: Endpoint, method, status code

## Anti-Patterns to Avoid

### God Objects

```python
# ❌ BAD: Class does everything
class JobManager:
    def create_job(self): ...
    def process_job(self): ...
    def send_email(self): ...
    def charge_payment(self): ...
    def generate_report(self): ...
    # 50 more methods...

# ✅ GOOD: Single responsibility
class JobService:
    def create_job(self): ...
    def process_job(self): ...

class EmailService:
    def send_job_notification(self): ...

class PaymentService:
    def charge_for_job(self): ...
```

### Magic Numbers

```python
# ❌ BAD: Magic numbers
if user.age > 18:
    ...
await asyncio.sleep(300)

# ✅ GOOD: Named constants
ADULT_AGE = 18
CACHE_TTL_SECONDS = 300

if user.age > ADULT_AGE:
    ...
await asyncio.sleep(CACHE_TTL_SECONDS)
```

## Maintainability Checklist

Code is maintainable when:
- [ ] Names are clear and consistent
- [ ] Functions are small and focused
- [ ] Complexity is low (< 10 cyclomatic complexity)
- [ ] No code duplication
- [ ] Errors handled consistently
- [ ] Tests are comprehensive
- [ ] Logging is structured and meaningful
- [ ] Documentation is clear and up-to-date
