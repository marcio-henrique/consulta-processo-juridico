# Requirements: Quality and delivery

## Introduction

Prove quality (>= 80% coverage, end-to-end smoke, security checks, accurate docs) and complete the delivery rules of the challenge (private repository, shared with the reviewers, email with video, no commits after the deadline). Challenge items: NFR 2, NFR 4, NFR 5 and all deliverables. Related: [prepare-delivery](../../../docs/skills/prepare-delivery.md).

## Requirements

### Requirement 1: Coverage evidence

**User Story:** As a reviewer, I want proof of >= 80% automated coverage.

#### Acceptance Criteria
1. WHEN the full backend suite runs, THEN SimpleCov SHALL report at least 80% line coverage and the run SHALL fail below that.
2. WHEN the full frontend suite runs, THEN Vitest SHALL report at least 80% lines, functions and statements and 70% branches and the run SHALL fail below that.
3. THE README SHALL state the measured coverage numbers and the commands to reproduce them.
4. THE exclusions from coverage SHALL be limited to generated code, `config/`, `db/`, `bin/`, the `summaries:eval` task and test support files, and SHALL be listed in the README.

### Requirement 2: Requirement traceability

**User Story:** As a reviewer, I want to see which test proves each requirement.

#### Acceptance Criteria
1. THE spec 08 folder SHALL contain a traceability table mapping each challenge item (FR 1-5, NFR 1-5, Diff 1-5) and each spec requirement group to at least one test file or manual evidence.
2. IF a requirement has no automated test, THEN the table SHALL state the manual evidence and the reason.

### Requirement 3: End-to-end smoke

**User Story:** As a maintainer, I want one test across the whole stack.

#### Acceptance Criteria
1. THE Playwright test SHALL run against the Compose stack with `LLM_PROVIDER=fake` and the imported CSV.
2. THE flow SHALL be: open `/` anonymous, get redirected to login, sign up, search `1001399-31.2023.8.26.0070`, see Foro de Batatais and R$ 10.000,00, see the summary and the first movements, rate the summary, search the challenge example and see the not-found state, sign out.
3. THE test SHALL be runnable with one documented command and SHALL be included in CI if the runtime stays under 10 minutes; otherwise it SHALL be documented as a manual step.

### Requirement 4: Security and dependency checks

**User Story:** As an owner, I want to avoid shipping obvious vulnerabilities or secrets.

#### Acceptance Criteria
1. WHEN the checks run, THEN `brakeman`, `bundler-audit` and `npm audit --omit=dev` SHALL report no high or critical findings, or each remaining finding SHALL be documented with a reason.
2. A scan of the full git history for key patterns SHALL find no real secrets.
3. THE `.env` file and any key SHALL NOT be tracked.
4. THE tests and CI SHALL NOT call real LLM endpoints.

### Requirement 5: README and AGENTS.md

**User Story:** As a reviewer, I want to run the project from the README alone.

#### Acceptance Criteria
1. THE README SHALL include: overview, screenshots, technologies with reasons, prerequisites, quick start, ENV table, LLM configuration (fake and real), creating an account, importing data, running tests and coverage, project layout, assumptions and known limits, and links to AGENTS.md and the docs.
2. WHEN the README commands are run on a clean clone, THEN they SHALL succeed without extra steps.
3. THE AGENTS.md SHALL describe the real structure, commands, rules, roles and skills used.

### Requirement 6: Final requirements check

**User Story:** As the owner, I want every challenge requirement verified before sending.

#### Acceptance Criteria
1. THE checklist in `prepare-delivery.md` section A SHALL be completed with evidence for each item.
2. THE summary for the golden-set lawsuits SHALL have been reviewed by the Legal Expert role and fixes applied or limitations documented.
3. THE UI SHALL pass the keyboard-only and contrast checks recorded in the PR.

### Requirement 7: Delivery

**User Story:** As a candidate, I want to deliver exactly as asked.

#### Acceptance Criteria
1. THE repository SHALL be private on GitHub and shared with `ariel@resolvvi.com` and `tayllan@resolvvi.com`.
2. THE demo video SHALL be at most 4 minutes and the link SHALL be viewable without logging in.
3. THE email to both recipients SHALL include the repository link and the video link and SHALL be sent before the deadline.
4. ALL commit messages SHALL be in English.
5. NO commit or push SHALL happen after the deadline (challenge email time plus 48 hours).
