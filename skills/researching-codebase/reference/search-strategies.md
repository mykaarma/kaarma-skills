# Advanced Search Strategies

## Performance Investigation Patterns

### Finding Hotpaths

**Database query investigation**:
```bash
# Find all database queries
grep -r "select\|query\|filter\|execute" src/

# Find N+1 query patterns (loops with queries)
grep -A5 "for.*in" src/ | grep "query\|select"

# Find missing indexes (full table scans)
grep -r "scan\|EXPLAIN" logs/
```

**API endpoint profiling**:
```bash
# Find all API endpoints
grep -r "@router\|@app.route\|@get\|@post" src/

# Find endpoints with external calls
grep -r "requests\|httpx\|fetch" src/api/

# Find async/await patterns
grep -r "await" src/ | wc -l
```

### Memory Leak Investigation

```bash
# Find large data structures
grep -r "list\[\]\|dict()\|\[\]" src/

# Find caching without size limits
grep -r "cache\|@lru_cache\|memoize" src/

# Find unclosed resources
grep -r "open(\|connect(\|session(" src/
# Check for corresponding .close() or context managers
```

## Architecture Discovery Patterns

### Finding Service Boundaries

**Identify modules**:
```bash
# List top-level directories
ls -d src/*/

# Find module dependencies
grep -r "^from src\." src/ | cut -d: -f2 | sort | uniq -c | sort -rn
```

**Map data flow**:
```bash
# Entry points
grep -r "router\|consumer\|handler" src/

# Business logic
grep -r "service\|manager\|controller" src/

# Data layer
grep -r "repository\|dao\|model" src/
```

### Understanding Configuration

**Find all config sources**:
```bash
# Environment variables
grep -r "os.getenv\|process.env\|ENV" src/

# Config files
find . -name "*.yaml" -o -name "*.json" -o -name "*.toml" -o -name ".env*"

# Hard-coded configs
grep -r "TIMEOUT\|MAX_\|LIMIT" src/ | grep "=.*[0-9]"
```

## Dependency Analysis Patterns

### Finding Circular Dependencies

```bash
# Python: Find mutual imports
for file in src/**/*.py; do
    echo "=== $file ===" 
    grep "^from\|^import" $file
done | grep -A1 "===" | sort

# Check for cycles manually or use tools like pydeps
```

### Understanding External Dependencies

```bash
# List all external imports
grep -r "^import\|^from" src/ | grep -v "^from src" | cut -d: -f2 | sort | uniq

# Find version constraints
cat pyproject.toml package.json go.mod | grep -A1 "dependencies\|require"

# Find deprecated dependencies
grep -r "deprecated\|legacy" node_modules/ .venv/
```

## Testing Pattern Discovery

### Find Test Coverage Gaps

```bash
# Find files without tests
for file in src/**/*.py; do
    testfile="tests/$(basename $file | sed 's/.py/_test.py/')"
    if [ ! -f "$testfile" ]; then
        echo "Missing test: $file"
    fi
done
```

### Understand Test Strategies

```bash
# Find mocking patterns
grep -r "mock\|patch\|stub" tests/

# Find integration test patterns
grep -r "integration\|e2e\|end.to.end" tests/

# Find test fixtures
grep -r "@fixture\|@pytest.fixture\|beforeEach" tests/
```

## Database Schema Discovery

### Understanding Data Models

```bash
# Find all models
grep -r "class.*Model\|@Entity\|type.*struct" src/

# Find relationships
grep -r "ForeignKey\|relationship\|references" src/

# Find migrations
ls -la migrations/ alembic/versions/ db/migrate/
```

### Query Pattern Analysis

```bash
# Find complex queries
grep -r "join\|JOIN" src/ | wc -l

# Find raw SQL
grep -r "execute\|raw\|query(" src/

# Find ORM usage
grep -r "filter\|where\|select" src/
```

## Git History Investigation

### Find When Feature Was Added

```bash
# Search commit messages
git log --all --grep="feature name"

# Search code changes
git log -S "function_name" --source --all

# Find file history
git log --follow --oneline -- path/to/file.py
```

### Understand Why Code Changed

```bash
# Show full context for commit
git show <commit-hash>

# Find related commits
git log --since="2024-01-01" --grep="related keyword"

# Blame with commit messages
git blame -w -C -C -C path/to/file.py
```

## Error Handling Pattern Discovery

### Find Error Patterns

```bash
# Find exception handling
grep -r "try:\|except\|catch\|Error" src/

# Find error types
grep -r "class.*Error\|class.*Exception" src/

# Find error logging
grep -r "logger.error\|console.error\|log.Error" src/
```

### Trace Error Propagation

```bash
# Find where errors are raised
grep -r "raise\|throw new" src/

# Find where errors are caught
grep -r "except.*:\|catch (" src/

# Find error handlers
grep -r "error_handler\|on_error\|handleError" src/
```

## When to Use These Strategies

- **Performance issues**: Use hotpath and profiling patterns
- **Architecture review**: Use service boundary and dependency patterns
- **Bug investigation**: Use error handling and git history patterns
- **Test improvements**: Use test coverage and strategy patterns
- **Refactoring**: Use dependency analysis and architecture discovery
