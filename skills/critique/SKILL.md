---
name: critique
description: >
  Structured, focused code critique bundle. Activate when the user runs
  /critique [optional focus text]. Covers five lenses: Correctness, Design,
  Safety, Maintainability, and Performance — each as a focused sub-skill.
  Runs one lens, many, or all depending on the argument or user selection.
  Never runs blind — always resolves focus before starting work. After
  delivering the report, interactively asks the user which findings to address.
---

# /critique — Code Critique Entry Point

Single entry point that routes to one or more focused sub-skills. Each
sub-skill runs its own grep pass, analysis, and findings section. All
selected sections are combined into one artifact. After delivery, the user
chooses which findings to act on — or none.

---

## Phase 1 — Pre-flight: Workspace context

Before routing, read `AGENTS.md` using the native `view_file` tool. Check
in this order and stop at the first hit:

1. `./AGENTS.md`
2. `~/.gemini/AGENTS.md`

Absorb any stated architecture decisions, conventions, or off-limits areas
before proceeding. Do not re-derive what is already declared.

---

## Phase 2 — Routing: Resolve focus

### A. Argument provided

If the user ran `/critique <text>`, map keywords from `<text>` to focus areas:

| Keywords detected in the argument                                                              | Focus area      |
| :--------------------------------------------------------------------------------------------- | :-------------- |
| correct, logic, bug, edge, null, undefined, type, validation, error                           | Correctness     |
| design, architect, abstraction, layout, token, component, pattern, struct, separation, concerns, soc, cohesion | Design |
| safety, security, race, concurrency, injection, auth, secret, xss, csrf                       | Safety          |
| maintain, readable, naming, test, coverage, doc, duplicate, smell, debt                       | Maintainability |
| perf, performance, speed, memory, render, query, complexity, leak, n+1                        | Performance     |
| observ, log, logging, trace, metric, instrument, debug, monitor                               | Observability   |
| all, wide, full, everything, complete, every                                                  | All six         |

A phrase may match more than one area — activate all matched areas.
Skip to Phase 3 immediately.

### B. No argument provided

Invoke the `ask_question` tool directly with this exact payload:

```json
{
  "questions": [
    {
      "question": "What should this critique focus on? Select one or more.",
      "options": [
        "Correctness — logic errors, edge cases, type safety, null handling, input validation",
        "Design — architecture, abstractions, layout, design tokens, component structure",
        "Safety — security, concurrency, races, injection, auth gaps, secret exposure",
        "Maintainability — naming, readability, test coverage, documentation, duplication",
        "Performance — complexity, memory leaks, re-renders, N+1 queries, blocking calls",
        "Observability — logging strategy, silent failures, error context, PII in logs, instrumentation",
        "Everything — run all six in sequence"
      ],
      "is_multi_select": true
    }
  ],
  "toolSummary": "Critique focus selection",
  "toolAction": "Resolving which lenses to run"
}
```

Wait for the user's selection before proceeding. Do not start any analysis
until focus is confirmed.

---

## Phase 3 — Execution: Run sub-skills

For each selected focus area, read and execute the corresponding file from
the `focus/` directory. Run in this fixed order when multiple are selected:

1. `focus/correctness.md`
2. `focus/design.md`
3. `focus/safety.md`
4. `focus/maintainability.md`
5. `focus/performance.md`
6. `focus/observability.md`

Each sub-skill outputs its own titled findings section. Accumulate all
sections as you go — do not deliver anything until Phase 4.

---

## Phase 4 — Delivery: Combine and output the artifact

When all selected sub-skills are complete, write the combined output as a
single artifact using the `write_to_file` tool.

Path: `<appDataDir>/brain/<conversation-id>/critique_report.md`

Populate `ArtifactMetadata` as follows:
```json
{
  "Summary": "Structured critique report covering the selected focus areas.",
  "UserFacing": true,
  "RequestFeedback": false
}
```

Format the artifact body exactly like this:

```markdown
# Critique Report — <project or directory name>
Focus: <list of selected areas>
Date: <today>

---

## Correctness Findings        ← omit section entirely if not selected
...

## Design Findings             ← omit section entirely if not selected
...

## Safety Findings             ← omit section entirely if not selected
...

## Maintainability Findings    ← omit section entirely if not selected
...

## Performance Findings        ← omit section entirely if not selected
...

## Observability Findings      ← omit section entirely if not selected
...

---

## Summary
<3–5 sentence cross-cutting summary: most critical issues, any patterns
that cut across multiple lenses, and what to fix first.>
```

Send the text response: "Critique complete — open the report with `/artifact`."

---

## Phase 5 — Review: Address findings?

After the artifact is delivered, invoke the `ask_question` tool directly
with this payload:

```json
{
  "questions": [
    {
      "question": "Would you like to address any of the findings now?",
      "options": [
        "Yes — let me pick which findings to fix",
        "Yes — fix all confirmed findings in priority order",
        "No — report only, I'll handle it manually",
        "Open /artifact first, ask me again after"
      ],
      "is_multi_select": false
    }
  ],
  "toolSummary": "Post-critique action",
  "toolAction": "Deciding whether to address findings"
}
```

**If "No — report only, I'll handle it manually":**
Exit cleanly. No further action.

**If "Open /artifact first, ask me again after":**
Tell the user to open the report with `/artifact`. Wait. When they return,
re-invoke the Phase 5 `ask_question` payload so they can choose then.

---

## Phase 6 — Planning: Build the implementation plan

### 6A — Target selection

**If "Yes — let me pick which findings to fix":**
Invoke `ask_question` with every finding from the report as a selectable
option. Format each line as: `[Lens] file:line — pattern name — bucket`.
Set `is_multi_select: true`. Wait for selection before continuing.

**If "Yes — fix all confirmed findings in priority order":**
Target all findings bucketed `confirmed bug`, `confirmed vulnerability`,
or `confirmed bottleneck`. Skip `needs human review` and
`worth discussing` buckets unless the user explicitly included them.

### 6B — Write `implementation_plan.md`

Write the file using the `write_to_file` tool.

Path: `<appDataDir>/brain/<conversation-id>/implementation_plan.md`

```json
{
  "Summary": "Implementation plan for critique findings — describes what will change, how, and what to watch for.",
  "UserFacing": true,
  "RequestFeedback": false
}
```

Format the body exactly like this:

```markdown
# Implementation Plan
Generated from: critique_report.md
Scope: <number> findings selected
Date: <today>

---

## Finding 1 — <pattern name> (`file:line`)
**Lens:** <Correctness / Design / Safety / Maintainability / Performance>
**Problem:** <one sentence — what is wrong and why it matters>
**Change:** <what will be modified — function name, block, file>
**Approach:** <how the fix works — specific, not generic>
**Watch for:** <side effects, callers to update, tests to adjust, or
  related state that must stay consistent>
**Estimate:** <Trivial / Small / Medium / Large>

---

## Finding 2 — ...

(one block per selected finding, ordered by severity)

---

## Execution Order
<Numbered list of findings in the order they will be implemented.
Place fixes with no dependencies first. Flag any finding whose fix
depends on another being done first.>
```

### 6C — Write `task.md`

Write the file using the `write_to_file` tool immediately after the plan.

Path: `<appDataDir>/brain/<conversation-id>/task.md`

```json
{
  "Summary": "Checklist of implementation tasks derived from the critique plan.",
  "UserFacing": true,
  "RequestFeedback": false
}
```

Format the body exactly like this:

```markdown
# Task List
Generated from: implementation_plan.md
Date: <today>

---

- [ ] **[Lens]** `file:line` — <pattern name> — <one-line description of the fix>
- [ ] **[Lens]** `file:line` — <pattern name> — <one-line description of the fix>
...

---

**Total:** <n> tasks  |  Confirmed fixes: <n>  |  Estimate: <sum of sizes>
```

Tasks are listed in execution order from the plan. One line per finding —
no nesting, no sub-tasks. The user updates the checkboxes as work completes.

### 6D — Confirm before touching code


Next, invoke `ask_question` with this payload:

```json
{
  "questions": [
    {
      "question": "Plan and task list are ready. Review them with /artifact, then choose how to proceed:",
      "options": [
        "Proceed — implement all tasks in plan order",
        "Proceed — but ask me before each task",
        "Revise the plan first (write-in what to change)",
        "Cancel — I'll implement manually using the plan"
      ],
      "is_multi_select": false
    }
  ],
  "toolSummary": "Implementation confirmation",
  "toolAction": "Confirming before code changes begin"
}
```

**If "Proceed — implement all tasks in plan order":**
Work through `task.md` top to bottom. After each fix, briefly state what
changed. Do not pause between tasks unless a fix requires a decision
(ambiguous approach, API surface change, or deletion of non-trivial code).

**If "Proceed — but ask me before each task":**
Before implementing each task, state what you are about to do and wait
for the user to confirm or skip it.

**If "Revise the plan first":**
Accept the write-in, update `implementation_plan.md` and `task.md`
accordingly, then re-invoke the Phase 6D confirmation payload.

**If "Cancel — I'll implement manually using the plan":**
Exit cleanly. The plan and task list remain available via `/artifact`.

---

## Phase 7 — Completion

Whenever a critique task or workflow is finished (e.g., when exiting at
Phase 5, Phase 6D, or after completing all tasks in Phase 6), notify the user in the text response.
