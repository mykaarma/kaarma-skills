---
name: auditing-security
description: >
  Deep code security audit for Java/Spring Boot and TypeScript services. Covers auth/authz,
  input validation, SQL injection, PII exposure, and API security.
  Use when preparing for a security review, before a major release, or when a security concern is raised.
  Also trigger when the user says things like "audit this service for security", "security review before release",
  "check for vulnerabilities in the code", "is this endpoint secure?", "check for SQL injection",
  "check for PII in logs", or "audit our auth layer".
  Complements the vuln-scan skill (which covers CVEs and dependency scanning) — this skill focuses on
  application-level code patterns.
---

# Deep Code Security Audit — Java/Spring Boot & TypeScript

Perform a structured, phase-by-phase security audit of the target service. Each phase includes exact search commands, example findings, and actionable remediation.

---

## Before You Start

Establish context:

```bash
# Identify the project root and tech stack
ls pom.xml build.gradle package.json tsconfig.json 2>/dev/null

# Count Java controllers (scope of Phase 1–2)
find . -name "*Controller.java" | wc -l

# Count repository files (scope of Phase 3)
find . -name "*Repository.java" -o -name "*RepositoryImpl.java" | wc -l

# Identify config files for Phase 5
find . -name "SecurityConfig.java" -o -name "WebMvcConfigurer*.java" \
       -o -name "CorsConfig.java" 2>/dev/null
```

Announce scope: *"Found X controllers, Y repositories. Running 6-phase audit."*

---

## Phase 1: Auth & Authorization Audit

**Goal**: Ensure every endpoint is protected and dealer context is properly scoped.

### 1a. Verify mkid Cookie Auth (CRITICAL)

myKaarma services must authenticate via the `mkid` session cookie. Authorization header-based JWT auth is NOT the standard pattern and should be flagged.

```bash
# Flag: endpoints accepting Authorization header directly
grep -rn "Authorization" --include="*.java" \
  | grep -v "//\|test\|Test\|import\|@ApiImplicitParam\|@Parameter\|swagger" \
  | grep -i "getHeader\|@RequestHeader\|HttpHeaders"

# Flag: services rolling their own token parsing outside the gateway filter
grep -rn "Bearer\|parseJwt\|validateToken\|JwtUtil\|JwtService" \
  --include="*.java" \
  | grep -v "test\|Test\|import"

# Safe: cookie-based auth via filter/interceptor
grep -rn "mkid\|MkidCookie\|CookieAuthFilter\|DealerContextFilter" \
  --include="*.java"
```

**Finding (unsafe)**: `String token = request.getHeader("Authorization");`
**Safe pattern**: Auth resolved by upstream filter/interceptor; controller receives `@AuthenticatedDealer DealerContext ctx`.

**Severity**: CRITICAL — bypassing the standard auth mechanism can allow unauthenticated access.

**Remediation**: Remove any custom auth header parsing from controllers/services. Route all auth through the shared `mkid` cookie filter. If building a new internal service, use the standard `dealer-auth-spring-boot-starter`.

---

### 1b. Missing Authorization Guards (CRITICAL)

```bash
# Find all @RequestMapping/@GetMapping/@PostMapping etc. without @PreAuthorize nearby
# (Python one-liner to detect controller methods missing auth annotations)
python3 - <<'EOF'
import os, re, sys

controller_pattern = re.compile(r'@(Get|Post|Put|Delete|Patch|Request)Mapping')
auth_pattern = re.compile(r'@(PreAuthorize|Secured|RolesAllowed|WithMkidAuth|AuthRequired)')

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ['target', 'node_modules', '.git']]
    for f in files:
        if not f.endswith('Controller.java') and not f.endswith('Resource.java'):
            continue
        path = os.path.join(root, f)
        with open(path) as fh:
            lines = fh.readlines()
        for i, line in enumerate(lines):
            if controller_pattern.search(line):
                # Check the 5 lines before for an auth annotation
                window = lines[max(0, i-5):i+1]
                if not any(auth_pattern.search(l) for l in window):
                    print(f"{path}:{i+1}: UNGUARDED endpoint — {line.strip()}")
EOF

# Also check for class-level @PreAuthorize that might cover all methods
grep -rn "@PreAuthorize\|@Secured\|@RolesAllowed" --include="*.java" \
  | grep -v "test\|Test"
```

**Finding (unsafe)**:
```java
@PostMapping("/dealer/{dealerId}/settings")
public ResponseEntity<Settings> updateSettings(@PathVariable Long dealerId, ...) { ... }
```

**Safe pattern**:
```java
@PreAuthorize("hasRole('DEALER_ADMIN') and #dealerId == authentication.dealerId")
@PostMapping("/dealer/{dealerId}/settings")
public ResponseEntity<Settings> updateSettings(@PathVariable Long dealerId, ...) { ... }
```

**Severity**: CRITICAL

**Remediation**: Add `@PreAuthorize` at method or class level. For myKaarma services, prefer the shared `@WithDealerAuth` meta-annotation which validates the mkid cookie and injects dealer context.

---

### 1c. IDOR — Primary Keys in API (HIGH)

Using database primary keys (auto-increment longs) in API URLs lets attackers enumerate resources.

```bash
# Flag: Long/Integer path variables named *Id in controller methods
grep -rn "@PathVariable" --include="*.java" \
  | grep -E "Long|Integer|int\b|long\b" \
  | grep -iv "uuid\|test\|Test"

# Flag: response DTOs returning numeric 'id' fields
grep -rn "getId\(\)\|\.id\b" --include="*.java" \
  | grep "ResponseEntity\|@ResponseBody\|return\b" \
  | grep -v "test\|Test\|import"

# Safe: look for UUID usage
grep -rn "UUID\|@PathVariable.*uuid\|@PathVariable.*token" \
  --include="*.java" | grep -v "test\|Test"
```

**Finding (unsafe)**: `@GetMapping("/messages/{messageId}")` where `messageId` is a `Long` DB PK.
**Safe pattern**: `@GetMapping("/messages/{messageUuid}")` where the UUID is a stable external identifier.

**Severity**: HIGH

**Remediation**: Add a `public_id` UUID column to entities exposed via API. Map PKs to UUIDs in the repository layer; never expose numeric PKs in URLs or response bodies. Reference `patterns/java-security-patterns.md` for the UUID mapping pattern.

---

### 1d. Dealer Context Isolation (CRITICAL)

All data queries must be scoped to the authenticated dealer. Cross-dealer data leakage is a critical privacy violation.

```bash
# Flag: repository queries that do NOT include dealerId/dealerCode as a filter
# Look for findAll(), findBy* without dealer scoping
grep -rn "findAll\(\)\|findBy[^D]" --include="*Repository.java" \
  | grep -v "//\|test\|Test\|ByDealer\|AndDealer\|dealerId"

# Flag: @Query annotations missing dealer filter
grep -rn -A 2 "@Query" --include="*.java" \
  | grep -v "dealerId\|dealer_id\|dealerCode\|dealer_code\|test\|Test"

# Flag: service methods accepting arbitrary dealerId from request vs. from auth context
grep -rn "getDealerId\|dealerId" --include="*.java" \
  | grep "@RequestParam\|@PathVariable\|@RequestBody" \
  | grep -v "test\|Test"
```

**Finding (unsafe)**:
```java
// Takes dealerId from the path — attacker can supply any dealer
public List<Message> getMessages(@PathVariable Long dealerId) {
    return messageRepo.findByDealerId(dealerId);
}
```

**Safe pattern**:
```java
// dealerId always comes from authenticated context
public List<Message> getMessages(@AuthenticationPrincipal DealerContext ctx) {
    return messageRepo.findByDealerId(ctx.getDealerId());
}
```

**Severity**: CRITICAL

**Remediation**: Never trust a dealer ID from the request. Always derive it from the authenticated `DealerContext` injected by the auth filter. Validate path `dealerId` params against `ctx.getDealerId()` when they must be present in the URL for routing.

---

## Phase 2: Input Validation Audit

**Goal**: Every controller parameter that originates from user input must be validated.

### 2a. Missing @Valid on Request Bodies (HIGH)

```bash
# Flag: @RequestBody without @Valid
grep -rn "@RequestBody" --include="*.java" \
  | grep -v "@Valid\|@Validated\|test\|Test"

# Flag: controller methods with @RequestBody not using @Valid
python3 - <<'EOF'
import os, re

rb = re.compile(r'@RequestBody')
valid = re.compile(r'@(Valid|Validated)\b')

for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ['target', 'node_modules', '.git']]
    for f in files:
        if not f.endswith('Controller.java') and not f.endswith('Resource.java'):
            continue
        path = os.path.join(root, f)
        text = open(path).read()
        # Find method signatures containing @RequestBody without @Valid nearby
        for m in rb.finditer(text):
            # grab preceding 100 chars in same parameter list
            snippet = text[max(0, m.start()-100):m.end()]
            if not valid.search(snippet):
                line = text[:m.start()].count('\n') + 1
                print(f"{path}:{line}: @RequestBody missing @Valid")
EOF
```

**Finding (unsafe)**:
```java
@PostMapping("/customers")
public ResponseEntity<Customer> create(@RequestBody CustomerRequest req) { ... }
```

**Safe pattern**:
```java
@PostMapping("/customers")
public ResponseEntity<Customer> create(@Valid @RequestBody CustomerRequest req) { ... }
// CustomerRequest uses: @NotNull, @NotBlank, @Size, @Email, etc.
```

**Severity**: HIGH

**Remediation**: Add `@Valid` before every `@RequestBody` parameter. Add Bean Validation constraints (`@NotNull`, `@NotBlank`, `@Size`, `@Pattern`) to DTO fields. Add a global `@ControllerAdvice` that catches `MethodArgumentNotValidException` and returns 400.

---

### 2b. Path Traversal in File Operations (HIGH)

```bash
# Flag: user-supplied input passed to file operations
grep -rn "new File\|Paths.get\|FileInputStream\|FileOutputStream\|new FileWriter" \
  --include="*.java" \
  | grep -v "//\|test\|Test\|classpath\|getResourceAsStream"

# Flag: filename coming from request params
grep -rn "@RequestParam.*[Ff]ile[Nn]ame\|@RequestParam.*[Pp]ath\|@PathVariable.*[Ff]ile" \
  --include="*.java" \
  | grep -v "test\|Test"
```

**Finding (unsafe)**:
```java
String filename = request.getParameter("filename");
File file = new File("/var/uploads/" + filename); // path traversal: ../../etc/passwd
```

**Safe pattern**:
```java
String filename = request.getParameter("filename");
Path safeBase = Paths.get("/var/uploads").toRealPath();
Path requested = safeBase.resolve(filename).normalize();
if (!requested.startsWith(safeBase)) {
    throw new SecurityException("Path traversal attempt detected");
}
```

**Severity**: HIGH

**Remediation**: Always normalize and validate file paths against an allowed base directory. Use `Path.normalize()` + `Path.startsWith(baseDir)`. Store user uploads in S3 with generated keys — never with user-supplied names.

---

### 2c. File Upload Validation (HIGH)

```bash
# Flag: multipart file uploads without size or type checks
grep -rn "MultipartFile\|@RequestPart" --include="*.java" \
  | grep -v "test\|Test"

# Check for missing content-type validation
grep -rn "getOriginalFilename\|getContentType\|getSize" --include="*.java" \
  | grep -v "test\|Test"
```

**Finding (unsafe)**:
```java
@PostMapping("/upload")
public ResponseEntity<String> upload(@RequestParam MultipartFile file) {
    file.transferTo(new File("/var/uploads/" + file.getOriginalFilename()));
    return ResponseEntity.ok("uploaded");
}
```

**Safe pattern**:
```java
private static final Set<String> ALLOWED_TYPES = Set.of("image/jpeg", "image/png", "application/pdf");
private static final long MAX_SIZE = 10 * 1024 * 1024; // 10MB

@PostMapping("/upload")
public ResponseEntity<String> upload(@RequestParam MultipartFile file) {
    if (file.getSize() > MAX_SIZE) throw new ValidationException("File too large");
    if (!ALLOWED_TYPES.contains(file.getContentType())) throw new ValidationException("Invalid file type");
    String safeKey = UUID.randomUUID() + getExtension(file.getContentType());
    s3Client.putObject(bucket, safeKey, file.getInputStream());
    return ResponseEntity.ok(safeKey);
}
```

**Severity**: HIGH

**Remediation**: Validate content-type against an allowlist (not the user-supplied `getOriginalFilename()` extension — it can be spoofed). Enforce size limits. Store in S3 with UUID-generated keys. Set `spring.servlet.multipart.max-file-size` and `max-request-size` in `application.properties`.

---

## Phase 3: SQL Injection Audit

**Goal**: All database queries must use parameterized inputs. No string concatenation in query construction.

### 3a. String Concatenation in JPQL/HQL (CRITICAL)

```bash
# Flag: string concatenation inside @Query or query builder methods
grep -rn -A 3 "@Query" --include="*.java" \
  | grep '"+\|+ "' \
  | grep -v "//\|test\|Test"

# Flag: EntityManager createQuery with concatenation
grep -rn "createQuery\|createNativeQuery" --include="*.java" \
  | grep '"+\|+ "' \
  | grep -v "//\|test\|Test"

# Flag: Criteria API misuse (string literal mixed with variable)
grep -rn "CriteriaBuilder\|CriteriaQuery" --include="*.java" \
  -A 5 | grep '"+\|+ "' | grep -v "test\|Test"
```

**Finding (unsafe)**:
```java
String jpql = "SELECT c FROM Customer c WHERE c.email = '" + email + "'";
List<Customer> results = em.createQuery(jpql).getResultList();
```

**Safe pattern**:
```java
@Query("SELECT c FROM Customer c WHERE c.email = :email")
List<Customer> findByEmail(@Param("email") String email);
// or with EntityManager:
em.createQuery("SELECT c FROM Customer c WHERE c.email = :email", Customer.class)
  .setParameter("email", email)
  .getResultList();
```

**Severity**: CRITICAL

**Remediation**: Always use named parameters (`:param`) or positional parameters (`?1`) in JPQL. Never build query strings via concatenation. Spring Data repository methods with `@Query` and `@Param` are the preferred pattern.

---

### 3b. Unparameterized Native Queries (CRITICAL)

```bash
# Flag: native SQL with concatenation
grep -rn "createNativeQuery\|nativeQuery = true" --include="*.java" \
  -A 3 | grep '"+\|+ "\|String.format\|String.join' \
  | grep -v "//\|test\|Test"

# Flag: JdbcTemplate with string building
grep -rn "jdbcTemplate\|NamedParameterJdbcTemplate" --include="*.java" \
  -A 3 | grep '"+\|+ "\|String.format' \
  | grep -v "//\|test\|Test"

# Flag: MyBatis dynamic SQL with unescaped ${} (should be #{})
grep -rn '\${' --include="*.xml" --include="*.java" \
  | grep -iv "test\|Test\|spring\|logback\|maven"
```

**Finding (unsafe)**:
```java
// MyBatis — ${} interpolates directly; #{} parameterizes
String sql = "SELECT * FROM messages WHERE dealer_id = " + dealerId;
jdbcTemplate.query(sql, rowMapper);
```

**Safe pattern**:
```java
// JdbcTemplate — use ? placeholders
String sql = "SELECT * FROM messages WHERE dealer_id = ?";
jdbcTemplate.query(sql, rowMapper, dealerId);

// NamedParameterJdbcTemplate
String sql = "SELECT * FROM messages WHERE dealer_id = :dealerId";
namedJdbcTemplate.query(sql, Map.of("dealerId", dealerId), rowMapper);
```

**Severity**: CRITICAL

**Remediation**: For `JdbcTemplate`, always use `?` placeholders. For `NamedParameterJdbcTemplate`, use `:name` params. For MyBatis, use `#{}` (not `${}`). Review all `nativeQuery = true` annotations — each one is a potential vector.

---

### 3c. MongoDB Query Injection (HIGH)

```bash
# Flag: user input passed to $where or raw query Document
grep -rn '\$where\|BasicDBObject\|Document.*user\|Query.*user' \
  --include="*.java" \
  | grep -v "//\|test\|Test\|import"

# Flag: MongoTemplate with string-based queries
grep -rn "mongoTemplate.find\|mongoTemplate.findOne\|mongoTemplate.aggregate" \
  --include="*.java" -A 3 \
  | grep 'query\|where\|criteria' \
  | grep '"+\|+ "' \
  | grep -v "test\|Test"
```

**Finding (unsafe)**:
```java
// Attacker can inject: {"$gt": ""} to match all documents
BasicQuery query = new BasicQuery("{ \"username\": \"" + username + "\" }");
mongoTemplate.findOne(query, User.class);
```

**Safe pattern**:
```java
// Use Spring Data MongoDB Criteria — never string-interpolate into query docs
Query query = new Query(Criteria.where("username").is(username));
mongoTemplate.findOne(query, User.class);
// Or use MongoRepository derived query methods
userRepository.findByUsername(username);
```

**Severity**: HIGH

**Remediation**: Use Spring Data MongoDB `Criteria` API or repository derived query methods exclusively. Never construct query JSON strings from user input. Avoid `$where` clauses entirely — they execute JavaScript server-side.

---

## Phase 4: Sensitive Data Audit

**Goal**: No PII, credentials, or payment data in logs or API responses.

### 4a. PII in Log Statements (HIGH)

```bash
# Flag: phone numbers in logs
grep -rn "log\.\(debug\|info\|warn\|error\)" --include="*.java" \
  | grep -Ei "phone\|mobile\|cell\|msisdn\|getPhone\|phoneNumber\|mobileNumber"

# Flag: email addresses in logs
grep -rn "log\.\(debug\|info\|warn\|error\)" --include="*.java" \
  | grep -Ei "email\|getEmail\|emailAddress"

# Flag: customer names in logs
grep -rn "log\.\(debug\|info\|warn\|error\)" --include="*.java" \
  | grep -Ei "getName\|firstName\|lastName\|customerName\|fullName"

# Flag: SLF4J/Logback structured logging with PII fields
grep -rn "MDC.put\|withContext\|structuredArguments" --include="*.java" \
  | grep -Ei "phone\|email\|name\|ssn\|dob\|address"
```

**Finding (unsafe)**:
```java
log.info("Sending message to customer: phone={}, email={}", customer.getPhone(), customer.getEmail());
```

**Safe pattern**:
```java
log.info("Sending message to customerId={}", customer.getId());
// For debugging PII issues in dev/staging only, use a mask utility:
log.debug("Sending message to phone={}", MaskUtils.maskPhone(customer.getPhone()));
```

**Severity**: HIGH — violates CCPA/PII handling requirements.

**Remediation**: Replace PII in log messages with opaque identifiers (customer UUID, internal ID). If correlation is needed for debugging, log the ID and let support look up PII separately. Add a `MaskUtils` utility for masked logging in debug-level statements only.

---

### 4b. Hardcoded Credentials & API Keys (CRITICAL)

```bash
# Flag: hardcoded passwords
grep -rn "password\s*=\s*[\"'][^\"']\+[\"']" --include="*.java" \
  | grep -v "//\|test\|Test\|placeholder\|example\|changeme\|TODO"

# Flag: hardcoded API keys
grep -rn -Ei "apiKey\s*=\s*[\"'][A-Za-z0-9+/]{16,}[\"']\|api.key\s*=\s*[\"'][^\"']+[\"']" \
  --include="*.java" --include="*.properties" --include="*.yml" \
  | grep -v "test\|Test\|\${" # ${} means it's injected from env

# Flag: AWS credentials
grep -rn "AKIA[0-9A-Z]\{16\}\|aws_secret_access_key\s*=" \
  --include="*.java" --include="*.properties" --include="*.yml" \
  --include="*.xml" | grep -v "test\|Test"

# Flag: Twilio/SendGrid/Stripe keys
grep -rn -E "SK[0-9a-f]{32}|AC[0-9a-f]{32}|pk_live_|sk_live_|SG\." \
  --include="*.java" --include="*.properties" --include="*.yml" \
  | grep -v "test\|Test"

# Check git history for secrets (recent 100 commits)
git log --all --oneline -100 | while read hash msg; do
  git show "$hash" -- '*.java' '*.properties' '*.yml' 2>/dev/null \
  | grep -E "password\s*=\s*['\"][^'\"]|apiKey\s*=\s*['\"][^'\"]|AKIA[A-Z0-9]{16}" \
  && echo "Found in commit: $hash $msg"
done 2>/dev/null | head -30
```

**Severity**: CRITICAL — rotate the credential immediately if found.

**Remediation**: All credentials must be injected via environment variables or AWS Secrets Manager. In `application.properties`/`application.yml`, use `${ENV_VAR_NAME}` placeholders. Add `.env` and `application-local.properties` to `.gitignore`. If a secret was committed, assume it is compromised — rotate it before removing it from history.

---

### 4c. Sensitive Fields in API Responses (HIGH)

```bash
# Flag: fields that should never be serialized to API responses
grep -rn "password\|passwordHash\|saltedPassword\|cardNumber\|cvv\|ssn\|taxId" \
  --include="*.java" \
  | grep -v "@JsonIgnore\|@JsonProperty.*access.*READ\|//\|test\|Test\|import"

# Flag: entity classes with no @JsonIgnore on sensitive fields
grep -rn "class.*Entity\|@Entity\b" --include="*.java" -l \
  | xargs grep -L "@JsonIgnore\|@JsonProperty\|DTO" 2>/dev/null

# Flag: internal system IDs exposed
grep -rn "getInternalId\|getDatabaseId\|getPrimaryKey" --include="*.java" \
  | grep -v "//\|test\|Test\|import"
```

**Finding (unsafe)**:
```java
@Entity
public class Customer {
    private Long id;           // DB primary key — never expose
    private String passwordHash; // Should never serialize
    private String cardLast4;    // Needs @JsonIgnore or separate DTO
}
```

**Safe pattern**:
```java
@Entity
public class Customer {
    @JsonIgnore
    private Long id;
    @JsonIgnore
    private String passwordHash;
}

// Separate response DTO
public class CustomerResponse {
    private UUID publicId;
    private String displayName;
    // card data NEVER included
}
```

**Severity**: HIGH

**Remediation**: Use separate response DTOs — never serialize JPA entities directly. Add `@JsonIgnore` to all sensitive entity fields as a backstop. Use `@JsonView` or MapStruct to control what surfaces in each API context.

---

### 4d. Payment Card Data in Logs (CRITICAL)

```bash
# Flag: any logging near card-related fields
grep -rn "log\.\(debug\|info\|warn\|error\)" --include="*.java" \
  | grep -Ei "card\|pan\|cvv\|cvc\|expiry\|cardNumber\|accountNumber\|routing"

# Flag: card data in exception messages (which often get logged)
grep -rn "new.*Exception\|throw new" --include="*.java" \
  | grep -Ei "card\|pan\|cvv\|payment\|account"

# Flag: request logging middleware that might capture payment bodies
grep -rn "ContentCachingRequestWrapper\|requestBody\|getBody\|logRequest\|RequestLoggingFilter" \
  --include="*.java" | grep -v "test\|Test"
```

**Severity**: CRITICAL — PCI DSS violation. Card data must NEVER appear in logs, traces, or exception messages.

**Remediation**: Mask all card fields before any logging. Use a tokenization service (e.g., Stripe, Braintree) — never store or log raw card numbers. If using a request-logging filter, add a field-level blocklist for payment endpoints. File a PCI compliance report if card data is found in logs.

---

## Phase 5: API Security Audit

**Goal**: Proper CORS, rate limiting, no mass assignment, and financial endpoint safeguards.

### 5a. CORS Configuration (HIGH)

```bash
# Flag: wildcard CORS origin
grep -rn "allowedOrigins\|addAllowedOrigin\|@CrossOrigin" --include="*.java" \
  | grep '"[*]"\|\*'

# Flag: @CrossOrigin on individual controllers (should be centralized)
grep -rn "@CrossOrigin" --include="*.java" \
  | grep -v "test\|Test"

# Flag: Spring Security CORS config
grep -rn "cors()\|CorsConfiguration\|CorsConfigurationSource" --include="*.java" \
  -A 5 | grep "allowedOrigins\|setAllowedOrigins"
```

**Finding (unsafe)**:
```java
@CrossOrigin(origins = "*")   // allows any domain
@RestController
public class PaymentController { ... }
```

**Safe pattern**:
```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of(
        "https://app.mykaarma.com",
        "https://dealer.mykaarma.com"
    ));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    config.setAllowCredentials(true);
    // ...
}
```

**Severity**: HIGH

**Remediation**: Define an explicit CORS allowlist in `SecurityConfig`. Never use `*` for origins, especially on authenticated endpoints. Remove `@CrossOrigin` from individual controllers — centralize it in `WebMvcConfigurer` or Spring Security.

---

### 5b. Rate Limiting on Sensitive Endpoints (HIGH)

```bash
# Flag: auth/OTP/password endpoints without rate limiting
grep -rn "@PostMapping\|@GetMapping" --include="*.java" \
  | grep -Ei "login\|otp\|password.*reset\|forgot.*password\|verify.*phone\|send.*code"

# Check if Bucket4j, resilience4j, or custom rate limiter is in use
grep -rn "RateLimiter\|Bucket4j\|@RateLimited\|rateLimitFilter\|redis.*rate" \
  --include="*.java" | grep -v "test\|Test"

grep "bucket4j\|resilience4j\|rate.limit" pom.xml build.gradle 2>/dev/null
```

**Finding (unsafe)**: An `/api/otp/send` endpoint with no rate limiting — attacker can trigger 10,000 OTP messages to a victim's phone.

**Safe pattern**:
```java
@PostMapping("/otp/send")
@RateLimited(key = "#request.remoteAddr", limit = 5, window = "1m")
public ResponseEntity<Void> sendOtp(@Valid @RequestBody OtpRequest request) { ... }
```

**Severity**: HIGH

**Remediation**: Apply rate limiting via Bucket4j + Redis (or AWS API Gateway throttling) on all: login endpoints, OTP send/verify, password reset, and payment initiation endpoints. Track by IP and by customer/dealer ID. Alert on threshold breaches via Zenduty.

---

### 5c. Mass Assignment via @JsonIgnoreProperties (HIGH)

```bash
# Flag: @JsonIgnoreProperties(ignoreUnknown = true) on request DTOs
# This is fine on response objects but dangerous on input DTOs — extra fields are silently accepted
grep -rn "@JsonIgnoreProperties(ignoreUnknown = true)" --include="*.java" \
  | grep -Ei "Request|Command|Form|Input|Body" \
  | grep -v "test\|Test"

# Flag: Spring MVC binding allowing extra fields (no explicit allowedFields)
grep -rn "setAllowedFields\|setDisallowedFields\|DataBinder" --include="*.java" \
  | grep -v "test\|Test"
```

**Finding (unsafe)**:
```java
// Attacker can POST {"role": "ADMIN", "dealerId": 999} and it gets bound silently
@JsonIgnoreProperties(ignoreUnknown = true)
public class UpdateProfileRequest {
    private String displayName;
    // role and dealerId not declared here, but if they exist on the entity they can be set
}
```

**Safe pattern**:
```java
// Explicit DTO with ONLY the fields that should be settable by users
public class UpdateProfileRequest {
    @NotBlank @Size(max = 100)
    private String displayName;
    // Role, dealerId, etc. are never here
}
// No @JsonIgnoreProperties needed — Jackson rejects unknown fields by default
// Or explicitly: @JsonIgnoreProperties(value = {"role","dealerId"}, allowSetters = false)
```

**Severity**: HIGH

**Remediation**: Keep request DTOs minimal — only the fields users are allowed to set. Do not use `ignoreUnknown = true` on input DTOs. Map from DTO to entity explicitly (never use `BeanUtils.copyProperties` for security-sensitive objects). Use MapStruct with an explicit ignore list for sensitive fields.

---

### 5d. Idempotency on Payment/Financial Endpoints (HIGH)

```bash
# Flag: payment/financial POST endpoints without idempotency key handling
grep -rn "@PostMapping" --include="*.java" \
  | grep -Ei "payment\|charge\|refund\|invoice\|transaction\|disburse\|pay"

# Check if idempotency key header is read
grep -rn "Idempotency-Key\|idempotencyKey\|X-Idempotency\|idempotent" \
  --include="*.java" | grep -v "test\|Test"
```

**Finding (unsafe)**: `POST /payments/charge` with no idempotency key — network retry creates duplicate charge.

**Safe pattern**:
```java
@PostMapping("/payments/charge")
public ResponseEntity<ChargeResult> charge(
    @RequestHeader("X-Idempotency-Key") String idempotencyKey,
    @Valid @RequestBody ChargeRequest request
) {
    return idempotencyService.executeOnce(idempotencyKey, () -> paymentService.charge(request));
}
```

**Severity**: HIGH

**Remediation**: Require `X-Idempotency-Key` header on all payment mutation endpoints. Store results in Redis keyed by `(dealerId, idempotencyKey)` with a 24h TTL. Return the cached result on duplicate requests. Document this in the API contract.

---

## Phase 6: Infrastructure & Framework Security

**Goal**: Ensure framework-level security settings are locked down in production.

### 6a. Spring Boot Actuator Exposure (HIGH)

```bash
# Flag: actuator endpoints exposed without auth
grep -rn "management.endpoints.web.exposure.include" \
  --include="*.properties" --include="*.yml" \
  | grep -v "health\|info\|#\|test"

# Flag: actuator on the same port as the app (should be on internal management port)
grep -rn "management.server.port\|management.endpoint" \
  --include="*.properties" --include="*.yml"

# Flag: /actuator/env, /actuator/heapdump, /actuator/mappings exposed
grep -rn "env\|heapdump\|mappings\|beans\|shutdown" \
  --include="*.properties" --include="*.yml" \
  | grep "management.endpoints\|exposure.include"
```

**Finding (unsafe)**:
```properties
management.endpoints.web.exposure.include=*
management.endpoint.env.enabled=true
```

**Safe pattern**:
```properties
# Only expose health and info publicly
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=when-authorized
# Run actuator on a separate internal port not reachable from the internet
management.server.port=8081
# Restrict actuator to internal network via Security config
```

**Severity**: HIGH — `/actuator/env` exposes environment variables including secrets; `/actuator/heapdump` can expose credentials from memory.

**Remediation**: Restrict actuator to `health` and `info` on the public port. Expose full actuator only on a management port (8081) that is blocked by the load balancer security group. Protect all sensitive actuator endpoints with role-based access: `management.endpoint.*.roles=ACTUATOR_ADMIN`.

---

### 6b. Debug Endpoints in Production Code (MEDIUM)

```bash
# Flag: debug/test endpoints that shouldn't reach production
grep -rn "@GetMapping\|@PostMapping\|@RequestMapping" --include="*.java" \
  | grep -Ei "debug\|test\|ping\|echo\|dump\|healthcheck\|internal.*test"

# Flag: @Profile("!production") — check if missing
grep -rn "@Profile\b" --include="*.java" | grep -v "test\|Test"

# Flag: endpoints with no auth that return server info
grep -rn "@GetMapping\|@PostMapping" --include="*.java" -A 5 \
  | grep -Ei "version|buildInfo|serverInfo|sysInfo|env|config" \
  | grep -v "test\|Test\|@PreAuthorize\|@Secured"
```

**Severity**: MEDIUM

**Remediation**: Annotate any debug/internal controller with `@Profile("!production")` to prevent it deploying to prod. Remove test endpoints entirely where possible. Use `/actuator/info` (properly restricted) rather than custom version endpoints.

---

### 6c. Defer to vuln-scan for CVE Scanning

For dependency-level CVEs, container image scanning, K8s misconfiguration, and secrets in git history, run the **vuln-scan** skill:

```
/vuln-scan
```

The auditing-security skill covers application code patterns; vuln-scan covers the supply chain and infrastructure layer.

---

## Audit Summary Format

After completing all phases, produce a findings summary:

```
## Security Audit Summary

**Service**: <name>
**Audit date**: <date>
**Phases completed**: 1–6

---

### CRITICAL Findings

| # | Phase | File | Line | Issue | Remediation |
|---|-------|------|------|-------|-------------|
| 1 | Auth  | PaymentController.java | 45 | Missing @PreAuthorize | Add @WithDealerAuth |
| 2 | SQL   | MessageRepo.java | 112 | JPQL string concat | Use @Param |

### HIGH Findings

| # | Phase | File | Line | Issue | Remediation |
|---|-------|------|------|-------|-------------|

### MEDIUM Findings

| # | Phase | File | Line | Issue | Remediation |
|---|-------|------|------|-------|-------------|

---

### Risk Score
- CRITICAL: X  →  Must fix before any production deployment
- HIGH: Y       →  Fix within current sprint
- MEDIUM: Z     →  Track in backlog, fix within 30 days

### Next Steps
1. File Jira tickets for each CRITICAL and HIGH finding (use /jira-create-ticket)
2. Re-run this audit after remediation to verify fixes
3. Run /vuln-scan for dependency CVE coverage
```

---

## Reference

See `patterns/java-security-patterns.md` in this skill directory for annotated safe vs. unsafe code examples for each category covered above.
