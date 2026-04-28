# Reference: Observability & Logging

## Structured Logging

Always log as structured data (JSON). Every log line should include:
- `timestamp`, `level`, `service` name
- `correlation_id` / `trace_id`
- Business context (resource UUID, user email, action)

```java
@Slf4j
@Service
public class GvmService {

    public CreateGvmResponse createGvm(GvmCreateRequest request) {
        log.info("Creating GVM name={} type={}", request.getName(), request.getType());

        if (gvmRepository.existsByNameAndIsValidTrue(request.getName())) {
            log.warn("GVM name already taken name={}", request.getName());
            throw new BadArgumentsException(ErrorCodes.GVM_NAME_TAKEN);
        }

        GVM saved = gvmRepository.save(gvmMapper.toEntity(request));
        log.info("GVM created uuid={}", saved.getUuid());
        return new CreateGvmResponse(gvmMapper.toDTO(saved));
    }
}
```

MDC keys to set at the start of every request (in the interceptor):
```java
MDC.put(MDCConstants.ENDPOINT,        HttpMethod.POST + ":/v1/gvms/");
MDC.put(MDCConstants.RESOURCE_UUID,   resourceUuid);
MDC.put(MDCConstants.USER_EMAIL,      user.getEmail());
MDC.put(MDCConstants.CORRELATION_ID,  correlationId);
// Clear in afterCompletion()
```

## Log Levels

| Situation | Level |
|-----------|-------|
| Normal business operation completed | `INFO` |
| Client sent bad/invalid request (4xx) | `WARN` |
| Unexpected server-side failure (5xx) | `ERROR` |
| Detailed execution flow for debugging | `DEBUG` — disabled in production |

**Never log:** passwords, auth tokens, API keys, PII, full request/response bodies.

## Correlation ID / Tracing

```java
@Override
public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
    String correlationId = request.getHeader("X-Correlation-ID");
    if (correlationId == null || correlationId.isBlank()) {
        correlationId = UUID.randomUUID().toString();
    }
    MDC.put(MDCConstants.CORRELATION_ID, correlationId);
    response.setHeader("X-Correlation-ID", correlationId);
    MDC.put(MDCConstants.REQUEST_ID, UUID.randomUUID().toString());
    request.setAttribute(MDCConstants.START_TIME, System.currentTimeMillis());
    return true;
}

@Override
public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                             Object handler, Exception ex) {
    long duration = System.currentTimeMillis() - (long) request.getAttribute(MDCConstants.START_TIME);
    if (duration > 2000) {
        log.warn("Slow request duration={}ms uri={}", duration, request.getRequestURI());
    }
    MDC.clear();
}
```

Pass `X-Correlation-ID` header on all outbound service-to-service calls.

## Health & Metrics

```
GET /health        → 200 {"status": "UP"} or 503 {"status": "DOWN", "details": {...}}
GET /metrics       → Prometheus text format (or delegate to sidecar)
GET /info          → {"version": "1.2.3", "service": "orders-api", "env": "prod"}
```

Track at minimum:
- HTTP request count and latency (p50, p95, p99) by endpoint
- Error rate by status code
- Queue depth and consumer lag for async workers
- DB connection pool utilization
