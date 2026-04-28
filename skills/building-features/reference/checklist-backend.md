# Backend Implementation Checklist

## API Design

- [ ] **REST principles**: Use appropriate HTTP methods (GET, POST, PUT, DELETE)
- [ ] **Status codes**: Return correct codes (200, 201, 400, 401, 403, 404, 500)
- [ ] **Versioning**: Include API version in URL or header
- [ ] **Content negotiation**: Support JSON, handle content-type headers
- [ ] **Pagination**: Limit response sizes, provide cursor/offset pagination
- [ ] **Filtering and sorting**: Allow clients to filter and sort results
- [ ] **Rate limiting**: Prevent abuse with rate limits per user/IP
- [ ] **Deprecation**: Mark old endpoints as deprecated before removal

## Data Models

- [ ] **Schema validation**: Use Pydantic, Marshmallow, or similar
- [ ] **Type hints**: Add type annotations throughout
- [ ] **Nullable fields**: Explicitly mark optional fields
- [ ] **Default values**: Provide sensible defaults
- [ ] **Relationships**: Define foreign keys and relationships correctly
- [ ] **Indexes**: Add database indexes for frequently queried fields
- [ ] **Migrations**: Create database migrations for schema changes
- [ ] **Constraints**: Add unique constraints, check constraints where needed

## Error Handling

- [ ] **Validation errors**: Return 400 with clear field-level errors
- [ ] **Authentication errors**: Return 401 with helpful message
- [ ] **Authorization errors**: Return 403 when user lacks permission
- [ ] **Not found errors**: Return 404 for missing resources
- [ ] **Server errors**: Return 500, log details, don't expose internals
- [ ] **Retry logic**: Implement exponential backoff for transient failures
- [ ] **Circuit breakers**: Prevent cascading failures to dependencies
- [ ] **Timeout handling**: Set timeouts for all external calls

## Async Patterns

- [ ] **Connection pooling**: Use connection pools for database and Redis
- [ ] **Async/await**: Use async/await correctly, avoid blocking operations
- [ ] **Concurrency limits**: Limit concurrent operations to prevent resource exhaustion
- [ ] **Task cancellation**: Handle task cancellation gracefully
- [ ] **Context managers**: Use `async with` for resource management
- [ ] **Error propagation**: Ensure errors bubble up correctly in async code
- [ ] **Deadlock prevention**: Avoid circular awaits and lock ordering issues

## Database Operations

- [ ] **Transactions**: Wrap multi-step operations in transactions
- [ ] **Isolation levels**: Choose appropriate isolation level
- [ ] **Optimistic locking**: Use version columns for concurrent updates
- [ ] **N+1 queries**: Use eager loading, joins, or batch queries
- [ ] **Query timeouts**: Set timeouts to prevent long-running queries
- [ ] **Connection management**: Always close connections (use context managers)
- [ ] **Bulk operations**: Use bulk inserts/updates for large datasets
- [ ] **Soft deletes**: Consider soft deletes for audit trails

## Queue and Worker Patterns

- [ ] **Idempotency**: Jobs should be safe to retry (idempotency keys)
- [ ] **Job data**: Store minimal data in queue, fetch from database
- [ ] **Retry policy**: Configure max retries and backoff
- [ ] **Dead letter queue**: Handle permanently failed jobs
- [ ] **Job timeout**: Set per-job timeouts
- [ ] **Graceful shutdown**: Handle SIGTERM for clean worker shutdown
- [ ] **Job priority**: Use priority queues if needed
- [ ] **Progress tracking**: Update job status in database

## Performance

- [ ] **Caching**: Cache expensive operations (Redis, in-memory)
- [ ] **Cache invalidation**: Invalidate cache when data changes
- [ ] **Database indexes**: Add indexes for WHERE, JOIN, ORDER BY clauses
- [ ] **Lazy loading**: Don't fetch data until needed
- [ ] **Batch processing**: Process multiple items together when possible
- [ ] **Async where possible**: Use async I/O for network and disk operations
- [ ] **Connection reuse**: Reuse HTTP connections (session pooling)
- [ ] **Resource limits**: Set memory and CPU limits

## Security

- [ ] **Input validation**: Validate all inputs (schema validation)
- [ ] **SQL injection**: Use parametrized queries, never string concatenation
- [ ] **Authentication**: Require auth for protected endpoints
- [ ] **Authorization**: Check permissions before operations
- [ ] **Secrets management**: Use environment variables or secret managers
- [ ] **HTTPS only**: Enforce HTTPS in production
- [ ] **CORS**: Configure CORS appropriately
- [ ] **Content Security Policy**: Add CSP headers
- [ ] **Rate limiting**: Prevent brute force and DoS attacks
- [ ] **Audit logging**: Log security-relevant events

See [security-considerations.md](security-considerations.md) for comprehensive security guidance.
