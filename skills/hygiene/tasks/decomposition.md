# Hygiene Task — Decomposition

## Scope

Functions exceeding a reasonable line threshold, mixed abstraction levels
within a single function, multiple distinct phases in one body, and deeply
nested control flow that obscures intent.

---

## Scan

```sh
# File line counts — files most likely to contain long functions
!find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" \
  -o -name "*.js" -o -name "*.jsx" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" \
  | xargs wc -l 2>/dev/null | sort -rn | head -20

# Function declarations — locate all functions to measure
grep_search(query="^export function|^function|^const.*=.*=>|^async function|^export const.*=>", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

grep_search(query="^def |^async def ", includes=["*.py"], is_regex=True)

grep_search(query="^func \b", includes=["*.go"], is_regex=True)

# Deep nesting indicators — four or more levels of indent
grep_search(query="^\s\{16,\}", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Multiple return paths — functions with many exit points
grep_search(query="\breturn\b|\braise\b|\bthrow\b|\bpanic\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Comment headers inside functions — a sign of hidden phases
grep_search(query="^\s*//\s*[A-Z][A-Za-z ]\{5,\}|^\s*#\s*[A-Z][A-Za-z ]\{5,\}", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)
```

---

## Patterns

- **Oversized function** — A function exceeding approximately 40 lines of
  logic (excluding blank lines, comments, and closing braces). Size alone
  is a signal, not a verdict — confirm the body contains more than one
  distinct concern before extracting.

- **Mixed abstraction levels** — A function that combines high-level
  orchestration with low-level detail in the same body. For example, a
  function that both decides what to do (business logic) and how to format
  the output (presentation) without delegating either.

- **Phased function** — A function whose body is visually divided into
  named phases via section comments (`// Step 1`, `# Validate`, `// Build`,
  `// Send`). Each phase is a candidate for extraction into its own named
  function.

- **Deep nesting** — Control flow nested four or more levels deep. Usually
  a sign that early-return guards, extraction, or a helper function would
  flatten the structure and make the intent readable.

- **Multiple exit points without guard clause pattern** — A function with
  many `return` statements scattered through nested branches rather than
  a flat guard-clause structure at the top.

---

## Output

### Findings

For each finding:
- **Location**: `file:line` — function name, approximate line count
- **Pattern**: which category above
- **Decomposition proposal**: what to extract, suggested name for each
  extracted function, where it should live
- **Risk**: `low` (pure extraction, no logic change) / `medium` (requires
  parameter threading) / `high` (shared mutable state involved)

Only propose decompositions rated `low` or `medium`. Flag `high` risk
cases in Deferred Items.

### Changes made

List every extraction performed:
- `file:line` — `originalFunction` → extracted `newFunction` at `file:line`

Confirm after each extraction that the original function's observable
behavior is identical.
