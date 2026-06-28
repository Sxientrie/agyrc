# Critique — Correctness

## Scope

Logic errors, type safety, null/undefined/None handling, unchecked error
returns, off-by-one errors, input validation, and unhandled edge cases.

---

## Scan

```sh
# Entry points — public-facing functions, exported symbols, API handlers
!grep -rn "^export\|^def \|^func \|^public \|^async def\|router\.\|app\.route\|@app\.\|@router\." \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" .

# Null / undefined dereference risks and unsafe casts
!grep -rn "!\.\|?\.\|as any\|@ts-ignore\|# type: ignore\|unsafe\.\|force_unwrap\|!!" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" .

# Unchecked error returns
!grep -rn "_ =\|except:\|except Exception:\|\.catch\b\|Promise\.all\b\|unhandledRejection" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" .

# Off-by-one suspects — bounds, lengths, ranges
!grep -rn "\[.*-\s*1\]\|range(\|len(\|\.length\b\|\.size()\|slice(" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" .

# Loose equality and type coercion
!grep -rn "==\b\|!=\b\|parseInt\b\|parseFloat\b\|Number(\|str(\b\|int(" \
  --include="*.ts" --include="*.js" --include="*.py" .

# External input entry points (env vars, config, HTTP params, CLI args)
!grep -rn "os\.environ\|process\.env\|argv\b\|request\.\(args\|form\|json\|params\)\|getenv\b" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" .
```

---

## Patterns

For each scan hit, determine whether it is actually a risk:

- **Null / undefined dereference** — A value that could be null, undefined,
  None, or an empty slice is accessed without a guard before the access point.

- **Unchecked error returns** — An error is returned by a function but the
  caller ignores it: assigned to `_` in Go, bare `except:` in Python,
  Promise rejection with no `.catch` or `try/await` in JS/TS.

- **Off-by-one** — Loop bounds, slice indices, or length comparisons that
  miss the last element, overshoot by one, or produce an empty result
  on a non-empty input.

- **Type coercion / unsafe cast** — `as any`, `# type: ignore`, or implicit
  coercions that bypass the type system and could produce NaN, unexpected
  string concatenation, or runtime panics.

- **Unvalidated external input** — User-supplied or environment-supplied
  values used in logic, paths, or queries without bounds-checking, format
  validation, or sanitization.

- **Unhandled edge cases** — Logic that assumes a "happy path" shape:
  empty collections, zero values, negative numbers, maximum integer
  overflow, or concurrent empty-vs-populated states.

---

## Output

Produce a section titled `## Correctness Findings`.

For each finding:

- **Location**: `file:line` — function or block name
- **Pattern**: which of the six categories above
- **Failure mode**: what specific value or sequence triggers the bug, and
  what the caller or user would observe when it fires
- **Bucket**:
  - `confirmed bug` — the code is wrong today
  - `likely bug — needs human review` — depends on caller contract or
    runtime state that can't be determined statically
  - `edge case worth hardening` — currently safe but fragile

Rank within the section: confirmed bugs → likely bugs → hardening candidates.
No code changes. Findings only.
