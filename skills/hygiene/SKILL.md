---
name: hygiene
description: >
  Structured code hygiene and technical debt cleanup. Activate when the user
  runs /hygiene [optional focus text]. Covers seven cleanup tasks: Dead Code,
  Naming, Decomposition, Feature Flags, Dependencies, Formatting, and Coverage.
  Scans first, surfaces issues, lets the user pick what to clean via
  multi-select, plans safe changes, executes them, then verifies behavior is
  unchanged. Makes hygiene a repeatable process, not an ad hoc one.
---

# /hygiene — Code Hygiene and Technical Debt Cleanup

Reads before it touches. Plans before it changes. Verifies after every pass.
Applies the Boy Scout Rule — each run leaves the codebase cleaner than it
found it, through small, continuous, behavior-preserving improvements.

---

## Phase 1 — Pre-flight: Workspace and codebase context

### 1A — Read AGENTS.md

Read `AGENTS.md` using the native `view_file` tool. Check in this order,
stop at the first hit:

1. `./AGENTS.md`
2. `~/.gemini/AGENTS.md`

Note any stated conventions, formatter config, off-limits files, or
test commands before proceeding. Do not override declared conventions.

### 1B — Broad hygiene scan

Run all of the following to establish baseline signal across all seven
cleanup dimensions:

```sh
# File size — large files signal decomposition and dead code candidates
!find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" \
  -o -name "*.js" -o -name "*.jsx" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" \
  | xargs wc -l 2>/dev/null | sort -rn | head -20

# Unused / dead imports
grep_search(query="^import|^from\b|require(", includes=["*.ts", "*.tsx", "*.js", "*.py"], is_regex=True)

# Generic or unclear names
grep_search(query="\bdata\b|\btemp\b|\bval\b|\bfoo\b|\bbar\b|\btmp\b|\bobj\b|\bres\b\b|\bret\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Commented-out code and stale flags
grep_search(query="//.*=|#.*def |#.*import|feature.*flag|FLAG_|FF_|FEATURE_|isEnabled\b|toggle\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# TODO / FIXME / HACK / debt markers
grep_search(query="TODO|FIXME|HACK|XXX|TECH.DEBT|WORKAROUND|DO NOT MERGE|REMOVEME", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Dependency manifests
!find . \( -name "package.json" -o -name "requirements.txt" -o -name "go.mod" \
  -o -name "Pipfile" -o -name "Cargo.toml" \) \
  ! -path "*/node_modules/*" | head -10

# Formatter / linter config present
!find . \( -name ".eslintrc*" -o -name ".prettierrc*" -o -name "pyproject.toml" \
  -o -name ".flake8" -o -name "golangci.yml" -o -name "biome.json" \) \
  ! -path "*/node_modules/*" | head -10

# Test file footprint
!find . \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \) \
  ! -path "*/node_modules/*" | wc -l

# Public functions without obvious test counterparts
grep_search(query="^export function|^export const|^export default|^def |^pub fn\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)
```

---

## Phase 2 — Routing: Resolve focus

### A. Argument provided

If the user ran `/hygiene <text>`, map keywords from `<text>` to tasks:

| Keywords detected                                                               | Task              |
| :------------------------------------------------------------------------------ | :---------------- |
| dead, unused, unreferenced, orphan, remove                                      | Dead Code         |
| rename, naming, variable, clarity, descriptive, generic                         | Naming            |
| decompose, extract, split, long, function, refactor, break                      | Decomposition     |
| flag, feature flag, commented, toggle, stale, cleanup                           | Feature Flags     |
| depend, package, library, outdated, upgrade, version                            | Dependencies      |
| format, style, lint, indent, consistent, prettier, eslint                       | Formatting        |
| test, coverage, doc, docstring, missing, undocumented                           | Coverage          |
| all, hygiene, everything, full, complete, debt                                  | All seven         |

A phrase may match more than one task — activate all matched tasks.
Skip to Phase 3 immediately.

### B. No argument provided

Invoke `ask_question` with this payload:

```json
{
  "questions": [
    {
      "question": "What hygiene tasks should we run? Select one or more.",
      "options": [
        "Dead Code — remove unused imports, functions, variables, and dead branches",
        "Naming — rename unclear, generic, or misleading identifiers",
        "Decomposition — break up long functions into smaller focused ones",
        "Feature Flags — delete stale flags, toggles, and commented-out blocks",
        "Dependencies — identify and update outdated or vulnerable packages",
        "Formatting — fix inconsistent style, indentation, and lint violations",
        "Coverage — add missing tests and documentation for public APIs",
        "Everything — run all seven in sequence"
      ],
      "is_multi_select": true
    }
  ],
  "toolSummary": "Hygiene task selection",
  "toolAction": "Choosing which cleanup tasks to run"
}
```

Wait for selection. Do not begin any task until confirmed.

---

## Phase 3 — Execution: Run sub-skills

For each selected task, read and execute the corresponding file from the
`tasks/` directory. Run in this fixed order when multiple are selected:

1. `tasks/dead-code.md`
2. `tasks/naming.md`
3. `tasks/decomposition.md`
4. `tasks/feature-flags.md`
5. `tasks/dependencies.md`
6. `tasks/formatting.md`
7. `tasks/coverage.md`

Each sub-skill produces a **findings block** and a **changes block**.
Accumulate both before moving to Phase 4.

**Boy Scout Rule enforcement:** Each sub-skill must leave every file it
touches cleaner than it found it. No task may introduce new inconsistencies
while fixing old ones.

**Behavior preservation rule:** No task in phases 1–6 (Dead Code through
Formatting) may alter runtime behavior. If a change would alter behavior,
flag it and skip it. Coverage (task 7) adds new code only — it never
modifies existing logic.

---

## Phase 4 — Verification: Confirm behavior is unchanged

After all selected sub-skills complete their changes, run verification:

### 4A — Test suite

```sh
# Detect and run the test suite
!if [ -f "package.json" ]; then
  cat package.json | grep -A5 '"scripts"'
fi

!if [ -f "Makefile" ]; then
  grep "^test\b\|^check\b\|^lint\b" Makefile | head -10
fi
```

Based on what is found, run the appropriate test command. If the test suite
was passing before and fails after, **revert the last sub-skill's changes**
and report which change caused the failure.

### 4B — Static checks

```sh
# TypeScript — type errors introduced?
!npx tsc --noEmit 2>/dev/null | head -20

# Python — import errors introduced?
!python -m py_compile $(find . -name "*.py" ! -path "*/node_modules/*" \
  ! -path "*/.git/*") 2>&1 | head -20

# Go — compilation errors?
!go build ./... 2>/dev/null | head -20
```

Report any errors introduced. Revert the responsible change and note it
in the delivery artifact.

---

## Phase 5 — Delivery: Write the hygiene report artifact

Write using the `write_to_file` tool.

Path: `<appDataDir>/brain/<conversation-id>/hygiene_report.md`

```json
{
  "Summary": "Code hygiene report — findings, changes made, and verification results.",
  "UserFacing": true,
  "RequestFeedback": false
}
```

Format the body exactly like this:

```markdown
# Hygiene Report — <project or directory name>
Tasks run: <list>
Date: <today>
Principle: Boy Scout Rule — left cleaner than found.

---

## Dead Code                    ← omit section if not selected
### Findings
...
### Changes made
...

## Naming                       ← omit section if not selected
### Findings
...
### Changes made
...

## Decomposition                ← omit section if not selected
### Findings
...
### Changes made
...

## Feature Flags                ← omit section if not selected
### Findings
...
### Changes made
...

## Dependencies                 ← omit section if not selected
### Findings
...
### Changes made
...

## Formatting                   ← omit section if not selected
### Findings
...
### Changes made
...

## Coverage                     ← omit section if not selected
### Findings
...
### Changes made
...

---

## Verification
<test results, static check results, any reverted changes>

---

## Deferred Items
<changes flagged as risky or behavior-altering that were skipped,
with explanation. Omit section if nothing was deferred.>

---

## Summary
<3–5 sentences: what was cleaned, what was deferred, net improvement
to the codebase, and what to tackle next run.>
```

Notify the user by showing a toast.

```bash
termux-toast -s -g bottom "Hygiene Complete — report is ready."
```

---

## Phase 6 — Completion: Notify and close

```bash
termux-toast -s -g bottom "Hygiene done — codebase left cleaner than found."
```

