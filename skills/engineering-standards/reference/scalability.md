# Reference: Scalability Patterns

## Soft Deletes

Never hard-delete primary entities. Use a boolean flag (`isValid`):

```java
// On delete — flip the flag, never run DELETE
@Modifying
@Transactional
@Query("UPDATE GVM g SET g.isValid = false WHERE g.uuid = :uuid")
void softDeleteByUuid(@Param("uuid") String uuid);

// On all queries — always append isValid = true
Optional<GVM> findByUuidAndIsValidTrue(String uuid);
List<GVM> findAllByIsValidTrue();
```

```sql
-- Index: always compound with isValid so the filter is free
CREATE INDEX idx_gvms_uuid_valid ON gvms (uuid, is_valid);
```

## Pagination — Always

Every list endpoint must be paginated. No exceptions.

```
Request:  GET /v1/gvms?offset=0&limit=25
Response: { "gvms": [...], "totalCount": 142, "offset": 0, "limit": 25 }

Default limit: 25
Maximum limit: 100 (enforced server-side — ignore client requests above this)
```

## Database Indexes

Index every column that appears in a `WHERE` clause:

```sql
CREATE UNIQUE INDEX idx_gvms_uuid ON gvms (uuid);
CREATE INDEX idx_gvms_uuid_valid ON gvms (uuid, is_valid);
CREATE INDEX idx_gvms_type_id ON gvms (gvm_type_id);
CREATE INDEX idx_gvms_status_valid ON gvms (status, is_valid);
```

## Caching

Cache expensive or frequently-read, rarely-changing data:

```java
@Service
public class GvmTypesService {

    @Cacheable(value = "gvmTypes", key = "'all'")
    public List<GvmTypeDTO> getAllGvmTypes() {
        return gvmTypesRepository.findAllByIsValidTrue()
            .stream().map(gvmTypesMapper::toDTO).toList();
    }

    @CacheEvict(value = "gvmTypes", allEntries = true)
    public GvmTypeDTO createGvmType(GvmTypeCreateRequest request) {
        GvmTypes saved = gvmTypesRepository.save(gvmTypesMapper.toEntity(request));
        return gvmTypesMapper.toDTO(saved);
    }
}
```

```yaml
spring:
  cache:
    type: redis           # or caffeine for in-process
  redis:
    host: ${redis.host}
    port: ${redis.port}
```

Cache candidates: lookup tables, user permission lists, configuration that changes infrequently.
Do **not** cache mutable entity state.

## Async Offloading

Never block HTTP threads on slow work. Target: HTTP handlers complete in < 500ms.

```
HTTP Request → Controller: validate + persist + publish → 202 Accepted
                                              ↓
                                      Message Queue
                                              ↓
                                      Worker: slow work
                                              ↓
                                      WebSocket / PubNub → Frontend
```

## Database Connection Pooling

### Pool Sizing Formula (Little's Law)

Calculate optimal pool size using:
```
connections_needed ≈ λ (borrow/s) × W (sec)
maxPoolSize ≈ ⌈(λ × W) × H⌉

Where:
- λ = throughput (connection borrows per second)
- W = connection hold time (average query duration)
- H = headroom factor (1.2–1.5)
```

**Example Calculation:**
```
Average borrow rate per pod: 700/sec
Average query time: 30ms (0.03s)
Pool size = 700 × 0.030 = 21 connections per pod
Max pool size = 21 × 1.5 = 32 connections per pod
```

### Monitoring Pool Metrics

Find λ (borrow rate) from Grafana:
```
<internal-grafana-url>/jvm-micrometer-eks
Panel: "HikariCP Connection Borrow Rate" (max per pod over 2min)
```

Find W (query duration) from Grafana:
```
Panel: "HikariCP Connection Usage Time" (average query time)
Usually 20-30ms for typical queries
```

### Spring Boot 2.x Configuration (HikariCP)

**Standard Configuration:**
```yaml
spring:
  datasource:
    type: com.zaxxer.hikari.HikariDataSource
    hikari:
      pool-name: myKaarmaDBPool
      maximum-pool-size: 35          # Based on Little's Law calculation
      minimum-idle: 15               # ~40% of max pool size
      idle-timeout: 180000           # 3 minutes
      connection-timeout: 5000       # 5 seconds (fail fast)
      validation-timeout: 5000       # 5 seconds
      max-lifetime: 240000           # 4 minutes
      leak-detection-threshold: 9000  # 9 seconds
      allow-pool-suspension: true
      
      # MySQL Optimization Properties
      data-source-properties:
        useServerPrepStmts: true              # Use server-side prepared statements
        cachePrepStmts: true                  # Cache prepared statements
        prepStmtCacheSize: 250                # Number of statements to cache
        prepStmtCacheSqlLimit: 2048           # Max SQL length to cache
        useLocalSessionState: true           # Track state locally
        rewriteBatchedStatements: true       # Optimize batch operations
        cacheResultSetMetadata: true         # Cache column metadata
        cacheServerConfiguration: true      # Cache server config
        elideSetAutoCommits: true           # Skip redundant autocommit calls
```

**Legacy kaarma-services (c3p0) - Avoid for New Services:**
```dockerfile
# Override in Dockerfile (max 50 connections)
RUN sed -i "s/max_size\">50</max_size\">5</g" /etc/kaarmaconfig-prod/hibernate.cfg.xml
```

### Key Configuration Rules

**Pool Sizing:**
- Keep Tomcat threads / HikariCP connections ≤ 5:1 ratio
- Use separate pools for API endpoints vs queue listeners when possible
- Monitor pending connections - should rarely exceed 0

**Timeout Settings:**
- `connection-timeout: 5000` - Fail fast to prevent service degradation
- `max-lifetime: 240000` - 4 minutes (less than MySQL wait_timeout)
- `leak-detection-threshold: 9000` - Detect connection leaks

**MySQL Optimizations:**
- `useServerPrepStmts: true` - Server prepares once, client sends parameters
- `cachePrepStmts: true` - Reduces parsing overhead
- `rewriteBatchedStatements: true` - Massive speedup for batch operations

### Query Timeout (Use with Caution)

For API microservices with SLA < 10 seconds:
```yaml
spring:
  jpa:
    properties:
      jakarta.persistence.query.timeout: 5000  # 5 seconds
```

Or per-query:
```java
@QueryHints(value = {@QueryHint(name = "jakarta.persistence.query.timeout", value = "5000")})
List<Employee> findActiveEmployees(long inactiveDaysThreshold);
```

**⚠️ Warning:** Avoid on batch processing services with long-running queries.

### Monitoring and Validation

**Actuator Endpoints:**
```
/actuator/metrics/hikaricp.connections.max
/actuator/metrics/hikaricp.connections.active
/actuator/prometheus  # If micrometer dependency added
```

**Critical Metrics to Monitor:**
- Active connections vs max pool size
- Connection borrow rate
- Pending connection requests (should be ~0)
- Connection usage time
- Connection timeouts

### Deprecated Properties (Remove These)

Spring Boot 2.x ignores these legacy properties:
```yaml
# ❌ Remove these - no effect in Spring Boot 2.x
spring.datasource.max-active
spring.datasource.max-idle
spring.datasource.min-idle
spring.datasource.initial-size
spring.datasource.validation-query
spring.datasource.test-on-borrow
spring.datasource.test-on-return
spring.datasource.test-while-idle
spring.datasource.time-between-eviction-runs-millis
spring.datasource.min-evictable-idle-time-millis
spring.datasource.max-wait-millis
```

### HTTP Client Connection Pooling

For outbound HTTP calls:
```yaml
# RestTemplate / WebClient configuration
http:
  client:
    max-connections: 50
    keep-alive: true
    connect-timeout: 5s
    read-timeout: 30s
```

## Read Replica Pattern

For high-read services, route read-heavy queries to a MySQL slave/replica:

```
Primary DB  → writes, low-volume reads, anything requiring latest data
Slave DB    → reporting queries, bulk reads, analytics, search indexing

# Package convention
repository/           ← primary DB repositories
mkslave/repository/   ← slave DB repositories (read-only)
```

```java
// Slave repo (read-only, high-volume queries)
@Repository
public interface MessageSlaveRepository extends JpaRepository<Message, Long> {

    @Query(value = """
        SELECT * FROM messages
        WHERE dealer_id = :dealerId AND is_valid = 1
        ORDER BY id DESC
        LIMIT :limit OFFSET :offset
        """, nativeQuery = true)
    List<Message> searchMessages(@Param("dealerId") Long dealerId,
                                 @Param("offset") int offset,
                                 @Param("limit") int limit);
}
```

**Rule:** Never write to the slave. Any operation that modifies data must use the primary connection.
