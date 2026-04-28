---
name: brand-guidelines
description: Applies myKaarma's official brand colors, typography, spacing, navigation patterns, dark mode, and interaction design to all UI output. Invoke this skill before starting any UI project — components, dashboards, forms, or AI-generated artifacts — to ensure full consistency with myKaarma's visual identity and design system.
---

# myKaarma Brand & UI Skill

## When to Invoke This Skill

Use this skill when:
- Building any UI component, dashboard, form, or screen for myKaarma
- Generating styled code (React/JSX, HTML/CSS, or AI artifacts)
- Setting up navigation, layout, or page structure
- Applying dark mode or theme switching
- Reviewing visual consistency against brand standards
- Looking up correct color, spacing, shadow, or typography tokens

**Keywords:** branding, colors, typography, tokens, styling, UI, dashboard, form, navigation, sidebar, dark mode, theme, components, myKaarma

---

## Rule Zero — Never Hardcode Values

Always reference design tokens by their CSS custom property name. Every token must include an inline hex fallback so the UI renders correctly even if `theme.css` cannot be fetched.

```css
/* ❌ Never — no token, no fallback */
.header { color: #0377B3; font-size: 16px; }

/* ❌ Never — token without fallback */
.header { color: var(--primary-color); }

/* ✅ Always — token + inline hex fallback */
.header { color: var(--primary-color, #0377B3); }
```

```jsx
// ❌ No fallback
<div style={{ color: 'var(--primary-color)' }}>

// ✅ With fallback
<div style={{ color: 'var(--primary-color, #0377B3)' }}>
```

**Why fallbacks matter:** AI tools may not be able to fetch `theme.css` due to network restrictions or context limits. Inline fallbacks ensure the correct brand color renders regardless.

---

## Authoritative Source Files

| Resource | URL |
|---|---|
| Design tokens (root theme) | `https://static.mykaarma.com/res/mkblue/css/theme.css` |
| Typography classes | `https://static.mykaarma.com/res/global/css/text-size.css` |
| Button styles | `https://static.mykaarma.com/res/global/css/mk-button.css` |

When these files cannot be fetched, use the hex fallback values defined in this document.

---

## Design Principles

1. **Tokens over values.** Every color, size, shadow, and spacing unit must reference a design token with an inline hex fallback.
2. **Hierarchy through typography, not decoration.** Use size, weight, and color to establish hierarchy — not borders or backgrounds.
3. **Semantic color.** Blue = action. Green = success. Red = error. Orange = warning/logo. Gray = inactive. Never decorative.
4. **Design for humans, not databases.** Never surface raw UUIDs, hashes, or API keys as visible text. Truncate + copy icon.
5. **Flat by default.** Use borders and background contrast for separation. Shadows only for floating elements.

---

## Color System

### Light Mode — Core Tokens

| Token | CSS Variable | Hex Fallback | When to use |
|---|---|---|---|
| Primary | `--primary-color` | `#0377B3` | CTAs, active states, links, focus rings, chart primaries |
| Secondary | `--secondary-color` | `#D3E4F1` | Tag backgrounds, selected row highlights, nav active bg |
| Tertiary | `--tertiary-color` | `#535862` | Secondary text, metadata, labels |
| Quaternary | `--quaternary-color` | `#FFFFFF` | Card surfaces, white-on-dark text |
| Disabled | `--disabled-color` | `#E9EAEB` | Disabled inputs, inactive surfaces |
| Primary Accent | `--primary-accent` | `#ED6D22` | **Logo mark only** + warnings, attention states |
| Secondary Accent | `--secondary-accent` | `#BADA55` | Positive indicators, success badges |
| Tertiary Accent | `--tertiary-accent` | `#FFE0B6` | Subtle warm highlights, low-priority badges |

### Light Mode — Backgrounds

| Token | CSS Variable | Hex Fallback | When to use |
|---|---|---|---|
| Main | `--bg-main` | `#FFFFFF` | Page background |
| Base 1 | `--bg-base-1` | `#FBFBFB` | Card and section backgrounds |
| Base 2 | `--bg-base-2` | `#D8D8D8` | Borders, dividers |
| Base 3 | `--bg-base-3` | `#B8B8B8` | Muted elements, placeholder fills |

### Light Mode — Status Colors (always use as pairs)

| Status | Foreground Token | Hex | Background Token | Hex |
|---|---|---|---|---|
| Error | `--Red-700` | `#B42318` | `--Red-50` | `#FEF3F2` |
| Success | `--Green-700` | `#027A48` | `--Green-50` | `#ECFDF3` |
| Warning | `--primary-accent` | `#ED6D22` | `--tertiary-accent` | `#FFE0B6` |
| Info | `--primary-color` | `#0377B3` | `--secondary-color` | `#D3E4F1` |

### Semantic Color Rules

- `--primary-color` **only** for: primary buttons, active nav items, links, focus rings, primary chart series.
- `--primary-accent` (orange) **only** for: the logo mark background, warnings, attention-required states. **Never for primary actions.**
- `--secondary-accent` (lime) **only** for: success/positive status indicators.
- Inactive or disabled text must use `--tertiary-color` or `--disabled-color`. **Never style inactive text in blue.**
- Status colors must always appear as a pair: foreground token on its matching background token.

---

## Dark Mode

### Surface Tokens

| Role | Token | Hex Fallback |
|---|---|---|
| Page background | `--bg-main` | `#0F1117` |
| Card / panel | `--bg-base-1` | `#1A1F2E` |
| Elevated surface | `--bg-base-2` | `#232839` |
| Border / divider | `--bg-base-3` | `#2E3347` |
| Input background | `--bg-dark-1` | `#1E2433` |

> **Derivation logic:** `#0F1117` is the brand navy pushed to near-black with its cool blue undertone preserved. Each surface step adds ~8% lightness. This keeps dark mode feeling like myKaarma without using pure black.

### Text Tokens

| Role | Hex Fallback |
|---|---|
| Primary text | `#F0F4F8` |
| Secondary text | `#8B95A6` |
| Disabled / muted | `#4A5568` |

### Interactive Tokens

| Role | Hex Fallback | Notes |
|---|---|---|
| Primary action / brand | `#3B9DD4` | Lightened from `#0377B3` for dark bg contrast |
| Secondary button border + text | `#7EB8D9` | Clearly visible on `#1A1F2E` topbar background |
| Focus ring | `rgba(59,157,212,0.4)` | 40% opacity of dark primary |
| Hover surface | `rgba(255,255,255,0.05)` | 5% white overlay |

### Dark Mode Status Colors (always use as pairs)

| Status | Text Hex | Background Hex |
|---|---|---|
| Error | `#F97066` | `#1C0A09` |
| Success | `#32D583` | `#052E16` |
| Warning | `#FD853A` | `#1C0F04` |
| Info | `#36ADEF` | `#031527` |

### Complete Token Override Block

Scope all token overrides to `#shell.light` and `#shell.dark`. Never use `.light` or `.dark` alone — the host environment may have its own classes that conflict.

```css
#shell.light {
  --bg-page:         #F5F7FA;
  --bg-sidebar:      #FFFFFF;
  --bg-topbar:       #FFFFFF;
  --bg-card:         #FFFFFF;
  --border:          #E9EAEB;
  --text-primary:    #1A1A2E;
  --text-secondary:  #535862;
  --text-muted:      #B8B8B8;
  --brand:           #0377B3;
  --nav-active-bg:   #D3E4F1;
  --nav-active-text: #0377B3;
  --nav-dot-default: #D8D8D8;
  --btn-sec-color:   #0377B3;
  --toggle-track:    #E9EAEB;
  --avatar-bg:       #D3E4F1;
  --avatar-text:     #0377B3;
  --chip-bg:         #FFFFFF;
  --chip-border:     #D8D8D8;
  --chip-text:       #535862;
  --chip-active-bg:  #D3E4F1;
  --chip-active-border: #0377B3;
  --chip-active-text: #0377B3;
  --input-bg:        #FFFFFF;
  --row-hover:       #F0F6FB;
}

#shell.dark {
  --bg-page:         #0F1117;
  --bg-sidebar:      #1A1F2E;
  --bg-topbar:       #1A1F2E;
  --bg-card:         #232839;
  --border:          #2E3347;
  --text-primary:    #F0F4F8;
  --text-secondary:  #8B95A6;
  --text-muted:      #4A5568;
  --brand:           #3B9DD4;
  --nav-active-bg:   rgba(59,157,212,0.18);
  --nav-active-text: #3B9DD4;
  --nav-dot-default: #2E3347;
  --btn-sec-color:   #7EB8D9;
  --toggle-track:    #3B9DD4;
  --avatar-bg:       rgba(59,157,212,0.2);
  --avatar-text:     #3B9DD4;
  --chip-bg:         transparent;
  --chip-border:     #3B4560;
  --chip-text:       #8B95A6;
  --chip-active-bg:  rgba(59,157,212,0.18);
  --chip-active-border: #3B9DD4;
  --chip-active-text: #3B9DD4;
  --input-bg:        #1E2433;
  --row-hover:       rgba(255,255,255,0.04);
}
```

### Dark Mode Rules

- Never use pure black (`#000000`) as background. Use `#0F1117`.
- Never use pure white (`#FFFFFF`) as body text on dark surfaces. Use `#F0F4F8`.
- Shadows are nearly invisible on dark surfaces — use `border: 1px solid var(--border, #2E3347)` instead.
- Run `initTheme()` synchronously in `<head>` before first render to prevent flash of wrong theme.
- Always scope token overrides to `#shell.light` / `#shell.dark` — never bare `.light` / `.dark`.

```js
// Run in <head> before first render
function initTheme() {
  const stored = localStorage.getItem('mk-theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  document.getElementById('shell').className = stored || (prefersDark ? 'dark' : 'light');
}
initTheme();

function toggleTheme() {
  const shell = document.getElementById('shell');
  const next = shell.className === 'dark' ? 'light' : 'dark';
  shell.className = next;
  localStorage.setItem('mk-theme', next);
}

window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
  if (!localStorage.getItem('mk-theme')) {
    document.getElementById('shell').className = e.matches ? 'dark' : 'light';
  }
});
```

---

## Extended Color Scales

Full 25–900 scales are available for Brand, Gray, Red, Orange, Yellow, Green, Warm-Green, Light-blue, Purple, and Yellow-Brown. Reference as `--{Palette}-{shade}` (e.g., `--Brand-500`, `--Gray-200`).

**Critical rule: never reference extended scale tokens directly in component code.** Use them only inside token definition blocks (e.g., inside `#shell.light { }` or `#shell.dark { }`). In component code, always use the semantic tokens defined above (`--primary-color`, `--brand`, etc.) with their inline fallbacks.

```css
/* ❌ Never in component code */
.badge { color: var(--Green-700); }

/* ✅ In component code — use semantic token + fallback */
.badge { color: var(--badge-act-fg, #027A48); }

/* ✅ Scale tokens are fine inside token definition blocks */
#shell.light {
  --badge-act-fg: var(--Green-700, #027A48);
}
```

---

## Typography

**Font:** Lato only. Weights: 400 (body), 700 (headings, buttons). Fallback: `sans-serif`.

Use `.myk-` prefixed classes exclusively. **Never** use `.mk-` prefixed classes (legacy, backward compat only). **Never** define custom font sizes inline.

| Class | Size | Line Height | Weight | Usage |
|---|---|---|---|---|
| `.myk-h1` | 2rem (32px) | 2.5rem | 700 | Page titles |
| `.myk-h2` | 1.5rem (24px) | 2rem | 700 | Section headers |
| `.myk-h3` | 1.25rem (20px) | 1.75rem | 700 | Subsection headers |
| `.myk-h4` | 1.125rem (18px) | 1.5rem | 700 | Card headers |
| `.myk-h5` | 1rem (16px) | 1.5rem | 700 | Small headers |
| `.myk-h6` | 0.875rem (14px) | 1.25rem | 700 | Minimal headers |
| `.myk-body1` | 1rem (16px) | 1.5rem | 400 | Primary body text |
| `.myk-body2` | 0.875rem (14px) | 1.25rem | 400 | Secondary body, table cells |
| `.myk-subtitle1` | 0.75rem (12px) | 1rem | 400 | Captions, metadata, timestamps |
| `.myk-subtitle2` | 0.625rem (10px) | 1.1rem | 400 | Fine print, tooltips |
| `.myk-button-lg` | 1rem | 1.5rem | 700 | Large buttons — uppercase, 0.08em spacing |
| `.myk-button-reg` | 0.875rem | 1.25rem | 700 | Regular buttons — uppercase, 0.08em spacing |
| `.myk-button-sm` | 0.75rem | 1rem | 700 | Small buttons — uppercase, 0.08em spacing |

### Typography Rules
- Primary data (names, values): bold (`700`), `var(--text-primary, #1A1A2E)`
- Secondary data (metadata, timestamps): regular (`400`), `var(--text-secondary, #535862)`
- Muted / inactive text: `var(--text-muted, #B8B8B8)` — **never blue or any active color**
- Never more than three type sizes within a single card or section

---

## Layout & Spacing

### Card-Based Layout
- Group related content into cards: `background: var(--bg-card, #FFFFFF); border: 1px solid var(--border, #E9EAEB); border-radius: 8px`
- Page background always slightly contrasting behind cards
- Cards never touch viewport edge — always padded with `var(--space-5, 24px)`

### Z-Pattern Reading Flow
- **Left:** Labels, entity names, status badges, descriptive text
- **Right:** Action buttons, toggles, dropdowns, overflow menus
- Never place a primary action on the left side of a row

### Spacing Scale

| Token | Value | Fallback | Use |
|---|---|---|---|
| `--space-1` | 4px | `4px` | Icon gaps, badge padding |
| `--space-2` | 8px | `8px` | Component internal padding |
| `--space-3` | 12px | `12px` | Compact row padding |
| `--space-4` | 16px | `16px` | Standard card padding |
| `--space-5` | 24px | `24px` | Section spacing |
| `--space-6` | 32px | `32px` | Page-level section gaps |
| `--space-8` | 48px | `48px` | Large layout separators |

### Border Radius

| Token | Value | Use |
|---|---|---|
| `--radius-sm` | 4px | Badges, tags, chips |
| `--radius-md` | 6px | Inputs, selects |
| `--radius-lg` | 8px | Cards, buttons |
| `--radius-xl` | 12px | Modals, panels |

### Density

| Mode | Row height | Font | Use when |
|---|---|---|---|
| Compact | 32px | `.myk-subtitle1` | Dense tables, audit logs |
| Default | 40px | `.myk-body2` | Standard lists |
| Comfortable | 48px | `.myk-body1` | Forms, settings |

---

## Elevation & Shadows

The system is intentionally flat. Default to borders and background contrast. Use shadows only for floating elements.

| Token | Value | Use |
|---|---|---|
| `--shadow-xs` | `0 1px 2px rgba(10,13,18,0.05)` | Default card lift |
| `--shadow-sm` | `0 1px 3px rgba(10,13,18,0.10)` | Focused inputs, hovered cards |
| `--shadow-md` | `0 4px 8px rgba(10,13,18,0.12)` | Dropdowns, popovers |
| `--shadow-lg` | `0 8px 16px rgba(10,13,18,0.15)` | Modals, sheets |

Dark mode: use `border: 1px solid var(--border, #2E3347)` instead of shadows for card separation.

---

## Navigation — Hybrid Sidebar + Top Bar

### Structure

```
┌──────────────────────────────────────────────────────┐
│ Sidebar (220px)  │ Top Bar (full width)               │
│                  │  Page title + breadcrumb │ Actions │
│ Logo (52px tall) ├───────────────────────────────────-│
│                  │                                    │
│ Nav groups       │  Page content                      │
│  └ Nav items     │                                    │
│  (max 10 total)  │                                    │
│ ──────────────── │                                    │
│ [JD] [☀ toggle] │                                    │
└──────────────────────────────────────────────────────┘
```

### Sidebar Rules

- Width: 220px fixed
- Logo area: 52px tall, `#ED6D22` logo mark (always), `var(--brand)` wordmark
- Max 4 nav groups, max 10 items total. Always label every group.
- No `border` on `#shell` — sidebar uses only `border-right: 1px solid var(--border)`

**Nav item states:**

| State | Background | Text | Weight |
|---|---|---|---|
| Default | transparent | `var(--text-secondary, #535862)` | 400 |
| Hover (light) | `#F5F7FA` | `var(--text-secondary, #535862)` | 400 |
| Hover (dark) | `rgba(255,255,255,0.05)` | `var(--text-secondary, #8B95A6)` | 400 |
| Active | `var(--nav-active-bg)` | `var(--nav-active-text)` | 700 |
| Disabled | transparent | `var(--disabled-color, #E9EAEB)` | 400 |

- Active state: background fill only — **never a left border bar**
- Active icon: filled style (Material Icons). All others: outlined style.
- One item active at a time.

### Top Bar Rules

- Height: 52px — matches sidebar logo area exactly
- **Left:** Page title (`.myk-h5`) + breadcrumb below (`.myk-subtitle1`, muted)
- **Right:** Max 3 controls — one primary button, one secondary, optional utility
- **Does not contain:** user avatar, dark mode toggle, notifications, or search

```jsx
// ✅ Correct top bar
<header style={{
  background: 'var(--bg-topbar, #FFFFFF)',
  borderBottom: '1px solid var(--border, #E9EAEB)',
  height: 52, display: 'flex', alignItems: 'center', padding: '0 20px', gap: 12
}}>
  <div>
    <h5 className="myk-h5">Conversations</h5>
    <nav style={{ fontSize: 11, color: 'var(--text-muted, #B8B8B8)' }}>Home › Conversations</nav>
  </div>
  <div style={{ marginLeft: 'auto', display: 'flex', gap: 8 }}>
    <button className="tb-btn secondary">Export</button>
    <button className="tb-btn primary">+ New</button>
  </div>
</header>
```

### Sidebar Footer

```jsx
<div style={{ marginTop: 'auto', padding: '10px 8px', borderTop: '1px solid var(--border, #E9EAEB)', display: 'flex', alignItems: 'center', gap: 8 }}>
  <div className="avatar">JD</div>
  <button
    onClick={toggleTheme}
    aria-label="Toggle dark mode"
    role="switch"
    aria-checked={dark}
    style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 6, background: 'none', border: 'none', cursor: 'pointer' }}
  >
    <span style={{ fontSize: 10, color: 'var(--text-muted, #B8B8B8)' }}>{dark ? 'Dark' : 'Light'}</span>
    <div className="toggle-track">
      <div className="toggle-knob">
        {dark ? <MoonIcon size={10} color="#334155" /> : <SunIcon size={10} color="#ED6D22" />}
      </div>
    </div>
  </button>
</div>
```

---

## Dark Mode Toggle

### Placement
Lives **exclusively in the sidebar footer**. Never in the top bar, page content, or a dropdown. A Settings page may mirror it as a secondary surface using the same `localStorage` key (`mk-theme`).

### Toggle Anatomy
- Track: 40×22px pill. Off = `var(--toggle-track, #E9EAEB)`. On = `var(--brand, #3B9DD4)`.
- Knob: 16px white circle. **Light mode:** sun icon (`#ED6D22`). **Dark mode:** moon icon (`#334155` — dark slate on white knob, not light gray).
- Knob animates `left: 3px` ↔ `left: 21px` with `transition: left 200ms`.
- `role="switch"` + `aria-checked` required. Label ("Light"/"Dark") updates on toggle.

```css
.toggle-track { width: 40px; height: 22px; border-radius: 11px; background: var(--toggle-track, #E9EAEB); position: relative; }
.toggle-knob  { width: 16px; height: 16px; border-radius: 50%; background: #fff; position: absolute; top: 3px; left: 3px; transition: left 200ms; box-shadow: 0 1px 3px rgba(0,0,0,0.35); display: flex; align-items: center; justify-content: center; }
#shell.dark .toggle-knob { left: 21px; }
```

---

## Buttons

Every button requires `.mk-button` base class + a variant class. Missing base class breaks styles.

| Classes | Use |
|---|---|
| `.mk-button .primary-mk-button` | Primary: Save, Submit, Confirm |
| `.mk-button .secondary-mk-button` | Secondary: Cancel, Back |
| `.mk-button .tertiary-mk-button` | Outline/tertiary actions |
| `.mk-button .quaternary-mk-button` | Ghost/minimal actions |
| `.mk-button .functional-mk-button` | Utility: Filter, Sort, Export |

### Button Sizes

| Class | Height |
|---|---|
| *(default)* | 30px |
| `.mk-button-small` | 24px |
| `.mk-button-large` | 48px |

### Universal Button CSS

```css
.tb-btn {
  height: 30px;
  padding: 0 16px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  cursor: pointer;
  /* Always use inline-flex for centering — never line-height */
  display: inline-flex;
  align-items: center;
  justify-content: center;
  white-space: nowrap;
  font-family: 'Lato', sans-serif;
}
.tb-btn.primary {
  background: var(--brand, #0377B3);
  color: #ffffff;
  border: none;
}
.tb-btn.secondary {
  background: transparent;
  color: var(--btn-sec-color, #0377B3);
  /* 1px border everywhere — same color as text */
  border: 1px solid var(--btn-sec-color, #0377B3);
}
/* Dark mode: --btn-sec-color resolves to #7EB8D9 */
```

### Button Rules
- One primary button per section or modal — never two primary buttons side by side
- Destructive actions require a red variant or a confirmation step
- Disabled: `opacity: 0.5; pointer-events: none; cursor: not-allowed`
- Always use `display: inline-flex; align-items: center; justify-content: center` — **never `line-height` for vertical centering**

```jsx
// ✅ Correct
<button className="mk-button primary-mk-button">Save Changes</button>
<button className="mk-button secondary-mk-button">Cancel</button>

// ❌ Missing base class
<button className="primary-mk-button">Save</button>

// ❌ Two primary buttons
<button className="mk-button primary-mk-button">Save</button>
<button className="mk-button primary-mk-button">Save & Continue</button>
```

---

## Logo Rule

The myKaarma logo mark background is **always** `#ED6D22` (`--primary-accent`) in both light and dark mode. The wordmark uses `var(--brand, #0377B3)` (mode-aware).

```jsx
// ✅ Logo mark — always orange, both modes
<div style={{
  background: '#ED6D22',
  borderRadius: 6, width: 28, height: 28,
  display: 'flex', alignItems: 'center', justifyContent: 'center'
}}>
  <span style={{ color: '#fff', fontSize: 11, fontWeight: 700 }}>mk</span>
</div>
<span style={{ color: 'var(--brand, #0377B3)', fontSize: 13, fontWeight: 700 }}>myKaarma</span>
```

---

## Components

### Filter Chips & Tab Controls

**Never use `<button>` elements for chips or tab-style filters.** The widget host injects its own `<button>` styles that override custom CSS in light mode. Use `<div>` with `onclick` instead.

```jsx
// ❌ Host styles override this in light mode — appears black
<button className="chip active">All</button>

// ✅ Div is not affected by host button styles
<div className="chip active" onClick={() => setActive('all')}>All</div>
```

```css
.chip {
  height: 28px; padding: 0 14px; border-radius: 14px;
  font-size: 11px; font-weight: 700; cursor: pointer;
  display: inline-flex; align-items: center; justify-content: center;
  user-select: none;
  background: var(--chip-bg, #FFFFFF);
  border: 1px solid var(--chip-border, #D8D8D8);
  color: var(--chip-text, #535862);
}
.chip.active {
  background: var(--chip-active-bg, #D3E4F1);
  border-color: var(--chip-active-border, #0377B3);
  color: var(--chip-active-text, #0377B3);
}
```

### Forms & Inputs

- Border: `1px solid var(--border, #E9EAEB)`, radius `6px`
- Focus: `border-color: var(--brand, #0377B3)`, `box-shadow: 0 0 0 3px rgba(3,119,179,0.3)`
- Error: `border-color: #B42318`, `box-shadow: 0 0 0 3px rgba(180,35,24,0.3)`
- Disabled: `background: var(--disabled-color, #E9EAEB)`, `opacity: 0.5`, `pointer-events: none`
- Labels sit **above** inputs, never inside as placeholder replacements
- Always pair error state with a visible error message — never color alone

### Status Badges

Always use semantic color pairs:

```jsx
// ✅ Success badge
<span style={{
  color: 'var(--badge-act-fg, #027A48)',
  background: 'var(--badge-act-bg, #ECFDF3)',
  borderRadius: 4, padding: '2px 8px', fontSize: 10, fontWeight: 700
}}>Active</span>

// ❌ Wrong — blue for a status
<span style={{ color: 'var(--primary-color, #0377B3)' }}>Active</span>
```

### Data Tables

- Header: `var(--bg-page)` background, `.myk-subtitle1`, `font-weight: 700`, uppercase
- Row hover: `background: var(--row-hover)`
- Numeric values: right-align. All other content: left-align.
- **Never display raw UUIDs, hashes, or API keys.** Truncate to 8 chars + copy icon.
- Always show an empty state — never a blank table with headers only
- Actions column: always pinned to the right

```jsx
// ✅ UUID handled correctly
<td>
  <span title={record.id} style={{ color: 'var(--text-muted, #B8B8B8)', cursor: 'pointer' }}>
    {record.id.slice(0, 8)}…
  </span>
  <CopyIcon size={12} onClick={() => copy(record.id)} />
</td>
```

### Empty States

```jsx
<div style={{ textAlign: 'center', padding: 48 }}>
  <InboxIcon size={48} style={{ color: 'var(--text-muted, #B8B8B8)' }} />
  <h5 className="myk-h5">No conversations yet</h5>
  <p className="myk-body2" style={{ color: 'var(--text-muted, #B8B8B8)' }}>
    Conversations will appear here once customers reach out.
  </p>
  <button className="mk-button primary-mk-button">Start a Conversation</button>
</div>
```

### Modals

- Radius: `12px`. Shadow: `var(--shadow-lg)`.
- Max widths: 560px small / 800px medium / 1100px large
- Overlay: `rgba(0,0,0,0.5)` light / `rgba(0,0,0,0.75)` dark
- Always include visible close button + `Escape` to close
- One primary action per modal footer. Cancel always to the left.

### Loading / Skeleton

- Never show a blank screen while loading — skeleton loaders shaped like real content
- Skeleton: `background: var(--bg-base-2, #D8D8D8)` with shimmer animation
- Spinner only for button-level loading — not page-level loading

---

## Iconography

- **Primary:** Material Design Icons — outlined style default, filled for active/selected states
- **Secondary:** myKaarma custom icon set (design team) — check with design before using
- Every icon must have `aria-label` or adjacent visible text
- Never use an icon alone for a destructive action

| Size | Use |
|---|---|
| 16px | Inline with text, table action icons |
| 20px | Button icons, form field icons |
| 24px | Standalone icons, nav items |
| 48px | Empty state illustrations |

---

## Interaction Patterns

### Focus States

```css
:focus-visible {
  outline: none;
  border-color: var(--brand, #0377B3);
  box-shadow: 0 0 0 3px rgba(3,119,179,0.3);
}
#shell.dark :focus-visible {
  box-shadow: 0 0 0 3px rgba(59,157,212,0.4);
}
```

### Hover States

| Element | Light | Dark |
|---|---|---|
| Primary button | `opacity: 0.9` | `opacity: 0.9` |
| Secondary button | `background: var(--secondary-color, #D3E4F1)` | `rgba(255,255,255,0.05)` |
| Table row | `var(--row-hover, #F0F6FB)` | `rgba(255,255,255,0.04)` |
| Nav item | `#F5F7FA` | `rgba(255,255,255,0.05)` |

### Disabled States

```css
[disabled], .disabled {
  opacity: 0.5;
  pointer-events: none;
  cursor: not-allowed;
}
```

### Transitions

```css
transition: all 150ms ease-in-out;        /* state changes */
transition: box-shadow 100ms ease-in-out; /* elevation changes */
```

---

## Text Truncation & Overflow

### Core Rule
Never let text overflow its container or wrap in single-line contexts. Every text element that could receive dynamic content must have an explicit truncation or overflow strategy defined.

### Truncation Patterns

| Context | Rule | CSS |
|---|---|---|
| Table cell — name/label | Truncate with ellipsis | `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` |
| Table cell — ID / UUID | Truncate to 8 chars + copy icon | JS: `id.slice(0, 8) + '…'` |
| Card title | Max 1 line, ellipsis | `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` |
| Card subtitle / description | Max 2 lines | `-webkit-line-clamp: 2; display: -webkit-box; -webkit-box-orient: vertical; overflow: hidden` |
| Badge / chip label | Never truncate — shorten the copy instead | N/A |
| Nav item label | Never truncate — max 18 characters | Keep labels short by design |
| Sidebar customer name | Truncate at 1 line | `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` |
| Top bar page title | Never truncate — max 24 characters | Keep titles short by design |

### Tooltip Rule
Any truncated text element must show the full value in a native `title` attribute tooltip on hover. Never truncate silently.

```jsx
// ✅ Truncated cell with full value on hover
<td
  title="AutoNation Ford of North Scottsdale"
  style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 200 }}
>
  AutoNation Ford of North Scottsdale
</td>

// ✅ UUID truncation with copy
<td>
  <span title={record.id} style={{ color: 'var(--text-muted, #B8B8B8)' }}>
    {record.id.slice(0, 8)}…
  </span>
  <CopyIcon size={12} onClick={() => navigator.clipboard.writeText(record.id)} />
</td>
```

### Table Column Overflow
Tables with many columns expand past their container by default. Always set:

```css
table {
  width: 100%;
  table-layout: fixed; /* prevents columns expanding past container */
}
td, th {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

### Number & Currency Overflow
Never let long numbers break layout. Format all displayed numbers:

```js
// Currency
new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(48200)
// → $48.2K

// Large counts
new Intl.NumberFormat('en-US', { notation: 'compact' }).format(2841)
// → 2.8K

// Always round — never display raw JS float math
Math.round(value * 100) / 100
```

---

## Responsive & Breakpoints

### Breakpoint Scale

| Name | Width | Layout behavior |
|---|---|---|
| Mobile | < 768px | Single column, sidebar hidden, drawer on demand |
| Tablet | 768px – 1023px | Sidebar collapses to drawer, content full width |
| Desktop | 1024px+ | Full sidebar (220px) + content side by side |

```css
/* Mobile first */
@media (max-width: 767px)  { /* mobile overrides */ }
@media (min-width: 768px) and (max-width: 1023px) { /* tablet overrides */ }
@media (min-width: 1024px) { /* desktop — default layout */ }
```

### Sidebar Responsive Behavior

On tablet and mobile, the sidebar slides in as a **drawer over content** — it does not push content or collapse to an icon rail.

```
Desktop (1024px+)          Tablet/Mobile (< 1024px)
┌──────────┬────────────┐  ┌────────────────────────┐
│ Sidebar  │  Content   │  │ [☰] Top Bar    Actions │
│  220px   │            │  ├────────────────────────┤
│          │            │  │                        │
│          │            │  │  Content (full width)  │
│          │            │  │                        │
└──────────┴────────────┘  └────────────────────────┘
                                 ↓ when [☰] tapped
                           ┌──────────┬─────────────┐
                           │ Drawer   │ dimmed       │
                           │ (220px)  │ overlay      │
                           │          │              │
                           │ [✕]      │              │
                           └──────────┴─────────────┘
```

**Drawer rules:**
- Width: 220px — same as desktop sidebar
- Slides in from the left with `transform: translateX(-220px)` → `translateX(0)`, `transition: transform 250ms ease`
- Overlay behind drawer: `rgba(0,0,0,0.5)` — tapping overlay closes drawer
- Always include a visible close (✕) button inside the drawer at top-right
- Drawer sits above all content (`z-index: 200`)
- Body scroll locks while drawer is open (`overflow: hidden` on `<body>`)

```css
.sidebar-drawer {
  position: fixed;
  top: 0; left: 0;
  width: 220px; height: 100vh;
  background: var(--bg-sidebar, #FFFFFF);
  border-right: 1px solid var(--border, #E9EAEB);
  transform: translateX(-220px);
  transition: transform 250ms ease;
  z-index: 200;
}
.sidebar-drawer.open { transform: translateX(0); }

.drawer-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 199;
  display: none;
}
.drawer-overlay.visible { display: block; }
```

### Top Bar — Responsive

| Breakpoint | Changes |
|---|---|
| Desktop | Full title + breadcrumb + all action buttons |
| Tablet | Title only (no breadcrumb) + primary button only |
| Mobile | Hamburger (☰) + title only + icon-only primary action |

```css
@media (max-width: 1023px) {
  .breadcrumb { display: none; }
  .tb-btn.secondary { display: none; }
  .hamburger { display: flex; }
}
@media (max-width: 767px) {
  .tb-btn.primary span { display: none; } /* icon only on mobile */
  .topbar-title { font-size: 13px; }
}
```

### Content Grid — Responsive

```css
/* Stat cards */
.stats-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr); /* desktop */
  gap: 12px;
}
@media (max-width: 1023px) {
  .stats-row { grid-template-columns: repeat(2, 1fr); } /* tablet: 2 cols */
}
@media (max-width: 767px) {
  .stats-row { grid-template-columns: 1fr; } /* mobile: stacked */
}

/* Card grids */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 16px;
}
```

### Data Tables — Mobile

Tables cannot horizontally scroll gracefully on mobile. Convert to **card-per-row** layout at mobile breakpoint:

```css
@media (max-width: 767px) {
  .t-head { display: none; } /* hide column headers */
  .t-row {
    display: flex;
    flex-direction: column;
    padding: 12px 16px;
    gap: 4px;
  }
  .t-row::before {
    content: attr(data-name);
    font-weight: 700;
    font-size: 13px;
    color: var(--text-primary, #1A1A2E);
  }
}
```

---

## Form Patterns

### Universal Form Rules

- Labels always **above** the input — never inside as placeholder replacements
- Required fields marked with a red asterisk `*` adjacent to the label — never inside the input
- Helper text (gray, `.myk-subtitle1`) sits below the input when additional context is needed
- Error message (red, `.myk-subtitle1`) replaces helper text on validation failure
- Never disable the submit button to show validation — show inline errors instead
- Group related fields into logical sections with a section header (`.myk-h6`, muted)
- Max form width: `640px` — never let a single-column form stretch full page width

```jsx
// ✅ Correct field anatomy
<div className="field-group" style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
  <label className="myk-subtitle1" style={{ fontWeight: 700, color: 'var(--text-primary, #1A1A2E)' }}>
    Email Address <span style={{ color: '#B42318' }}>*</span>
  </label>
  <input
    type="email"
    style={{
      height: 36, borderRadius: 6, padding: '0 12px',
      border: hasError ? '1px solid #B42318' : '1px solid var(--border, #E9EAEB)',
      background: 'var(--input-bg, #FFFFFF)',
      color: 'var(--text-primary, #1A1A2E)',
      fontSize: 14, fontFamily: 'Lato, sans-serif',
      boxShadow: hasError ? '0 0 0 3px rgba(180,35,24,0.2)' : 'none'
    }}
  />
  {hasError
    ? <span className="myk-subtitle1" style={{ color: '#B42318' }}>Please enter a valid email address.</span>
    : <span className="myk-subtitle1" style={{ color: 'var(--text-muted, #B8B8B8)' }}>We'll send the appointment confirmation here.</span>
  }
</div>
```

### Field Sizing

| Type | Height | Use |
|---|---|---|
| Default input | 36px | Most text fields |
| Large input | 44px | Prominent single fields (e.g. search, hero forms) |
| Textarea | Min 80px | Multi-line text, notes, descriptions |
| Select / dropdown | 36px | Always matches input height |

### Field Layout Grid

```css
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  max-width: 640px;
}
.form-grid .full-width { grid-column: 1 / -1; }

@media (max-width: 767px) {
  .form-grid { grid-template-columns: 1fr; } /* stack on mobile */
}
```

### Single-Page Form Pattern

Use for short forms (under 8 fields): service notes, quick customer lookup, payment entry.

```
┌─────────────────────────────────────┐
│ Section heading (.myk-h6, muted)    │
│                                     │
│ [First name]      [Last name]       │
│ [Email address              ]       │
│ [Phone number     ] [Type ▾ ]       │
│                                     │
│ Section heading                     │
│ [Vehicle year ▾] [Make ▾] [Model ▾]│
│ [Notes / description        ]       │
│ [                           ]       │
│                                     │
│           [Cancel]  [Save Changes]  │
└─────────────────────────────────────┘
```

- Action buttons always bottom-right aligned
- Cancel (secondary) to the left of primary action
- One primary action maximum

### Multi-Step Wizard Pattern

Use for complex flows (5+ fields, multiple domains): appointment booking, customer onboarding, payment setup.

```
Step indicator (top of form):
● ─────── ○ ─────── ○ ─────── ○
1.Info    2.Vehicle  3.Service  4.Confirm
```

**Step indicator rules:**
- Completed steps: filled brand blue circle (`--brand, #0377B3`) + checkmark
- Current step: filled brand blue circle + step number, label bold
- Upcoming steps: empty circle (`--border, #E9EAEB`), label muted
- Never show all steps' fields at once — one step rendered at a time

```jsx
// Step indicator
<div style={{ display: 'flex', alignItems: 'center', gap: 0, marginBottom: 32 }}>
  {steps.map((step, i) => (
    <React.Fragment key={i}>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
        <div style={{
          width: 28, height: 28, borderRadius: '50%',
          background: i < current ? 'var(--brand, #0377B3)' : i === current ? 'var(--brand, #0377B3)' : 'var(--border, #E9EAEB)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: i <= current ? '#fff' : 'var(--text-muted, #B8B8B8)',
          fontSize: 12, fontWeight: 700
        }}>
          {i < current ? '✓' : i + 1}
        </div>
        <span style={{
          fontSize: 11,
          fontWeight: i === current ? 700 : 400,
          color: i === current ? 'var(--text-primary, #1A1A2E)' : 'var(--text-muted, #B8B8B8)',
          whiteSpace: 'nowrap'
        }}>{step.label}</span>
      </div>
      {i < steps.length - 1 && (
        <div style={{ flex: 1, height: 1, background: i < current ? 'var(--brand, #0377B3)' : 'var(--border, #E9EAEB)', margin: '0 8px', marginBottom: 20 }} />
      )}
    </React.Fragment>
  ))}
</div>

// Step navigation footer
<div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 32, paddingTop: 16, borderTop: '1px solid var(--border, #E9EAEB)' }}>
  <button className="mk-button secondary-mk-button" onClick={prevStep} disabled={current === 0}>
    ← Back
  </button>
  <button className="mk-button primary-mk-button" onClick={current === steps.length - 1 ? handleSubmit : nextStep}>
    {current === steps.length - 1 ? 'Confirm & Submit' : 'Continue →'}
  </button>
</div>
```

**Wizard navigation rules:**
- "Back" always secondary button, left-aligned
- "Continue" / "Submit" always primary button, right-aligned
- Never allow skipping steps — forward navigation only via Continue
- Always save step data in state before advancing — never lose progress on Back
- On final step, show a summary of all previous answers before submit
- After submit, show a success confirmation screen — never redirect silently

---

## Skeleton Loaders

### Core Rules
- Every data surface must have a skeleton that **matches the exact shape** of the loaded content
- Never use a generic spinner for page-level or section-level loading
- Spinner is acceptable only for button-level loading (after a user action)
- Skeleton shimmer: animate from `var(--bg-base-2, #D8D8D8)` to `var(--bg-base-3, #B8B8B8)` and back

```css
@keyframes shimmer {
  0%   { background-position: -400px 0; }
  100% { background-position: 400px 0; }
}
.skeleton {
  border-radius: 4px;
  background: linear-gradient(
    90deg,
    var(--bg-base-2, #D8D8D8) 25%,
    var(--bg-base-3, #B8B8B8) 50%,
    var(--bg-base-2, #D8D8D8) 75%
  );
  background-size: 800px 100%;
  animation: shimmer 1.5s infinite linear;
}

/* Dark mode skeleton */
#shell.dark .skeleton {
  background: linear-gradient(
    90deg,
    #232839 25%,
    #2E3347 50%,
    #232839 75%
  );
  background-size: 800px 100%;
}
```

### Stat Card Skeleton

Matches the 4-column stat card row used in dashboards and the Conversations view.

```jsx
// Skeleton for one stat card — repeat × 4 in a grid
<div style={{
  background: 'var(--bg-card, #FFFFFF)',
  border: '1px solid var(--border, #E9EAEB)',
  borderRadius: 8, padding: 16
}}>
  <div className="skeleton" style={{ height: 28, width: '60%', marginBottom: 8 }} /> {/* stat value */}
  <div className="skeleton" style={{ height: 12, width: '80%', marginBottom: 6 }} /> {/* label */}
  <div className="skeleton" style={{ height: 10, width: '50%' }} />                  {/* delta */}
</div>
```

### Table Row Skeleton

Matches the conversation/customer table structure with avatar, name, and columns.

```jsx
// Skeleton for one table row — repeat × 5 for a full table
<div style={{
  display: 'grid',
  gridTemplateColumns: '2fr 80px 90px 90px 72px',
  padding: '0 16px', height: 46, alignItems: 'center',
  borderBottom: '1px solid var(--border, #E9EAEB)'
}}>
  {/* Customer cell: avatar + name/sub */}
  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
    <div className="skeleton" style={{ width: 28, height: 28, borderRadius: '50%', flexShrink: 0 }} />
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: 1 }}>
      <div className="skeleton" style={{ height: 13, width: '70%' }} />
      <div className="skeleton" style={{ height: 11, width: '50%' }} />
    </div>
  </div>
  <div className="skeleton" style={{ height: 12, width: '60%' }} /> {/* channel */}
  <div className="skeleton" style={{ height: 20, width: 56, borderRadius: 4 }} /> {/* badge */}
  <div className="skeleton" style={{ height: 12, width: '50%' }} /> {/* timestamp */}
  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 6 }}>
    <div className="skeleton" style={{ width: 26, height: 26, borderRadius: 4 }} />
    <div className="skeleton" style={{ width: 26, height: 26, borderRadius: 4 }} />
  </div>
</div>
```

### Sidebar Nav Skeleton

For when the nav items are loading (e.g. permission-based nav that fetches from API).

```jsx
<div style={{ padding: '12px 8px' }}>
  <div className="skeleton" style={{ height: 10, width: '40%', marginBottom: 8, marginLeft: 8 }} />
  {[1,2,3,4,5].map(i => (
    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '7px 8px', marginBottom: 2 }}>
      <div className="skeleton" style={{ width: 16, height: 16, borderRadius: 3, flexShrink: 0 }} />
      <div className="skeleton" style={{ height: 13, width: `${50 + i * 8}%` }} />
    </div>
  ))}
</div>
```

### Form Skeleton

For settings pages or forms that load existing data before rendering.

```jsx
<div style={{ maxWidth: 640, display: 'flex', flexDirection: 'column', gap: 20 }}>
  {[1,2,3].map(i => (
    <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div className="skeleton" style={{ height: 11, width: '25%' }} /> {/* label */}
      <div className="skeleton" style={{ height: 36, width: '100%', borderRadius: 6 }} /> {/* input */}
    </div>
  ))}
  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 8 }}>
    <div className="skeleton" style={{ height: 30, width: 80, borderRadius: 6 }} />
    <div className="skeleton" style={{ height: 30, width: 120, borderRadius: 6 }} />
  </div>
</div>
```

### Button Loading State

For after a user submits an action — spinner replaces button text, button stays same size.

```jsx
<button
  className="mk-button primary-mk-button"
  disabled={loading}
  style={{ opacity: loading ? 0.7 : 1, minWidth: 120 }}
>
  {loading
    ? <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" style={{ animation: 'spin 0.7s linear infinite' }}>
          <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
        </svg>
        Saving…
      </span>
    : 'Save Changes'
  }
</button>

<style>
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
</style>
```

---

## Accessibility

- All text must meet WCAG AA contrast (4.5:1 body, 3:1 large text and UI)
- Never remove `:focus-visible`
- Form errors must use `aria-live` or `aria-describedby` — never color alone
- Use the `disabled` HTML attribute on form elements (not just CSS opacity)
- Every icon must have `aria-label` or adjacent visible text
- Toggle must have `role="switch"` and `aria-checked`

---

## Known Rendering Pitfalls

Confirmed bugs from testing. AI must avoid all of these.

### 1. Never use `<button>` for chips or tab filters
The widget host injects `<button>` styles (black background, white text) that override custom CSS in light mode. Use `<div>` with `onclick`.

### 2. Never put `border` on the root `#shell` element
A border on the outermost container bleeds through as a visible ring in light mode. Use only internal borders.

```css
/* ❌ Visible ring in light mode */
#shell { border: 1px solid #ccc; border-radius: 12px; }

/* ✅ No border on root */
#shell { border-radius: 12px; overflow: hidden; }
```

### 3. Never use `line-height` to center button text
Always use `display: inline-flex; align-items: center; justify-content: center`.

### 4. Always scope tokens to `#shell.light` / `#shell.dark`
Never use bare `.light` or `.dark` — host may have conflicting classes.

### 5. Always run `initTheme()` in `<head>` before render
Avoids flash of wrong theme on load.

### 6. Moon icon must be dark, not light
Moon icon fill/stroke must be `#334155` (dark slate) so it's visible against the white toggle knob. Never use light gray or white for the moon icon.

---

## What AI Must Never Do

| ❌ Never | ✅ Instead |
|---|---|
| Hardcode any hex value without a token | Use `var(--token, #fallback)` |
| Use a token without an inline fallback | Always write `var(--brand, #0377B3)` not `var(--brand)` |
| Display a raw UUID in a table | Truncate to 8 chars + copy icon |
| Use `font-size: 14px` inline | Use `.myk-body2` class |
| Blue badge for "Active" status | `#027A48` text on `#ECFDF3` bg |
| Two primary buttons in one form | One primary, one secondary |
| Blank screen while loading | Skeleton row components |
| `--primary-accent` for primary actions | Orange is for logo mark and warnings only |
| Icon without `aria-label` | Always add accessible label |
| Custom shadow value | Use `var(--shadow-xs)` through `var(--shadow-lg)` |
| `.mk-h1` or any `.mk-` class | Use `.myk-h1` and `.myk-` classes only |
| Color alone for disabled state | `opacity: 0.5` + `pointer-events: none` |
| Pure black (`#000000`) as dark bg | Use `#0F1117` |
| Pure white (`#FFFFFF`) as dark text | Use `#F0F4F8` |
| Logo mark in blue | Logo mark is always `#ED6D22` — both modes |
| `<button>` for chips or tab filters | Use `<div>` with `onclick` |
| `border` on the root `#shell` element | Internal borders only |
| `line-height` to center button text | `display: inline-flex; align-items: center; justify-content: center` |
| `.dark { }` or `.light { }` bare selectors | Always scope as `#shell.dark` / `#shell.light` |
| Secondary button with 2px border | Always `1px` border — matches text color |
| Scale tokens (e.g. `--Green-700`) in component code | Use semantic tokens with fallbacks instead |
| Light gray or white moon icon | Moon icon must be `#334155` on white knob |
| Truncate text without a `title` tooltip | Always pair truncation with `title={fullValue}` |
| Let table columns expand past container | Use `table-layout: fixed` + `text-overflow: ellipsis` |
| Display raw JS float math | Always use `Math.round()`, `.toFixed()`, or `Intl.NumberFormat` |
| Full sidebar on tablet/mobile | Sidebar becomes a drawer (`position: fixed`, slides from left) |
| Spinner for page or section loading | Use skeleton loaders shaped like the real content |
| Generic rectangle skeleton | Skeleton must match exact shape: avatar circle, badge pill, etc. |
| Labels inside inputs as placeholder replacements | Labels always above the input |
| Disable submit button to show validation | Show inline field-level error messages instead |
| Skip step in a multi-step wizard | Forward navigation only via Continue button |
| Redirect silently after form submit | Always show a success confirmation screen |
| Stretch a form to full page width | Max form width is `640px` |

---

## Quick Reference — Paste Into Any AI Prompt

```
You are building UI for myKaarma, a B2B automotive SaaS platform.
Follow every rule below without exception.

TOKENS: Never hardcode colors. Always use CSS custom properties with inline hex fallbacks.
Format: var(--token-name, #hexfallback). Example: var(--primary-color, #0377B3)

COLORS:
- Primary blue var(--primary-color, #0377B3): CTAs, links, active states only
- Primary accent #ED6D22: logo mark background and warnings only — never for actions
- Green #027A48 on #ECFDF3: success/active badges
- Red #B42318 on #FEF3F2: error states
- Orange #ED6D22 on #FFE0B6: warning states
- Muted gray var(--text-muted, #B8B8B8): inactive text only

LOGO: Logo mark background is always #ED6D22 (both modes). Wordmark uses var(--brand, #0377B3).

TYPOGRAPHY: Use .myk- prefixed classes only. Never define custom font sizes. Never use .mk- classes.

BUTTONS:
- Requires .mk-button base class + variant (e.g. primary-mk-button)
- One primary button per section maximum
- Always: display:inline-flex; align-items:center; justify-content:center (never line-height)
- Secondary button: 1px solid border, same color as text, transparent background

CHIPS & FILTERS: Never use <button> for chips — host styles override them. Use <div onclick="">.

DARK MODE:
- Scope ALL token overrides to #shell.dark and #shell.light (never bare .dark / .light)
- Never pure black (#000000) bg — use #0F1117
- Never pure white (#FFFFFF) text — use #F0F4F8
- Dark secondary button border + text: #7EB8D9
- Moon icon: #334155 (dark slate on white knob)
- Run initTheme() in <head> before render to prevent flash

SHELL: No border on root #shell element. Use border-radius + overflow:hidden only.

NAV: Sidebar 220px + 52px top bar. Toggle in sidebar footer only.
Active nav = background fill only — never left border bar.

DATA: Never show raw UUIDs. Truncate to 8 chars + copy icon.

TRUNCATION: All dynamic text in table cells and card titles must truncate with ellipsis.
Always pair truncation with title={fullValue} tooltip. Use table-layout:fixed on all tables.
Never display raw JS floats — always format with Math.round(), toFixed(), or Intl.NumberFormat.

RESPONSIVE (3 breakpoints):
- Desktop 1024px+: sidebar 220px fixed + content
- Tablet 768–1023px: sidebar hidden, drawer on demand, 2-col stat grid, secondary btn hidden
- Mobile <768px: sidebar hidden, drawer on demand, 1-col layout, tables become card rows

SIDEBAR DRAWER (tablet/mobile): position:fixed, width:220px, slides from left with
transform:translateX(-220px)→translateX(0), z-index:200, overlay rgba(0,0,0,0.5) behind it.

FORMS:
- Labels always above inputs, never inside. Required fields marked with red asterisk *.
- Error messages below field in red — never disable submit to show validation.
- Max form width 640px. Use 2-col grid (1fr 1fr), stack to 1-col on mobile.
- Single-page: under 8 fields. Multi-step wizard: 5+ fields or multiple domains.
- Wizard: step indicator at top, one step at a time, Back(secondary left) + Continue(primary right).
- Final step shows summary before submit. Always show success screen after submit.

SKELETONS: Every data surface needs a skeleton matching the exact shape of real content.
- Stat card skeleton: 28px value block + 12px label + 10px delta
- Table row skeleton: 28px avatar circle + name/sub lines + column blocks
- Never use a generic spinner for page or section loading — spinner for button loading only.
- Skeleton CSS: shimmer animation between --bg-base-2 and --bg-base-3

EMPTY STATES, DISABLED STATES: Always implement — never skip.

ICONS: Material Design Icons (outlined default, filled for active). Always aria-label.

SOURCE FILES (fetch if accessible):
- theme.css: https://static.mykaarma.com/res/mkblue/css/theme.css
- text-size.css: https://static.mykaarma.com/res/global/css/text-size.css
- mk-button.css: https://static.mykaarma.com/res/global/css/mk-button.css
If source files cannot be fetched, use the hex fallback values in each var() call.
```
