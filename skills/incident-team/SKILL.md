---
name: incident-team
description: "Dispatch parallel investigation agents during a production incident — timeline builder, root cause analyzer, impact assessor, and mitigation finder. Use for P1/P2 incidents, production down, data integrity issues."
---

# Incident Team — Parallel Incident Investigation

## Overview

Production incidents waste time when investigation is sequential. This skill dispatches four specialized agents simultaneously to cover the full incident picture — timeline, root cause, impact, and mitigation — then synthesizes into an actionable incident brief.

**Speed is the priority.** Parallel investigation compresses a 40-minute sequential investigation into ~10 minutes.

## When to Use

**Use for:**
- P1 incidents: production down, payment failures, data loss
- P2 incidents: degraded functionality affecting dealers, latency spikes, cascading failures
- Data integrity alerts: duplicate records, missing data, corrupted state
- Security incidents: unauthorized access, credential exposure, unusual traffic patterns
- Any situation where "what broke, when, and who is affected" are all unknown

**Do NOT use when:**
- Issue is already identified and you just need a fix (go directly to `/debugging-errors`)
- It's a non-production environment with no dealer impact
- You already have a clear root cause and just need a rollback
- The issue has been resolved and you're doing a post-mortem

## Step 1: Gather Incident Context

Before dispatching, collect:

```
Incident brief:
- Service(s) affected: [e.g., payment-service, kmanage-api]
- Symptom: [e.g., 500s on POST /payments, RabbitMQ queue depth spiking]
- First reported: [timestamp or "~X minutes ago"]
- Error sample (paste stack trace or log snippet if available):

  [paste here]

- Recent deploys you're aware of: [or "unknown"]
- Jira incident ticket (if created): [MYK-XXXX or "not yet"]
```

If the user provides a Jira incident ticket number, read it with the Atlassian MCP tool before dispatching.

## Step 2: Confirm Before Dispatch

<HARD-GATE>
Confirm the dispatch plan:

```
Ready to dispatch the incident team for: [symptom description]

Agents to be dispatched in parallel:
  A. Timeline Builder    — git log, deploys, Jira tickets → chronological timeline
  B. Root Cause Analyzer — error patterns, logs, code → probable root causes
  C. Impact Assessor     — affected dealers/users, blast radius estimate
  D. Mitigation Finder   — rollback options, quick fixes, feature flags

Proceed? (yes/no)
```

Do not dispatch until confirmed.
</HARD-GATE>

## Step 3: Dispatch Agents in Parallel

Dispatch all four agents simultaneously.

**Agent A — Timeline Builder**
```
You are building a chronological incident timeline. Your goal is to establish
WHAT CHANGED in the 48 hours before this incident, in order.

1. Run: git log --since="48 hours ago" --oneline --all -- [affected service paths]
2. Check for recent Jenkins deploys: look for deploy markers in git tags or commit messages
3. Search Jira for recently closed tickets affecting these services:
   - Use Atlassian MCP: search for tickets transitioned to Done in the last 48 hours
   - Filter by component/service if possible
4. Note any config changes, environment variable updates, or infrastructure changes mentioned
   in commit messages or ticket descriptions

Build a timeline in this format:
  [timestamp] — [event type: DEPLOY/COMMIT/CONFIG/TICKET] — [description] — [author]

Flag any event that occurred within 30 minutes of the incident start as HIGH SUSPICION.

Context:
- Service(s): [service names]
- Incident start: [timestamp]
- Error: [error description]
```

**Agent B — Root Cause Analyzer**
```
You are analyzing the root cause of a production incident.

1. Read the error/stack trace provided. Identify:
   - The specific class and method where the failure originates
   - Any chained exceptions (look for "Caused by:" chains)
   - Any relevant error codes or messages

2. Search the codebase for the identified class/method:
   - Read the surrounding code
   - Look for recent changes (git blame or git log -p)
   - Check if there are known similar issues in git history

3. Hypothesize up to 3 probable root causes, ranked by likelihood:
   - Hypothesis 1: [most likely] — supporting evidence
   - Hypothesis 2: [second most likely] — supporting evidence
   - Hypothesis 3: [less likely but worth ruling out] — supporting evidence

4. For each hypothesis, state what would CONFIRM or RULE IT OUT.

Context:
- Service(s): [service names]
- Stack trace / error: [error text]
- Recent changes: [provide Timeline Builder output if available, otherwise "unknown"]
```

**Agent C — Impact Assessor**
```
You are assessing the blast radius of a production incident.

1. Identify which dealers/users are affected:
   - Is the failure isolated to specific dealer UUIDs, or system-wide?
   - Is it affecting all requests or a percentage (check for feature flags, A/B segments)?
   - Are there specific workflows impacted (payments, messaging, scheduling)?

2. Estimate scope:
   - How many dealers could be affected? (check service's dealer coverage)
   - Are any Tier 1 / high-volume dealers in the affected set?
   - Is data being silently corrupted (harder to recover) vs. operations failing noisily?
   - Are downstream services also failing (cascading impact)?

3. Assess data integrity risk:
   - Could this incident have caused duplicate records, missed writes, or inconsistent state?
   - If so, which tables/collections and what time range?

4. Rate overall impact:
   - CRITICAL: Multiple Tier 1 dealers down, data corruption possible, payments failing
   - HIGH: Many dealers affected, core workflow broken but no data loss yet
   - MEDIUM: Some dealers affected, degraded experience, no data integrity risk
   - LOW: Isolated, cosmetic, or low-traffic path

Context:
- Service(s): [service names]
- Error: [error description]
- Error rate or frequency if known: [e.g., "100% of requests" or "~20 errors/min"]
```

**Agent D — Mitigation Finder**
```
You are finding the fastest path to restore service for a production incident.

1. Rollback option:
   - What was the last stable commit/deploy? (use git log)
   - Is a rollback via Jenkins feasible right now? What is the rollback risk?
   - Are there database migrations that would make rollback unsafe?

2. Quick fix option:
   - Based on the error/stack trace, is there a targeted code fix that could be deployed fast?
   - Is there a null check, try-catch, or config change that would stop the bleeding?
   - Can it be deployed as a hotfix without full CI pipeline?

3. Feature flag / circuit breaker option:
   - Is there an existing feature flag that could disable the broken feature?
   - Is there a circuit breaker that could be tripped manually?
   - Can the affected endpoint be temporarily disabled at the Kong/load balancer level?

4. Mitigation ranking:
   - FASTEST: [option + estimated time to implement + risk level]
   - SAFEST: [option + estimated time to implement + risk level]
   - RECOMMENDED: [your recommendation with reasoning]

Context:
- Service(s): [service names]
- Error: [error description]
- Recent changes: [provide Timeline Builder output if available]
```

## Step 4: Synthesize the Incident Brief

After all agents return, synthesize into a single incident brief. If Agent D found a quick fix, lead with that — responders need the action item first.

### Output Format

```
## Incident Brief
Service: [service name]
Severity: [P1/P2]
Generated: [timestamp]

---

### RECOMMENDED ACTION
[If Agent D has a clear winner, state it here with estimated time]
> Example: "Roll back to commit abc1234 (deployed 2h ago). Estimated: 5 min.
>  Risk: LOW — no DB migrations in recent commits."

---

### Timeline
[Agent A output — condensed]
  HH:MM — DEPLOY — payment-service v2.4.1 — jenkins-bot (HIGH SUSPICION: 15min before incident)
  HH:MM — COMMIT — fix NPE in PaymentProcessor — jane.doe
  ...

---

### Root Cause Hypothesis
[Agent B output — top 3 ranked]
  1. [MOST LIKELY] NullPointerException in PaymentProcessor.process() due to missing null
     check introduced in v2.4.1. Evidence: stack trace matches line 142, commit abc1234
     changed this method. CONFIRM by reading PaymentProcessor.java:142.

  2. [POSSIBLE] ...

---

### Impact
[Agent C output]
  Severity: CRITICAL / HIGH / MEDIUM / LOW
  Dealers affected: [count or "all" or "unknown"]
  Data integrity risk: YES / NO / UNKNOWN
  Cascading: [yes/no + which downstream services]

---

### Mitigation Options
[Agent D output]
  FASTEST: [option] — [time] — [risk]
  SAFEST:  [option] — [time] — [risk]

---

### Open Questions
- [anything agents flagged as unknown that needs human input]
```

### Jira-Ready Format

After the incident brief, emit a compact version for pasting into the Jira incident ticket description:

```
*Incident Brief — [service] — [date]*

*Recommended Action:* [one sentence]

*Timeline (last 48h):*
[bullet list of HIGH SUSPICION events]

*Root Cause (hypothesis):*
[top hypothesis in 2 sentences]

*Impact:*
[severity + dealer count + data integrity risk]

*Mitigation:*
[fastest option + safest option]
```

## Conflict Resolution

When agents return contradictory findings:
- Agent A says no recent deploy, Agent B says code change caused the bug — note both, flag as NEEDS VERIFICATION
- Agent C says impact is LOW, but Agent D says rollback is risky — surface both, let the incident commander decide
- Never silently discard an agent's finding

## Key Constraints

- This skill is for active incidents — bias toward speed, not comprehensiveness
- Agents work from what is available; if logs or deploys are inaccessible, they will note gaps
- This skill does NOT execute rollbacks or code fixes — it finds options for humans to decide
- If an agent errors or times out, mark that section as INCOMPLETE and proceed with others
