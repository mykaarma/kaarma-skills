---
name: value-and-viable
description: "You MUST use this before any implementation work — building features, creating services, adding functionality, or modifying behavior. Validates that we are solving the right problem, aligned on the user need, and have a plan to prove success."
---

# Value & Viable — Build the Right Thing

## Overview

Every line of code we ship must be operationalized, maintained, and owned long-term. Building is easy; building the **right** thing is hard. This skill ensures we understand WHY before we start HOW.

<HARD-GATE>
Do NOT write any code, scaffold any project, create any implementation plan, or take any implementation action until all six stages below are completed and acknowledged. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## When to Use This Skill

Use **before** any implementation work:
- New features or services
- Significant modifications to existing functionality
- New integrations or data pipelines
- Any work that will require ongoing maintenance and operational ownership

**Don't use for:**
- Bug fixes where the root cause is already clear and isolated
- Configuration changes or environment updates
- Documentation-only changes

## The Six-Stage Gate

You MUST complete these stages **in order** before any implementation begins.

### Stage 1 — Problem Statement

Articulate the observed problem or request clearly.

- What is happening (or not happening)?
- Who is affected? (Specific user personas, not "users")
- What triggered this work? (Customer complaint, metric decline, strategic initiative)
- What is the impact of **not** solving this?

### Stage 2 — Root Cause Analysis

**Do not solve symptoms.** Dig past the surface to the real underlying problem.

**Genchi Genbutsu — "Go and See":** Validate your understanding by observing the user's actual environment and workflow, not relying solely on secondhand reports or descriptions. Users develop workarounds and become blind to their own needs (the **"Expert Problem"** — people become so acclimated to problems that they can no longer see them). Needs become obvious only after they are solved, so people usually describe pain-points in terms of existing solutions, not underlying needs.

Use the **"5 Whys"** technique:

```
Problem: Dealers are requesting a new daily summary report.
  Why? → They can't find yesterday's service activity quickly.
  Why? → The existing dashboard only shows real-time data.
  Why? → Historical views were never built because real-time was the original requirement.
  Why? → The original requirement assumed dealers check the dashboard throughout the day.
  Why? → That assumption was wrong — most service managers review activity once, the next morning.

Root cause: The dashboard was designed for real-time monitoring, but the primary use case
is next-day review. The solution isn't a new report — it's a historical view in the existing dashboard.
```

**Gate check:** *Are we solving the root cause, or patching a symptom?*

> **Red flags that you're solving a symptom:**
> - The solution adds a workaround for an existing tool's limitation
> - The user asked for a specific feature (features are solutions, not problems)
> - The problem keeps recurring in different forms
> - You can't explain the root cause in one sentence
> - You're relying on what the user *said* they need rather than what you *observed* them struggle with

### Stage 3 — User Need Alignment

Define the **user need** as a testable outcome — not a feature, not a solution.

**User Need format:**

> *[User persona] needs to [outcome/capability] so that [business value].*

For richer context, also express it as a **Job To Be Done (JTBD):**

> *When [situation/trigger], I want to [motivation/need], so I can [expected outcome].*

**Examples:**

| ❌ Feature-as-need (wrong) | ✅ Outcome-as-need (right) |
|---------------------------|--------------------------|
| "Dealers need a daily report" | "Service managers need to review yesterday's activity in under 2 minutes so they can start the day with full context" |
| "We need a search API" | "Support agents need to find customer history within 10 seconds so they can resolve cases without asking customers to repeat themselves" |
| "Build a notification system" | "When a customer responds to an MPI, service advisors need to know within 30 seconds so that repair approvals aren't delayed" |

**Gate check:** *Does the user need describe an outcome, not a feature?*

### Stage 4 — Solution Exploration

**Brainstorm multiple approaches before committing to one.** Testing ideas early is cheap; pivoting after implementation is expensive.

Start by reframing the user need as a **"How Might We" (HMW)** question to keep ideation focused on the outcome, not a predetermined solution:

> *How might we [user need from Stage 3]?*

Example: "How might we make service managers feel confident they have full context when starting their day?" — not "How might we build a daily report?"

Then explore:
- Propose **2-3 approaches** with trade-offs for each
- Consider: build vs. buy vs. reuse existing capability
- Evaluate each approach against the **user need** from Stage 3
- Select an approach with **explicit reasoning** for why it best meets the need

**Scope to the smallest testable increment.** For the selected approach, ask: *What is the smallest version we can ship to learn whether this solves the user need?* Full solutions are expensive to pivot away from. Identify the core interaction that proves or disproves value, and scope your first delivery to that.

> A historical view that only covers "yesterday" with no filters is a valid first increment. A full date-range picker with export and scheduling is not — that's a roadmap, not a starting point.

**REQUIRED SUB-SKILL:** Use the `brainstorming` skill for structured exploration if a dedicated brainstorming session is warranted.

If the `brainstorming` skill was already invoked earlier, reference its output here rather than duplicating work.

**Gate check:** *Did we evaluate multiple options, or did we jump to the first idea?*

### Stage 5 — Value & Viability Assessment

Validate the selected approach:

| Question | Answer required |
|----------|----------------|
| **Value** | What user/business outcome does solving this root cause drive? |
| **Business viability** | Will this help close deals, prevent churn, or drive expansion? What % of our user base does this impact? Is the impact large enough to justify the investment? |
| **Operationally viable** | Can we operationalize this? Is it deploy-able, train-able, support-able? Who owns it long-term? Will we need to hire or re-allocate resources? |
| **Evidence** | What data, user feedback, or direct observation supports building this? Is this a validated need or an assumption? |
| **Alternatives** | Why was this approach chosen over the others explored in Stage 4? |

> **If you can't confidently answer the business viability question, stop and have a conversation with the product manager and executive sponsor before proceeding.** Building something we can't justify is worse than not building it at all.

**Design-For checklist** — Before proceeding, confirm the solution accounts for:

| Principle | How is it addressed? |
|-----------|---------------------|
| **Measurement** | Can we instrument it to track success metrics? |
| **Adoption** | How will users discover and learn to use it? |
| **Usability** | Can users accomplish the task without training or support? |
| **Scalability** | Will it handle growth in users, data, or load? |
| **Failure** | What happens when it breaks? Is there a graceful fallback? |
| **Consistency** | Does it fit with existing product patterns and UX? |

### Stage 5b — Customer Validation Checkpoint

**Before committing to full build, validate the solution concept with real users.**

The viability assessment (Stage 5) confirms the approach makes sense internally. This checkpoint confirms it makes sense to the people who will actually use it.

Choose the **lightest-weight validation method** appropriate for the scope:

| Method | When to use | Examples |
|--------|------------|---------|
| **Mockup / wireframe walkthrough** | UI-facing features | Walk 2-3 users through a Figma prototype and observe where they hesitate or get confused |
| **Design spike / proof of concept** | Technical feasibility unknowns | Build the riskiest slice in a branch, demo it, and get feedback before committing |
| **Concierge test** | Workflow or process changes | Manually perform the proposed solution for a small group and measure whether it delivers the expected outcome |
| **Existing data analysis** | Behavior-based features | Analyze logs, usage data, or support tickets to confirm the assumed behavior pattern exists at scale |

**Gate check:** *Has at least one real user (or real user data) confirmed that this solution direction addresses their need?*

> If validation reveals a gap between what you planned and what users need, loop back to Stage 3 or Stage 4 — not forward into implementation. Cheap pivots happen here; expensive ones happen after launch.

### Stage 6 — Success Measurement Plan

Define **upfront** how we will prove the feature is valuable and usable.

| Dimension | What to define | Examples |
|-----------|---------------|---------|
| **Valuable** | Metrics proving user/business benefit | Adoption rate, time saved, revenue impact, support ticket reduction |
| **Usable** | Signals proving users can actually use it | Task completion rate, error rate, time-to-complete, user feedback scores |
| **Tracking** | Where and how metrics are collected | Analytics events, dashboards, user surveys, support ticket tags |
| **Threshold** | Numbers that define success vs. failure | ">60% adoption in 30 days", "<5% error rate", "NPS > 40" |
| **Kill criteria** | Numbers that trigger deprecation or pivot | "<10% adoption at 30 days → deprecate", "<50% task completion → redesign UX" |
| **Review cadence** | When to check and decide next steps | 30 / 60 / 90 day checkpoints |

**Kill criteria matter as much as success criteria.** Teams need explicit permission to stop investing. If the kill threshold is hit, the default action is to deprecate and reclaim the investment — not to "give it more time." Continuing past a kill threshold requires a new justification.

**Post-launch review:** Schedule a review at the first cadence checkpoint (typically 30 days). Return to this measurement plan, compare actuals against thresholds and kill criteria, and make an explicit keep / iterate / kill decision. The feature is not "done" at launch — it's done when it's proven valuable or removed.

**Gate check:** *If we can't define what success looks like, we can't build with confidence.*

---

## The Value & Viable Brief

Copy this template and complete it before implementation:

```markdown
## Value & Viable Brief

### Problem Statement
[What is happening? Who is affected? What triggered this?]

### Root Cause
[Result of 5 Whys or equivalent analysis. One sentence root cause.]

### User Need
[Persona] needs to [outcome] so that [business value].

### Approaches Considered
1. [Approach A] — [trade-offs]
2. [Approach B] — [trade-offs]
3. [Approach C] — [trade-offs]
Selected: [Which and why]

### Value & Viability
- Value: [outcome driven]
- Viable: [owner, maintenance cost]
- Evidence: [data/research supporting this]

### Risks & Open Questions
- [Assumption that hasn't been validated yet]
- [Dependency on another team or system]
- [Technical unknown that could change the approach]
- [Anything we'll learn only after shipping]

### Success Metrics
| Metric | Target | Kill threshold | Tracking | Review at |
|--------|--------|----------------|----------|-----------|
| [metric 1] | [success threshold] | [failure threshold] | [how] | [when] |
| [metric 2] | [success threshold] | [failure threshold] | [how] | [when] |

### Kill Criteria
If kill thresholds are hit at the first review checkpoint, default action is: **[deprecate / redesign / pivot to approach X]**
```

---

## Anti-Patterns

### "This is too simple to justify"
Simple things still need rationale. The brief can be short — a few sentences per section — but it must exist.

### "We already know why"
Then write it down. If it's obvious, it takes 30 seconds. If it's hard to articulate, you didn't actually know.

### "The PM told us to build it"
That's a request, not a root cause. PMs have context you may lack, but the root cause still needs to be understood by the person building it.

### "The customer asked for it"
Customers describe symptoms, not root causes. *"I need a report"* usually means *"I can't find information I need."* Dig deeper.

### "There's only one way to do this"
There are always alternatives. Even "do nothing" is an option worth evaluating.

### "We don't have time to explore options"
You don't have time to rebuild the wrong thing. 30 minutes of exploration saves weeks of wasted implementation.

### "We'll figure out success metrics later"
If you can't define success before building, you can't claim success after shipping. Define it now.

---

## When This Skill is Complete

You've completed the Value & Viable gate when:
- [ ] Root cause is identified (not a symptom)
- [ ] User need is stated as an outcome (not a feature)
- [ ] Multiple approaches were explored and one selected with reasoning
- [ ] Value and viability are documented
- [ ] Success metrics, thresholds, and review cadence are defined
- [ ] The brief is written and acknowledged

**Next step:** Proceed to implementation planning (use `writing-plans` or `building-features` skill).
