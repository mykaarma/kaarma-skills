# Reference: Frontend Patterns

## Service Layer (API Calls + State)

Keep all API calls in a dedicated service layer. Components never call `fetch`/`axios`/`http` directly.

```typescript
// React — custom hook as service
function useGvmService() {
  const [gvms, setGvms] = useState<Gvm[]>([]);
  const [status, setStatus] = useState<FetchStatus>(FetchStatus.UNDEFINED);

  async function loadGvms(page = 1, pageSize = 25) {
    setStatus(FetchStatus.LOADING);
    try {
      const data = await apiClient.post<GetUserGVMResponse>('/v1/user-gvms/searches', { page, pageSize });
      setGvms(data.gvms);
      setStatus(FetchStatus.SUCCESS);
    } catch (err) {
      setStatus(FetchStatus.ERROR);
      toast.error(extractErrorMessage(err));
    }
  }

  return { gvms, status, loadGvms };
}
```

```typescript
// Angular — injectable service
@Injectable({ providedIn: 'root' })
export class GvmService {
  private selectedGvm$ = new BehaviorSubject<Gvm | null>(null);
  selectedGvm = this.selectedGvm$.asObservable();

  private httpOptions = {
    headers: new HttpHeaders({ 'Content-Type': 'application/json' }),
    withCredentials: true,  // sends mkid cookie for authentication
  };

  constructor(private http: HttpClient) {}

  getAllGvms(page = 1, pageSize = 25): Observable<GetUserGVMResponse> {
    return this.http.post<GetUserGVMResponse>(
      `${environment.apiUrl}/v1/user-gvms/searches`,
      { page, pageSize },
      this.httpOptions
    );
  }
}
```

**Rules:**
- One service per domain entity (`GvmService`, `WorkflowService`)
- Services return data, not side-effects — components decide how to render
- Base URL always comes from `environment.apiUrl` — never hardcoded
- Always pass `withCredentials: true` — authentication is cookie-based, no Authorization header
- Typed return values only — never use `any` / untyped responses

---

## HTTP Client Setup

Authentication is cookie-based. The `mkid` cookie is set once at app startup and sent with every request via `withCredentials: true`. There is no Authorization header.

```typescript
// Axios instance (React / Vue / vanilla TS)
const apiClient = axios.create({
  baseURL: env.API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  withCredentials: true,  // sends mkid and session cookies on every request
});

// Response interceptor — centralized error handling
apiClient.interceptors.response.use(
  response => response.data,
  error => {
    console.error(`[HTTP ${error.response?.status}]`, error.config?.url, error.response?.data);
    return Promise.reject(error);
  }
);
```

```typescript
// Angular — set mkid cookie once on app init (app.component.ts)
ngOnInit(): void {
  this.cookieService.set('mkid', environment.mkid, undefined, '/');
}

// Error interceptor
@Injectable()
export class HttpErrorsInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    return next.handle(req).pipe(
      catchError(err => {
        console.error(`[HTTP Error] ${req.method} ${req.url}`, err.status, err.error);
        return throwError(() => err);
      }),
    );
  }
}
```

---

## Component Patterns

Components own rendering and user interaction only. They delegate data fetching to services.

```typescript
// React component
function GvmHomePage() {
  const { gvms, status, loadGvms } = useGvmService();

  useEffect(() => { loadGvms(); }, []);

  if (status === FetchStatus.LOADING) return <Spinner />;
  if (status === FetchStatus.ERROR) return <ErrorState onRetry={loadGvms} />;

  return <GvmList gvms={gvms} />;
}
```

```typescript
// Angular component
@Component({ selector: 'app-gvm-home', templateUrl: './gvm-home.component.html' })
export class GvmHomeComponent implements OnInit, OnDestroy {
  gvms: Gvm[] = [];
  fetchStatus = FetchStatus.UNDEFINED;
  private destroy$ = new Subject<void>();

  constructor(private gvmService: GvmService, private toastr: ToastrService) {}

  ngOnInit() { this.loadGvms(); }
  ngOnDestroy() { this.destroy$.next(); this.destroy$.complete(); }

  private loadGvms() {
    this.fetchStatus = FetchStatus.LOADING;
    this.gvmService.getAllGvms().pipe(
      takeUntil(this.destroy$),
      catchError(err => {
        this.toastr.error(extractErrorMessage(err));
        this.fetchStatus = FetchStatus.ERROR;
        return of(null);
      }),
    ).subscribe(res => {
      if (res) { this.gvms = res.gvms; this.fetchStatus = FetchStatus.SUCCESS; }
    });
  }
}
```

**Rules:**
- Track async state with a `FetchStatus` enum — never use boolean `isLoading` flags
- Always handle the error case — show inline error UI or a toast; never silently swallow
- Clean up subscriptions / effects on component unmount (Angular: `takeUntil`; React: cleanup in `useEffect`)
- Components receive data as props/inputs — avoid deep service injection chains in leaf components

---

## Models & Enums

```typescript
// Domain model
interface Gvm {
  uuid: string;
  name: string;
  type: string;
  status: GvmStatus;
  details: GvmDetails;
}

enum GvmStatus {
  RUNNING = 'RUNNING',
  STOPPED = 'STOPPED',
  PENDING = 'PENDING',
}

enum FetchStatus {
  UNDEFINED = 'UNDEFINED',
  LOADING = 'LOADING',
  SUCCESS = 'SUCCESS',
  ERROR = 'ERROR',
}

interface ApiErrorResponse {
  errors: Array<{ errorCode: number; errorTitle: string; errorMessage: string }>;
  warnings: Array<{ warningCode: number; warningMessage: string }>;
}

function extractErrorMessage(err: unknown): string {
  const apiErr = err?.response?.data as ApiErrorResponse;
  return apiErr?.errors?.[0]?.errorMessage ?? 'An unexpected error occurred.';
}
```

---

## Frontend Code Style (ESLint + Prettier)

```json
// .prettierrc
{
  "trailingComma": "es5",
  "tabWidth": 2,
  "semi": true,
  "useTabs": false,
  "singleQuote": true,
  "printWidth": 120
}
```

```json
// .eslintrc.json key rules
{
  "rules": {
    "@typescript-eslint/no-unused-vars": "off",
    "unused-imports/no-unused-imports": "warn",
    "unused-imports/no-unused-vars": {
      "vars": "all",
      "varsIgnorePattern": "^_",
      "args": "after-used",
      "argsIgnorePattern": "^_"
    }
  }
}
```

Run before every commit:
```bash
npx prettier --write "src/**/*.{ts,html,css}"
npx eslint "src/**/*.ts" --fix
```
