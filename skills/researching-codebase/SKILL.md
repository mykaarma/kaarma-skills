---
name: researching-codebase
description: Systematically explore and understand existing codebases before making changes. Use when starting on a new project, investigating bugs, planning features, or needing to understand architectural patterns. Provides search strategies and investigation workflows.
---

# Researching Codebases Systematically

## When to Use This Skill

Use systematic codebase research when:
- **Starting on a new project**: Need to understand architecture and patterns
- **Planning features**: Must understand existing implementations before adding new ones
- **Investigating bugs**: Need to trace data flow and identify root causes
- **Refactoring**: Must understand dependencies before changing code
- **Code review**: Need context to evaluate proposed changes
- **Performance optimization**: Must identify hotpaths and bottlenecks

## Quick Search Patterns

### Pattern 1: Find Similar Implementations

**Goal**: Understand how existing code solves similar problems

```bash
# Find by feature name
grep -r "authentication" --include="*.py" src/

# Find by pattern (e.g., all API endpoints)
grep -r "@app.route" --include="*.py" src/

# Find database models
grep -r "class.*Model" --include="*.py" src/
```

**What to look for**:
- Naming conventions
- Error handling patterns
- Testing approaches
- Configuration management

### Pattern 2: Understand Data Flow

**Goal**: Trace how data moves through the system

```bash
# Find where data enters (API endpoints, queue consumers)
grep -r "def.*request\|async def.*handler" src/

# Find where data is stored (database operations)
grep -r "session.add\|session.query\|INSERT\|UPDATE" src/

# Find where data exits (responses, callbacks)
grep -r "return.*json\|response\|callback" src/
```

**Follow the chain**:
1. Entry point (API/queue)
2. Validation layer
3. Business logic
4. Data persistence
5. Response/callback

### Pattern 3: Identify Conventions

**Goal**: Learn project-specific patterns and standards

**Check these files first**:
- `CLAUDE.md` or `README.md`: Project guidance
- `pyproject.toml` / `package.json`: Dependencies and scripts
- `.github/workflows/`: CI/CD patterns
- `tests/conftest.py`: Test fixtures and patterns
- `Makefile`: Common commands

**Look for**:
- Import patterns (relative vs absolute)
- Error handling (custom exceptions?)
- Logging patterns (structured logging?)
- Configuration (env vars, config files?)

## Deep Dive Workflows

### Workflow 1: Understanding a New Feature Area

Copy this checklist and track your progress:

```
Research Progress:
- [ ] Step 1: Find the entry point (API route, queue task, CLI command)
- [ ] Step 2: Identify data models and schemas
- [ ] Step 3: Trace business logic and validations
- [ ] Step 4: Find related tests
- [ ] Step 5: Check documentation and comments
```

**Step 1: Find the entry point**

```bash
# For web APIs
grep -r "router\|route\|endpoint" src/

# For background jobs
grep -r "task\|job\|worker" src/

# For CLI tools
grep -r "click\|argparse\|main" src/
```

**Step 2: Identify data models**

```bash
# Find database models
grep -r "class.*Base\|@dataclass\|TypedDict" src/

# Find API schemas
grep -r "BaseModel\|Schema\|Serializer" src/
```

**Step 3: Trace business logic**

Read the entry point file. Look for:
- Function calls (where does it delegate to?)
- Database queries (what data does it access?)
- External service calls (APIs, queues, etc.)
- Error handling (what can go wrong?)

**Step 4: Find related tests**

```bash
# Tests often mirror source structure
# src/api/users.py → tests/test_api_users.py

# Or search by feature name
grep -r "test.*user" tests/
```

**Step 5: Check documentation**

- Inline comments (especially "WHY" comments)
- Docstrings (function signatures, return types)
- Project docs (CLAUDE.md, architecture diagrams)

### Workflow 2: Debugging an Issue

```
Debug Research:
- [ ] Step 1: Reproduce the issue (logs, error message, stack trace)
- [ ] Step 2: Find the failing code path
- [ ] Step 3: Identify assumptions and preconditions
- [ ] Step 4: Search for related issues or recent changes
- [ ] Step 5: Verify with tests
```

**Step 1: Gather evidence**

- Error message and stack trace
- Request/response data
- Recent changes (`git log --since="1 week ago" --oneline`)
- Related logs

**Step 2: Find the failing code**

Use the stack trace to locate the exact line. Then:
- Read surrounding code for context
- Check function arguments and return values
- Look for conditional logic that might be involved

**Step 3: Identify assumptions**

Look for:
- Input validation (or lack thereof)
- Null checks (is something unexpectedly None?)
- Async/sync mismatches
- Race conditions in concurrent code

**Step 4: Search for patterns**

```bash
# Has this happened before?
git log -p --all -S "error message text"

# Recent changes to this file
git log -p --since="2 weeks ago" path/to/file.py

# Who last touched this code?
git blame path/to/file.py
```

**Step 5: Verify with tests**

- Do tests cover this case?
- Can you write a failing test that reproduces the issue?
- Do existing tests pass or fail?

### Workflow 3: Performance Investigation

See [reference/search-strategies.md](reference/search-strategies.md) for detailed performance investigation patterns.

## Common Investigation Techniques

### Technique 1: Grep Patterns for Different Languages

**Python**:
```bash
# Find class definitions
grep -r "^class " --include="*.py"

# Find async functions
grep -r "async def" --include="*.py"

# Find database queries
grep -r "select\|query\|filter" --include="*.py"
```

**JavaScript/TypeScript**:
```bash
# Find React components
grep -r "export.*function\|export default" --include="*.tsx"

# Find API calls
grep -r "fetch\|axios\|api\." --include="*.ts"

# Find state management
grep -r "useState\|useContext\|createSlice" --include="*.tsx"
```

**Go**:
```bash
# Find struct definitions
grep -r "^type.*struct" --include="*.go"

# Find interface definitions
grep -r "^type.*interface" --include="*.go"

# Find HTTP handlers
grep -r "http.Handler\|gin.Context" --include="*.go"
```

### Technique 2: Understanding Dependencies

**Check import statements**:
```bash
# Python
grep -r "^from\|^import" src/ | sort | uniq

# JavaScript
grep -r "^import" src/ | sort | uniq
```

**Trace dependency usage**:
```bash
# Where is library X used?
grep -r "library_name" src/

# What does this module export?
grep "^def\|^class" src/module.py
```

### Technique 3: Finding Examples

**Look for tests**:
```bash
# Tests show real usage patterns
grep -r "def test_" tests/

# Integration tests show end-to-end flows
grep -r "test.*integration" tests/
```

**Check documentation**:
- README examples
- Inline docstring examples
- Comments with "Example:" or "Usage:"

## Integration with Project Documentation

**Always check project docs first**:

1. **Read CLAUDE.md or project README**: Understand conventions before exploring
2. **Follow project patterns**: Match existing style and structure
3. **Ask before diverging**: If you need different patterns, understand why existing ones were chosen

**Reference project docs**:
- "See CLAUDE.md for testing patterns" (before writing tests)
- "Check project conventions for error handling" (before adding error handling)
- "Refer to architecture docs for service boundaries" (before refactoring)

## Quick Reference: Common File Locations

**Configuration**:
- Python: `pyproject.toml`, `setup.py`, `.env`, `settings.py`
- Node: `package.json`, `.env`, `config/`
- Go: `go.mod`, `config.yaml`

**Tests**:
- Python: `tests/`, `test_*.py`, `*_test.py`
- Node: `test/`, `*.test.ts`, `*.spec.ts`
- Go: `*_test.go`

**Entry points**:
- Web API: `main.py`, `app.py`, `server.ts`, `main.go`
- CLI: `cli.py`, `cmd/`, `bin/`
- Workers: `worker.py`, `queue.py`, `jobs/`

**Documentation**:
- `README.md`, `CLAUDE.md`, `docs/`, `ARCHITECTURE.md`

## When Research is Complete

You've successfully researched the codebase when:
- You can explain the data flow for the feature area
- You've identified similar implementations to follow
- You understand project conventions and patterns
- You've found relevant tests
- You know where to look for more information

For advanced search strategies and performance investigation patterns, see [reference/search-strategies.md](reference/search-strategies.md).
