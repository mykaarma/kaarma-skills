---
name: auditing-localization
description: Use when reviewing code, UI screens, or features for localization compliance against myKaarma's attribute-based rendering standards. Triggers on requests like "check localization", "audit i18n", "review RTL support", or "is this locale-ready".
---

# Localization Audit for myKaarma Features

## When to Use This Skill

Use this skill when:
- **Reviewing code for locale compliance**: Checking that code uses attribute-based rendering, not hardcoded locale checks
- **Pre-launch localization review**: Before shipping a feature to a new market (Middle East, Quebec, Mexico, etc.)
- **Auditing RTL support**: Verifying layout, icons, and text alignment work correctly in RTL mode
- **Checking data formatting**: Ensuring currency, dates, times, and units follow dealer locale attributes
- **Validating i18n completeness**: Confirming all strings are externalized and no hardcoded text remains

**Keywords**: localization audit, i18n review, RTL check, locale compliance, internationalization, l10n, attribute-based rendering, currency formatting, date formatting, resource bundles, Middle East

## How to Run an Audit

### Step 1: Gather Context

Before auditing, establish:

| Field | Examples |
|-------|---------|
| **Feature / screen** | Payment summary, service appointment scheduler, customer messaging |
| **Target markets** | US + Qatar, all markets, Middle East only |
| **Platforms** | Web (Angular/React), iOS, backend API |
| **Locale attributes API used?** | ManageAPI, neither, unknown |
| **Known constraints** | Existing i18n framework, legacy code, third-party components |
| **Specific concerns** | RTL layout, currency display, date formatting, phone validation |

### Step 2: Audit Against the Framework

See [reference/localization-audit-framework.md](reference/localization-audit-framework.md) for the full audit checklist covering:

1. Golden Rule Compliance (Attribute-Based Rendering)
2. UI Layout & RTL Support
3. Iconography & Visual Direction
4. Text & Resource Bundles (i18n)
5. Data Formatting (Currency, Dates, Units)
6. Locale Resolution & Fallback Chain
7. Phone Number Validation
8. API Integration
9. Definition of Done Checklist

### Step 3: Structure Output

**Executive Summary** — 2-3 sentences: overall localization readiness and the most critical gaps.

**Critical Issues** — blockers; feature will break or display incorrectly in target markets
> Issue -> Why it matters -> Specific recommendation with code example

**Major Issues** — significant problems; feature works but with incorrect formatting or layout
> Issue -> Why it matters -> Specific recommendation with code example

**Minor Issues** — polish, edge cases (bullet list)

**API Integration Flags** — missing API calls, incorrect response handling, caching concerns

**Top 3 Priorities** — if the team can only fix 3 things before launch

## Severity Reference

| Level | Definition |
|-------|-----------|
| **Critical** | Feature will break, display garbled text, or show incorrect data in target market |
| **Major** | Feature works but with wrong formatting, broken layout, or confusing UX in target market |
| **Minor** | Edge cases, polish issues, or non-blocking inconsistencies |

## Common Localization Blind Spots

Engineers almost always build for LTR + USD + en-US first. Flag these proactively:

- **Hardcoded locale checks** — `if (locale === "ar-qa")` instead of checking `textDirection`, `currency`, or `units`
- **Physical CSS properties** — `margin-left` instead of `margin-inline-start`
- **Hardcoded strings** — UI text not in resource bundles
- **Hardcoded currency symbols** — `$` instead of `localeAttributes.currency.symbol`
- **Hardcoded date patterns** — `MM/dd/yyyy` instead of `localeAttributes.date.pattern`
- **Left/Right constraints (iOS)** — instead of Leading/Trailing
- **Directional icons not mirrored** — back arrows, progress bars still point LTR
- **Static icons incorrectly mirrored** — checkmarks, search icons flipped when they shouldn't be
- **Google Translate for UI strings** — slow, expensive, wrong automotive terms
- **Backend formatting** — dates/currency formatted on server instead of client
- **Missing phone validation** — no `libphonenumber`, no international country code support
- **Mixed language and formatting** — customer language affecting currency/date display

## Standalone Prompt

To run this audit outside Claude Code (e.g., pasting into Claude.ai or another AI), use the ready-to-use prompt in [reference/localization-audit-prompt.md](reference/localization-audit-prompt.md).
