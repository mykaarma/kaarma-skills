# Reference: Project Structure

## Monorepo Layout

```
<service-name>/
├── server/                  # Backend service
│   ├── src/
│   │   ├── controller/      # Request routing / handlers
│   │   ├── service/         # Business logic
│   │   ├── aggregator/      # Cross-service orchestration
│   │   ├── repository/      # Data access layer (DB queries)
│   │   ├── model/
│   │   │   ├── entity/      # DB-mapped models
│   │   │   ├── dto/         # Data transfer objects
│   │   │   ├── request/     # Inbound request shapes
│   │   │   ├── response/    # Outbound response shapes
│   │   │   └── enums/       # Enumerations & error codes
│   │   ├── mapper/          # Entity ↔ DTO conversion
│   │   ├── exception/       # Custom exception types
│   │   ├── config/          # Framework & infra configuration
│   │   ├── middleware/       # Auth, logging, rate-limit middleware
│   │   ├── scheduler/       # Cron / background jobs
│   │   ├── messaging/
│   │   │   ├── publishers/  # Outbound message producers
│   │   │   └── consumers/   # Inbound message handlers
│   │   └── utils/           # External integrations (AWS, GitHub, etc.)
│   └── resources/
│       ├── config.yml        # App configuration
│       └── logback / logging config
└── ui-client/               # Frontend application
    └── src/
        ├── components/      # UI components
        ├── pages/           # Route-level views
        ├── services/        # API call layer + shared state
        ├── hooks/           # (React) or composables / providers
        ├── interceptors/    # HTTP middleware
        ├── models/
        │   ├── common/
        │   ├── request/
        │   ├── response/
        │   └── enums/
        └── utils/
```

**Principles:**
- Organize by domain layer, not by file type
- Keep business logic in `service/` — controllers and routes are thin wiring only
- External integrations (third-party APIs, cloud SDKs) live in `utils/` — not in services
- Configuration is always external to code (env vars, config files, secrets manager)

## Multi-Module Repo Structure (server / model / client)

For services consumed by other myKaarma services, split into three modules:

```
<service-name>/
├── model/          # Shared DTOs, request/response types, enums, exceptions
│                   # No framework dependencies — just POJOs / dataclasses
│                   # Published to internal Artifactory as a library
├── client/         # HTTP client library for calling this service
│                   # Uses Retrofit2 (Java)
│                   # Depends on model module
└── server/         # The actual service — depends on model module
```

**Model module rules:**
- No Spring / framework annotations
- Only: Lombok (or equivalent), Jackson, Swagger/OpenAPI annotations
- Serializable POJOs only — no DB entities

**Client module pattern (Java / Retrofit2):**

```java
// Retrofit2 interface — defines the API contract
public interface KCommunicationsApiService {

    @POST("department/{departmentUUID}/customer/{customerUUID}/message")
    Call<SendMessageResponse> sendMessage(
        @Path("departmentUUID") String departmentUUID,
        @Path("customerUUID") String customerUUID,
        @Body SendMessageRequest request
    );
}

// Client entry point — consumers call this, not the Retrofit interface directly
@Service
public class KCommunicationsApiClientService {

    private final KCommunicationsApiService apiService;

    public KCommunicationsApiClientService(@Value("${kcommunications.base.url}") String baseUrl) {
        this.apiService = new Retrofit.Builder()
            .baseUrl(baseUrl)
            .addConverterFactory(JacksonConverterFactory.create())
            .build()
            .create(KCommunicationsApiService.class);
    }

    public SendMessageResponse sendMessage(String departmentUUID, String customerUUID,
                                           SendMessageRequest request) {
        try {
            Response<SendMessageResponse> response =
                apiService.sendMessage(departmentUUID, customerUUID, request).execute();
            if (!response.isSuccessful()) {
                throw new DownstreamException(ErrorCodes.DOWNSTREAM_FAILURE);
            }
            return response.body();
        } catch (IOException e) {
            throw new DownstreamException(ErrorCodes.DOWNSTREAM_FAILURE);
        }
    }
}
```
