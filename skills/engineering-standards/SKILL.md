---
name: engineering-standards
description: Apply myKaarma engineering standards when building features, reviewing code, designing APIs, setting up services, or checking patterns for backend (Java/Spring Boot) or frontend (TypeScript/Angular/React). Use when an engineer asks "how should I..." or "what's the pattern for..." or before implementing any backend/frontend code.
---

# Engineering Standards

**Announce:** "Using engineering-standards skill."

## When to Use This Skill

Use this skill when an engineer needs to know the correct myKaarma pattern for:
- Setting up a new backend service or frontend app
- Writing controllers, services, repositories, DTOs, or mappers
- Designing or reviewing REST API endpoints
- Handling errors, auth, logging, or async messaging
- Writing or structuring tests
- Checking naming conventions
- Running a pre-launch review

## Routing Guide

Based on the task, read **only** the relevant reference file(s):

| Task | Reference |
|------|-----------|
| New service layout, folder structure, multi-module repos (server/model/client) | [reference/project-structure.md](reference/project-structure.md) |
| Controllers, services, repositories, DTOs, mappers, middleware, Spring config | [reference/backend-patterns.md](reference/backend-patterns.md) |
| Angular/React services, HTTP client, components, models, enums, code style | [reference/frontend-patterns.md](reference/frontend-patterns.md) |
| REST API endpoints, URL patterns, response shapes, pagination rules | [reference/api-design.md](reference/api-design.md) |
| Industry-standard API design patterns, resource-oriented design, Google AIP guidelines | [reference/google-api-guidelines.md](reference/google-api-guidelines.md) |
| Error codes, exception types, global error handler, frontend error display | [reference/error-handling.md](reference/error-handling.md) |
| Authentication (mkid cookie), dealer context, CORS, secrets management | [reference/security-auth.md](reference/security-auth.md) |
| RabbitMQ publishers/consumers, async patterns, when to use queues, DLQ | [reference/async-messaging.md](reference/async-messaging.md) |
| Structured logging, MDC, log levels, correlation IDs, health/metrics | [reference/observability.md](reference/observability.md) |
| Soft deletes, pagination, DB indexes, caching, connection pooling, read replica | [reference/scalability.md](reference/scalability.md) |
| Java class/method/field names, TypeScript conventions, API field casing | [reference/naming-conventions.md](reference/naming-conventions.md) |
| Unit tests (Mockito), integration tests (Testcontainers), E2E, test organization | [reference/testing.md](reference/testing.md) |
| Pre-launch review checklist for backend and frontend | [reference/launch-checklist.md](reference/launch-checklist.md) |

## Key Principles (always apply, no file load needed)

- **Cookie-based auth only** — frontend sets `mkid` cookie on startup, all HTTP calls use `withCredentials: true`. No Authorization header.
- **User context from Kmanage API** — fetch user/dealer details using `userUuid` from Kmanage, not from any session object.
- **Soft delete everywhere** — `is_valid = false`, never `DELETE`.
- **Never expose DB primary keys** — always use `uuid` in API responses.
- **Paginate every list** — default 25, max 100, enforced server-side.
- **Business logic in service layer only** — controllers and repos are thin.
- **External integrations in `utils/`** — services never call SDKs directly.
