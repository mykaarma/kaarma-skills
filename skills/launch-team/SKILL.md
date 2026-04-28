---
name: launch-team
description: "Dispatch parallel pre-launch check agents before releasing a feature or service — security, localization, performance, observability, and launch checklist. Produces a GO / NO-GO / CONDITIONAL GO verdict."
---

# Launch Team — Parallel Pre-Launch Checks

## Overview

Releasing a feature without a structured pre-launch review is how regressions reach production. This skill dispatches five specialized agents in parallel to cover every dimension of launch readiness, then produces a clear GO / NO-GO / CONDITIONAL GO verdict.

**Use this before every significant feature release, new service launch, or major version change.**

## When to Use

**Use when:**
- A feature is code-complete, tested, and about to be released to production
- Launching a new microservice for the first time
- Releasing a change that touches payments, auth, dealer data, or localized UI
- After a significant refactor before it reaches canary/master
- Before enabling a feature flag for all dealers

**Do NOT use when:**
- You are in active incident response (use `/incident-team` instead)
- The change is a hotfix that needs to go out immediately (launch checks will slow you down — apply judgment)
- The change is purely internal (no API surface changes, no UI, no data model changes, no new dependencies)
- You are doing a dependency version bump with no logic changes

## Step 1: Gather Launch Context

Before dispatching, establish:

```
Launch context:
- Feature / service name: [e.g., "Dealer Notification Preferences API v2"]
- Jira ticket(s): [MYK-XXXX]
- Target markets: [US only | US + Middle East | all markets]
- Platforms: [backend API | frontend | both]
- API changes: [yes/no — new or modified endpoints]
- Database changes: [yes/no — migrations, new tables, schema changes]
- External integrations: [yes/no — new third-party APIs, webhooks]
- Feature flag controlled: [yes/no]
- Rollback plan: [known | needs to be defined]
```

## Step 2: Confirm Before Dispatch

<HARD-GATE>
Confirm the dispatch plan:

```
Ready to dispatch the launch team for: [feature name]

Agents to be dispatched in parallel:
  A. Security Check       — auth, injection, PII, guardrails (auditing-security skill)
  B. Localization Check   — RTL, currencies, date formats (auditing-localization skill)
  C. Performance Check    — N+1 queries, indexes, pagination, unbounded lists
  D. Observability Check  — logging, metrics, alerts (engineering-standards/observability.md)
  E. Launch Checklist     — engineering-standards/launch-checklist.md

Note: Agent B will be scoped to target markets: [markets from context]

Proceed? (yes/no)
```

Wait for explicit confirmation.
</HARD-GATE>

## Step 3: Dispatch Agents in Parallel

Dispatch all five agents simultaneously.

**Agent A — Security Check**
```
You are a pre-launch security auditor. Invoke the auditing-security skill and apply it
to the following feature/service before release.

Focus areas for pre-launch:
- All new endpoints: are they behind authentication? Is dealer context validated?
- New data flows: is PII handled correctly — not logged, not exposed in responses?
- Input validation: are all new inputs validated and sanitized?
- SQL/NoSQL injection: are all new queries using parameterized statements?
- Secrets: are any new API keys or credentials managed via secrets manager, not hardcoded?
- New external integrations: are requests going out over HTTPS? Are responses validated?
- Authorization: can a dealer access another dealer's data through any new endpoint?
- Dependency security: are any new dependencies known to have CVEs?

Return findings as:
- BLOCKER: launch must not proceed until resolved
- WARNING: should be resolved before GA launch
- INFO: monitor after launch

For each finding: location, issue, recommendation.
Context: [feature description, diff or file paths]
```

**Agent B — Localization Check**
```
You are a pre-launch localization auditor. Invoke the auditing-localization skill and
apply it to the following feature before release.

Target markets: [US only | US + Middle East | all markets]

Focus areas for pre-launch:
- Are all user-facing strings in resource bundles (no hardcoded English)?
- Are currency amounts using localeAttributes.currency, not hardcoded "$"?
- Are date/time values formatted using localeAttributes.date, not hardcoded patterns?
- Are CSS layout properties using logical properties (margin-inline-start) not physical (margin-left)?
- Are directional icons (arrows, progress bars) mirrored for RTL markets?
- Are phone number inputs using libphonenumber with international support?
- Is date formatting done client-side, not server-side?
- Are there any hardcoded locale checks (if locale === "ar-qa") instead of attribute checks?

If target market is US only, flag only issues that would block future expansion.
If Middle East is in scope, flag all RTL and currency issues as BLOCKER.

Return findings as: BLOCKER | WARNING | INFO
For each: location, issue, recommendation.
Context: [feature description, diff or file paths]
```

**Agent C — Performance Check**
```
You are a pre-launch performance auditor.

Analyze the following code changes for performance issues that could cause problems
at production scale (thousands of dealers, millions of records).

Check for:
1. N+1 query patterns:
   - Loops that call the database inside each iteration
   - Missing eager loading / JOIN fetch for collections
   - Calling findById() inside a loop instead of findAllById()

2. Missing database indexes:
   - New columns used in WHERE clauses without indexes
   - Foreign key columns without indexes
   - Composite query patterns that need compound indexes

3. Unbounded list queries:
   - findAll() or equivalent without LIMIT
   - Any list endpoint missing offset/limit pagination (myKaarma standard: max 100)
   - Kafka/RabbitMQ consumer batch sizes not bounded

4. Missing caching:
   - Frequently read, rarely written data fetched on every request
   - Dealer configuration or feature flags fetched per-request without cache

5. Blocking operations in async context:
   - Thread.sleep() or synchronous blocking calls in async handlers
   - Missing timeouts on external HTTP calls

6. Expensive operations in request path:
   - Heavy computation that could be async/deferred
   - Large object serialization on every request

Return findings as: BLOCKER | WARNING | INFO
For each: location, the query or pattern, estimated impact, recommendation.
Context: [feature description, diff or file paths]
```

**Agent D — Observability Check**
```
You are a pre-launch observability auditor. Reference engineering-standards/observability.md
for myKaarma standards.

Verify that the following changes have adequate observability for production operation:

1. Structured logging:
   - Are new service flows logged with appropriate levels (INFO for normal, WARN for degraded, ERROR for failures)?
   - Do log messages include correlation IDs (dealerUUID, customerUUID, requestUUID)?
   - Is PII absent from all log messages?
   - Are exceptions logged with full stack trace at ERROR level?

2. Metrics:
   - Are new API endpoints instrumented with latency histograms?
   - Are error rates tracked (HTTP 4xx, 5xx counts)?
   - Are background jobs / consumers instrumented with job duration and failure counts?
   - Are business-level metrics emitted for key operations (payment processed, message sent)?

3. Alerts:
   - Are there alert rules for error rate spikes on new endpoints?
   - Is there a latency alert (p99 > threshold) for new critical paths?
   - Are there alerts for new background job failures?

4. Health checks:
   - Does the service expose a /health or /actuator/health endpoint?
   - Do new external dependencies have health checks?

5. Runbook:
   - Is there a runbook or CLAUDE.md entry describing how to operate/debug the new feature?

Return findings as: BLOCKER | WARNING | INFO
For each: what is missing, where it should be added, example of correct instrumentation.
Context: [feature description, diff or file paths]
```

**Agent E — Launch Checklist**
```
You are a pre-launch checklist auditor. Read engineering-standards/reference/launch-checklist.md
and run through every item for the following feature.

For each checklist item, return one of:
  PASS   — requirement met (brief evidence)
  FAIL   — requirement not met (what is missing)
  N/A    — not applicable to this feature (brief reason)
  UNKNOWN — cannot determine from available information (what is needed)

After running all items, summarize:
- Total PASS / FAIL / N/A / UNKNOWN counts
- List all FAIL items — these are launch blockers
- List all UNKNOWN items — these need human verification before launch

Context: [feature description, diff, Jira ticket MYK-XXXX if available]
```

## Step 4: Aggregate and Produce Launch Readiness Report

After all agents return, aggregate into the launch readiness report.

### Verdict Logic

| Condition | Verdict |
|-----------|---------|
| Any BLOCKER from any agent, OR any FAIL from Agent E | NO-GO |
| No BLOCKERs or FAILs, but 3+ WARNINGs | CONDITIONAL GO |
| No BLOCKERs or FAILs, fewer than 3 WARNINGs | GO |
| Multiple UNKNOWN items from Agent E | CONDITIONAL GO (pending verification) |

### Output Format

```
## Launch Readiness Report
Feature: [name]
Ticket: [MYK-XXXX]
Date: [date]
Target markets: [markets]

### Verdict: [GO | NO-GO | CONDITIONAL GO]

---

### BLOCKERS — Must resolve before launch ([count])

[B1] [Agent: A/B/C/D/E] — [location]
Issue: ...
Resolution: ...

---

### CONDITIONS (for CONDITIONAL GO) ([count])

[C1] [Agent: A/B/C/D/E] — [description]
Condition: resolve [X] before enabling for [all dealers / Middle East / etc.]

---

### WARNINGS — Resolve before GA ([count])

[W1] ...

---

### CHECKLIST SUMMARY (from Agent E)
PASS: [count] | FAIL: [count] | N/A: [count] | UNKNOWN: [count]
[List all FAIL and UNKNOWN items]

---

### What's Ready
- [positive observations — what was done well]

---

### Suggested Launch Timeline

[Based on findings]:
- If GO: "Ready to release. Proceed when convenient."
- If CONDITIONAL GO: "Estimated [X] hours to resolve conditions.
  Recommend targeting [date] for [partial/full] rollout."
- If NO-GO: "Estimated [X] hours/days to resolve [N] blockers.
  Re-run /launch-team after fixes."
```

## Conflict Resolution

When agents report conflicting severity:
- Agent A marks an issue WARNING, Agent D marks same area BLOCKER — take the higher severity
- Agent B flags localization as N/A (US only), but Agent E checklist flags it FAIL — surface the conflict, ask the user to clarify market scope
- Never silently drop a finding

## Key Constraints

- This skill orchestrates other skills — it does not duplicate their logic
- It is read-only: it produces a report, it does not fix issues or deploy code
- Never auto-dispatch without the user's explicit confirmation (HARD-GATE above)
- If an agent is unavailable or times out, mark that dimension as INCOMPLETE in the report — do not produce a GO verdict with incomplete checks
- For Middle East / RTL market launches, Agent B findings are treated as equal in weight to Agent A (security) — localization failures are launch blockers in those markets
