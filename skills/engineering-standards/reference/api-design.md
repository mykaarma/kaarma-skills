# Reference: REST API Design

> Full rules: see `api-guidelines` skill.
> Industry standards: see [google-api-guidelines.md](google-api-guidelines.md) for Google AIP patterns.

## URL Patterns

```
# Collections (plural nouns, no verbs)
GET    /v1/gvms                          # List with pagination
POST   /v1/gvms                          # Create
GET    /v1/gvms/{gvmUuid}               # Get one
PATCH  /v1/gvms/{gvmUuid}               # Partial update
DELETE /v1/gvms/{gvmUuid}               # Soft delete

# Nested resources (max 3 levels deep)
GET    /v1/gvms/{gvmUuid}/workflows
POST   /v1/gvms/{gvmUuid}/workflows/{workflowUuid}/executions

# Complex filters → POST to /searches
POST   /v1/gvms/searches
POST   /v1/gvms/{gvmUuid}/executions/searches

# Bulk operations → POST with :bulk-verb suffix
POST   /v1/gvms:bulk-create
POST   /v1/gvms:bulk-update
POST   /v1/gvms:bulk-delete
```

## Quick Rules

| Rule | Correct | Incorrect |
|------|---------|-----------|
| No verbs in paths | `GET /v1/gvms/{uuid}` | `GET /v1/gvms/getGvm` |
| Plural collection names | `/v1/gvms` | `/v1/gvm` |
| Hyphens in multi-word paths | `/v1/gvm-types` | `/v1/gvmTypes`, `/v1/gvm_types` |
| All APIs versioned | `/v1/gvms` | `/gvms` |
| JSON responses only | `{"status": "OK"}` | `"OK"` |
| 4xx for client errors | `400` with error body | `200` with error body |
| Auth via cookies | `mkid` cookie, `withCredentials: true` | `?token=...` in query string |
| Pagination on all list endpoints | `?offset=0&limit=25` | unbounded list |

## Standard Response Shapes

**Success (collection):**
```json
{
  "gvms": [...],
  "totalCount": 42,
  "offset": 0,
  "limit": 25
}
```

**Success (single entity):**
```json
{
  "gvm": { "uuid": "...", "name": "..." }
}
```

**Error (any 4xx / 5xx):**
```json
{
  "errors": [
    {
      "errorCode": 100018,
      "errorTitle": "INVALID_AUTH",
      "errorMessage": "Authentication token is invalid or expired."
    }
  ],
  "warnings": []
}
```

- Never return `2xx` with error content in the body
- Always include `errors` and `warnings` arrays (empty `[]` when not applicable)
- `errorCode` is a stable integer — clients can branch on it without parsing strings

## Pagination

```
GET /v1/gvms?offset=0&limit=25&sort=created_at&order=desc&status=RUNNING
```

- `offset` + `limit` for cursor-free pagination
- Always include `totalCount` in the response
- Default limit: 25, Maximum limit: 100 (enforced server-side)
