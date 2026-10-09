# Accessibility audit (D-4a)

Target: WCAG 2.2 AA. Passing automated checks does not prove conformance. Full validation needs manual testing with assistive technologies and an expert review; the manual column below says what is still open.

## Automated evidence

| Check | Where | Status |
|-------|-------|--------|
| axe (`vitest-axe`) on every component and page test, including the feedback buttons with a vote | `frontend/src/**/*.test.tsx` | Run with the frontend suite (see the README for the last result) |
| axe in the browser with tags `wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa` on login, sign-up with errors, lawsuit ready (with feedback buttons) and not found | `frontend/playwright/lookup.spec.ts` | Needs the running stack |
| Reflow at 320 px without page-level horizontal scroll | `frontend/playwright/lookup.spec.ts` | Needs the running stack |
| ESLint `jsx-a11y` | `npm run lint` | Run with the frontend lint |

## Contrast (computed from `frontend/src/styles/tokens.css`)

Ratios use the WCAG relative luminance formula. Text needs 4.5:1, UI components and focus indicators need 3:1.

| Pair | Foreground | Background | Ratio | Needed | Result |
|------|-----------|-----------|------:|-------:|--------|
| Text on surface | #1f2933 | #ffffff | 14.76 | 4.5 | pass |
| Text on page | #1f2933 | #f4f6f8 | 13.62 | 4.5 | pass |
| Muted text on surface | #52606d | #ffffff | 6.46 | 4.5 | pass |
| Muted text on page | #52606d | #f4f6f8 | 5.96 | 4.5 | pass |
| Button text on brand (also the pressed vote button) | #ffffff | #1d3557 | 12.36 | 4.5 | pass |
| Secondary button text on surface | #1d3557 | #ffffff | 12.36 | 4.5 | pass |
| Secondary button text on hover | #1d3557 | #f0f3f6 | 11.10 | 4.5 | pass |
| Link on surface | #0b4fb3 | #ffffff | 7.54 | 4.5 | pass |
| Link on page | #0b4fb3 | #f4f6f8 | 6.96 | 4.5 | pass |
| Error on surface | #b3261e | #ffffff | 6.54 | 4.5 | pass |
| Error on error background | #b3261e | #fdecea | 5.72 | 4.5 | pass |
| Success message on surface | #1b6e3c | #ffffff | 6.28 | 4.5 | pass |
| Input border on surface | #7b8794 | #ffffff | 3.66 | 3 | pass |
| Input border on page | #7b8794 | #f4f6f8 | 3.38 | 3 | pass |
| Focus ring on surface | #0b57d0 | #ffffff | 6.39 | 3 | pass |
| Focus ring on page | #0b57d0 | #f4f6f8 | 5.89 | 3 | pass |

The focus ring (#0b57d0) against the brand colour is only 1.94:1, but the ring is drawn with a 2 px offset, so it sits on the surrounding surface or page colour, not on the filled button. In the dark header the ring uses the accent colour (`esaj.css`, `.app-header :focus-visible`).

## Code review items

| Item | Finding |
|------|---------|
| Focus indicator | `:focus-visible` outline 3 px with 2 px offset (`base.css`) |
| Reduced motion | `prefers-reduced-motion: reduce` stops the skeleton shimmer (`base.css`) |
| Vote buttons | Native `<button>` elements, `aria-pressed`, a check mark in the label when pressed so state is not colour only, group labelled by the question, 44 px target (`--target-size`) |
| Live messages | Feedback result in a polite `aria-live` region that exists before it is filled; the summary card has its own polite region; the two are not nested |
| Headings | The feedback block adds no heading, so the page outline is unchanged |

## Still manual (not done by the agent)

- Keyboard-only walk through login, search, lawsuit page, voting and sign out in a real browser.
- Screen reader pass (NVDA or VoiceOver) of the lawsuit page and the vote announcement.
- Zoom to 200% and 400% and text spacing overrides.

Record the outcome of these in the final pull request.
