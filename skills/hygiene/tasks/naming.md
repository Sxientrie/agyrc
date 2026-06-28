# Hygiene Task — Naming

## Scope

Single-letter variables, generic identifiers, misleading names, unexplained
abbreviations, and names that no longer match what the code actually does.

---

## Scan

```sh
# Single-letter variables (outside loop counters i/j/k/x/y)
grep_search(query="\b[a-wz]\s*[=:]|const [a-wz]\b|let [a-wz]\b|var [a-wz]\b", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

# Generic / meaningless names
grep_search(query="\bdata\b|\btemp\b|\bval\b|\btmp\b|\bobj\b|\binfo\b|\bstuff\b|\bitem\b|\bresult\b|\bres\b|\bret\b|\bfoo\b|\bbar\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Unexplained abbreviations
grep_search(query="\bmgr\b|\bmsg\b|\bcfg\b|\bctx\b|\bconn\b|\bauth\b|\breq\b|\bresp\b|\bsvc\b|\bsrv\b|\berr\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Boolean names that don't read as true/false questions
grep_search(query="const |let |var |bool\b|boolean\b", includes=["*.ts", "*.tsx", "*.js", "*.go", "*.py"], is_regex=True) (filter out matches for 'is[A-Z]|has[A-Z]|can[A-Z]|should[A-Z]|was[A-Z]|did[A-Z]|will[A-Z]')

# Function names that start with vague verbs
grep_search(query="^export function|^function|^def |^func ", includes=["*.ts", "*.tsx", "*.js", "*.py", "*.go"], is_regex=True)
```

---

## Patterns

- **Single-letter identifier** — Any variable, parameter, or binding using
  a single letter outside of conventional loop counters (`i`, `j`, `k`)
  or mathematical coordinates (`x`, `y`, `z`). Cannot be understood without
  reading surrounding context.

- **Generic name** — An identifier so broad it conveys no domain meaning:
  `data`, `temp`, `val`, `obj`, `info`, `result`, `stuff`, `item`. A name
  that could mean anything means nothing.

- **Unexplained abbreviation** — An abbreviated name not established by
  the language or framework (`err` in Go is conventional; `svc` in
  application code usually isn't). If the full word fits, use it.

- **Misleading boolean** — A boolean variable or parameter whose name does
  not read as a yes/no question. `isActive`, `hasPermission`, `canRetry`
  are clear. `active`, `permission`, `retry` are ambiguous.

- **Vague verb function** — A function named with a generic verb that
  describes mechanics not purpose: `handle`, `process`, `do`, `run`,
  `execute`, `manage`. The name should say what it specifically does:
  `processOrder` → `calculateOrderTotal`, `handleUser` → `updateUserProfile`.

- **Stale name** — A name that made sense when written but no longer matches
  the code's current behavior. Detected when the function body contradicts
  the name (e.g., `fetchUser` that also creates the user).

---

## Output

### Findings

For each finding:
- **Location**: `file:line` — current name
- **Pattern**: which category above
- **Suggested rename**: proposed name with rationale
- **Confidence**: `rename` / `discuss first` (for public API names that
  would require callers to update)

### Changes made

List every rename performed with before/after:
- `file:line` — `oldName` → `newName`

Note any name that was flagged but deferred because it is part of a
public API, a serialized field, or a cross-file contract requiring
coordinated update.
