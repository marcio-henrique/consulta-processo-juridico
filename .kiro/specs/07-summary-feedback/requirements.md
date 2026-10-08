# Requirements: Summary feedback

## Introduction

Let a signed-in user rate whether the AI summary was helpful, and give the team a way to read the results. Challenge item: differential 5. Depends on spec 04 (summaries) and spec 06 (users). Related: [authentication](../../../docs/domains/authentication.md) section 7.

## Requirements

### Requirement 1: Store feedback

**User Story:** As a product owner, I want ratings tied to specific summaries, so that I can compare prompt versions.

#### Acceptance Criteria
1. THE `summary_feedbacks` table SHALL store `summary_id`, `user_id` and `helpful` (boolean), all required, with foreign keys and a unique index on `(summary_id, user_id)`.
2. THE feedback SHALL reference the summary row, so a new summary (new digest, prompt version or model) starts without votes.

### Requirement 2: Rate a summary

**User Story:** As a user, I want to say whether the summary helped me.

#### Acceptance Criteria
1. WHEN `rateSummary(summaryId:, helpful:)` is called by a signed-in user for an existing summary, THEN the system SHALL create the feedback and return it with an empty `errors` list.
2. WHEN the same user rates the same summary again, THEN the system SHALL update the existing vote (upsert) and SHALL NOT create a second row.
3. IF the summary does not exist, THEN the system SHALL return `NOT_FOUND`.
4. IF the caller is anonymous, THEN the system SHALL return `UNAUTHENTICATED`.
5. THE rating of one user SHALL NOT affect the votes of other users.
6. THE mutation SHALL be idempotent when the same value is sent repeatedly.

### Requirement 3: Read own vote

**User Story:** As a user, I want to see my previous vote.

#### Acceptance Criteria
1. THE `Summary.myFeedback` field SHALL return `true`, `false` or `null` for the current user only.
2. THE API SHALL NOT expose other users' votes or aggregates to regular users.

### Requirement 4: Feedback UI

**User Story:** As a user, I want a quick, unobtrusive way to vote.

#### Acceptance Criteria
1. WHEN a summary is shown, THEN the summary card SHALL show the question "Este resumo foi útil?" with two buttons "Útil" and "Não foi útil".
2. THE buttons SHALL use `aria-pressed` to reflect the current vote and reflect `myFeedback` on load.
3. WHEN the user clicks a button, THEN the UI SHALL update optimistically, call `rateSummary`, and show "Obrigado pelo feedback." in an `aria-live="polite"` region.
4. IF the call fails, THEN the UI SHALL revert the optimistic state and show "Não foi possível registrar seu voto." 
5. WHEN the user clicks the already active button, THEN the UI SHALL keep the vote (no toggle off) and SHALL NOT show an error.
6. THE feedback controls SHALL NOT appear while the summary is loading or failed.

### Requirement 5: Reporting

**User Story:** As the team, I want to know how well each prompt/model performs.

#### Acceptance Criteria
1. THE system SHALL provide `bin/rails feedback:report` that prints, per `prompt_version` and `model`: summaries count, votes count, helpful count, not-helpful count and helpful rate.
2. THE report SHALL show a clear message when there are no votes.
3. THE report SHALL NOT print user identifiers or emails.
