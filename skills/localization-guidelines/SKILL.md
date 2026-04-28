---
name: localization-guidelines
description: Applies myKaarma's attribute-based localization standards to code artifacts. Use when building UI that must support RTL, multiple currencies, metric units, date/time formats, or locale-aware rendering. References the locale attributes API as the authoritative source.
---

# myKaarma Localization Guidelines

## When to Use This Skill

Use this skill when:
- **Building locale-aware UI**: Applying RTL layout, currency formatting, date/time display, or unit rendering
- **Generating internationalized code**: Creating components that must work across markets (US, Middle East, future locales)
- **Reviewing localization compliance**: Checking that code uses attribute-based rendering, not hardcoded locale checks
- **Referencing locale API**: Looking up the correct API contract for dealer locale attributes
- **Adding i18n strings**: Ensuring all user-facing text uses resource bundle keys

**Keywords**: localization, i18n, l10n, RTL, right-to-left, locale, internationalization, currency, date format, metric, Arabic, Middle East, attribute-based rendering, locale attributes

## The Golden Rule: Check Attributes, Not Locales

**Always code against locale attributes (properties), never against locale strings.** This is the single most important rule. By checking the property (RTL, Metric, 24hr, currency) rather than the locale, new market launches require zero code changes — only a new configuration entry in KManage.

```javascript
// Anti-Pattern (Forbidden) - checking locale strings
if (dealerLocale === "ar-qa") { showRTL(); }
if (locale === "en-us") { showDollar(); }
if (locale.startsWith("ar")) { useMetric(); }

// Standard (Required) - checking attributes
if (localeAttributes.textDirection === "rtl") { showRTL(); }
if (localeAttributes.currency.symbol === "$") { showDollar(); }
if (localeAttributes.units.system === "METRIC") { useMetric(); }
```

```swift
// iOS Anti-Pattern (Forbidden)
if dealerLocale == "ar-qa" { showRTL() }

// iOS Standard (Required)
if localeAttributes.textDirection == .rightToLeft { showRTL() }
```

**Why:** Locale strings are unstable and do not scale. Attributes represent behavior, not geography. When Quebec (fr-CA) or Mexico (es-MX) launches, attribute-based code works automatically.

## Authoritative Source

Locale attributes are served by a single API:

**Endpoint:** `GET /manage/v2/dealers/{dealerUUID}/locale-attributes`

This endpoint is used for all contexts — dealer UI, customer portal, SMS, email. **Do not branch on locale strings.**

## UI & Layout Standards

### Logical Layout Properties (Mandatory)

Never use physical direction properties. Always use logical properties so layout automatically flips for RTL.

**iOS:**
```swift
// Bad: physical directions
view.leftAnchor.constraint(equalTo: container.leftAnchor)
view.rightAnchor.constraint(equalTo: container.rightAnchor)

// Good: logical directions
view.leadingAnchor.constraint(equalTo: container.leadingAnchor)
view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
```

**Web / CSS:**
```css
/* Bad: physical properties */
.card { margin-left: 16px; padding-right: 8px; text-align: left; }

/* Good: logical properties */
.card { margin-inline-start: 16px; padding-inline-end: 8px; text-align: start; }
```

```css
/* Additional logical property mappings */
/* margin-left    -> margin-inline-start */
/* margin-right   -> margin-inline-end   */
/* padding-left   -> padding-inline-start */
/* padding-right  -> padding-inline-end   */
/* text-align: left -> text-align: start  */
/* text-align: right -> text-align: end   */
/* border-left    -> border-inline-start  */
/* border-right   -> border-inline-end    */
/* left           -> inset-inline-start   */
/* right          -> inset-inline-end     */
```

### Iconography Mirroring Rules

| Icon Type | Examples | Mirror in RTL? |
|-----------|----------|---------------|
| **Directional** | Back/forward arrows, progress bars, directional car icons | Yes - MUST mirror |
| **Static** | Checkmarks, search/magnifying glass, camera | No - must NOT mirror |

### Text Alignment

Text alignment must follow `localeAttributes.textDirection`. Never hardcode alignment.

```css
/* Bad */
.headline { text-align: left; }

/* Good */
.headline { text-align: start; }
```

Headlines left-aligned in the US must be right-aligned in Qatar.

### Resource Bundles (i18n Keys)

- **Runtime Google Translate is forbidden** for UI strings (slow, expensive, incorrect automotive terminology)
- Allowed only for dynamic user-generated content if unavoidable
- Every UI string must be an i18n key:
  - iOS: `.strings` files
  - Web: `.json` files
- Example key: `lb_mileage_input`

## Data Formatting Standards

The backend must remain a "Pure Data" source. **Formatting is always a UI responsibility.**

### Numbers & Currency

| Layer | Rule | Example |
|-------|------|---------|
| **Backend** | Always send raw numeric types (`Double`, `BigDecimal`) | `1250.50` |
| **Frontend** | Use `currency.symbol` and `currency.decimalDigits` from locale attributes | `ر.ق 1,250.50` |
| **Input fields** | Always use Western numerals (0-9) | Ensures DB compatibility |

```javascript
// Example: formatting currency from locale attributes
function formatCurrency(amount, localeAttrs) {
  const { symbol, decimalDigits, placement } = localeAttrs.currency;
  const formatted = amount.toFixed(decimalDigits);
  return placement === "after" ? `${formatted} ${symbol}` : `${symbol}${formatted}`;
}
```

### Dates & Time

| Layer | Rule | Example |
|-------|------|---------|
| **API transmission** | ISO-8601 strings always | `2026-01-22T08:00:00Z` |
| **Display** | Use centralized formatting utility with `date.pattern` / `time.pattern` | `22/01/2026`, `14:30` |

```javascript
// Example centralized utility
formatDate(date, localeAttrs.date.pattern); // Output: 22/01/2026
formatTime(date, localeAttrs.time.pattern); // Output: 14:30
```

**Never format dates/times on the backend. Never hardcode date patterns.**

### Distance / Mileage

| Layer | Rule | Example |
|-------|------|---------|
| **Storage** | Store raw value + unit flag | `{ "value": 50000, "unit": "km" }` |
| **Display** | Use `units.distanceAbbr` from locale attributes | `50,000 km` |

## Locale Resolution & Fallback Chain

### Dealership Personnel (Dealer UI)

| Priority | Source |
|----------|--------|
| 1 | Advisor Preferred Locale (language only) |
| 2 | Dealer Preferred Locale |
| 3 | System Global Default: `en-US` (safety language) |

### Car Owner / Customer (Customer UI & Messages)

| Priority | Source |
|----------|--------|
| 1 | Customer Preferred Locale (language only) |
| 2 | System Global Default: `en-US` (safety language) |

### Critical Rules

- **Units, dates, and currency** always follow **dealer locale** (both dealer-facing and customer-facing)
- **Advisor locale** affects **language only** (advisor's preferred language for UI text)
- **Customer locale** affects **language only** (customer's preferred language for messages/portal)
- **Never mix language and formatting concerns**

### The Final Rule of Thumb

| Concern | Source |
|---------|--------|
| Words & Direction | `language` (from user/customer preference) |
| Numbers, Units, Dates | `formatting` (from dealer attributes) |
| Locale strings | **Never check them** |

## Phone Number Validation

All phone number fields must accept international country codes using `libphonenumber`:

```javascript
// Required validation steps (using myKaarma hosted libphonenumber)
// Web: https://static.mykaarma.com/js/libphonenumber/3.2.44/libphonenumber.js

// 1. Check isPossibleNumber (mandatory for ALL dealers)
const possible = isPossibleNumber(input, defaultCountryCode);

// 2. Extract country code and national format, display both
const parsed = parsePhoneNumber(input, defaultCountryCode);
const display = `+${parsed.countryCallingCode} ${parsed.formatNational()}`;
```

Libraries:
- Java: `com.googlecode.libphonenumber` (Maven)
- Web: `https://static.mykaarma.com/js/libphonenumber/3.2.44/libphonenumber.js`

## API Response Reference

### ManageAPI — Dealer Locale Attributes

**Endpoint:** `GET /manage/v2/dealers/{dealerUUID}/locale-attributes`

**Response envelope:** `{ errors, warnings, apiRequestId, localeAttributes }`

**`localeAttributes` fields:**

| Field | Type | Example | Usage |
|-------|------|---------|-------|
| `locale` | string | `"ar-qa"` | For reference only — **never branch on this** |
| `textDirection` | string | `"rtl"` or `"ltr"` | Layout direction |
| `numberingSystem` | string | `"latn"` | Numeral system |
| `timeZone` | string | `"Asia/Qatar"` | IANA timezone |
| `currency.code` | string | `"QAR"` | ISO currency code |
| `currency.symbol` | string | `"QR"` | Display symbol |
| `currency.decimalDigits` | number | `2` | Decimal precision |
| `currency.placement` | string | `"before"` | Symbol before/after amount |
| `units.system` | string | `"METRIC"` | Unit system |
| `units.distance` | string | `"KILOMETER"` | Distance unit enum |
| `units.distanceAbbr` | string | `"km"` | Distance label |
| `units.temperature` | string | `"CELSIUS"` | Temperature unit enum |
| `units.temperatureAbbr` | string | `"°C"` | Temperature label |
| `units.weight` | string | `"KILOGRAM"` | Weight unit enum |
| `units.weightAbbr` | string | `"kg"` | Weight label |
| `date.pattern` | string | `"dd/MM/yyyy"` | Date format pattern |
| `time.pattern` | string | `"HH:mm"` | Time format pattern |
| `legalDocuments.documents` | object | See below | Legal document URLs by type |

**Legal document types:** `TERMS_AND_CONDITIONS`, `PRIVACY_POLICY`, `CCPA`, `SECURE_TOKEN_ACCESS_EXPIRED`, `SECURE_TOKEN_ACCESS_FAILED`, `SECURE_TOKEN_ACCESS_REVOKED`, `SECURE_TOKEN_RESOURCE_NOT_FOUND`

Each document is an array of `{ url, format }` objects.

This response is safe to cache heavily by `dealerUUID`.
