# Collection URL Patterns - Detailed Reference

## Plural Nouns for Collections

Collections represent groups of resources and must use plural nouns.

### Standard CRUD Operations

| Operation | HTTP Method | URL Pattern | Example |
|-----------|-------------|-------------|---------|
| List all | GET | `/{collection}` | `GET /dealers` |
| Create one | POST | `/{collection}` | `POST /dealers` |
| Get one | GET | `/{collection}/{id}` | `GET /dealers/{dealerUUID}` |
| Replace one | PUT | `/{collection}/{id}` | `PUT /dealers/{dealerUUID}` |
| Update properties | PATCH | `/{collection}/{id}` | `PATCH /dealers/{dealerUUID}` |
| Delete one | DELETE | `/{collection}/{id}` | `DELETE /dealers/{dealerUUID}` |

## Hyphenated Terms

Use hyphens (kebab-case) to separate multi-word terms in URLs per REST URI term separation guidelines.

```
# Good
/dealer-associates/{associateUUID}
/communication-preferences/{preferenceUUID}
/service-appointments/{appointmentUUID}

# Bad
/dealerAssociates/{associateUUID}        # camelCase
/communication_preferences/{id}          # snake_case
/CommunicationPreferences/{id}           # PascalCase
```

## Resource Nesting

Nest related resources under their parent to express relationships.

```
# Department belongs to a dealer
GET /dealers/{dealerUUID}/departments
GET /dealers/{dealerUUID}/departments/{departmentUUID}

# Vehicle belongs to a customer
GET /customers/{customerUUID}/vehicles
GET /customers/{customerUUID}/vehicles/{vehicleUUID}

# Course belongs to a user
GET /users/{userUUID}/courses
GET /users/{userUUID}/courses/{courseUUID}
```

### Nesting Depth Limit

Avoid nesting more than 3 levels deep. Deeply nested URLs are harder to read, harder to maintain, and often indicate a modeling problem.

```
# Acceptable (2 levels)
GET /dealers/{dealerUUID}/departments/{departmentUUID}

# Acceptable (3 levels)
GET /dealers/{dealerUUID}/departments/{departmentUUID}/advisors

# Too deep (4+ levels) - flatten instead
# Bad
GET /dealers/{dealerUUID}/departments/{deptUUID}/advisors/{advisorUUID}/schedules

# Better - use a top-level resource with query filters
GET /schedules?advisorUUID={advisorUUID}
```

## Properties vs Collections

### Properties (Singular Nouns)

Use singular nouns for objects with a one-to-one relationship to the parent resource.

A property is uniquely identified by its parent's identifier - there is exactly one per parent.

```
# Receipt for a trip (1 trip = 1 receipt)
GET /trips/{tripUUID}/receipt

# Profile for a user (1 user = 1 profile)
GET /users/{userUUID}/profile

# Configuration for a dealer (1 dealer = 1 config)
GET /dealers/{dealerUUID}/configuration
```

### Collections (Plural Nouns)

Use plural nouns for one-to-many relationships where the parent can have multiple children.

```
# A dealer has many departments
GET /dealers/{dealerUUID}/departments

# A customer has many vehicles
GET /customers/{customerUUID}/vehicles

# A department has many advisors
GET /departments/{departmentUUID}/advisors
```

## Bulk Operations

### Syntax: `:bulk-verb`

For operations on multiple resources, use custom methods with `:bulk-verb` appended to the collection name. The HTTP method must always be **POST**.

The `:bulk-verb` must be in kebab/hyphenated case.

### Bulk Operation Types

#### bulk-create

Create multiple resources at once.

```
POST /dealers:bulk-create
{
    "requests": [
        { "name": "Audi of Long Beach", "address": "..." },
        { "name": "BMW of Irvine", "address": "..." }
    ]
}
```

#### bulk-update

Full update of multiple resources (like PUT for each).

```
POST /dealers:bulk-update
{
    "requests": [
        { "uuid": "uuid_123", "name": "MB of Silver Lake", "address": "..." },
        { "uuid": "uuid_456", "name": "MB of Long Beach", "address": "..." }
    ]
}
```

#### bulk-patch

Partial update of multiple resources (like PATCH for each).

```
POST /dealers:bulk-patch
{
    "requests": [
        { "uuid": "uuid_456", "name": "MB of Long Beach" }
    ]
}
```

#### bulk-delete

Delete multiple resources at once.

```
POST /dealers:bulk-delete
{
    "uuids": ["uuid_789", "uuid_101112"]
}
```

#### bulk-save

Upsert operation - update existing entries, create new ones.

```
POST /adp-make-models:bulk-save
{
    "adpMakeModelDTOList": [
        { "makeName": "Audi", "modelName": "Q3", ... }
    ]
}
```

### Bulk Operations in Nested Collections

For bulk operations across nested collections of multiple parents, use collection names without identifiers.

```
# Update courses for multiple users
POST /users/courses:bulk-update

# Update KPI definitions across multiple dealers
POST /dealers/kpi-definitions:bulk-update
```

### Authentication for Bulk Operations

- If `dealerUuids` are in the request body, authentication is done on those UUIDs
- If a `dealerUuid` is in the path variable, authentication uses that UUID
- If both are provided, the **union** is used for authentication

References:
- [Custom methods - Google API Design Guide](https://cloud.google.com/apis/design/custom_methods)
- [Delete multiple records using REST - Stack Overflow](https://stackoverflow.com/questions/21863326/delete-multiple-records-using-rest/53264372#53264372)
- [GitHub API examples](https://docs.github.com/en/rest/pulls/comments?apiVersion=2022-11-28#list-review-comments-in-a-repository)
