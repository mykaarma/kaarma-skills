# Java / Spring Boot Security Patterns

Reference for safe vs. unsafe code patterns used in myKaarma services. Each section maps to a phase in the `auditing-security` SKILL.md.

---

## 1. Parameterized Queries vs. String Concatenation

### UNSAFE — JPQL with string concatenation (SQL Injection)

```java
// BAD: attacker supplies: email = "' OR '1'='1"
public List<Customer> searchByEmail(String email) {
    String jpql = "SELECT c FROM Customer c WHERE c.email = '" + email + "'";
    return entityManager.createQuery(jpql, Customer.class).getResultList();
}
```

### SAFE — Named parameter binding

```java
// GOOD: parameter binding prevents injection regardless of input value
@Query("SELECT c FROM Customer c WHERE c.email = :email")
List<Customer> findByEmail(@Param("email") String email);

// Also safe with EntityManager:
public List<Customer> searchByEmail(String email) {
    return entityManager.createQuery(
            "SELECT c FROM Customer c WHERE c.email = :email", Customer.class)
        .setParameter("email", email)
        .getResultList();
}
```

---

### UNSAFE — Native SQL with JdbcTemplate concatenation

```java
// BAD: SQL injection via dealerId manipulation (even though it looks like a number)
public List<Message> getMessages(String dealerId) {
    String sql = "SELECT * FROM messages WHERE dealer_id = " + dealerId
               + " ORDER BY created_at DESC";
    return jdbcTemplate.query(sql, messageRowMapper);
}
```

### SAFE — JdbcTemplate with placeholders

```java
// GOOD: always use ? for JdbcTemplate
public List<Message> getMessages(Long dealerId) {
    String sql = "SELECT * FROM messages WHERE dealer_id = ? ORDER BY created_at DESC";
    return jdbcTemplate.query(sql, messageRowMapper, dealerId);
}

// Or with NamedParameterJdbcTemplate:
public List<Message> getMessages(Long dealerId) {
    String sql = "SELECT * FROM messages WHERE dealer_id = :dealerId ORDER BY created_at DESC";
    return namedJdbcTemplate.query(sql, Map.of("dealerId", dealerId), messageRowMapper);
}
```

---

### UNSAFE — MyBatis with ${} interpolation

```xml
<!-- BAD: ${status} is interpolated as raw SQL — injectable -->
<select id="findByStatus" resultType="Message">
  SELECT * FROM messages WHERE status = '${status}'
</select>
```

### SAFE — MyBatis with #{} parameterization

```xml
<!-- GOOD: #{status} is a prepared statement parameter — safe -->
<select id="findByStatus" resultType="Message">
  SELECT * FROM messages WHERE status = #{status}
</select>
```

---

### UNSAFE — MongoDB string-based query construction

```java
// BAD: user input interpolated directly into query JSON
BasicQuery query = new BasicQuery(
    "{ \"username\": \"" + username + "\", \"dealerId\": " + dealerId + " }");
mongoTemplate.findOne(query, User.class);
```

### SAFE — Spring Data MongoDB Criteria API

```java
// GOOD: Criteria API parameterizes all values
Query query = new Query(
    Criteria.where("username").is(username)
            .and("dealerId").is(dealerId));
mongoTemplate.findOne(query, User.class);

// Or use a MongoRepository derived method — always safe:
userRepository.findByUsernameAndDealerId(username, dealerId);
```

---

## 2. Auth Patterns — Protected vs. Unprotected Endpoints

### UNSAFE — No authorization guard

```java
// BAD: any authenticated user can update any dealer's settings
@RestController
@RequestMapping("/api/v1")
public class DealerSettingsController {

    @PostMapping("/dealers/{dealerId}/settings")
    public ResponseEntity<Settings> updateSettings(
            @PathVariable Long dealerId,
            @RequestBody SettingsRequest request) {
        return ResponseEntity.ok(settingsService.update(dealerId, request));
    }
}
```

### SAFE — Auth guard + dealer context from token

```java
// GOOD: PreAuthorize + dealer context always from authenticated principal
@RestController
@RequestMapping("/api/v1")
public class DealerSettingsController {

    @PreAuthorize("hasRole('DEALER_ADMIN')")
    @PostMapping("/dealers/{dealerId}/settings")
    public ResponseEntity<Settings> updateSettings(
            @AuthenticationPrincipal DealerContext ctx,
            @PathVariable Long dealerId,
            @Valid @RequestBody SettingsRequest request) {
        // Verify the authenticated dealer matches the path parameter
        if (!ctx.getDealerId().equals(dealerId)) {
            throw new AccessDeniedException("Cannot modify another dealer's settings");
        }
        return ResponseEntity.ok(settingsService.update(ctx.getDealerId(), request));
    }
}
```

---

### UNSAFE — Cross-dealer data leakage

```java
// BAD: attacker supplies arbitrary dealerId in the request body
@PostMapping("/messages/search")
public List<Message> search(@RequestBody MessageSearchRequest request) {
    // request.getDealerId() comes from the attacker
    return messageRepo.findByDealerIdAndStatus(
        request.getDealerId(), request.getStatus());
}
```

### SAFE — Dealer ID always from auth context

```java
// GOOD: dealerId is always derived from the authenticated session
@PostMapping("/messages/search")
@PreAuthorize("isAuthenticated()")
public List<Message> search(
        @AuthenticationPrincipal DealerContext ctx,
        @Valid @RequestBody MessageSearchRequest request) {
    // Ignore any dealerId in the request body — use the one from auth
    return messageRepo.findByDealerIdAndStatus(ctx.getDealerId(), request.getStatus());
}
```

---

## 3. Safe Logging vs. PII Logging

### UNSAFE — PII directly in log statements

```java
// BAD: phone number, email, name all in logs — CCPA/privacy violation
@Service
@Slf4j
public class NotificationService {

    public void sendSms(Customer customer, String message) {
        log.info("Sending SMS to customer: name={}, phone={}, email={}",
            customer.getFullName(), customer.getPhone(), customer.getEmail());
        smsGateway.send(customer.getPhone(), message);
    }
}
```

### SAFE — Opaque identifiers in logs

```java
// GOOD: only log non-PII identifiers
@Service
@Slf4j
public class NotificationService {

    public void sendSms(Customer customer, String message) {
        log.info("Sending SMS to customerId={}, dealerId={}",
            customer.getPublicId(), customer.getDealerId());
        smsGateway.send(customer.getPhone(), message);
    }
}
```

---

### UNSAFE — Payment card data in logs

```java
// BAD: card number in logs — PCI DSS violation
@Slf4j
public class PaymentProcessor {
    public ChargeResult charge(PaymentRequest request) {
        log.debug("Processing card: number={}, expiry={}, cvv={}",
            request.getCardNumber(), request.getExpiry(), request.getCvv());
        // ...
    }
}
```

### SAFE — No card data in logs, use tokenized reference only

```java
// GOOD: only log the tokenized reference, never raw card data
@Slf4j
public class PaymentProcessor {
    public ChargeResult charge(PaymentRequest request) {
        log.info("Processing charge: tokenId={}, dealerId={}, amount={}",
            request.getPaymentTokenId(), request.getDealerId(), request.getAmount());
        // Card number, CVV, expiry never touch our logs
    }
}
```

---

### UNSAFE — MDC / structured logging leaking PII

```java
// BAD: putting phone number in MDC makes it appear in every subsequent log line
MDC.put("customerPhone", customer.getPhone());
MDC.put("customerEmail", customer.getEmail());
log.info("Processing request");
```

### SAFE — Only safe correlation IDs in MDC

```java
// GOOD: correlation IDs only — trace back to PII via internal lookup if needed
MDC.put("customerId", customer.getPublicId().toString());
MDC.put("dealerId", String.valueOf(ctx.getDealerId()));
MDC.put("requestId", requestId);
log.info("Processing request");
```

---

## 4. UUID Usage vs. Primary Key Exposure

### UNSAFE — DB primary key in API URL and response

```java
// BAD: sequential Long IDs allow enumeration
@GetMapping("/messages/{messageId}")
public ResponseEntity<Message> getMessage(@PathVariable Long messageId) {
    return ResponseEntity.ok(messageRepo.findById(messageId).orElseThrow());
}

// BAD: entity returned directly exposes the DB PK
@Data
@Entity
public class Message {
    private Long id;         // DB PK — exposed in JSON response
    private String content;
    private Long dealerId;   // Also exposed
}
```

### SAFE — UUID as external identifier, PK hidden

```java
// GOOD: UUID-based lookup, entity DTO strips internal IDs
@GetMapping("/messages/{messageUuid}")
@PreAuthorize("isAuthenticated()")
public ResponseEntity<MessageResponse> getMessage(
        @AuthenticationPrincipal DealerContext ctx,
        @PathVariable UUID messageUuid) {
    Message msg = messageRepo.findByPublicIdAndDealerId(messageUuid, ctx.getDealerId())
        .orElseThrow(() -> new ResourceNotFoundException("Message not found"));
    return ResponseEntity.ok(MessageResponse.from(msg));
}

// Entity with both internal PK and external UUID
@Data
@Entity
public class Message {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @JsonIgnore                    // Never serialize the PK
    private Long id;

    @Column(unique = true, nullable = false)
    private UUID publicId = UUID.randomUUID();  // Stable external identifier

    private String content;

    @JsonIgnore
    private Long dealerId;         // Internal routing — never expose
}

// Response DTO — only safe fields
@Data
public class MessageResponse {
    private UUID id;               // publicId mapped here
    private String content;
    private Instant createdAt;
    // dealerId, internal id — never included

    public static MessageResponse from(Message msg) {
        MessageResponse r = new MessageResponse();
        r.setId(msg.getPublicId());
        r.setContent(msg.getContent());
        r.setCreatedAt(msg.getCreatedAt());
        return r;
    }
}
```

---

## 5. Input Validation Patterns

### UNSAFE — @RequestBody without @Valid

```java
// BAD: no validation — null fields, oversized strings, invalid email accepted
@PostMapping("/customers")
public ResponseEntity<CustomerResponse> create(@RequestBody CustomerRequest request) {
    return ResponseEntity.ok(customerService.create(request));
}

public class CustomerRequest {
    private String name;
    private String email;
    private String phone;
}
```

### SAFE — @Valid with Bean Validation constraints

```java
// GOOD: validation enforced before the method body runs
@PostMapping("/customers")
public ResponseEntity<CustomerResponse> create(
        @Valid @RequestBody CustomerRequest request) {
    return ResponseEntity.ok(customerService.create(request));
}

public class CustomerRequest {
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100, message = "Name must be 2–100 characters")
    private String name;

    @NotBlank(message = "Email is required")
    @Email(message = "Must be a valid email address")
    private String email;

    @Pattern(regexp = "^\\+?[1-9]\\d{9,14}$", message = "Must be a valid phone number")
    private String phone;  // Optional but validated if provided
}

// Global handler for validation errors
@ControllerAdvice
public class ValidationExceptionHandler {
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleValidationError(MethodArgumentNotValidException ex) {
        List<String> errors = ex.getBindingResult().getFieldErrors().stream()
            .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
            .collect(Collectors.toList());
        return new ErrorResponse("Validation failed", errors);
    }
}
```

---

## 6. File Upload Security

### UNSAFE — Accepting any file, any name, any size

```java
// BAD: path traversal possible, no type validation, no size limit
@PostMapping("/upload")
public ResponseEntity<String> upload(
        @RequestParam("file") MultipartFile file) throws IOException {
    String filename = file.getOriginalFilename();  // User-controlled!
    file.transferTo(new File("/var/uploads/" + filename));
    return ResponseEntity.ok("Uploaded: " + filename);
}
```

### SAFE — Type allowlist, UUID name, S3 storage

```java
// GOOD: strict type checking, UUID-based storage key, S3 (no local FS)
@PostMapping("/upload")
@PreAuthorize("isAuthenticated()")
public ResponseEntity<UploadResponse> upload(
        @AuthenticationPrincipal DealerContext ctx,
        @RequestParam("file") MultipartFile file) throws IOException {

    // 1. Enforce size limit (also set spring.servlet.multipart.max-file-size=10MB)
    if (file.getSize() > 10 * 1024 * 1024) {
        throw new ValidationException("File size exceeds 10MB limit");
    }

    // 2. Validate MIME type against allowlist (don't trust file extension)
    String contentType = file.getContentType();
    Set<String> allowed = Set.of("image/jpeg", "image/png", "image/gif", "application/pdf");
    if (contentType == null || !allowed.contains(contentType)) {
        throw new ValidationException("File type not allowed: " + contentType);
    }

    // 3. Generate a safe storage key — never use original filename
    String extension = switch (contentType) {
        case "image/jpeg" -> ".jpg";
        case "image/png"  -> ".png";
        case "image/gif"  -> ".gif";
        default           -> ".pdf";
    };
    String s3Key = "uploads/" + ctx.getDealerId() + "/" + UUID.randomUUID() + extension;

    // 4. Store in S3 — no local filesystem
    s3Client.putObject(PutObjectRequest.builder()
        .bucket(uploadsBucket)
        .key(s3Key)
        .contentType(contentType)
        .build(), RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

    return ResponseEntity.ok(new UploadResponse(s3Key));
}
```

---

## 7. Mass Assignment Prevention

### UNSAFE — Entity bound directly from request, or DTO with ignoreUnknown

```java
// BAD option 1: entity bound directly from request
@PostMapping("/profiles")
public ResponseEntity<User> updateProfile(@RequestBody User user) {
    // Attacker can set user.role = "ADMIN", user.dealerId = 999
    return ResponseEntity.ok(userRepo.save(user));
}

// BAD option 2: ignoreUnknown on input DTO allows silently ignoring injected fields
@JsonIgnoreProperties(ignoreUnknown = true)
public class UpdateProfileRequest {
    private String displayName;
    // role and active are not declared — but if they map to a mutable entity field
    // and BeanUtils.copyProperties is used, they can be set
}
```

### SAFE — Minimal DTO, explicit mapping

```java
// GOOD: DTO contains only the fields users are allowed to mutate
public class UpdateProfileRequest {
    @NotBlank @Size(max = 100)
    private String displayName;

    @Size(max = 500)
    private String bio;

    // role, dealerId, active, passwordHash — NEVER here
}

// Explicit mapping — never copy-all
@Service
public class UserService {
    public User updateProfile(Long userId, UpdateProfileRequest req) {
        User user = userRepo.findById(userId).orElseThrow();
        // Only update the fields that are allowed to change
        user.setDisplayName(req.getDisplayName());
        user.setBio(req.getBio());
        // user.role, user.dealerId are never touched here
        return userRepo.save(user);
    }
}
```

---

## 8. CORS Configuration

### UNSAFE — Wildcard origin

```java
// BAD: allows any website to make credentialed requests to your API
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.addAllowedOrigin("*");
    config.addAllowedMethod("*");
    config.addAllowedHeader("*");
    // ...
}

// Also bad — per-controller @CrossOrigin with wildcard
@CrossOrigin(origins = "*")
@RestController
public class DealerController { ... }
```

### SAFE — Explicit origin allowlist

```java
// GOOD: explicit allowlist, credentials enabled, methods enumerated
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of(
        "https://app.mykaarma.com",
        "https://dealer.mykaarma.com",
        "https://dealer-portal.mykaarma.com"
    ));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
    config.setAllowedHeaders(List.of("Content-Type", "Authorization", "X-Idempotency-Key"));
    config.setAllowCredentials(true);   // Required for mkid cookie
    config.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}
```

---

## Quick Reference: Severity by Pattern

| Pattern | Severity | Phase |
|---------|----------|-------|
| JPQL/SQL string concatenation | CRITICAL | 3 |
| Missing @PreAuthorize on endpoint | CRITICAL | 1 |
| Dealer ID from request body (not auth ctx) | CRITICAL | 1 |
| Hardcoded credentials/API keys | CRITICAL | 4 |
| Payment card data in logs | CRITICAL | 4 |
| mkid cookie auth bypassed | CRITICAL | 1 |
| DB primary key in API URL | HIGH | 1 |
| @RequestBody without @Valid | HIGH | 2 |
| File upload without type validation | HIGH | 2 |
| MongoDB Criteria injection | HIGH | 3 |
| PII (phone/email) in log statements | HIGH | 4 |
| CORS wildcard origin | HIGH | 5 |
| Missing rate limiting on OTP/login | HIGH | 5 |
| Mass assignment via broad DTO | HIGH | 5 |
| Actuator endpoints exposed | HIGH | 6 |
| Debug endpoints without @Profile | MEDIUM | 6 |
