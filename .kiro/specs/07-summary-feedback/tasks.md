# Tasks: Summary feedback

Lead: Backend (B3) + Frontend (F2). Reviewers: AI Engineer, QA. Status: implemented (browser check pending the E2E run).

## 4-hour execution board (overrides the hour estimates below)

Schedule and ownership: [EXECUTION-PLAN-4H](../../../docs/plan/EXECUTION-PLAN-4H.md). First item to cut if a gate slips (cut line step 1).

| Task | Lane | ⏱ min | After |
|------|------|------:|-------|
| FB-1 Model (migration is in F-10) | B3 | 6 | F-10 |
| FB-2 `Feedback::Rate` and `rateSummary` | B3 | 12 | FB-1, A-8 |
| FB-3 `Summary.myFeedback` | B3 | 6 | FB-2 |
| FB-4 `FeedbackButtons` in `SummaryCard` (MSW first) | F2 | 10 | U-7 |
| FB-5 `feedback:report` | B3 | 8 | FB-2 |
| FB-6 Docs | B3 | 5 | FB-5 |
Cut-line note: this is the first item to drop if time runs out (see the implementation plan).

- [x] **FB-1. Migration and model** (0.5 h)
  - Red: model validations; DB-level uniqueness on `(summary_id, user_id)`.
  - _Requirements: 1.1, 1.2_

- [x] **FB-2. `Feedback::Rate` service and `rateSummary` mutation** (0.5 h)
  - Red: create, change vote, idempotent repeat, other user independent, unknown summary, anonymous rejected, concurrent upsert leaves one row.
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] **FB-3. `Summary.myFeedback`** (0.25 h)
  - Red: null/true/false per user; no exposure of other users' votes; no N+1 (Dataloader).
  - Regenerate `backend/schema.graphql`.
  - _Requirements: 3.1, 3.2_

- [x] **FB-4. `FeedbackButtons` in `SummaryCard`** (0.5 h)
  - Red: pressed state from data, optimistic update, rollback, active button click keeps vote, hidden while loading/failed, live message.
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] **FB-5. `feedback:report` rake task** (0.25 h)
  - Red: output with and without votes; no identifiers.
  - _Requirements: 5.1, 5.2, 5.3_

- [x] **FB-6. Docs** (0.25 h)
  - Update [authentication](../../../docs/domains/authentication.md) section 7, `architecture.md` ER/schema, README (how to read the report); run [finish-delivery-docs](../../../docs/skills/finish-delivery-docs.md).

## Definition of done (spec)
- [ ] In the browser: vote, reload, vote persists; change vote; second user sees no vote.
- [ ] `feedback:report` prints a sensible table after a few votes.
- [ ] Gate green on both sides.
