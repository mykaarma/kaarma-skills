---
name: auditing-ux-ui
description: Use when reviewing PM-built prototypes, wireframes, Figma mockups, or UI screens for usability gaps, UX issues, and UI quality. Triggers on requests like "review this design", "audit this prototype", "UX feedback", or "check this UI".
---

# UX/UI Audit for PM Prototypes

## When to Use This Skill

Use this skill when:
- **Reviewing PM prototypes**: Lo-fi wireframes, hi-fi mockups, clickable prototypes, or live builds
- **Pre-handoff design review**: Before a design is handed to engineering
- **Spot-checking UI quality**: Catching usability, accessibility, or visual issues
- **Generating structured feedback**: Producing actionable critique with severity levels

**Keywords**: UX audit, UI review, usability, prototype feedback, design review, heuristics, accessibility, wireframe, Figma

## How to Run an Audit

### Step 1: Gather Context

Before auditing, establish:

| Field | Examples |
|-------|---------|
| **Product type** | B2B dashboard, internal admin tool, mobile consumer app |
| **Target user** | Service advisors (low tech literacy, high pressure, tablet/desktop), developers, first-time consumers |
| **Key user goal** | What is the user trying to accomplish in this specific flow? |
| **Prototype stage** | Lo-fi wireframe / Hi-fi mockup / Clickable prototype / Live build |
| **Known constraints** | Existing design system, mobile-first, WCAG AA required |
| **PM's open questions** | Any specific areas they want scrutinized |

### Step 2: Audit Against the Framework

See [reference/audit-framework.md](reference/audit-framework.md) for the full audit checklist covering:

1. Task Completion & User Flows
2. Information Architecture & Navigation
3. Usability Heuristics (Nielsen's 10)
4. UI Clarity & Visual Design
5. Feedback & System States
6. Edge Cases & Missing States
7. Accessibility (WCAG 2.1 AA)
8. Mobile & Responsive
9. Engineering Feasibility Flags

### Step 3: Structure Output

**Executive Summary** — 2–3 sentences: what's working and the most critical gaps.

**Critical Issues** — blockers; users will fail or be seriously confused
> Issue → Why it matters → Specific recommendation

**Major Issues** — significant friction; users will struggle but may get through
> Issue → Why it matters → Specific recommendation

**Minor Issues** — polish, small inconsistencies (bullet list)

**Engineering Flags** — underspecified interactions, design system conflicts, ambiguous states, risky builds

**Top 3 Priorities** — if the team can only fix 3 things before next review

## Severity Reference

| Level | Definition |
|-------|-----------|
| **Critical** | Users will fail the task or be seriously confused |
| **Major** | Significant friction — users may struggle but get through |
| **Minor** | Polish issues, small inconsistencies, rough edges |

## Common PM Prototype Blind Spots

PMs almost always design the happy path. Flag these proactively:

- **Empty states** — what does the screen look like with no data?
- **Error states** — network failure, server error, invalid input
- **Long content** — very long names, large datasets, many list items
- **Permission/access states** — user doesn't have access to this feature
- **Loading states** — what does the UI show while data is fetching?
- **Returning vs. first-time users** — are they treated differently where it matters?

## Standalone Prompt

To run this audit outside Claude Code (e.g., pasting into Claude.ai or another AI), use the ready-to-use prompt in [reference/audit-prompt.md](reference/audit-prompt.md).
