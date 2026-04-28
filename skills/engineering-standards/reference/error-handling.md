# Reference: Error Handling

## Error Code Enum

Define all error codes in one place per service:

```java
public enum ErrorCodes {

    // 4xx — Client errors (100xxx)
    BAD_REQUEST        (100001, "BAD_REQUEST",     "Invalid request parameters."),
    RESOURCE_NOT_FOUND (100002, "NOT_FOUND",        "The requested resource does not exist."),
    INVALID_AUTH       (100003, "INVALID_AUTH",     "Authentication token is invalid or expired."),
    UNAUTHORIZED       (100004, "UNAUTHORIZED",     "You do not have permission for this action."),
    RESOURCE_CONFLICT  (100005, "CONFLICT",         "Resource already exists."),

    // 5xx — Server errors (200xxx)
    INTERNAL_ERROR     (200001, "INTERNAL_ERROR",   "An unexpected error occurred."),
    DOWNSTREAM_FAILURE (200002, "DOWNSTREAM_FAIL",  "A required downstream service failed.");

    private final int code;
    private final String title;
    private final String message;

    ErrorCodes(int code, String title, String message) {
        this.code = code;
        this.title = title;
        this.message = message;
    }

    public int getCode()    { return code; }
    public String getTitle()   { return title; }
    public String getMessage() { return message; }
}
```

## Exception Types

```java
// Base exception holds structured error list
public class ServiceException extends RuntimeException {
    private final List<ErrorDTO> errors;

    public ServiceException(ErrorCodes errorCode) {
        this.errors = List.of(new ErrorDTO(errorCode));
    }
    public ServiceException(ErrorCodes errorCode, String extraDetail) {
        this.errors = List.of(new ErrorDTO(errorCode, extraDetail));
    }
    public List<ErrorDTO> getErrors() { return errors; }
}

// Specific subtypes map to HTTP status codes
public class BadArgumentsException extends ServiceException {      // → 400
    public BadArgumentsException(ErrorCodes code) { super(code); }
    public BadArgumentsException(ErrorCodes code, String detail) { super(code, detail); }
}
public class ResourceNotFoundException extends ServiceException {  // → 404
    public ResourceNotFoundException(ErrorCodes code) { super(code); }
}
public class UnauthorizedException extends ServiceException {      // → 403
    public UnauthorizedException(ErrorCodes code) { super(code); }
}
public class DownstreamException extends ServiceException {        // → 503
    public DownstreamException(ErrorCodes code) { super(code); }
}
```

## Global Error Handler

```java
@Slf4j
@ControllerAdvice
@RestController
public class GlobalExceptionHandler {

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler(BadArgumentsException.class)
    public ResponseDTO handleBadArguments(HttpServletRequest req, BadArgumentsException e) {
        log.warn("Bad request [{}]: {}", req.getRequestURI(), e.getErrors());
        return buildErrorResponse(e.getErrors());
    }

    @ResponseStatus(HttpStatus.NOT_FOUND)
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseDTO handleNotFound(HttpServletRequest req, ResourceNotFoundException e) {
        log.warn("Not found [{}]: {}", req.getRequestURI(), e.getErrors());
        return buildErrorResponse(e.getErrors());
    }

    @ResponseStatus(HttpStatus.FORBIDDEN)
    @ExceptionHandler(UnauthorizedException.class)
    public ResponseDTO handleUnauthorized(HttpServletRequest req, UnauthorizedException e) {
        log.warn("Unauthorized [{}]: {}", req.getRequestURI(), e.getErrors());
        return buildErrorResponse(e.getErrors());
    }

    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    @ExceptionHandler(Exception.class)
    public ResponseDTO handleUnexpected(HttpServletRequest req, Exception e) {
        log.error("Unexpected error [{}]", req.getRequestURI(), e);
        return buildErrorResponse(List.of(new ErrorDTO(ErrorCodes.INTERNAL_ERROR)));
    }

    private ResponseDTO buildErrorResponse(List<ErrorDTO> errors) {
        ResponseDTO response = new ResponseDTO();
        response.setErrors(new HashSet<>(errors));
        return response;
    }
}
```

**Rules:**
- `warn` log for 4xx — these are expected, not bugs
- `error` log for 5xx — these need investigation
- Never expose stack traces, internal paths, or DB error details in responses
- Always return the same error shape — clients should be able to parse any error identically

## Frontend Error Handling

```typescript
// Utility — extract message from any HTTP error
function extractErrorMessage(err: unknown): string {
  const body = (err as any)?.response?.data ?? (err as any)?.error;
  return body?.errors?.[0]?.errorMessage ?? 'An unexpected error occurred.';
}

// In a service — let errors propagate to the component
async function fetchGvm(uuid: string): Promise<Gvm> {
  const response = await apiClient.get<{ gvm: Gvm }>(`/v1/gvms/${uuid}`);
  return response.gvm;
  // Do NOT catch here — caller decides how to surface the error
}

// In a component — catch and inform the user
async function loadGvm() {
  try {
    setStatus(FetchStatus.LOADING);
    const gvm = await gvmService.fetchGvm(uuid);
    setGvm(gvm);
    setStatus(FetchStatus.SUCCESS);
  } catch (err) {
    setStatus(FetchStatus.ERROR);
    toast.error(extractErrorMessage(err));
  }
}
```
