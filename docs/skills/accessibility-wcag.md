---
name: accessibility-wcag
description: Build and verify UI against WCAG 2.2 level AA - semantic markup, labels, keyboard, focus, contrast, reflow, status messages and accessible authentication, with automated axe checks plus a manual checklist. Use for every frontend task and the final accessibility audit.
---

# Skill: Accessibility (WCAG 2.2 AA)

## Purpose
Make every screen usable with keyboard, screen readers, zoom and low vision. Target: **WCAG 2.2 level AA** ([W3C](https://www.w3.org/TR/WCAG22/)). Automated tools catch only part of the problems, so this skill combines automated checks with a short manual pass. Full conformance claims require expert review with assistive technologies; this skill reduces risk, it does not certify.

## When to use
- While building any component (use the checklist as a definition of done).
- Task U-10 (accessibility pass) and the final audit (D-4a in spec 08).
- When a bug about keyboard, focus, contrast or screen readers is reported.

## Build rules (apply while coding)

| Area | Rule | WCAG |
|------|------|------|
| Language | `<html lang="pt-BR">`; page `<title>` changes per route | 3.1.1, 2.4.2 |
| Structure | One `<h1>` per page, headings in order, landmarks (`header`, `nav`, `main`, `footer`), skip link "Ir para o conteúdo" as the first focusable element | 1.3.1, 2.4.1, 2.4.6 |
| Forms | Visible `<label>` bound with `htmlFor`; `autocomplete` tokens (`email`, `current-password`, `new-password`); instructions before the field; required state in text, not only color | 1.3.1, 1.3.5, 3.3.2 |
| Errors | Message in text next to the field, linked with `aria-describedby`, `aria-invalid="true"`, and announced via `role="alert"`; say what is wrong and how to fix it; focus the first invalid field or the error summary on submit | 3.3.1, 3.3.3, 4.1.3 |
| Status messages | Loading, success and failure messages in `aria-live="polite"` regions (or `role="status"`); skeletons set `aria-busy="true"` | 4.1.3 |
| Keyboard | Everything operable with Tab, Enter, Space; no keyboard traps; logical DOM order; no positive `tabindex` | 2.1.1, 2.1.2, 2.4.3 |
| Focus | Visible focus indicator on every interactive element (2px outline, contrast >= 3:1 against adjacent colors); focus never hidden behind sticky UI; move focus to the page heading after route changes | 2.4.7, 2.4.11, 1.4.11 |
| Target size | Interactive targets at least 24x24 CSS px (prefer 44x44 for buttons) | 2.5.8 |
| Names | Accessible name contains the visible label text; icon-only buttons have `aria-label` | 2.5.3, 4.1.2 |
| Buttons vs links | Links navigate (`<a>` / router `Link`), buttons act (`<button type="button">`); toggles use `aria-pressed`, expanders use `aria-expanded` and `aria-controls` | 4.1.2 |
| Color and contrast | Text >= 4.5:1 (large text >= 3:1); UI component boundaries and icons >= 3:1; never color alone to convey state (add text or icon) | 1.4.3, 1.4.11, 1.4.1 |
| Reflow and zoom | No horizontal scroll at 320 CSS px width / 400% zoom (tables may scroll inside their own container); text resizes to 200% without loss; do not disable zoom in the viewport meta | 1.4.4, 1.4.10 |
| Text spacing | Layout survives line-height 1.5, paragraph spacing 2x, letter spacing 0.12em, word spacing 0.16em | 1.4.12 |
| Tables | Real `<table>` with `<caption>` (can be visually hidden), `<th scope="col">`; no layout tables | 1.3.1 |
| Motion | Respect `prefers-reduced-motion`; skeleton shimmer must be disableable by it; no flashing content | 2.3.1, 2.2.2 |
| Hover/focus content | Tooltips or popovers dismissible, hoverable and persistent | 1.4.13 |
| Authentication | Allow paste and password managers; no cognitive tests or transcription of codes; keep entered data on error | 3.3.8, 3.3.7 |
| Consistency | Same navigation and component behavior across pages; same labels for the same function | 3.2.3, 3.2.4 |
| Images | Decorative images `alt=""`; no informative images without text alternative | 1.1.1 |

## Automated checks

| Layer | Tool | Where |
|-------|------|-------|
| Lint | `eslint-plugin-jsx-a11y` (recommended config, errors) | `npm run lint` |
| Component | `vitest-axe` (`toHaveNoViolations`) on each page and key component state (loading, error, ready) | `*.test.tsx` |
| E2E | `@axe-core/playwright` scanning `/login`, `/`, `/processos/:number` (ready, not-found) with tags `wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa` | `frontend/e2e/a11y.spec.ts` |

Rule: zero **serious/critical** axe violations. Any waived rule needs a comment with the reason and an entry in the PR description.

## Manual pass (about 20 minutes, before merge of each UI task and in the final audit)

1. **Keyboard only:** complete sign up, sign in, search, expand a movement, load more, rate the summary, sign out. Focus visible and in logical order; no trap.
2. **Screen reader smoke** (NVDA/Orca/VoiceOver, one is enough): headings list, landmarks, form labels and errors announced, summary loading/ready announced, table read with headers.
3. **Zoom:** 200% browser zoom and 320 px viewport; no clipped or overlapping content, no page-level horizontal scroll.
4. **Contrast:** check tokens with a contrast tool; record ratios for text, muted text, borders, focus ring.
5. **Reduced motion:** enable the OS setting; animations stop.
6. **Text spacing bookmarklet** (WCAG 1.4.12) on the lawsuit page.

Record results (pass/fail per item, tool and version) in the PR using the template below.

```markdown
### Accessibility (WCAG 2.2 AA)
- axe (component + E2E): 0 serious/critical
- Keyboard-only flow: pass
- Screen reader smoke (<tool>): pass / notes
- Zoom 200% / 320 px: pass
- Contrast ratios: text 7.1:1, muted 4.9:1, focus ring 4.2:1
- Reduced motion: pass
- Known gaps: <list or none>
```

## Output
Accessible components with tests, the PR checklist filled, and no serious/critical axe findings.

## Common mistakes
- `div` buttons, placeholder-as-label, color-only errors.
- Moving focus nowhere after navigation, or trapping it in an expander.
- Announcing every skeleton change (noisy live regions) or never announcing the final result.
- Suppressing the focus outline without a replacement.
- Treating a green axe run as full conformance.
