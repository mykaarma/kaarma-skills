# Reference: Testing Requirements

## Testing Pyramid

```
        /\
       /E2E\         Few — critical user flows only
      /------\
     /  Integ  \     Some — API endpoints, DB interactions
    /------------\
   /  Unit Tests  \  Many — all business logic
  /________________\
```

## Unit Tests

Test services and utilities in isolation. Mock all I/O (DB, HTTP, queues).

```java
@ExtendWith(MockitoExtension.class)
class GvmServiceTest {

    @Mock GvmRepository gvmRepository;
    @Mock RabbitMQPublisher publisher;
    @Mock GvmMapper gvmMapper;
    @InjectMocks GvmService gvmService;

    @Test
    void createGvm_nameAlreadyTaken_throwsBadArgumentsException() {
        GvmCreateRequest request = new GvmCreateRequest();
        request.setName("test-gvm");
        when(gvmRepository.existsByNameAndIsValidTrue("test-gvm")).thenReturn(true);

        BadArgumentsException ex = assertThrows(
            BadArgumentsException.class,
            () -> gvmService.createGvm(request)
        );
        assertThat(ex.getErrors().get(0).getErrorCode()).isEqualTo(ErrorCodes.GVM_NAME_TAKEN.getCode());
        verify(gvmRepository, never()).save(any());
    }

    @Test
    void createGvm_validRequest_savesAndPublishes() {
        GvmCreateRequest request = buildValidRequest();
        GVM saved = buildSavedEntity();
        when(gvmRepository.existsByNameAndIsValidTrue(any())).thenReturn(false);
        when(gvmRepository.save(any())).thenReturn(saved);
        when(gvmMapper.toDTO(saved)).thenReturn(new GvmDTO());

        gvmService.createGvm(request);

        verify(gvmRepository).save(any(GVM.class));
        verify(publisher).publishGvmCreated(saved.getUuid());
    }
}
```

- Cover the happy path + all validation/error branches
- Target 80%+ line coverage on service layer
- Tests should run in milliseconds — no real DB, HTTP, or queue connections

## Integration Tests

Test that your code works against real infrastructure (containerized via Docker / testcontainers):

```java
@SpringBootTest
@Testcontainers
class GvmRepositoryIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

    @Autowired GvmRepository gvmRepository;

    @Test
    void saveAndFindByUuid_returnsEntity() {
        GVM entity = new GVM();
        entity.setUuid("test-uuid");
        entity.setName("test-gvm");
        entity.setValid(true);
        gvmRepository.save(entity);

        Optional<GVM> found = gvmRepository.findByUuidAndIsValidTrue("test-uuid");
        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("test-gvm");
    }
}
```

- Never mock the database in integration tests — mock data, not infrastructure
- Use isolated test databases (separate schema or container per test run)
- Run integration tests in CI on every PR

## E2E Tests

Required for critical flows: GVM create/start/stop, user authentication, deployment triggers.

- Run against a real staging environment (not mocked)
- Part of the deployment gate — failing E2E blocks production deploys

## Test File Organization

```
server/
├── tests/
│   ├── unit/
│   │   ├── service/     # GvmService tests
│   │   └── util/        # Utility function tests
│   ├── integration/
│   │   ├── api/         # HTTP endpoint tests (real DB)
│   │   └── repository/  # Repository query tests
│   └── e2e/             # End-to-end flows
```
