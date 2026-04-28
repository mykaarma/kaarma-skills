---
name: reviewing-code
description: Perform thorough code reviews for production systems focusing on reliability, security, performance, and maintainability. Use after implementing features, before merging PRs, or when auditing existing code. Provides structured checklists for distributed systems, async patterns, error handling, and observability.
---

# Code Review for Production Systems

## When to Use This Skill

Use this skill for:
- **Pre-merge PR reviews**: Before merging code to main
- **Feature completion review**: After implementing new features
- **Bug fix review**: Ensuring fixes don't introduce new issues
- **Refactoring review**: Validating code improvements
- **Security audit**: Checking for security vulnerabilities
- **Performance audit**: Identifying bottlenecks and inefficiencies
- **Post-incident review**: Learning from production issues

## Code Review Workflow

Copy this checklist and track review progress:

```
Code Review Progress:
- [ ] Step 1: Understand the change (read description, linked issues)
- [ ] Step 2: Review architecture and design decisions
- [ ] Step 3: Check security (see security-checklist.md)
- [ ] Step 4: Review performance (see performance-checklist.md)
- [ ] Step 5: Check maintainability (see maintainability-checklist.md)
- [ ] Step 6: Verify tests are comprehensive
- [ ] Step 7: Check error handling and edge cases
- [ ] Step 8: Review observability (logging, metrics)
- [ ] Step 9: Verify documentation is updated
- [ ] Step 10: Approve or request changes
```

## Quick Review Checklist

### Critical Issues (Block Merge)

- [ ] **Security vulnerabilities**: SQL injection, XSS, secrets in code
- [ ] **Data loss risks**: Missing transactions, no rollback logic
- [ ] **Breaking changes**: API compatibility, database migrations
- [ ] **Resource leaks**: Unclosed connections, memory leaks
- [ ] **Incorrect logic**: Algorithm errors, off-by-one errors
- [ ] **Missing error handling**: Unhandled exceptions, no retry logic
- [ ] **No tests**: Core logic untested

### Important Issues (Should Fix)

- [ ] **Performance problems**: N+1 queries, missing indexes, blocking I/O
- [ ] **Poor error messages**: Unclear errors, missing context
- [ ] **Incomplete observability**: Missing logs, no metrics
- [ ] **Code duplication**: Violates DRY principle
- [ ] **Hard to maintain**: Complex logic, poor naming
- [ ] **Missing documentation**: Unclear purpose, no examples
- [ ] **Test gaps**: Edge cases untested, error paths untested

### Minor Issues (Nice to Have)

- [ ] **Naming**: Variables/functions could be clearer
- [ ] **Comments**: Missing "why" comments for complex logic
- [ ] **Code style**: Formatting inconsistencies
- [ ] **Type hints**: Missing or incomplete type annotations
- [ ] **Simplification opportunities**: Could be more concise

## Review by Category

### Security Review

See [reference/security-checklist.md](reference/security-checklist.md) for comprehensive security review.

**Quick security checks**:
- [ ] No secrets hard-coded or logged
- [ ] Input validated and sanitized
- [ ] SQL queries parametrized (no string concatenation)
- [ ] Authentication required where needed
- [ ] Authorization checked before operations
- [ ] Sensitive data encrypted
- [ ] Rate limiting on sensitive endpoints

### Performance Review

See [reference/performance-checklist.md](reference/performance-checklist.md) for detailed performance review.

**Quick performance checks**:
- [ ] No N+1 queries (use eager loading)
- [ ] Database indexes on frequently queried fields
- [ ] Async operations use `await` correctly
- [ ] Connection pooling configured
- [ ] Timeouts set on external calls
- [ ] Caching used where appropriate
- [ ] No blocking operations in async code

### Maintainability Review

See [reference/maintainability-checklist.md](reference/maintainability-checklist.md) for full maintainability review.

**Quick maintainability checks**:
- [ ] Clear, descriptive names
- [ ] Functions do one thing
- [ ] No deep nesting (max 3 levels)
- [ ] DRY: No code duplication
- [ ] SOLID principles followed
- [ ] Error handling consistent
- [ ] Logging structured and meaningful

## Distributed Systems Concerns

### Idempotency

**Check**: Can this operation be safely retried?

```python
# Bad: Not idempotent
async def process_payment(order_id, amount):
    await charge_card(amount)  # Charges multiple times on retry
    await mark_order_paid(order_id)

# Good: Idempotent with idempotency key
async def process_payment(order_id, amount, idempotency_key):
    if await is_already_processed(idempotency_key):
        return await get_payment_result(idempotency_key)
    
    result = await charge_card(amount, idempotency_key=idempotency_key)
    await mark_order_paid(order_id)
    return result
```

### Transaction Boundaries

**Check**: Are multi-step operations atomic?

```python
# Bad: No transaction
async def transfer_funds(from_account, to_account, amount):
    await debit(from_account, amount)  # If this succeeds...
    await credit(to_account, amount)    # ...but this fails, money is lost

# Good: Wrapped in transaction
async def transfer_funds(db, from_account, to_account, amount):
    async with db.begin():  # Atomic transaction
        await debit(from_account, amount)
        await credit(to_account, amount)
```

### Retry Safety

**Check**: What happens when this is retried?

```python
# Bad: Retry not safe
async def update_counter(counter_id):
    counter = await get_counter(counter_id)
    counter.value += 1  # Increments multiple times on retry
    await save_counter(counter)

# Good: Retry-safe with optimistic locking
async def update_counter(counter_id):
    while True:
        counter = await get_counter(counter_id)
        counter.value += 1
        try:
            await save_counter(counter)  # Fails if version changed
            break
        except VersionMismatch:
            continue  # Retry with fresh data
```

### Circuit Breaker Pattern

**Check**: Are external dependencies protected?

```python
# Good: Circuit breaker for external service
@circuit_breaker(failure_threshold=5, timeout=60)
async def call_external_api():
    response = await httpx.get("https://api.example.com/data")
    return response.json()
```

## Common Code Smells

### Async/Sync Mismatches

```python
# Bad: Blocking operation in async function
async def process_file(path):
    data = open(path).read()  # Blocks event loop
    return await process_data(data)

# Good: Use async file I/O
async def process_file(path):
    async with aiofiles.open(path) as f:
        data = await f.read()
    return await process_data(data)
```

### Missing Error Handling

```python
# Bad: No error handling
async def fetch_data():
    response = await httpx.get(url)
    return response.json()

# Good: Handle errors appropriately
async def fetch_data():
    try:
        response = await httpx.get(url, timeout=10.0)
        response.raise_for_status()
        return response.json()
    except httpx.TimeoutException:
        logger.warning("Request timed out")
        raise TransientError("Service timeout")
    except httpx.HTTPStatusError as e:
        if e.response.status_code >= 500:
            raise TransientError("Service error")
        raise PermanentError(f"Request failed: {e}")
```

### Resource Leaks

```python
# Bad: Connection not closed
async def query_database():
    conn = await asyncpg.connect(dsn)
    result = await conn.fetch("SELECT * FROM users")
    return result  # Connection never closed!

# Good: Use context manager
async def query_database():
    async with asyncpg.create_pool(dsn) as pool:
        async with pool.acquire() as conn:
            result = await conn.fetch("SELECT * FROM users")
            return result
```

## Testing Review

### Test Coverage

- [ ] **Happy path tested**: Main functionality works
- [ ] **Error cases tested**: Invalid inputs, exceptions
- [ ] **Edge cases tested**: Boundary conditions, empty inputs
- [ ] **Async tested correctly**: Uses pytest.mark.asyncio
- [ ] **Mocks appropriate**: External services mocked in unit tests
- [ ] **Integration tests**: Database and API operations tested
- [ ] **Test data managed**: Uses constants or fixtures

### Test Quality

```python
# Bad: Tests implementation details
def test_uses_quicksort():
    result = sort_function([3, 1, 2])
    assert result.algorithm == "quicksort"

# Good: Tests behavior
def test_sorts_correctly():
    result = sort_function([3, 1, 2])
    assert result == [1, 2, 3]
```

## Observability Review

### Logging

- [ ] **Structured logging**: JSON format with context
- [ ] **Correlation IDs**: Trace requests across services
- [ ] **Appropriate levels**: DEBUG, INFO, WARNING, ERROR
- [ ] **No sensitive data**: Passwords, tokens, PII redacted
- [ ] **Meaningful messages**: Include relevant context

```python
# Good: Structured logging
logger.info("Job processed", extra={
    "job_id": job_id,
    "duration_ms": duration * 1000,
    "status": "completed",
    "correlation_id": correlation_id
})
```

### Metrics

- [ ] **Key metrics instrumented**: Latency, error rate, throughput
- [ ] **Labels added**: Endpoint, method, status
- [ ] **Histograms for latency**: Not just averages
- [ ] **Counters for events**: Requests, errors, jobs processed

### Tracing

- [ ] **Distributed traces**: Span created for operations
- [ ] **Error tracking**: Errors captured with context

## Documentation Review

- [ ] **README updated**: If public API changed
- [ ] **API docs updated**: OpenAPI/Swagger specs
- [ ] **Code comments**: "Why" not "what"
- [ ] **CLAUDE.md updated**: If patterns changed
- [ ] **Migration guide**: If breaking changes
- [ ] **Runbook**: For operational procedures

## Integration with Project Documentation

**Always check project docs**:
- See CLAUDE.md for project-specific review guidelines
- Follow established code review practices
- Use project's definition of "blocking" issues
- Match project conventions for feedback

**Example**: "Project requires security review for all PR's touching authentication. See CLAUDE.md section 'Security Review Process'."

## Review Feedback Guidelines

### How to Give Feedback

**Blocking issues** (must fix):
```
❌ BLOCKING: This SQL query is vulnerable to injection.
Use parametrized queries instead:
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

**Important suggestions** (should fix):
```
⚠️ IMPORTANT: This could cause N+1 queries.
Consider eager loading:
query = query.options(joinedload(Job.user))
```

**Minor suggestions** (nice to have):
```
💡 SUGGESTION: Consider renaming `data` to `transcription_result` for clarity.
```

**Praise** (when appropriate):
```
✅ Nice: Good use of context manager for connection handling!
```

### Be Constructive

- Explain **why** something is an issue
- Suggest **how** to fix it
- Link to documentation or examples
- Ask questions if unclear ("Is this intentional?")
- Acknowledge good patterns

## When Review is Complete

Code is ready to merge when:
- [ ] No blocking security issues
- [ ] No data loss or corruption risks
- [ ] Tests are comprehensive
- [ ] Error handling is adequate
- [ ] Performance is acceptable
- [ ] Documentation is updated
- [ ] Observability is sufficient
- [ ] Code is maintainable

For comprehensive checklists, see reference files:
- [Security Checklist](reference/security-checklist.md)
- [Performance Checklist](reference/performance-checklist.md)
- [Maintainability Checklist](reference/maintainability-checklist.md)

---

## Industry Standards

### Google's Code Review Philosophy

> "The primary purpose of code review is to make sure that the overall code health of the codebase is improving over time."

**Key principles from [Google Engineering Practices](https://google.github.io/eng-practices/review/)**:

1. **Technical facts over opinions**: Data and engineering principles overrule personal preferences
2. **Style guide is authority**: On matters of style, defer to the style guide
3. **Enable progress**: Developers must be able to make progress; don't block unnecessarily
4. **Small changes**: Split large PRs into smaller, focused changes
5. **One business day max**: Respond to code reviews within one business day

### Review Focus Areas (Google)

From [Google Code Review Guide](https://google.github.io/eng-practices/review/reviewer/looking-for.html):

1. **Design**: Is the code well-designed and appropriate for the system?
2. **Functionality**: Does the code behave as intended?
3. **Complexity**: Could the code be simpler? Over-engineering?
4. **Tests**: Are tests correct, sensible, and useful?
5. **Naming**: Are names clear and descriptive?
6. **Comments**: Are comments clear and explain "why" not "what"?
7. **Style**: Does code follow the style guide?
8. **Documentation**: Is documentation updated?

### Microsoft Engineering Fundamentals

From [Microsoft Code Review Playbook](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/):

- Ask for unit, integration, or E2E tests appropriate for the change
- Be vigilant about **over-engineering**: Solve today's problem, not speculative future problems
- Tests should be added in the same PR as production code

---

## DORA Metrics (2024)

Use DORA metrics to measure software delivery performance. From [Google DORA 2024 Report](https://cloud.google.com/blog/products/devops-sre/announcing-the-2024-dora-report):

### Four Key Metrics

| Metric | Elite | High | Medium | Low |
|--------|-------|------|--------|-----|
| Deployment Frequency | Multiple/day | Weekly-Monthly | Monthly-Quarterly | Quarterly+ |
| Lead Time for Changes | <1 hour | 1 day-1 week | 1-6 months | 6+ months |
| Change Failure Rate | 0-15% | 16-30% | 31-45% | 46%+ |
| Recovery Time | <1 hour | <1 day | 1 day-1 week | 1 week+ |

### How This Affects Code Review

- **Deployment Frequency**: Small, focused PRs enable frequent deploys
- **Lead Time**: Fast review turnaround (< 1 business day) reduces lead time
- **Change Failure Rate**: Thorough reviews catch bugs before production
- **Recovery Time**: Good test coverage and rollback plans speed recovery

### 2024 Key Findings

- **Platform engineering**: Teams using internal developer platforms saw 10% performance boost
- **Psychological safety**: Strongest predictor of software delivery performance
- **AI tooling**: Boosts individual productivity but correlates with worsened delivery metrics (needs careful implementation)

---

## Structured Review Output

After completing the review, emit a JSON block so that `review-team` multi-agent orchestration and downstream MCP tools can aggregate results without parsing prose.

```json
{
  "verdict": "approve",
  "blocking_count": 0,
  "non_blocking_count": 2,
  "issues": [
    {
      "severity": "blocking",
      "file": "src/main/java/com/mykaarma/Service.java",
      "line": 42,
      "message": "SQL query uses string concatenation — vulnerable to injection. Use parameterized query.",
      "category": "security"
    },
    {
      "severity": "non-blocking",
      "file": "src/main/java/com/mykaarma/Processor.java",
      "line": 87,
      "message": "Missing timeout on external HTTP call — could block indefinitely under load.",
      "category": "performance"
    },
    {
      "severity": "suggestion",
      "file": "src/main/java/com/mykaarma/Handler.java",
      "line": 15,
      "message": "Rename `data` to `dealerPayload` for clarity.",
      "category": "style"
    }
  ]
}
```

Field notes:
- `verdict` — `"approve"` (no blocking issues), `"request-changes"` (one or more blocking issues), `"needs-discussion"` (architectural concerns requiring human judgment)
- `blocking_count` / `non_blocking_count` — counts of issues by severity (suggestions excluded from counts)
- `issues[].severity` — `"blocking"` (must fix before merge), `"non-blocking"` (should fix), `"suggestion"` (nice to have)
- `issues[].category` — `"security"`, `"performance"`, `"correctness"`, `"style"`
- `issues[].line` — omit or use `null` if the issue applies to the file as a whole

Emit this as the **last fenced code block** in the response. See `skills/structured-output/SKILL.md` for the standard envelope format.

---

## Google SRE Best Practices

From [Google SRE Book](https://sre.google/sre-book/service-best-practices/):

### Production Readiness Review

- **Monitoring**: If you can't monitor it, you can't be reliable
- **Rollouts**: Must be supervised and monitored; roll back first, diagnose after
- **Error budgets**: Define acceptable failure level (e.g., 99.9% = 43 min/month downtime)
- **Graceful degradation**: Services should produce reasonable results when overloaded
- **Blameless postmortems**: Focus on process and technology, not people
