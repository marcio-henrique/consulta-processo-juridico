# Execution log

One append-only file per lane: `docs/plan/log/<lane>.md` (`p`, `b1`, `b2`, `b3`, `ai`, `f1`, `f2`, `sec`, `qa`).

Format, one line per event, newest at the bottom:

```
HH:MM | <TASK-ID or GATE> | <event: done | blocked | request | contract-change | note> | <detail>
```

Examples:

```
00:28 | G0 | done | rspec green with gate, /up 200 (commit abc1234)
00:41 | L-2 | blocked | need CnjNumber from B2 (I-1)
00:44 | I-1 | request | B1: CnjNumber.parse(str) -> Result#valid?, #formatted, #error is merged on lane/b2
01:05 | F-10 | contract-change | added Summary.generatedAt non-null; affects A-10, U-7 (docs/contracts/schema.graphql updated)
```

Rules:
- Integrator (lane P) reads all logs at each gate and posts the gate result in `p.md`.
- A request addressed to another lane stays open until that lane answers with a `done` line referencing it.
- Never put secrets, prompts or movement contents in the log.
