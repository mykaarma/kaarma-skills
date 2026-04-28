# Reference: Security & Authentication

## Auth Flow

Authentication is cookie-based. The frontend sets an `mkid` cookie on startup; this cookie is sent with every request via `withCredentials: true`. The backend reads the cookie to identify the user.

```
Every inbound request:
  1. Extract mkid from request cookies
  2. Validate mkid — look up user by mkid
  3. Fetch user identity and store on request context for downstream use
  4. If mkid is missing or invalid → 401 Unauthorized

Per-resource authorization:
  5. Check user has permission for the specific resource
  6. If not → 403 Forbidden
```

```java
// In preHandle():
Cookie[] cookies = request.getCookies();
String mkid = Arrays.stream(cookies != null ? cookies : new Cookie[0])
    .filter(c -> "mkid".equals(c.getName()))
    .map(Cookie::getValue)
    .findFirst()
    .orElse(null);

if (mkid == null || mkid.isBlank()) {
    throw new BadArgumentsException(ErrorCodes.INVALID_AUTH);
}

UserResponseDTO user = userService.fetchUserByMkid(mkid);
if (user == null) {
    throw new BadArgumentsException(ErrorCodes.INVALID_AUTH);
}

SecurityContextHolder.getContext().setAuthentication(
    new UsernamePasswordAuthenticationToken(user, null, Collections.emptyList())
);
MDC.put(MDCConstants.USER_EMAIL, user.getUser().getEmail());
```

## User Context — Kmanage API

Once authenticated, fetch the full user/dealer context from **Kmanage API** using `userUuid`:

```java
// Fetch dealer associates and dealer context for the authenticated user
UserContextResponse context = kmanageClient.getUserContext(user.getUuid());
// context contains: dealerAssociates → departments → dealers
```

Dealer/department context is always derived from the Kmanage API call using `userUuid`.

## Dealer Context in API Calls (Backend)

Extract dealer context from the URL path in middleware and attach it to the request context:

```
Middleware / interceptor:
  1. Extract {departmentUUID} from URL path variables
  2. Resolve to dealerID:  SELECT dealer_id FROM dealer_departments WHERE uuid = ?
  3. Attach to request context: request.setAttribute("DEALER_UUID", dealerUuid)
  4. Set in MDC for logging: MDC.put("dealerUuid", dealerUuid)
```

```java
Map<String, String> pathVars = (Map<String, String>)
    request.getAttribute(HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE);

if (pathVars != null && pathVars.containsKey("departmentUUID")) {
    String departmentUUID = pathVars.get("departmentUUID");
    request.setAttribute(APIConstants.DEALER_DEPARTMENT_TOKEN, departmentUUID);
    MDC.put(MDCConstants.DEPARTMENT_UUID, departmentUUID);

    // Cached lookup — resolves to dealerID for downstream service use
    String dealerContext = generalRepository
        .getDealerContextForLoggingFromDepartmentUUID(departmentUUID); // @Cacheable
    MDC.put(MDCConstants.DEALER_CONTEXT, dealerContext);
}
```

**Cache the department → dealer lookup** — every request hits it, and mappings rarely change.

## Dealer Context in API Calls (Frontend)

Pass dealer/department UUIDs in the URL path on every API call:

```typescript
// Pattern A — In the URL path (preferred for dealer-scoped endpoints)
const url = `${environment.apiUrl}/dealers/${this.session.dealerUuid}/appointments`;
const url = `${environment.apiUrl}/department/${this.session.departmentUuid}/messages`;

// Pattern B — As a query parameter (subscriber-identified calls)
const url = `${environment.apiUrl}/appointments/${sarUuid}?subscriberName=mkDealer`;
```

Never embed dealer context in request bodies for GET requests.

## Secrets & Configuration

```
✅ Do:
  - Store secrets in environment variables or a secrets manager (AWS Secrets Manager, Vault)
  - Encrypt sensitive config values in application.yml using Jasypt: ENC(encryptedValue)
  - Pull config from Spring Cloud Config Server
  - Rotate tokens and credentials periodically
  - Use different credentials per environment (devvm / qa-aws / prod)

❌ Never:
  - Commit plaintext secrets, API keys, or passwords to source control
  - Log tokens, passwords, or PII
  - Use the same credentials across environments
  - Pass mkid or session identifiers as query parameters (use cookies)
```

## CORS

```
Allowed origins:  *.mykaarma.com, *.mykaarma.dev, localhost:* (dev only)
Allowed methods:  GET, POST, PATCH, DELETE, OPTIONS
Allow credentials: true   ← required for cookie-based auth
Max age (preflight cache): 30 minutes
```

## Security Checklist

- [ ] Every endpoint verified by auth middleware (opt-out, not opt-in)
- [ ] mkid cookie validated on every request — user fetched and stored on request context
- [ ] Permission checks fail with 403, not 404 (don't leak resource existence)
- [ ] No secrets in source code, logs, or error responses
- [ ] Parameterized queries only — no string concatenation for DB queries
- [ ] CORS restricted to known origins with `allowCredentials: true`
- [ ] All frontend HTTP calls use `withCredentials: true`
