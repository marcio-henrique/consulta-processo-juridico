# Tasks: Quality and delivery

Lead: QA + Security + Platform. Reviewers: Architect, owner. Status: D-1, D-2, D-3, D-5, D-6 done. D-4, D-7 to D-10 are open (see notes).

## 4-hour execution board (overrides the hour estimates below)

Schedule and ownership: [EXECUTION-PLAN-4H](../../../docs/plan/EXECUTION-PLAN-4H.md). E2E and axe specs are written in advance (QA, 2:00-2:45) and executed at G3.

| Task | Lane | ⏱ min | After | Gate |
|------|------|------:|-------|------|
| D-1 Verify both coverage gates | QA | 10 | G3 | G4 |
| D-2 Traceability table | QA | 20 | draft from G1 | G4 |
| D-3 Playwright E2E smoke **plus axe scans** (`wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa`) of `/login`, `/`, lawsuit ready, lawsuit not found | QA | 30 | G3 | G4 |
| D-4 Golden-set run review by the Legal Expert | QA | 20 | A-11 | G4 |
| D-4a Accessibility audit: manual pass from [accessibility-wcag](../../../docs/skills/accessibility-wcag.md), contrast ratios, keyboard, zoom, reduced motion | QA (with F2) | 20 | G3 | G4 |
| D-5 Security audit ([security-review](../../../docs/skills/security-review.md) final audit extras) | SEC | 20 | G3 | G4 |
| D-6 Final README, coverage numbers | P | 15 | D-1 | G4 |
| D-7 Clean-clone verification | QA | 20 | G5 start | T+4:00 |
| D-8 Demo video (human, owner) | owner | 30 | G5 | after 4:00 |
| D-9 Share repo and send email (human, owner) | owner | 10 | D-8 | after 4:00 |
| D-10 Freeze | all | - | deadline | - |

Add to requirement 6 of this spec: the accessibility audit (D-4a) and the security audit (D-5) results SHALL be attached to the final PR.

- [x] **D-1. Verify coverage gates with the full code base** (0.25 h)
  - Run both suites; confirm both gates pass; temporarily break one to confirm they still fail; record the numbers.
  - Done 2026-10-09: backend 98.31% lines (gate 80), frontend 100% lines / 95.65% branches (gates 80). Gate failure confirmed: backend partial runs exit 2 below 80%; frontend `--coverage.thresholds.lines=101` exits 1. The frontend branch gate stays at 80% (stricter than the 70% in the requirements).
  - _Requirements: 1.1, 1.2, 1.4_

- [x] **D-2. Traceability table** (0.5 h)
  - Create `.kiro/specs/08-quality-and-delivery/traceability.md` mapping FR/NFR/Diff and spec requirement groups to tests or manual evidence; add missing tests found by the exercise.
  - _Requirements: 2.1, 2.2_

- [x] **D-3. Playwright E2E smoke** (0.75 h)
  - Install Playwright in `frontend/`; write the flow from requirement 3.2; add `npm run test:e2e`; document; decide CI inclusion by runtime.
  - Done: `frontend/playwright/lookup.spec.ts` (kept in `playwright/`, not `e2e/`), run with `npm run test:e2e`; includes rating, reload persistence and axe scans. Not in CI (needs the full stack and a browser): documented as a manual step in the README.
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] **D-4. Golden-set review with the Legal Expert** (0.25 h)
  - Repeat the evaluation if prompt/model changed since A-11; record pass/fail and limitations (in README "Assumptions and limits").
  - Open: needs a real Gemini run and a legal reviewer; recorded as a limit in the README.
  - _Requirements: 6.2_

- [x] **D-5. Security and dependency audit** (0.5 h)
  - Run brakeman, bundler-audit, npm audit, secret scan; fix or document findings; confirm `.env` untracked.
  - Done: see [security-audit](security-audit.md).
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] **D-6. Final README and AGENTS.md** (0.5 h)
  - Write per the structure in design.md; add screenshots, coverage numbers, exclusions list; verify AGENTS.md matches reality.
  - _Requirements: 1.3, 5.1, 5.3_

- [ ] **D-7. Clean-clone verification** (0.5 h)
  - Follow [prepare-delivery](../../../docs/skills/prepare-delivery.md) section B on a fresh clone; fix whatever fails; keyboard-only and contrast checks recorded.
  - Open. Blocker found: `data/lawsuits_movements.csv` is not tracked by git yet (`.gitignore` allows it, but it was never added), so a fresh clone has no CSV. `git add data/lawsuits_movements.csv` before verifying. Manual accessibility checks are listed in [accessibility-audit](accessibility-audit.md).
  - _Requirements: 5.2, 6.1, 6.3_

- [ ] **D-8. Demo video** (0.5 h)
  - Rehearse once, record (Loom) at most 4 minutes; check the link in a private window.
  - _Requirements: 7.2_

- [ ] **D-9. Share and send** (0.25 h)
  - Repository private; add `ariel@resolvvi.com` and `tayllan@resolvvi.com`; send the email with repository and video links before the deadline; verify commit messages are English.
  - _Requirements: 7.1, 7.3, 7.4_

- [ ] **D-10. Freeze**
  - No more commits or pushes after the deadline. Do not merge anything late.
  - _Requirements: 7.5_

## Definition of done (spec)
- [ ] Every item in `prepare-delivery.md` is ticked with evidence.
- [ ] Email sent; repository frozen.
