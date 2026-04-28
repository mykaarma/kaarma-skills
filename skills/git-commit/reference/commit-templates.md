# Commit Message Templates

## Quick Reference

### Feature
```
feat(<scope>): <what you added>

<Why it was needed, how it works>
```

### Bug Fix
```
fix(<scope>): <what was broken>

<Root cause and how it was fixed>

Closes #<issue>
```

### Refactor
```
refactor(<scope>): <what was restructured>

<Why the refactor improves the code>
```

### Performance
```
perf(<scope>): <what was optimized>

<Before/after metrics if available>
```

### Documentation
```
docs(<scope>): <what was documented>
```

### Tests
```
test(<scope>): <what was tested>
```

### Build/Dependencies
```
build(deps): update <package> to <version>

<Why the update, any breaking changes>
```

### CI/CD
```
ci(<pipeline>): <what was changed>
```

### Chore
```
chore(<scope>): <maintenance task>
```

## Breaking Changes

Add `!` after type and include BREAKING CHANGE footer:

```
feat(api)!: change authentication to OAuth2

BREAKING CHANGE: API now requires OAuth2 tokens instead of API keys.
Migrate by:
1. Register your app at /settings/oauth
2. Replace X-API-Key header with Authorization: Bearer <token>
```

## Multi-line Message Examples

### Feature with Context
```
feat(worker): add retry logic with exponential backoff

Jobs now retry up to 3 times with delays of 60s, 180s, and 540s.
This prevents thundering herd on transient failures.

- Retry on: network errors, timeouts, 5xx responses
- Fail immediately on: validation errors, 4xx responses
```

### Complex Bug Fix
```
fix(api): prevent race condition in job status updates

Multiple workers could update the same job simultaneously,
causing status inconsistencies. Added optimistic locking
using version column.

Root cause: Missing transaction isolation
Solution: Added SELECT FOR UPDATE and version check

Closes #234
```

### Refactor with Rationale
```
refactor(db): extract repository pattern from services

Services were directly importing SQLAlchemy, making testing
difficult and coupling business logic to database implementation.

Changes:
- Created repository.py with CRUD operations
- Services now receive repository via dependency injection
- Added async context manager for session handling

This enables:
- Easier unit testing with mock repositories
- Future database swapping without service changes
```

## Scope Examples by Domain

### Web Application
- `auth`, `user`, `session`
- `api`, `routes`, `middleware`
- `db`, `models`, `migrations`
- `ui`, `components`, `pages`
- `styles`, `assets`

### Backend Service
- `worker`, `queue`, `scheduler`
- `api`, `grpc`, `graphql`
- `db`, `cache`, `storage`
- `config`, `logging`, `metrics`

### Infrastructure
- `docker`, `k8s`, `terraform`
- `ci`, `cd`, `deploy`
- `monitoring`, `alerting`

### Library/SDK
- `core`, `client`, `server`
- `types`, `utils`, `helpers`
- `examples`, `docs`

## Bad vs Good Examples

### Vague vs Specific
```
# Bad
fix: bug fix

# Good
fix(parser): handle unicode characters in input filenames
```

### No Context vs Explained
```
# Bad
refactor: cleanup

# Good
refactor(api): consolidate error handlers into middleware

Reduces code duplication across 12 route handlers.
```

### Past vs Imperative
```
# Bad
feat: added new feature

# Good
feat: add new feature
```

### Too Long vs Concise
```
# Bad
feat(user): add the ability for users to reset their password using their email

# Good
feat(user): add password reset via email
```
