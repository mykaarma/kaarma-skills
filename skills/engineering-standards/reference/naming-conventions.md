# Reference: Naming Conventions

## Backend (Java)

| Artifact | Convention | Examples |
|----------|-----------|---------|
| Class | PascalCase | `GvmService`, `GvmCreateRequest` |
| Method | camelCase | `createGvm`, `findByUuidAndIsValidTrue` |
| Variable / Field | camelCase | `gvmUuid`, `isValid` |
| Constant | UPPER_SNAKE_CASE | `MAX_PAGE_SIZE`, `DEFAULT_TIMEOUT` |
| Package | lowercase | `com.example.orders.service` |
| DB table | snake_case plural | `gvms`, `gvm_details`, `gvm_types` |
| DB column | snake_case | `gvm_uuid`, `is_valid`, `created_at` |
| Enum class | PascalCase | `GvmStatus`, `ErrorCodes` |
| Enum value | UPPER_SNAKE_CASE | `GvmStatus.RUNNING` |
| DTO suffix | `*DTO` / `*Request` / `*Response` | `GvmDTO`, `GvmCreateRequest` |
| Entity (DB model) | no suffix | `GVM`, `GVMDetails` |
| Repository suffix | `*Repository` | `GvmRepository` |
| Service suffix | `*Service` | `GvmService` |
| Controller suffix | `*Controller` | `GvmController` |
| Exception suffix | `*Exception` | `BadArgumentsException` |
| Mapper suffix | `*Mapper` | `GvmMapper` |

## Frontend (TypeScript)

| Artifact | Convention | Examples |
|----------|-----------|---------|
| Component / Page class | PascalCase | `GvmHomePage`, `GvmCard` |
| Service / Hook | PascalCase (class) / camelCase (hook) | `GvmService`, `useGvmService` |
| File | kebab-case | `gvm-home.component.ts`, `gvm.service.ts` |
| CSS class | kebab-case | `gvm-status-badge`, `action-button` |
| Enum | PascalCase values | `GvmStatus.RUNNING` |
| Observable / stream | suffix `$` | `selectedGvm$`, `destroy$` |
| Interface / type | PascalCase | `GvmCreateRequest`, `ApiErrorResponse` |
| Constant | UPPER_SNAKE_CASE | `MAX_PAGE_SIZE` |

## API Fields

Use `camelCase` in JSON payloads — Jackson serializes Java camelCase fields to camelCase by default:
```json
{ "gvmUuid": "...", "createdAt": "...", "isValid": true }
```

Apply uniformly across all endpoints. Do not mix camelCase and snake_case within one service.
