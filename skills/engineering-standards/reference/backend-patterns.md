# Reference: Backend Patterns

## Controllers / Route Handlers

Controllers translate HTTP into service calls. They own:
- Request parsing and input validation
- Setting tracing context (MDC / correlation IDs)
- Calling the right service method
- Returning the right HTTP status

They do **not** own business logic, DB access, or external calls.

```java
@Slf4j
@RestController
@RequestMapping("/v1/gvms")
@SecurityRequirement(name = "Authorization")
public class GvmController {

    private final GvmService gvmService;

    public GvmController(GvmService gvmService) {
        this.gvmService = gvmService;
    }

    @PostMapping("/")
    @ResponseStatus(HttpStatus.CREATED)
    public CreateGvmResponse createGvm(
            @Valid @RequestBody GvmCreateRequest request,
            HttpServletRequest httpRequest) {
        MDC.put(MDCConstants.ENDPOINT, "POST:/v1/gvms/");
        return gvmService.createGvm(request);
    }
}
```

**Rules:**
- Always validate at the boundary — reject bad input before it reaches the service layer
- Use constructor / dependency injection — never instantiate dependencies inside handlers
- One controller per resource domain (`GvmController`, `WorkflowController`)

---

## Services (Business Logic)

Services own all business logic. They are the only layer that decides what happens.

```java
@Slf4j
@Service
public class GvmService {

    private final GvmRepository gvmRepository;
    private final RabbitMQPublisher publisher;
    private final GvmMapper gvmMapper;

    public GvmService(GvmRepository gvmRepository, RabbitMQPublisher publisher, GvmMapper gvmMapper) {
        this.gvmRepository = gvmRepository;
        this.publisher = publisher;
        this.gvmMapper = gvmMapper;
    }

    @Transactional
    public CreateGvmResponse createGvm(GvmCreateRequest request) {
        if (gvmRepository.existsByNameAndIsValidTrue(request.getName())) {
            throw new BadArgumentsException(ErrorCodes.GVM_NAME_TAKEN);
        }

        GVM entity = gvmMapper.toEntity(request);
        entity.setUuid(UUID.randomUUID().toString());
        GVM saved = gvmRepository.save(entity);

        publisher.publishGvmCreated(saved.getUuid());

        return new CreateGvmResponse(gvmMapper.toDTO(saved));
    }
}
```

**Rules:**
- Services receive plain objects (DTOs/request models), not raw HTTP request objects
- Long-running work (cloud calls, CI/CD triggers) goes to a message queue, not in the request path
- Wrap external calls (AWS, GitHub, etc.) in utility classes — services call utilities, not SDKs directly

---

## Repositories (Data Access)

Repositories are the only place that talks to the database. No SQL/ORM queries outside this layer.

```java
public interface GvmRepository extends JpaRepository<GVM, Long> {

    Optional<GVM> findByUuidAndIsValidTrue(String uuid);
    boolean existsByNameAndIsValidTrue(String name);
    Page<GVM> findAllByIsValidTrue(Pageable pageable);

    @Query("SELECT g FROM GVM g JOIN FETCH g.gvmDetails WHERE g.isValid = true ORDER BY g.id DESC")
    List<GVM> findAllActiveWithDetails();

    @Modifying
    @Query("UPDATE GVM g SET g.isValid = false WHERE g.uuid = :uuid")
    void softDeleteByUuid(@Param("uuid") String uuid);
}
```

**Rules:**
- **Never hard-delete** primary entities — use `is_valid = false` (soft delete)
- Always append the soft-delete filter in every query — never return deleted records silently
- Paginate all list methods — never return unbounded arrays
- Never put business logic in repositories (no `if` blocks, no cross-entity decisions)

---

## DTOs & Mappers

Keep DB models (entities) separate from API models (DTOs). Never expose raw entities in responses.

```java
// Request DTO (Lombok + validation annotations)
@Data
public class GvmCreateRequest {
    @NotBlank
    private String name;
    @NotBlank
    private String type;
    @NotBlank
    private String instanceTypeUuid;
}

// Response DTO
@Data
@Builder
public class GvmDTO {
    private String uuid;
    private String name;
    private String type;
    private GvmStatus status;
    private Instant createdAt;
}

// MapStruct mapper (code-generated, no manual setters)
@Mapper(componentModel = "spring")
public abstract class GvmMapper {

    @Mapping(target = "type", source = "gvmType.name")
    public abstract GvmDTO toDTO(GVM entity);

    @Mapping(target = "gvmType.name", source = "type")
    @Mapping(target = "isValid", constant = "true")
    public abstract GVM toEntity(GvmCreateRequest request);

    public abstract List<GvmDTO> toDTOList(List<GVM> entities);
}
```

**Rules:**
- Never expose numeric DB primary keys (`id`) in API responses — always use `uuid`
- Request models validate input shape; response models control what gets serialized
- A mapper is the only place that translates between layers

---

## Middleware / Interceptors (Backend)

Apply cross-cutting concerns (auth, logging, tracing) in middleware — not in controllers or services.

```
Middleware execution order (inbound → outbound):
  1. Correlation ID injection
  2. Authentication (validate mkid cookie, populate user context)
  3. Authorization (role/ownership checks)
  4. Request logging (log method + path)
  5. → Controller → Service → Repository
  6. Response logging / timing
  7. Error handler (catch unhandled exceptions, format error response)
```

```java
@Slf4j
@Component
public class AuthorizeHandlerInterceptor implements HandlerInterceptor {

    private final UserService userService;

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws Exception {
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
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        MDC.clear();
    }
}

// Register in WebMvcConfig
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authorizeHandlerInterceptor)
                .addPathPatterns("/v1/**");
    }
}
```

---

## Spring Cloud Config Server

Java services pull configuration from a central Spring Cloud Config Server.

```yaml
# application.yml — only bootstrap config lives here
spring:
  application:
    name: your-service-name
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:devvm}
  cloud:
    config:
      label: ${SPRING_PROFILES_ACTIVE:devvm}
      uri: ${CONFIG_SERVER_URL:http://api:2827}
```

| Profile | Config Server |
|---------|--------------|
| `devvm` | `http://api:2827` (local GVM) |
| `qa-aws` | `http://lb01-central-config.kaar-ma.com` |
| `prod` | `http://lb01-central-config.kaar-ma.com` |

All sensitive values (DB passwords, API keys, AWS credentials) live in the config server, not in this repo.
