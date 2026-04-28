# Localization Audit Framework

Full checklist for auditing features against myKaarma's attribute-based localization standards. Rate each issue: **Critical / Major / Minor**.

---

## 1. Golden Rule Compliance (Attribute-Based Rendering)

- Are all locale-dependent decisions based on **attributes** (`textDirection`, `currency.code`, `units.system`) and **never** on locale strings (`"ar-qa"`, `"en-us"`)?
- Is there any `if (locale === "...")` pattern anywhere in the code?
- Are new market launches possible with **zero code changes** (only KManage config)?
- Does the code import and use the locale attributes API response correctly?

## 2. UI Layout & RTL Support

- Is `direction: rtl` applied at the root level based on `localeAttributes.textDirection`?
- Do flexbox containers use logical ordering (no hardcoded `flex-direction: row` that breaks in RTL)?
- Do labels, inputs, and buttons align correctly in both LTR and RTL?
- Are there any overlapping elements when the layout flips?
- Do scrollable areas scroll in the correct direction?

> **Note:** Specific CSS logical property mappings and iOS constraint rules are covered in the [localization-guidelines](../../localization-guidelines/SKILL.md) skill.

## 3. Iconography & Visual Direction

### Must Mirror in RTL
- [ ] Back / Forward navigation arrows
- [ ] Progress bars and step indicators
- [ ] Directional car icons (facing a direction)
- [ ] Chevrons indicating navigation direction
- [ ] Undo / Redo icons

### Must NOT Mirror in RTL
- [ ] Checkmarks and check icons
- [ ] Search / Magnifying glass
- [ ] Camera icons
- [ ] Clock icons
- [ ] Media playback controls (play, pause)
- [ ] Brand logos

## 4. Text & Resource Bundles (i18n)

- Are **all** user-facing strings externalized to resource bundles?
  - iOS: `.strings` files
  - Web: `.json` i18n files
- Are there any hardcoded strings in source code (labels, button text, error messages, tooltips)?
- Is Google Translate being used for UI strings? (Forbidden — incorrect automotive terminology)
- Are string keys following naming conventions (e.g., `lb_mileage_input`)?
- Are there any string concatenations that would break in other languages (word order varies)?
- Are pluralization rules handled correctly (not just appending "s")?

## 5. Data Formatting (Currency, Dates, Units)

### Currency
- Is the currency symbol from `localeAttributes.currency.symbol`?
- Is decimal precision from `localeAttributes.currency.decimalDigits`?
- Is symbol placement (before/after) from `localeAttributes.currency.placement`?
- Are there any hardcoded `$`, `USD`, or currency symbols?
- Is the backend sending raw numeric values (not pre-formatted strings)?

### Dates & Time
- Are all API payloads using ISO-8601 (`2026-01-22T08:00:00Z`)?
- Is display formatting using `localeAttributes.date.pattern` and `localeAttributes.time.pattern`?
- Is there a centralized formatting utility, or are dates formatted ad-hoc?
- Are there any hardcoded date patterns (`MM/dd/yyyy`, `h:mm a`)?
- Is the timezone from `localeAttributes.timeZone` used for display conversions?
- Is the first day of week respected (e.g., Saturday in Qatar)?

### Distance / Mileage
- Is distance stored as raw value + unit flag (`{ value: 50000, unit: "km" }`)?
- Is the display label from `localeAttributes.units.distanceAbbr`?
- Are there any hardcoded `"mi"`, `"miles"`, `"km"` strings?

### Temperature & Weight
- Are temperature and weight labels from `localeAttributes.units.temperatureAbbr` and `localeAttributes.units.weightAbbr`?

## 6. Locale Resolution & Fallback Chain

### Dealer UI
- Is the resolution order correct?
  1. Advisor Preferred Locale (language only)
  2. Dealer Preferred Locale
  3. System Default (`en-US`)
- Is the advisor locale used **only** for language, not for formatting?

### Customer UI & Messages
- Is the resolution order correct?
  1. Customer Preferred Locale (language only)
  2. System Default (`en-US`)
- Is the customer locale used **only** for language, not for formatting?

### Formatting
- Do units, dates, and currency **always** follow dealer locale (not advisor/customer locale)?
- Is the separation between language and formatting concerns maintained?

## 7. Phone Number Validation

- Is `libphonenumber` being used for phone validation?
  - Java: `com.googlecode.libphonenumber` (Maven)
  - Web: `https://static.mykaarma.com/js/libphonenumber/3.2.44/libphonenumber.js`
- Is `isPossibleNumber` checked? (Mandatory for all dealers)
- Are country code and national number extracted and displayed together?
- Does the input accept international country codes?

## 8. API Integration

- Is the locale attributes API being called?
  - Endpoint: `GET /manage/v2/dealers/{dealerUUID}/locale-attributes`
- Is the response being cached by `dealerUUID`?
- Is the response envelope handled correctly (`localeAttributes` nested field, not top-level)?
- Are `errors` and `warnings` from the response checked and handled?

## 9. Definition of Done Checklist

A feature is **not done** for international markets unless:

- [ ] **No hardcoded strings** — all text in `.strings` (iOS) or `.json` (Web)
- [ ] **RTL verified** — screen tested in RTL mode, no overlapping labels, icons mirrored correctly
- [ ] **No locale string checks** — all decisions use attributes, never `if (locale === "...")`
- [ ] **Phone validation** — `libphonenumber` with `isPossibleNumber`, country code extraction
- [ ] **Unit consistency** — currency, distance, date/time change dynamically based on `dealerUUID`
- [ ] **Centralized formatters** — dates, times, currency use shared utility functions
- [ ] **Backend sends raw data** — no pre-formatted strings from APIs
- [ ] **Correct API used** — `GET /manage/v2/dealers/{dealerUUID}/locale-attributes`
- [ ] **Language vs formatting separated** — advisor/customer locale = language only, dealer locale = formatting
