# Reference: Google API Improvement Proposals (AIPs)

> Based on https://google.aip.dev/general - Industry-standard API design patterns from Google

## Core Principles

### Resource-Oriented Design (AIP-121)
- APIs should model resources (nouns) not actions (verbs)
- Resources have types, names, and are manipulated via standard methods
- Use collection/resource hierarchy: `/users/{user}/posts/{post}`

### Standard Methods (AIP-130-135)

| Method | HTTP | URL Pattern | Purpose |
|--------|------|-------------|---------|
| List | GET | `/v1/users` | Retrieve multiple resources |
| Get | GET | `/v1/users/{user}` | Retrieve single resource |
| Create | POST | `/v1/users` | Create new resource |
| Update | PATCH | `/v1/users/{user}` | Modify existing resource |
| Delete | DELETE | `/v1/users/{user}` | Remove resource |

### Custom Methods (AIP-136)
For operations that don't fit standard CRUD:
```
POST /v1/users/{user}:resetPassword
POST /v1/instances/{instance}:start
POST /v1/projects/{project}:search
```

## Resource Design

### Resource Names (AIP-122)
```
// Collection and resource pattern
users/user-123
users/user-123/posts/post-456

// Full resource name includes service
//projects.googleapis.com/projects/my-project/topics/my-topic
```

### Resource Types (AIP-123)
- Use singular for resource type: `User`, `Post`, `Comment`
- Collections are plural: `users`, `posts`, `comments`
- Consistent naming across all operations

### Enumerations (AIP-126)
```proto
enum State {
  STATE_UNSPECIFIED = 0;  // Always include unspecified
  ACTIVE = 1;
  PAUSED = 2;
  DELETED = 3;
}
```

## Field Design

### Field Names (AIP-140)
- Use `snake_case` in proto definitions
- Use `camelCase` in JSON representations
- Be descriptive: `display_name` not `name`
- Use consistent naming patterns

### Time and Duration (AIP-142)
```proto
// Use google.protobuf.Timestamp for absolute time
google.protobuf.Timestamp create_time = 1;
google.protobuf.Timestamp update_time = 2;

// Use google.protobuf.Duration for time spans
google.protobuf.Duration timeout = 3;
```

### Standard Fields (AIP-148)
Common fields that should be consistent:
```proto
message Resource {
  string name = 1;                              // Full resource name
  string display_name = 2;                      // Human-readable name
  google.protobuf.Timestamp create_time = 3;    // Creation timestamp
  google.protobuf.Timestamp update_time = 4;    // Last modification
  map<string, string> labels = 5;               // User-defined labels
  string etag = 6;                              // Revision identifier
}
```

## Operations Patterns

### Long-Running Operations (AIP-151)
For operations that take significant time:
```json
// Initial request returns operation
POST /v1/instances
{
  "name": "operations/operation-123",
  "metadata": {...},
  "done": false
}

// Poll for completion
GET /v1/operations/operation-123
{
  "name": "operations/operation-123",
  "done": true,
  "response": {...}
}
```

### Batch Operations (AIP-231, 233-235)
```json
// Batch get
POST /v1/users:batchGet
{
  "names": ["users/user-1", "users/user-2"]
}

// Batch create
POST /v1/users:batchCreate
{
  "requests": [
    {"parent": "users", "user": {...}},
    {"parent": "users", "user": {...}}
  ]
}
```

## List and Pagination (AIP-132, 158)

### Standard List Method
```
GET /v1/users?page_size=50&page_token=abc123&filter=state=ACTIVE
```

### Response Format
```json
{
  "users": [...],
  "next_page_token": "def456",
  "total_size": 1234  // Optional
}
```

### Pagination Rules
- Use `page_size` and `page_token` (not offset/limit)
- Default page size: 10-100 depending on resource
- Maximum page size: enforce server-side limits
- Include `next_page_token` when more results available

## Filtering and Search (AIP-160)

### Filter Expressions
```
// Simple filters
state=ACTIVE
create_time>"2023-01-01T00:00:00Z"

// Complex filters  
state=ACTIVE AND (priority=HIGH OR priority=URGENT)
labels.env=prod AND labels.team=backend
```

### Search Method
```
POST /v1/users:search
{
  "query": "john smith",
  "page_size": 25,
  "page_token": "..."
}
```

## Error Handling (AIP-193)

### Standard Error Response
```json
{
  "error": {
    "code": 400,
    "message": "Invalid argument",
    "status": "INVALID_ARGUMENT",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.BadRequest",
        "field_violations": [
          {
            "field": "user.email",
            "description": "Email format is invalid"
          }
        ]
      }
    ]
  }
}
```

### Standard Error Codes
- `INVALID_ARGUMENT` (400) - Client error in request
- `UNAUTHENTICATED` (401) - Authentication required
- `PERMISSION_DENIED` (403) - Authorization failed
- `NOT_FOUND` (404) - Resource doesn't exist
- `ALREADY_EXISTS` (409) - Resource conflicts
- `RESOURCE_EXHAUSTED` (429) - Rate limit exceeded
- `INTERNAL` (500) - Server error
- `UNAVAILABLE` (503) - Service temporarily unavailable

## Versioning (AIP-185)

### Version in URL
```
/v1/users
/v2/users
/v1beta1/users  // Pre-release
```

### Backwards Compatibility Rules
- Never remove fields from responses
- Never change field semantics
- Never change resource name formats
- New fields should be optional
- Use deprecation warnings before removal

## Design Patterns

### Soft Delete (AIP-164)
```proto
message User {
  string name = 1;
  bool deleted = 2;                    // Soft delete flag
  google.protobuf.Timestamp delete_time = 3;
}
```

### Resource Associations (AIP-124)
```
// Reference by name
message Post {
  string author = 1;  // "users/user-123"
}

// Nested resources
/users/{user}/posts/{post}
```

### Singleton Resources (AIP-156)
For resources that exist only once per parent:
```
/projects/{project}/config
/users/{user}/profile
```

## Documentation Standards (AIP-192)

### API Documentation
- Every method needs clear description
- Document all parameters and fields
- Include example requests/responses
- Specify error conditions
- Document rate limits and quotas

### Field Documentation
```proto
message User {
  // The resource name of the user.
  // Format: users/{user}
  string name = 1;
  
  // The display name for the user.
  // Must be 1-100 characters.
  string display_name = 2;
  
  // Output only. The time when the user was created.
  google.protobuf.Timestamp create_time = 3;
}
```

## Security Patterns (AIP-211)

### Authorization Checks
- Check permissions at resource level
- Use consistent permission model
- Document required permissions
- Fail securely (deny by default)

### Sensitive Fields (AIP-147)
```proto
message User {
  string email = 1;
  // Sensitive. Never logged or cached.
  string password_hash = 2 [(google.api.field_behavior) = SENSITIVE];
}
```

## Naming Conventions (AIP-190)

### API Names
- Use kebab-case for service names: `cloud-storage`
- Use snake_case for proto fields: `display_name`
- Use camelCase for JSON fields: `displayName`

### Collection Names
- Always plural: `users`, `projects`, `instances`
- Use American English: `colors` not `colours`
- Avoid abbreviations: `configurations` not `configs`

### Method Names
- Standard methods: `List`, `Get`, `Create`, `Update`, `Delete`
- Custom methods: `Cancel`, `Move`, `Search`, `Batch*`
- Use imperative mood: `CreateUser` not `UserCreation`

## Integration with myKaarma Standards

### Alignment Points
1. **Resource-oriented design** aligns with myKaarma's RESTful approach
2. **Standard methods** match myKaarma's CRUD patterns
3. **Error handling** can enhance myKaarma's error response format
4. **Pagination** patterns can improve myKaarma's offset/limit approach

### Adaptation Guidelines
1. Keep myKaarma's cookie-based auth (not AIP auth patterns)
2. Use myKaarma's UUID patterns for resource IDs
3. Maintain myKaarma's soft delete with `is_valid` flag
4. Consider adopting AIP pagination tokens for better performance
5. Enhance error responses with AIP-style structured details

### Implementation Priority
1. **High**: Standard methods, resource naming, field conventions
2. **Medium**: Pagination improvements, error detail structure
3. **Low**: Long-running operations, batch methods (as needed)

## Quick Reference

### Must Follow
- Resource-oriented URLs: `/v1/collection/{id}`
- Standard HTTP methods for CRUD operations
- Consistent field naming (snake_case → camelCase)
- Structured error responses
- Proper HTTP status codes

### Should Consider
- Page token pagination for large datasets
- Filter expressions for complex queries
- Long-running operations for async work
- Batch operations for efficiency
- Standard fields (create_time, update_time, etag)

### May Adopt
- Full AIP error detail structure
- Proto-first API design
- Comprehensive field behavior annotations
- Advanced filtering syntax