# Reference: Async & Messaging

## When to Use Async

```
Synchronous (direct response):     User creates a GVM → validate → persist → 201 Created
Asynchronous (queue + event):      GVM created → provision EC2 instance → notify via WebSocket

Use async for:
  - Operations taking > 2 seconds (cloud provisioning, builds, ML inference)
  - Fan-out operations (notify many systems)
  - Retryable work (external API calls that can fail transiently)
  - Decoupling services that shouldn't know about each other
```

## Message Publisher

```java
@Slf4j
@Service
public class RabbitMQPublisher {

    private final RabbitTemplate rabbitTemplate;
    private final ObjectMapper objectMapper;

    @Value("${rabbitmq.gvm.exchange}")
    private String exchange;

    @Value("${rabbitmq.gvm.routing-key}")
    private String routingKey;

    public void publishGvmCreated(String gvmUuid) {
        try {
            Map<String, String> payload = Map.of("messageType", "GVM_CREATED", "gvmUuid", gvmUuid);
            String json = objectMapper.writeValueAsString(payload);
            Message message = MessageBuilder
                .withBody(json.getBytes(StandardCharsets.UTF_8))
                .setContentType(MessageProperties.CONTENT_TYPE_JSON)
                .build();
            rabbitTemplate.convertAndSend(exchange, routingKey, message);
            log.info("Published GVM_CREATED gvmUuid={}", gvmUuid);
        } catch (Exception e) {
            log.error("Failed to publish GVM_CREATED gvmUuid={}", gvmUuid, e);
            throw new ServiceException(ErrorCodes.INTERNAL_ERROR);
        }
    }
}
```

## Message Consumer

```java
@Slf4j
@Service
public class RabbitMQReceiver {

    private final ProvisioningService provisioningService;
    private final ObjectMapper objectMapper;

    @RabbitListener(queues = "${rabbitmq.gvm.queue}")
    public void handleGvmCreated(Message message) {
        String body = new String(message.getBody(), StandardCharsets.UTF_8);
        try {
            Map<String, String> payload = objectMapper.readValue(body, Map.class);
            String gvmUuid = payload.get("gvmUuid");
            log.info("Processing GVM_CREATED gvmUuid={}", gvmUuid);
            provisioningService.provision(gvmUuid);
        } catch (Exception e) {
            log.error("Failed to process GVM_CREATED message={}", body, e);
            // Do NOT rethrow — let RabbitMQ retry policy / DLQ handle it
        }
    }
}
```

**Rules:**
- Configure retries with exponential backoff on the broker/consumer
- Configure a dead-letter queue (DLQ) for messages that fail after retry exhaustion
- **Never throw from a consumer** — unhandled throws can cause infinite requeue loops
- Log the full message context on failure so DLQ messages are debuggable

## Async Response Pattern

For operations that are queued rather than completed synchronously, return `202 Accepted`:

```
POST /v1/gvms/{uuid}/start
→ 202 Accepted
  { "requestId": "<uuid>", "status": "PENDING", "statusUrl": "/v1/gvms/{uuid}" }

Client polls GET /v1/gvms/{uuid} for status updates.
Or: server pushes via WebSocket / PubNub / SSE when done.
```

Target: HTTP handlers complete in < 500ms. Anything longer belongs in a worker.

```
HTTP Request
    ↓
Controller: validate + persist + publish message → 202 Accepted
                              ↓
                      Message Queue (RabbitMQ / SQS)
                              ↓
                      Consumer: slow work (AWS, Jenkins, AWX, ML)
                              ↓
                      Real-time notification (WebSocket / PubNub / SSE) → Frontend
```
