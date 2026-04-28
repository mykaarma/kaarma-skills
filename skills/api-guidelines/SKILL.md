---
name: api-guidelines
description: Design and review REST APIs following myKaarma organization standards. Use when designing new API endpoints, reviewing API changes, or ensuring API consistency across services. Covers URL patterns, HTTP methods, status codes, versioning, naming conventions, pagination, and bulk operations.
---

# REST API Design Guidelines

## When to Use This Skill

Use this skill when:
- **Designing new API endpoints**: Ensuring correct URL patterns, methods, and response formats
- **Reviewing API changes**: Validating endpoints follow organization standards
- **Building CRUD operations**: Getting the right HTTP methods and URL structures
- **Implementing bulk operations**: Using correct `:bulk-verb` patterns
- **Adding filtering/pagination**: Structuring query parameters correctly
- **Preparing for API review**: Checking compliance before submitting for team review

**Important**: API review should be carried out for all major endpoint and API-related changes, not just for services behind Kong.

## API Design Checklist

```
API Design Progress:
- [ ] Step 1: Request/response format is JSON
- [ ] Step 2: Correct HTTP methods used (no verbs in URLs)
- [ ] Step 3: Collection URLs use plural nouns
- [ ] Step 4: Proper HTTP status codes returned
- [ ] Step 5: Error details included in response body
- [ ] Step 6: API versioning applied
- [ ] Step 7: Filtering, sorting, and pagination supported
- [ ] Step 8: Consistent field naming across endpoints
- [ ] Step 9: API documentation written (Swagger)
- [ ] Step 10: Reviewed by a potential API consumer
```

## Ground Rules

### 1. JSON Request and Response Format

All API requests and responses must use JSON format.

- Do not return raw strings as API responses
- XML format support in frameworks is decreasing

```java
// Bad: returning raw string
@GetMapping("/status")
public String getStatus() {
    return "OK";
}

// Good: returning JSON
@GetMapping("/status")
public ResponseEntity<Map<String, String>> getStatus() {
    return ResponseEntity.ok(Map.of("status", "OK"));
}
```

### 2. Standard HTTP Status Codes

Use correct HTTP status code ranges consistently:

| Range | Meaning | Examples |
|-------|---------|----------|
| 100-199 | Informational | 102 - Resource being processed |
| 200-299 | Success | 200 OK, 201 Created, 204 No Content |
| 300-399 | Redirects | 301 Moved Permanently |
| 400-499 | Client errors | 400 Bad Request, 404 Not Found, 403 Forbidden |
| 500-599 | Server errors | 500 Internal Server Error |

**Critical rules**:
- Invalid request data must always result in **4xx**, never 5xx
- Never return **2xx with error details** in the body for invalid requests
- **4xx** responses must include information about what data was invalid
- **5xx** responses must include as much diagnostic information as available

### 3. Error Details in Response Body

Always return structured error details to make debugging easier for API consumers.

```json
{
    "error": {
        "code": "INVALID_DEALER_UUID",
        "message": "The provided dealer UUID is not valid",
        "details": [
            {
                "field": "dealerUUID",
                "reason": "UUID format is incorrect"
            }
        ]
    }
}
```

Create standard error codes for your API (reference: kmanage-api error codes).

### 4. No Verbs in URLs

HTTP methods already represent the action. Do not duplicate verbs in the URL path.

```
# Bad - verbs in URLs
GET  /dealers/{dealerUUID}/getDepartments
POST /dealers/create
POST /dealers/save
PATCH /dealers/update

# Good - nouns only
GET   /dealers/{dealerUUID}/departments
POST  /dealers
PATCH /dealers/{dealerUUID}
GET   /dealers/{dealerUUID}
```

### 5. Collection URL Patterns

See [reference/collection-url-patterns.md](reference/collection-url-patterns.md) for comprehensive collection URL guidance.

**Quick rules**:

#### 5.1 Plural Nouns for Collections

Collections must be represented with plural nouns.

```
GET  /dealers                         # List dealers
POST /dealers                         # Create a dealer
GET  /dealers/{dealerUUID}            # Get a dealer
PUT  /dealers/{dealerUUID}            # Replace a dealer
PATCH /dealers/{dealerUUID}           # Update dealer properties
DELETE /dealers/{dealerUUID}          # Delete a dealer
```

#### 5.2 Hyphenated Terms in URLs

Use hyphens to separate multi-word terms in URLs.

```
# Good
/dealer-associates/...
/communication-preferences/...

# Bad
/dealerAssociates/...
/communication_preferences/...
```

#### 5.3 Resource Nesting

Nest related resources under their parent, but avoid nesting more than 3 levels deep.

```
# Good - clear nesting
GET /dealers/{dealerUUID}/departments
GET /customers/{customerUUID}/vehicles/{vehicleUUID}

# Bad - too deeply nested
GET /dealers/{dealerUUID}/departments/{deptUUID}/advisors/{advisorUUID}/schedules/{scheduleUUID}
```

#### 5.4 Properties vs Collections

Use singular nouns for properties (one-to-one relationships) and plural for collections (one-to-many).

```
# Property (1-to-1): a trip has exactly one receipt
GET /trips/{tripUUID}/receipt

# Collection (1-to-many): a dealer has many departments
GET /dealers/{dealerUUID}/departments
```

#### 5.5 Bulk Operations

For bulk operations on multiple resources, use custom methods with `:bulk-verb` syntax. HTTP method must be **POST**.

```
POST /dealers:bulk-create
{
    "requests": [{ "name": "Audi of Long Beach", ... }]
}

POST /dealers:bulk-update
{
    "requests": [{ "uuid": "uuid_123", "name": "MB of Silver Lake", ... }]
}

POST /dealers:bulk-patch
{
    "requests": [{ "uuid": "uuid_456", "name": "MB of Long Beach" }]
}

POST /dealers:bulk-delete
{
    "uuids": ["uuid_789", "uuid_101112"]
}

POST /adp-make-models:bulk-save
{
    "adpMakeModelDTOList": [{ "makeName": "Audi", "modelName": "Q3", ... }]
}
```

Use `bulk-save` for upsert operations (update if exists, create if not).

#### 5.6 Bulk Operations in Nested Collections

For bulk operations across nested collections, use collection names directly without identifiers.

```
# Bulk update courses across multiple users
POST /users/courses:bulk-update
```

**Authentication note**: If dealerUuids are provided in the request body, authentication is done on those dealerUuids. If a dealerUuid is also in the path, the union of both is used for authentication.

### 6. API Versioning

Always version your APIs to prevent breaking changes for existing consumers.

```
/customer/v1/...
/customer/v2/...
```

Versioning gives clients time to migrate when backward-incompatible changes are introduced.

### 7. API Documentation

Comprehensive documentation must include:
- All endpoints with compatible HTTP methods
- Request/response schemas with examples
- Parameter options (query, path, header)
- Clearly marked **mandatory** vs **optional** parameters
- Error codes and their meanings

**Tools**: Use Swagger/OpenAPI for API documentation.

**Review**: Get documentation reviewed by a potential API consumer (someone outside your team within the organization).

### 8. Filtering, Sorting, and Pagination

Use query parameters for filtering, sorting, and pagination to handle large datasets.

```
# Pagination
GET /customers/v2/customers/{customerUUID}/vehicles?offset=20&limit=10

# Filtering
GET /messages?tags=upset

# Sorting
GET /dealers?sort=name&order=asc

# Combined
GET /dealers?offset=0&limit=25&sort=createdAt&order=desc&status=active
```

### 9. Consistent Naming

Use consistent variable and field names across all organization APIs. This allows API consumers to easily identify and relate entities across myKaarma services.

Refer to the organization variable naming list for standard field names.

### 10. Ignore Unknown Fields

Clients must ignore unknown fields in API responses. This allows APIs to evolve by adding new fields without breaking existing consumers.

Services that follow this rule must make it clear in their documentation.

### 11. READ Requests with Complex Filters

See [reference/complex-read-patterns.md](reference/complex-read-patterns.md) for detailed guidance.

**Quick rules**:

1. **First try GET** with query parameters for filter data
2. If URL length is a concern, use **POST** with a request body:

```
# Create a search
POST /searches/
# Returns searchID or search results

# Retrieve search results (future)
GET /searches/{searchID}
```

Example: `POST /license/dealer-groups/{dealerGroupUuid}/products/{productUuid}/searches/`

### 12. READ Requests with Requester Validation

For GET endpoints that need requester identity for authorization (e.g., `requesterUserUuid`):

- Keep the endpoint as **GET** with no request body
- Pass authorization parameters in **headers** (not query params or body)

```java
// Good: requester info in headers
@GetMapping("/vouchers/{voucherUuid}")
public ResponseEntity<Voucher> getVoucher(
    @PathVariable String voucherUuid,
    @RequestHeader("X-Requester-User-UUID") String requesterUserUuid
) {
    // Verify requesterUserUuid has access to this voucher
    ...
}

// Bad: requester info as query param
@GetMapping("/vouchers/{voucherUuid}")
public ResponseEntity<Voucher> getVoucher(
    @PathVariable String voucherUuid,
    @RequestParam String requesterUserUuid
) { ... }
```

Headers and cookies should be used for authorization data.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Verbs in URLs (`/getDealer`) | Use nouns: `/dealers/{uuid}` |
| Singular collection names (`/dealer`) | Use plural: `/dealers` |
| camelCase in URLs (`/dealerAssociates`) | Use hyphens: `/dealer-associates` |
| 200 status with error body | Use 4xx/5xx with error details |
| Raw string responses | Always return JSON |
| No versioning | Add `/v1/` to all endpoints |
| No pagination on list endpoints | Add `offset` and `limit` params |
| Auth params in query string | Use headers for auth data |
| Deeply nested URLs (4+ levels) | Flatten to max 3 levels |
| GET with request body for filters | Use query params, or POST `/searches/` |

## Integration with Project Documentation

- See CLAUDE.md for project-specific API conventions
- Follow the API team review guidelines before posting for review
- Use the organization's standard variable naming list for field names
- Reference kmanage-api error codes for standard error code patterns
