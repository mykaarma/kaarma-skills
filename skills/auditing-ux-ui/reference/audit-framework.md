# UX/UI Audit Framework

Full checklist for auditing PM prototypes. Rate each issue: **Critical / Major / Minor**.

---

## 1. Task Completion & User Flows

- Can a new user understand what to do without instruction?
- Is the primary CTA obvious and reachable without scrolling on first load?
- Are multi-step flows clearly sequenced with progress indicators where needed?
- Are there dead ends, missing screens, or broken logic in the flow?
- Are all four states handled: **error, empty, loading, success**?
- Are there steps that feel unnecessary or could be collapsed?

## 2. Information Architecture & Navigation

- Is the hierarchy of information clear — do the most important things command the most visual weight?
- Is the navigation model consistent and predictable across screens?
- Are labels and menu items in plain language, not internal jargon?
- Can the user always tell where they are and how to go back or cancel?

## 3. Usability Heuristics (Nielsen's 10)

Flag violations of:

| Heuristic | What to check |
|-----------|--------------|
| Visibility of system status | Does the UI confirm what's happening? |
| Match system to real world | Language users actually use |
| User control and freedom | Undo, cancel, escape hatches |
| Consistency and standards | Follows expected UI conventions |
| Error prevention | Are mistakes avoidable (not just recoverable)? |
| Recognition over recall | Don't make users memorize things |
| Flexibility and efficiency | Works for both new and expert users |
| Aesthetic and minimalist design | Anything unnecessary or distracting? |
| Error recovery | Can users recognize, diagnose, and recover from errors? |
| Help and documentation | Available where users will actually get stuck? |

## 4. UI Clarity & Visual Design

- Is there a clear visual hierarchy on each screen?
- Are interactive elements (buttons, links, inputs) visually distinguishable from static content?
- Is typography readable — appropriate font size, line height, contrast?
- Is spacing consistent, or does the layout feel crowded or scattered?
- Are color and iconography used meaningfully, or arbitrarily?
- Does anything look unfinished, misaligned, or visually inconsistent across screens?

## 5. Feedback & System States

- Does the UI respond to user actions — hover states, loading indicators, confirmations?
- Are success, error, and warning states clearly communicated?
- Are destructive actions (delete, submit, send) protected with a confirmation step?
- Are form validation errors shown inline, or only after submission?

## 6. Edge Cases & Missing States

- **Empty states**: What does the screen look like with no data yet?
- **Error states**: Network failure, server error, invalid input
- **Long content**: Very long names, large datasets, many items in a list
- **Permission/access states**: What if the user doesn't have access?
- **Loading states**: What does the UI show while data is fetching?
- **Returning vs. first-time users**: Are they treated differently where it matters?

## 7. Accessibility (WCAG 2.1 AA)

- Text meets minimum contrast ratios (4.5:1 for body, 3:1 for large text)?
- Interactive elements are large enough to tap/click (minimum 44×44px)?
- Form fields have real labels — not just placeholder text?
- Icons and images have visible text or accessible alt labels?
- Tab/focus order is logical for keyboard users?

## 8. Mobile & Responsive Considerations

*(Skip if confirmed desktop-only)*

- Layout adapts reasonably to smaller screens?
- Touch targets are appropriately sized for thumb use?
- No excessive horizontal scrolling or content cutoff on mobile?
- Modals and overlays are usable on small screens?

## 9. Engineering Feasibility Flags

*(For engineering reviewers — flag anything technically complex or ambiguous)*

- Interactions or animations that would require significant custom development?
- UI components that conflict with the existing design system?
- Unclear states, missing specs, or behaviors an engineer would have to guess at?
- Assumptions of real-time data, complex backend logic, or unbuilt integrations?
