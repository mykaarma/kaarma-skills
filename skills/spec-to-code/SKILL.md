---
name: spec-to-code
description: "Spec-driven development loop — parses a spec into missions, executes them with test validation, loops until all acceptance criteria pass. Use when you have a written spec and want systematic implementation."
---

# Spec-to-Code

## Overview

Turn a written spec into passing code through five disciplined phases: Parse, Plan, Execute, Verify, Report. Each phase gates the next — no skipping ahead.

**Announce at start:** "I'm using the spec-to-code skill. Starting Phase 1: PARSE."

**Prerequisites:**
- A spec document (pass path as argument, or found in `docs/plans/`)
- A git worktree (see `using-git-worktrees` if not already set up)
- Value & Viable brief completed (guardrail G11 — no code without justification)

---

## Phase 1: PARSE

**Goal:** Extract everything needed to build, in structured form.

### Steps

1. Read the spec. If a path was passed as argument, read that file. Otherwise scan `docs/plans/` for the most recent spec document.
2. Extract and output the following sections:

```markdown
## Parsed Spec

**Goal:** [one sentence]

**Acceptance Criteria:**
- AC1: [measurable criterion]
- AC2: ...

**Constraints:**
- [hard limit, e.g. "must not break existing /api/v1 endpoints"]

**Out of Scope:**
- [explicitly excluded items from spec]

**Ambiguities / Questions:**
- [anything unclear that needs clarification before planning]
```

3. If there are ambiguities, ask the user to clarify before proceeding. Do not proceed to Phase 2 with unresolved questions that would change the implementation.

4. Derive the **Mission List** — a numbered set of discrete implementation units:

```markdown
## Mission List

M1: [short verb phrase, e.g. "Add dealer notification preference entity and migration"]
M2: [e.g. "Implement service layer CRUD for notification preferences"]
M3: [e.g. "Expose REST endpoints with pagination"]
M4: [e.g. "Write integration tests for preference endpoints"]
```

**Mission sizing:** Each mission should be completable in one focused session. If a mission would touch more than 5 files, split it.

---

## Phase 2: PLAN

**Goal:** For each mission, specify exactly what to build and test.

### Steps

For each mission produce:

```markdown
### M[N]: [Mission Title]

**Files to create:**
- `exact/path/to/NewFile.java` — [purpose]

**Files to modify:**
- `exact/path/to/Existing.java:45-80` — [what changes]

**Tests to write:**
- `tests/exact/path/TestClass.java` — [what behaviors to cover]

**Dependencies:**
- Depends on: M[X] (reason: needs entity defined in M[X])
- Blocks: M[Y]

**Can run in parallel with:** M[Z] (disjoint file sets, no shared state)

**Guardrail check:**
- G1: [ ] No Authorization header — cookie auth only
- G2: [ ] Soft delete only
- G3: [ ] uuid in API responses, not id
- G6: [ ] Business logic in service layer
- G8: [ ] List endpoints paginated
```

### Dependency Graph

After all missions are planned, output the dependency graph:

```
M1 → M2 → M3 → M4
          ↗
     M5 (parallel with M2)
```

### Hard Gate — PLAN → EXECUTE

**Do not proceed until the user confirms the plan.**

Output:

```
Plan complete. Missions: M1–M[N]. Dependency graph above.

Parallel opportunities: [list which missions can run concurrently]

Please review and confirm to proceed to EXECUTE, or request changes.
```

Wait for explicit confirmation ("confirmed", "proceed", "looks good", etc.).

---

## Phase 3: EXECUTE

**Goal:** Implement each mission, validate with tests, fix failures before moving on.

### Execution Order

Follow the dependency graph from Phase 2. Execute in dependency order. Missions with no dependency on each other may be dispatched as parallel agents (see `dispatching-parallel-agents`).

### Per-Mission Loop

For each mission M[N]:

```
1. Announce: "Executing M[N]: [title]"
2. Implement the changes specified in the plan
3. Run the targeted tests for this mission
4. If tests PASS → mark mission complete, continue to next
5. If tests FAIL → enter Fix Mode (see below)
```

### Fix Mode

When tests fail after implementing a mission:

```
Attempt 1: Read the failure output. Diagnose root cause. Apply fix. Re-run tests.
Attempt 2: If still failing — try a different approach. Re-run tests.
Attempt 3: If still failing — try once more with a minimal targeted fix. Re-run tests.
Attempt 4 (never): STOP. Do not retry a fourth time.
```

After 3 failed fix attempts on a single mission:

```
BLOCKED: M[N] — [mission title]

Failure after 3 fix attempts:
[paste the test failure output]

Root cause hypothesis: [your best diagnosis]

Options:
1. Descope this mission and continue with remaining missions
2. Revise the plan for this mission (provide updated approach)
3. Debug together (share more context about the failure)

Awaiting instruction.
```

### Circuit Breaker

Track consecutive mission failures (a mission that could not be fixed after 3 attempts counts as 1 failure). If **3 or more consecutive missions fail**:

```
CIRCUIT BREAKER TRIPPED

3 consecutive missions have failed to pass tests after retries.
This suggests a systemic issue — a wrong assumption in the plan, a missing dependency, or an environment problem.

Missions failed: M[X], M[Y], M[Z]
Last failure output: [paste]

Stopping execution. Please diagnose the root cause before we continue.
```

Do not proceed with any further missions until the user explicitly resets execution.

### Parallel Dispatch

For missions identified as parallelizable in Phase 2, use the `dispatching-parallel-agents` pattern:

```typescript
// Each independent mission becomes a focused agent prompt:
Task("Execute M[N]: [title]. Files: [list]. Tests to pass: [list]. Return: summary of changes made and test results.")
Task("Execute M[M]: [title]. Files: [list]. Tests to pass: [list]. Return: summary of changes made and test results.")
```

Review all agent returns before marking missions complete. Verify no file conflicts between parallel agents.

### Progress Reporting

After each mission completes (pass or blocked), output a one-line status:

```
[DONE] M1: Add dealer notification preference entity ✓ (3 tests passing)
[DONE] M2: Service layer CRUD ✓ (7 tests passing)
[BLOCKED] M3: REST endpoints — awaiting user input
```

---

## Phase 4: VERIFY

**Goal:** Confirm the full implementation satisfies every acceptance criterion from Phase 1.

### Steps

1. Run the full test suite: `mvn test` / `npm test` / `pytest` as appropriate for the project.

2. For each acceptance criterion from Phase 1, explicitly check it:

```markdown
## Acceptance Criteria Verification

AC1: [criterion text]
Status: PASS / FAIL
Evidence: [test name, or manual check result]

AC2: [criterion text]
Status: PASS / FAIL
Evidence: ...
```

3. Run the guardrail checklist one final time across all changed files:

```
G1 (auth): PASS / FAIL — [file:line if fail]
G2 (soft delete): PASS / FAIL
G3 (uuid not id): PASS / FAIL
G4 (no secrets): PASS / FAIL
G5 (parameterized queries): PASS / FAIL
G6 (service layer): PASS / FAIL
G7 (utils wrapper): PASS / FAIL
G8 (pagination): PASS / FAIL
G9 (no PII logged): PASS / FAIL
G10 (no var): PASS / FAIL
```

If any guardrail fails: fix it before declaring Phase 4 complete. Guardrail violations are blocking (per AGENTS.md).

---

## Phase 5: REPORT

**Goal:** Clear summary so the engineer knows exactly what was built and what's left.

### Output Format

```markdown
## Spec-to-Code Report

**Spec:** [filename or title]
**Date:** [today]

### Missions Summary

| Mission | Status | Tests |
|---------|--------|-------|
| M1: [title] | DONE | 3 passing |
| M2: [title] | DONE | 7 passing |
| M3: [title] | BLOCKED | — |

### Acceptance Criteria

| Criterion | Status |
|-----------|--------|
| AC1: [text] | PASS |
| AC2: [text] | FAIL — [reason] |

### Guardrails
All G1–G11: PASS (or list failures)

### Criteria Not Met
[For each FAIL criterion: explain what's missing and why]

### Recommended Next Steps
1. [action to address blocked missions or failed criteria]
2. ...

### Files Changed
[List of files created or modified]
```

After the report, offer the completion workflow:

```
Implementation complete (or partially complete — see blocked items above).

Next: Use finishing-a-development-branch to commit, open PR, and clean up the worktree.
```

---

## Worked Example

**Spec excerpt:**
> Add an API so dealers can set notification preferences (email/SMS) per event type. Must be paginated, must not expose DB primary keys.

**Phase 1 output:**

```
Goal: Dealer notification preference management API

Acceptance Criteria:
- AC1: GET /api/v1/dealers/{uuid}/notification-preferences returns paginated list
- AC2: POST/PUT/DELETE (soft) endpoints work correctly
- AC3: No DB primary keys (id) in any response — uuid only
- AC4: 80%+ test coverage on service layer

Constraints: Must not break existing /api/v1/dealers endpoints
Out of Scope: UI changes, email/SMS sending logic

Mission List:
M1: Add NotificationPreference entity and Flyway migration
M2: Repository and service layer with CRUD
M3: REST controller with paginated GET, POST, PUT, soft DELETE
M4: Integration tests for all endpoints
```

**Phase 2 dependency graph:**
```
M1 → M2 → M3 → M4
```
No parallel opportunities (linear dependency chain).

**Phase 3 execution:**
- M1: Creates entity + migration, runs `mvn test -pl data-layer` → 2 tests passing
- M2: Implements service, runs service tests → 6 passing
- M3: Adds controller, runs controller tests → 4 passing
- M4: Integration tests → 9 passing; checks G3 (uuid only) — confirmed

**Phase 4:** Full suite 21 tests passing. AC1–AC4 all PASS. G1–G11 all PASS.

**Phase 5:** Report shows 4/4 missions done, 4/4 criteria met. Hands off to `finishing-a-development-branch`.

---

## Integration with Other Skills

| Skill | When to Use |
|-------|-------------|
| `writing-plans` | If you need a lower-level bite-sized task plan inside a mission |
| `dispatching-parallel-agents` | For parallel mission execution |
| `subagent-driven-development` | Alternative execution path for independent missions in current session |
| `systematic-debugging` | When Fix Mode isn't resolving a failure |
| `test-driven-development` | Apply TDD within each mission's implementation |
| `finishing-a-development-branch` | After Phase 5 Report — commit, PR, cleanup |
| `verification-before-completion` | Run before claiming Phase 4 complete |

---

## Quick Reference

```
PARSE  → extract AC + missions
PLAN   → file map + dependency graph + [GATE: user confirmation]
EXECUTE → per-mission: implement → test → fix (max 3) → [circuit breaker at 3 consecutive failures]
VERIFY  → full suite + AC checklist + guardrail scan
REPORT  → summary table + next steps
```
