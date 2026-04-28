# Reference: Launch Checklist

## Backend

- [ ] All endpoints versioned (`/v1/...`)
- [ ] Global error handler registered — consistent `{errors, warnings}` shape on all errors
- [ ] `ErrorCodes` enum defined with 100xxx (client) and 200xxx (server) ranges
- [ ] Auth middleware validates `mkid` cookie on every route (opt-out, not opt-in)
- [ ] User fetched from Kmanage API using `userUuid` and cached on request context
- [ ] Soft delete (`is_valid`) on all primary entities
- [ ] All list endpoints paginated with enforced max limit
- [ ] No SQL/ORM queries outside the repository layer
- [ ] No secrets in source code — env vars or secrets manager only
- [ ] Structured JSON logging with correlation ID
- [ ] `GET /health` and `GET /metrics` endpoints exposed
- [ ] Retries + DLQ configured for all message consumers
- [ ] DB connection pool configured explicitly
- [ ] Indexes on UUID columns and all `WHERE` clause fields
- [ ] 80%+ unit test coverage on service layer
- [ ] Integration tests running against real DB in CI
- [ ] Dealer context extracted from URL path via middleware (not parsed in each controller)
- [ ] Dealer lookup cached (not re-queried on every request)
- [ ] Read replica used for high-volume list/search queries

## Frontend (standalone app or micro-frontend)

- [ ] `mkid` cookie set on app startup via `CookieService`
- [ ] All HTTP calls use `withCredentials: true` — no Authorization header
- [ ] HTTP error interceptor logs and re-throws errors
- [ ] Loader/spinner shows on requests (skippable for background calls)
- [ ] All API calls return typed responses — no `any`
- [ ] All subscriptions / effects cleaned up on unmount
- [ ] `FetchStatus` enum used for async state (not bare boolean flags)
- [ ] Every data fetch has `catch`/`error` handler with user-facing message
- [ ] Status enums used for all status comparisons — no raw string literals
- [ ] API base URL from `environment.apiUrl` — never hardcoded
- [ ] OpenTelemetry / tracing configured in HTTP client
- [ ] ESLint + Prettier configured and passing
