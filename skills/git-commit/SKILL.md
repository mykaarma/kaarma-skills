---
name: git-commit
description: Stage, commit, and push changes with meaningful commit messages following conventional commits. Use when you need to commit code changes, create atomic commits, or push to remote. Analyzes diffs to generate descriptive messages.
---

# Git Commit Workflow

## When to Use This Skill

Use this skill when:
- You've completed a feature, bug fix, or refactor
- You need to commit changes with a meaningful message
- You want to create atomic commits (one logical change per commit)
- You need to push changes to a remote repository

## Workflow Steps

### Step 1: Analyze Current State

First, understand what has changed:

```bash
# Check overall status
git status

# See detailed changes
git diff

# See staged changes
git diff --cached

# See changes per file (summary)
git diff --stat
```

### Step 2: Detect Branch Name Prefix

Before committing, extract the current branch name and check if it matches the `MYK-<digits>` pattern:

```bash
# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Extract MYK ticket ID if present (e.g., MYK-12345 from MYK-12345-add-auth or feature/MYK-12345)
TICKET=$(echo "$BRANCH" | grep -oE 'MYK-[0-9]+' | head -1)
```

- If `TICKET` is non-empty (e.g., `MYK-12345`), **prefix every commit message** with `MYK-12345: `
- If the branch does **not** contain a `MYK-<digits>` pattern, do **not** add any prefix

### Step 3: Group Changes Logically

Review changes and group them into logical commits. Each commit should:
- Represent ONE logical change
- Be self-contained and not break the build
- Have a clear purpose

**Common groupings:**
- Feature implementation (may span multiple files)
- Bug fix (typically focused)
- Refactoring (renaming, restructuring)
- Documentation updates
- Test additions
- Configuration changes
- Dependency updates

### Step 4: Stage Files Appropriately

```bash
# Stage specific files
git add path/to/file.py path/to/another.py

# Stage all changes in a directory
git add src/feature/

# Stage with patch mode (select specific hunks)
git add -p path/to/file.py

# Stage all tracked files
git add -u

# Stage everything (use carefully)
git add -A
```

### Step 5: Write Meaningful Commit Message

Follow the **Conventional Commits** format, prefixed with the branch ticket ID when applicable:

**When branch matches `MYK-<digits>` (e.g., branch `MYK-16256-jwt-refresh`):**
```
MYK-16256: <type>(<scope>): <short description>

<optional body - explain WHY, not what>

<optional footer - breaking changes, issue refs>
```

**When branch does NOT match (e.g., branch `main`, `feature/add-logging`):**
```
<type>(<scope>): <short description>

<optional body - explain WHY, not what>

<optional footer - breaking changes, issue refs>
```

**Types:**
| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code restructuring, no behavior change |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `build` | Build system, dependencies |
| `ci` | CI/CD configuration |
| `chore` | Maintenance tasks |

**Examples (branch contains MYK ticket):**

```bash
# Branch: MYK-16256-jwt-refresh
git commit -m "MYK-16256: feat(auth): add JWT refresh token support"

# Branch: MYK-16171-null-response-fix
git commit -m "MYK-16171: fix(api): handle null response from external service

The third-party API occasionally returns null instead of an empty array.
Added null check to prevent TypeError in downstream processing."

# Branch: MYK-67656-postgres-migration
git commit -m "MYK-67656: feat(db)!: migrate from MongoDB to PostgreSQL

BREAKING CHANGE: Database connection string format has changed.
Update MONGODB_URI to POSTGRES_URI in environment configuration."

# Branch: MYK-17909-duplicate-jobs
git commit -m "MYK-17909: fix(worker): prevent duplicate job processing

Closes #123"
```

**Examples (branch does NOT contain MYK ticket):**

```bash
# Branch: main
git commit -m "feat(auth): add JWT refresh token support"

# Branch: feature/null-response-fix
git commit -m "fix(api): handle null response from external service

The third-party API occasionally returns null instead of an empty array.
Added null check to prevent TypeError in downstream processing."

# Branch: hotfix/postgres-uri
git commit -m "chore(config): update database connection string format"
```

### Step 6: Push to Remote

```bash
# Push current branch
git push origin HEAD

# Push and set upstream
git push -u origin feature-branch

# Force push (use carefully, only on personal branches)
git push --force-with-lease origin feature-branch
```

## Generating Commit Messages from Diffs

When analyzing changes to generate a commit message:

1. **Run `git rev-parse --abbrev-ref HEAD`** and extract `MYK-<digits>` if present
2. **Run `git diff --cached`** (or `git diff` for unstaged)
3. **Identify the primary change type** (feat, fix, refactor, etc.)
4. **Determine the scope** from file paths (api, worker, db, etc.)
5. **Summarize the change** in imperative mood ("add", "fix", "update")
6. **Prefix with ticket ID** if branch matches `MYK-<digits>`
7. **Add context in body** if the "why" isn't obvious

### Analyzing Diff Patterns

| Diff Pattern | Likely Type | Message Hint |
|--------------|-------------|--------------|
| New file added | `feat` or `test` | "add X" |
| File deleted | `refactor` or `chore` | "remove X" |
| Function renamed | `refactor` | "rename X to Y" |
| Error handling added | `fix` or `feat` | "handle X error case" |
| Import changes only | `refactor` | "reorganize imports" |
| Comment changes | `docs` | "document X behavior" |
| Config value changed | `chore` or `fix` | "update X configuration" |
| Test file changed | `test` | "improve X test coverage" |

## Multi-Commit Workflow

When changes span multiple logical units:

```bash
# Branch: MYK-20100-email-verification

# 1. Stage first logical group
git add src/models/user.py src/schemas/user.py
git commit -m "MYK-20100: feat(user): add email verification fields"

# 2. Stage second logical group
git add src/services/email.py
git commit -m "MYK-20100: feat(email): implement verification email sender"

# 3. Stage tests separately
git add tests/test_user.py tests/test_email.py
git commit -m "MYK-20100: test(user): add email verification tests"

# 4. Push all commits
git push origin HEAD
```

## Interactive Staging with `git add -p`

For fine-grained control over what goes into a commit:

```bash
git add -p
# Options:
# y - stage this hunk
# n - skip this hunk
# s - split into smaller hunks
# e - manually edit the hunk
# q - quit
```

## Pre-Push Checklist

Before pushing, verify:

```
- [ ] All tests pass locally
- [ ] Code is formatted (run linter/formatter)
- [ ] No debug code or console.logs left
- [ ] Commit messages are meaningful
- [ ] No sensitive data (keys, passwords) in commits
- [ ] Branch is up to date with main (rebase if needed)
```

## Common Scenarios

### Scenario 1: Single Feature Commit (MYK branch)

```bash
# Branch: MYK-18432-language-detection
git status
git diff
git add -A
git commit -m "MYK-18432: feat(transcription): add language detection support"
git push origin HEAD
```

### Scenario 2: Fix with Related Test (MYK branch)

```bash
# Branch: MYK-19001-parser-empty-input
git add src/services/parser.py
git commit -m "MYK-19001: fix(parser): handle empty input gracefully"

git add tests/test_parser.py
git commit -m "MYK-19001: test(parser): add empty input test cases"

git push origin HEAD
```

### Scenario 3: Single Feature Commit (non-MYK branch)

```bash
# Branch: feature/language-detection
git status
git diff
git add -A
git commit -m "feat(transcription): add language detection support"
git push origin HEAD
```

### Scenario 4: Amend Last Commit

```bash
# Add forgotten file to last commit
git add forgotten_file.py
git commit --amend --no-edit

# Change last commit message
git commit --amend -m "MYK-16256: feat(api): better description here"
```

### Scenario 5: Interactive Rebase Before Push

```bash
# Clean up commits before pushing
git rebase -i HEAD~3
# Mark commits as 'squash' or 'fixup' to combine
# Reorder or edit commit messages
```

## Scope Detection from File Paths

| Path Pattern | Suggested Scope |
|--------------|-----------------|
| `src/api/` | `api` |
| `src/services/` | Service name (e.g., `transcription`) |
| `src/models/` or `src/db/` | `db` |
| `src/utils/` | `utils` or utility name |
| `tests/` | `test` (or the tested module) |
| `config/` or `.env` | `config` |
| `docker-compose*`, `Dockerfile` | `docker` |
| `k8s/`, `kubernetes/` | `k8s` |
| `docs/`, `*.md` | `docs` |
| `pyproject.toml`, `package.json` | `deps` or `build` |
| `.github/`, `.gitlab-ci*` | `ci` |

## Tips for Better Commits

1. **Commit early, commit often** - Small commits are easier to review and revert
2. **One thing per commit** - Don't mix features with refactoring
3. **Write for future you** - Explain why, not just what
4. **Use imperative mood** - "add feature" not "added feature"
5. **Reference issues** - Link to tickets with `Closes #123` or `Refs #456`
6. **Don't commit generated files** - Use `.gitignore`
7. **Review before committing** - Use `git diff --cached` to double-check
