00:00 | A-1..A-2 | done | Llm::RetryPolicy (2 retries 1 s/2 s, fallback model, 45 s deadline), Client, errors, Fake provider
00:00 | A-7 | done | Gemini adapter with WebMock specs; key only in x-goog-api-key; needs-sec-review
00:00 | A-3..A-6 | done | Classifier (fixture of real titles), Cleaner, PromptBuilder v1, OutputValidator
00:00 | A-8..A-10 | done | Summary model, Digest, Generate (advisory lock, corrective retry), latestSummary and generateSummary
00:00 | A-11 | done | summaries:eval; smoke run with Gemini on 3 lawsuits; Legal Expert review of the golden set still pending
00:00 | A-13 | done | all 100 real lawsuits fit the budget; worst case 1003553-62.2022.8.26.0068 (13,431 chars)
00:00 | A-10 | note | generateSummary does not check authentication or throttle; both come with the spec 06 guard (AU-4, AU-6)
00:00 | A-11 | done | full golden set run with Gemini and reviewed against the checklist; 1005003 swapped for 1004772 (contract doc updated)
00:00 | A-9 | done | AmountCheck: garbled or invented R$ amounts trigger the corrective retry, then SUMMARY_UNAVAILABLE
