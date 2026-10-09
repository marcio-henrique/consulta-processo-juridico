# Requirements: Lawsuit lookup UI

## Introduction

React interface: a minimal home page with the CNJ field, and a lawsuit page resembling the TJSP e-SAJ page with an extra AI summary section. Challenge items: FR 2, FR 3, FR 4 (display), differential 2 (React). Route protection is added by spec 06; feedback buttons by spec 07. Related: [lawsuit-lookup](../../../docs/domains/lawsuit-lookup.md), [ai-summary](../../../docs/domains/ai-summary.md) section 8, reference page `data/html_link_portal/`.

## Requirements

### Requirement 1: Home page

**User Story:** As a user, I want a page with only a number field and a button, so that I can search quickly.

#### Acceptance Criteria
1. THE home page SHALL contain a labeled text field for the CNJ number and a "Consultar" button, and no other content besides the app header.
2. WHILE the user types, THE field SHALL apply the CNJ mask `NNNNNNN-DD.AAAA.J.TR.OOOO` and accept pasted formatted or digits-only text.
3. IF the field is empty on submit, THEN the page SHALL show "Informe o número do processo." and keep focus on the field.
4. IF the number fails format or check-digit validation on submit, THEN the page SHALL show "Número de processo inválido. Confira os dígitos." and SHALL NOT navigate.
5. WHEN the number is valid, THEN the page SHALL navigate to `/processos/<canonical number>`.
6. WHEN the user presses Enter in the field, THEN the form SHALL submit.

### Requirement 2: Lawsuit page data

**User Story:** As a user, I want the lawsuit data laid out like the court page, so that it feels familiar.

#### Acceptance Criteria
1. THE lawsuit page SHALL show, in this order: the header with the CNJ number; process data (Foro, Vara, Valor da ação, Número de autores); the summary section; the movements section.
2. THE value SHALL be shown as pt-BR currency, for example `R$ 8.000,00`.
3. THE page SHALL NOT show fields that the data does not provide (status, class, subject, judge).
4. THE page SHALL provide a link back to the home page.

### Requirement 3: Movements table

**User Story:** As a user, I want to read the movements easily.

#### Acceptance Criteria
1. THE movements SHALL be shown in a `<table>` with a visually hidden caption and column headers "Data" and "Movimentação", newest first as returned by the API.
2. THE date SHALL be shown as `dd/mm/aaaa` with no timezone shifting.
3. EACH row SHALL show the title in bold and, when present, the content below it in smaller muted text preserving line breaks.
4. WHEN a content is longer than about 300 characters, THEN it SHALL be collapsed with a "Ver mais" button that toggles to "Ver menos" and sets `aria-expanded`.
5. THE table SHALL show the first 25 movements and, WHEN more exist, a "Carregar mais" button that appends the next page.
6. WHEN a lawsuit has no movements, THEN the section SHALL show "Nenhuma movimentação registrada.".

### Requirement 4: Summary section

**User Story:** As a layperson, I want a short explanation of the lawsuit.

#### Acceptance Criteria
1. WHEN the page loads and `latestSummary` exists, THEN the summary section SHALL show its paragraphs as plain text.
2. WHEN `latestSummary` is null, THEN the page SHALL call `generateSummary` automatically and show a skeleton with `aria-busy="true"` in the summary section only.
3. WHILE the summary is loading, THE rest of the page SHALL remain usable.
4. IF generation returns `SUMMARY_UNAVAILABLE` or `RATE_LIMITED`, THEN the section SHALL show "Não foi possível gerar o resumo agora." and a "Tentar novamente" button that calls the mutation again.
5. THE section SHALL show the disclaimer: "Resumo gerado por inteligência artificial a partir das movimentações do processo. Não substitui a análise de um advogado."
6. THE summary text SHALL be rendered as text (never HTML), splitting paragraphs on blank lines, inside a region with `aria-live="polite"`.
7. THE section title SHALL be "Resumo do processo".

### Requirement 5: Page states

**User Story:** As a user, I want clear feedback when something is wrong.

#### Acceptance Criteria
1. WHILE the lawsuit query is loading, THE page SHALL show skeletons for data and movements.
2. IF the API returns `NOT_FOUND` or `INVALID_CNJ`, THEN the page SHALL show "Processo não encontrado na base." with a link to the home page and a note that only imported lawsuits are available.
3. IF the request fails with a network or server error, THEN the page SHALL show a generic error message and a retry button, without technical details.
4. WHEN the URL number is not canonical (for example digits-only), THEN the page SHALL query using the given value and display the canonical number returned by the API.

### Requirement 6: Look and responsiveness

**User Story:** As a user on any device, I want a readable page.

#### Acceptance Criteria
1. THE visual style SHALL follow the e-SAJ structure (muted labels, bold values, striped movements table) without copying its assets.
2. THE layout SHALL work from 320 px to 1280 px wide without horizontal scrolling of the page (a wide table MAY scroll inside its own container).
3. THE UI language SHALL be pt-BR; code and identifiers SHALL be English.

### Requirement 7: Accessibility (WCAG 2.2 AA)

**User Story:** As a user of assistive technology, I want to use every feature, so that the service is available to everyone.

The target is WCAG 2.2 level AA. The playbook is [accessibility-wcag](../../../docs/skills/accessibility-wcag.md). Success criteria are cited in brackets.

#### Acceptance Criteria
1. THE document SHALL declare `lang="pt-BR"`, every route SHALL set a unique descriptive `document.title`, and every page SHALL have exactly one `h1` with headings in logical order [3.1.1, 2.4.2, 2.4.6, 1.3.1].
2. THE app SHALL provide landmarks (`header`, `main`, `footer`) and a skip link "Ir para o conteúdo" as the first focusable element [2.4.1, 1.3.1].
3. EVERY input SHALL have a visible label bound to it and an appropriate `autocomplete` value; required fields SHALL be indicated in text [1.3.1, 1.3.5, 3.3.2].
4. IF a validation error occurs, THEN the message SHALL be text next to the field, linked with `aria-describedby`, the field SHALL have `aria-invalid="true"`, the message SHALL be announced via `role="alert"`, the error SHALL say how to fix the problem, and focus SHALL move to the first invalid field [3.3.1, 3.3.3, 4.1.3].
5. THE whole flow (sign up, sign in, search, expand movement content, load more, rate summary, sign out) SHALL be operable with the keyboard only, with no keyboard trap and a logical focus order [2.1.1, 2.1.2, 2.4.3].
6. EVERY interactive element SHALL show a visible focus indicator with at least 3:1 contrast, focus SHALL NOT be hidden by other content, and interactive targets SHALL be at least 24x24 CSS px [2.4.7, 2.4.11, 1.4.11, 2.5.8].
7. WHEN the route changes, THEN focus SHALL move to the new page's `h1` [2.4.3].
8. TEXT contrast SHALL be at least 4.5:1 (3:1 for large text), UI component boundaries and focus rings at least 3:1, and no state SHALL be conveyed by color alone [1.4.3, 1.4.11, 1.4.1].
9. THE page SHALL reflow without two-dimensional scrolling at 320 CSS px width and at 400% zoom, text SHALL resize to 200% without loss, content SHALL survive the WCAG text-spacing overrides, and zoom SHALL NOT be disabled [1.4.4, 1.4.10, 1.4.12].
10. LOADING, success and error messages SHALL be exposed as status messages (`aria-live="polite"` or `role="status"`); skeleton regions SHALL set `aria-busy="true"` [4.1.3].
11. CUSTOM controls SHALL expose name, role and state: expanders with `aria-expanded`, toggles with `aria-pressed`; an accessible name SHALL contain the visible label text [4.1.2, 2.5.3].
12. THE movements table SHALL use `<table>`, `<caption>` and `<th scope="col">` [1.3.1].
13. THE sign-in and sign-up forms SHALL allow paste and password managers and SHALL NOT require cognitive tests; data entered SHALL be preserved after an error [3.3.8, 3.3.7].
14. ANIMATIONS (skeleton shimmer, transitions) SHALL be disabled under `prefers-reduced-motion: reduce` [2.2.2; 2.3.3 is level AAA and adopted as good practice].
15. THE automated checks (`eslint-plugin-jsx-a11y`, `vitest-axe` per page state, `@axe-core/playwright` per main screen with tags `wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa`) SHALL report zero serious or critical violations.
16. THE PR for each UI task SHALL include the accessibility checklist result from the skill (keyboard, screen-reader smoke, zoom, contrast ratios, reduced motion), and the final audit SHALL be recorded in spec 08.

### Requirement 8: Client-side CNJ helper

**User Story:** As a developer, I want a tested mirror of the server rules.

#### Acceptance Criteria
1. THE `cnj.ts` helper SHALL normalize, mask and validate (length and check digits) with the same results as the server for the examples in the lookup domain doc.
2. THE server SHALL remain authoritative; client validation SHALL be only for fast feedback.
