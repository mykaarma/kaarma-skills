---
name: review-team
description: "Dispatch parallel specialized review agents simultaneously — code review, security audit, test coverage, and API contract review. Use when a feature/PR is ready for thorough review before merge."
---

# Review Team — Parallel PR Review

## Overview

When a feature or PR is ready for review, a single sequential pass often misses issues that a specialist would catch. This skill dispatches four specialized reviewer agents in parallel, then aggregates their findings into a unified report with a single verdict.

**Where this fits:**
```
build feature → /review-team → address findings → merge
```

## When to Use

**Use when:**
- A PR or feature branch is ready for final review before merge
- The change is non-trivial (new endpoints, auth changes, data migrations, new services)
- You want higher confidence before merging to canary/master
- A previous review found issues you want to verify are fully resolved

**Do NOT use when:**
- Quick typo fixes or single-line changes — standard review is sufficient
- Code is still WIP (use `/reviewing-code` directly instead)
- You need a fast sanity check (use a single agent, not the full team)
- The change is purely to non-code artifacts (docs, configs only)

## Step 1: Confirm Before Dispatch

<HARD-GATE>
Before dispatching any agents, summarize what will be reviewed:

```
Ready to dispatch the review team for: [PR/feature description]

Agents to be dispatched in parallel:
  A. Code Reviewer       — correctness, architecture, patterns (reviewing-code skill)
  B. Security Reviewer   — auth, injection, PII, guardrails G1-G11 (auditing-security skill)
  C. Test Coverage       — test existence, edge cases, missing scenarios
  D. API Contract        — naming, pagination, error responses (api-guidelines skill)
                           [SKIPPED if no API changes detected]

Estimated time: 2-4 minutes

Proceed? (yes/no)
```

Wait for explicit confirmation before dispatching.
</HARD-GATE>

## Step 2: Detect API Changes

Before dispatching, check if the diff includes API changes:
- New or modified `@Controller`, `@RestController`, `@RequestMapping`, `@GetMapping`, etc.
- New or modified endpoint paths
- Changes to request/response DTOs

If no API changes are detected, skip Agent D and note it in the report.

## Step 3: Dispatch Agents in Parallel

Dispatch all agents simultaneously using the Agent tool. Each agent receives a focused prompt with the PR diff and relevant context.

**Agent A — Code Reviewer**
```
You are a code reviewer focused on correctness, architecture, and maintainability.
Invoke the reviewing-code skill and apply it to the following changes.

Focus on:
- Logic correctness and edge cases
- Architecture and design decisions (SOLID, separation of concerns)
- Error handling — are all exceptions caught and handled appropriately?
- Resource management — connections, streams, transactions properly closed?
- Idempotency — are mutations safe to retry?
- Code duplication and DRY violations
- Naming clarity and consistency
- Complexity: is there simpler way to achieve the same goal?

[PASTE DIFF / FILE PATHS HERE]

Return a structured list of findings. Each finding must include:
- severity: BLOCKING | IMPORTANT | SUGGESTION
- location: file + line number or method name
- issue: what is wrong
- recommendation: how to fix it
```

**Agent B — Security Reviewer**
```
You are a security auditor. Invoke the auditing-security skill and apply it to the
following changes. Check for myKaarma guardrails G1-G11.

Focus on:
- Authentication: are endpoints protected by mkid cookie auth where required?
- Authorization: is dealer context validated before operating on data?
- Injection vulnerabilities: SQL, NoSQL, command injection
- PII handling: are customer names, phones, emails logged or exposed incorrectly?
- Secrets: are any tokens, passwords, or API keys hardcoded or logged?
- Input validation: are all inputs sanitized before use?
- Insecure direct object references: are UUIDs validated against the caller's context?
- Rate limiting: are sensitive endpoints rate-limited?

[PASTE DIFF / FILE PATHS HERE]

Return a structured list of findings. Each finding must include:
- severity: BLOCKING | IMPORTANT | SUGGESTION
- guardrail: G1-G11 reference if applicable
- location: file + line number or method name
- issue: what is wrong
- recommendation: how to fix it
```

**Agent C — Test Coverage Reviewer**
```
You are a test coverage reviewer.

Examine the changed files and their corresponding test files. Check:
- Do tests exist for the changed functionality?
- Are happy-path cases covered?
- Are error and failure paths tested?
- Are edge cases covered (null inputs, empty lists, boundary values)?
- Are integration tests present for new API endpoints?
- Are external dependencies properly mocked in unit tests?
- Do tests assert behavior, not implementation details?
- Are there missing scenarios that could cause a production issue?

List specific untested scenarios by name, e.g.:
  "Missing test: what happens when dealerUUID is not found?"

[PASTE DIFF / FILE PATHS HERE]

Return a structured list of findings. Each finding must include:
- severity: BLOCKING | IMPORTANT | SUGGESTION
- location: test file that should contain the test, or existing test file with gaps
- issue: what scenario is untested or poorly tested
- recommendation: what test to add
```

**Agent D — API Contract Reviewer** (if API changes detected)
```
You are an API contract reviewer. Invoke the api-guidelines skill and apply it to
the following API changes.

Focus on:
- URL patterns: plural nouns, no verbs, hyphens for multi-word terms
- HTTP methods: correct method for the operation
- Status codes: 4xx for client errors, 5xx for server errors, never 2xx with error body
- Error response format: structured JSON with code, message, details
- Versioning: all endpoints under /v1/ or higher
- Pagination: all list endpoints must have offset/limit
- Naming consistency: field names match org conventions
- Bulk operations: using :bulk-verb pattern with POST
- Auth parameters: in headers, not query params
- Documentation: Swagger/OpenAPI annotations present

[PASTE DIFF / FILE PATHS HERE]

Return a structured list of findings. Each finding must include:
- severity: BLOCKING | IMPORTANT | SUGGESTION
- location: file + line number or endpoint path
- issue: what violates the API guidelines
- recommendation: the correct pattern
```

## Step 4: Aggregate and Report

After all agents return, perform aggregation:

### Deduplication

1. Collect all findings from all agents into one list
2. Identify overlapping findings (e.g., Agent A and Agent B both flag the same missing auth check)
3. Merge duplicates: keep the highest severity, reference both agents in the source
4. Tag each finding with which agent(s) raised it

### Severity Sort

Order findings: BLOCKING first, then IMPORTANT, then SUGGESTION.

### Verdict

| Condition | Verdict |
|-----------|---------|
| Any BLOCKING findings | REQUEST CHANGES |
| 3+ IMPORTANT findings with no BLOCKING | NEEDS DISCUSSION |
| Only IMPORTANT or SUGGESTION findings | REQUEST CHANGES or APPROVE (your judgment) |
| No findings above SUGGESTION level | APPROVE |

### Output Format

Print the unified report in this structure:

```
## Review Team Report
PR / Feature: [name]
Date: [date]
Agents run: Code, Security, Test Coverage, API Contract (or note skipped)

### Verdict: [APPROVE | REQUEST CHANGES | NEEDS DISCUSSION]

---

### BLOCKING Issues ([count])

[B1] [severity] [Agent: A/B/C/D] — [file:line]
Issue: ...
Recommendation: ...

---

### IMPORTANT Issues ([count])

[I1] [severity] [Agent: A/B/C/D] — [file:line]
Issue: ...
Recommendation: ...

---

### SUGGESTIONS ([count])

[S1] ...

---

### What Looks Good
- [positive observations]
```

Then emit the structured JSON summary:

```json
{
  "verdict": "REQUEST_CHANGES | APPROVE | NEEDS_DISCUSSION",
  "pr": "[pr name or branch]",
  "reviewed_at": "[ISO date]",
  "agents_run": ["code", "security", "test_coverage", "api_contract"],
  "summary": {
    "blocking": [count],
    "important": [count],
    "suggestions": [count]
  },
  "findings": [
    {
      "id": "B1",
      "severity": "BLOCKING",
      "agents": ["B"],
      "location": "src/main/java/.../PaymentController.java:42",
      "issue": "...",
      "recommendation": "..."
    }
  ]
}
```

This JSON can be pasted into a Jira comment or PR description automation.

## Conflict Resolution

When agents return conflicting findings (e.g., Agent A says "simplify this method" but Agent C says "this method needs more tests before refactoring"):

- Present both perspectives
- Flag it as NEEDS DISCUSSION
- Do not silently pick one — let the engineer decide

## Key Constraints

- This skill orchestrates other skills — it does not duplicate their logic
- Never auto-dispatch without user confirmation (HARD-GATE above)
- Never modify code — this skill is read-only
- If an agent times out or errors, note it in the report and flag those areas for manual review
