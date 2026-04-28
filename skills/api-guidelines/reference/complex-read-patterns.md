# Complex READ Patterns - Detailed Reference

## READ Requests with Complex Filters

When you need to send filter, sorting, and pagination data for read operations, choose the approach based on data complexity and URL length constraints.

### Approach 1: GET with Query Parameters (Preferred)

Use GET requests with query parameters when the filter data is simple enough to fit in a URL.

```
# Basic filtering
GET /dealers?status=active&region=west

# Pagination
GET /customers/v2/customers/{customerUUID}/vehicles?offset=20&limit=10

# Sorting
GET /dealers?sort=name&order=asc

# Combined
GET /messages?tags=upset&offset=0&limit=50&sort=createdAt&order=desc
```

You can define custom query parameter formats based on your use case:

```
# Range filter
GET /vehicles?year_min=2020&year_max=2024

# Multiple values
GET /dealers?status=active,pending

# Date range
GET /appointments?from=2024-01-01&to=2024-12-31
```

### Approach 2: POST /searches/ (For Complex Filters)

When URL length restrictions prevent using GET with query params, use POST with a request body to create a search.

```
# Create a search - returns search results (or a searchID for future retrieval)
POST /license/dealer-groups/{dealerGroupUuid}/products/{productUuid}/searches/
{
    "filters": {
        "status": ["active", "pending"],
        "region": "west",
        "createdAfter": "2024-01-01",
        "tags": ["premium", "certified"]
    },
    "sort": {
        "field": "name",
        "order": "asc"
    },
    "pagination": {
        "offset": 0,
        "limit": 25
    }
}

# Retrieve search results later (future capability)
GET /searches/{searchID}
```

### When to Use POST /searches/

Use this approach when:
- Filter criteria are complex (nested objects, arrays of values)
- URL would exceed length limits (~2000 characters)
- Filter criteria contain sensitive data that shouldn't be in URLs
- You need to save/reuse search criteria

### Guidelines

1. POST `/searches/` can return results directly or return a `searchID`
2. GET `/searches/{searchID}` returns results for a previously created search
3. Search results should support pagination via query params or request body
4. Document the search schema clearly in API documentation

## READ Requests with Requester Validation

For endpoints that need to validate the requester's identity for authorization purposes.

### Use Case

Endpoints like fetching a voucher that need a `requesterUserUuid` to verify the requester has access to the resource.

### Approach: Use Headers for Auth Data

Keep the endpoint as GET with no request body. Pass authorization-related parameters in headers.

```java
// Good: Authorization data in headers
@GetMapping("/vouchers/{voucherUuid}")
public ResponseEntity<VoucherDTO> getVoucher(
    @PathVariable String voucherUuid,
    @RequestHeader("X-Requester-User-UUID") String requesterUserUuid
) {
    // Verify requesterUserUuid has access to this voucher
    authorizationService.verifyAccess(requesterUserUuid, voucherUuid);

    VoucherDTO voucher = voucherService.getByUuid(voucherUuid);
    return ResponseEntity.ok(voucher);
}
```

```java
// Bad: Authorization data as query parameter
@GetMapping("/vouchers/{voucherUuid}")
public ResponseEntity<VoucherDTO> getVoucher(
    @PathVariable String voucherUuid,
    @RequestParam String requesterUserUuid  // Don't do this
) { ... }
```

```java
// Bad: Using POST just to pass requester info in body
@PostMapping("/vouchers/{voucherUuid}")
public ResponseEntity<VoucherDTO> getVoucher(
    @PathVariable String voucherUuid,
    @RequestBody RequesterDTO requester  // Don't do this
) { ... }
```

### Why Headers?

- Headers and cookies are the standard mechanism for authorization data
- Keeps the URL clean and cacheable
- Follows REST conventions (GET should not have a request body)
- Authorization concerns are separated from business data

### When This Pattern Applies

This pattern is for endpoints where:
- You're fetching a single, uniquely identified resource (not a filtered list)
- The requester identity is needed purely for authorization, not as a filter
- The endpoint doesn't qualify as a "complex filter" scenario (see above)
