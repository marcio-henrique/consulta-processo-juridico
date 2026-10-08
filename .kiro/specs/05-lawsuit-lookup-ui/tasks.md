# Tasks: Lawsuit lookup UI

Lead: Frontend. Reviewers: Legal Expert (copy), QA, Security. Status: not started.

## 4-hour execution board (overrides the hour estimates below)

Schedule and ownership: [EXECUTION-PLAN-4H](../../../docs/plan/EXECUTION-PLAN-4H.md). Everything is built against [docs/contracts/schema.graphql](../../../docs/contracts/schema.graphql) and MSW until U-12. Every UI task follows [accessibility-wcag](../../../docs/skills/accessibility-wcag.md) and ends with its PR checklist.

| Task | Lane | ⏱ min | After |
|------|------|------:|-------|
| U-9a Design tokens (contrast-checked), base CSS, `AppShell` (landmarks, skip link), `SkipLink`, focus-on-h1 on route change | F2 | 20 | F-6 |
| U-1 `cnj.ts` | F1 | 8 | F-6 |
| U-2 `format.ts` | F1 | 4 | F-6 |
| U-3 Routes, Apollo wiring, MSW handlers, `renderWithProviders`, page titles | F1 | 12 | F-7, U-9a |
| U-4 `CnjSearchForm` + `HomePage` | F1 | 12 | U-1, U-3 |
| U-5 `LawsuitHeader` + `LawsuitData` | F1 | 10 | U-3 |
| U-6 `MovementsTable`, `MovementRow`, load more | F1 | 20 | U-5 |
| U-7 `SummaryCard` | F2 | 15 | U-9a |
| U-8 `LawsuitPage` states and summary flow | F1 | 15 | U-6, U-7 |
| U-9 e-SAJ-like styling and responsive checks (320 px) | F2 | 25 | U-8 |
| U-10 Accessibility pass: axe per state, keyboard, zoom, contrast ratios recorded | F2 | 20 | U-9 |
| U-11 Coverage and cleanup | F2 | 10 | U-10 |
| U-12 Switch from MSW to the real API, manual end-to-end check | F1 | 15 | G2 (backend lookup live) |

U-10 must additionally verify requirements 7.1-7.16 of this spec (WCAG 2.2 AA) and record the results in the PR.

- [ ] **U-1. `cnj.ts` helper** (0.5 h)
  - Red: tests for digits-only, progressive mask, validation (valid, bad check digit, wrong length), challenge example valid, `...0071` invalid.
  - _Requirements: 8.1, 8.2, 1.2_

- [ ] **U-2. `format.ts` helper** (0.25 h)
  - Red: ISO date to `dd/mm/aaaa` without `Date` timezone shifts.
  - _Requirements: 3.2_

- [ ] **U-3. App shell, routes, Apollo wiring, test utilities** (0.5 h)
  - Routes `/` and `/processos/:number`; `AppShell` header; MSW handlers; `renderWithProviders`; `document.title` per page.
  - _Requirements: 7.4, 6.3_

- [ ] **U-4. `CnjSearchForm` and `HomePage`** (0.5 h)
  - Red: component tests per requirement 1.
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 7.1_

- [ ] **U-5. `LawsuitHeader` and `LawsuitData`** (0.5 h)
  - Red: values rendered with pt-BR currency from the API `formatted`; no unavailable fields.
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] **U-6. `MovementsTable`, `MovementRow`, load more** (1.0 h)
  - Red: caption/headers, order, bold title + muted content, collapse threshold, `aria-expanded`, `Carregar mais` with Apollo `fetchMore` and cache merge, empty state.
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] **U-7. `SummaryCard`** (0.75 h)
  - Red: ready, loading, error + retry, paragraphs, disclaimer, text-only rendering, `aria-live`.
  - _Requirements: 4.1, 4.4, 4.5, 4.6, 4.7_

- [ ] **U-8. `LawsuitPage` states and summary flow** (0.5 h)
  - Red: loading skeletons, not found, network error with retry, auto-generate once (StrictMode-safe), retry flow, canonical number display.
  - _Requirements: 4.2, 4.3, 5.1, 5.2, 5.3, 5.4_

- [ ] **U-9. e-SAJ-like styling and responsiveness** (1.0 h)
  - Compare against `data/html_link_portal/Portal de Serviços e-SAJ.html` side by side; tokens; striped table; 360-1280 px checks; take screenshots for the PR and the video.
  - _Requirements: 6.1, 6.2_

- [ ] **U-10. Accessibility pass** (0.5 h)
  - Keyboard-only run, focus order and visibility, contrast, labels, `role="alert"`, 200% zoom; fix findings. Optionally add `vitest-axe` to key components.
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] **U-11. Coverage and cleanup** (0.5 h)
  - Verify thresholds (80/80/80/70); remove dead code; `tsc --noEmit`, ESLint clean; docs via [finish-delivery-docs](../../../docs/skills/finish-delivery-docs.md).

## Notes
- Auth redirects (`/login?next=`) and the user menu come from spec 06 (AU-7 to AU-9). Feedback buttons come from spec 07 (FB-4).
- Use `1001399-31.2023.8.26.0070` as the "found" example in tests, docs and the demo. The challenge example is not in the data and must show the not-found state.

## Definition of done (spec)
- [ ] Against the real API: search a known number, see data, summary (fake or real) and movements with paging.
- [ ] Not-found and invalid states verified manually.
- [ ] Vitest coverage thresholds pass.
