# Hygiene Task — Coverage

## Scope

Public functions without tests, exported APIs without docstrings or JSDoc,
untested error paths, and missing inline documentation for non-obvious logic.

---

## Scan

```sh
# All public / exported functions — the baseline set to test
grep_search(query="^export function|^export const|^export default|^export class|^export async", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

grep_search(query="^def |^async def |^class ", includes=["*.py"], is_regex=True)

grep_search(query="^func \b|^pub fn\b", includes=["*.go", "*.rs"], is_regex=True)

# Test files — what is already covered
!find . \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \
  -o -name "*_test.go" \) ! -path "*/node_modules/*" | head -30

grep_search(query="describe(|it(\b|test(\b|def test_|func Test", includes=["*.ts", "*.tsx", "*.js", "*.py", "*.go"], is_regex=True)

# Docstrings / JSDoc presence on public symbols
grep_search(query="^\s*/\*\*|^\s*"""|^\s*'''", includes=["*.ts", "*.tsx", "*.js", "*.py"], is_regex=True)

# Error paths — are they tested?
grep_search(query="throw new|raise \b|return.*Error|reject(|\.catch(\b", includes=["*.ts", "*.tsx", "*.js", "*.py"], is_regex=True)

# Complex logic without explanation
grep_search(query="regex|RegExp|bitwise|<<|>>|\bxor\b|magic\b|\bformula\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)
```

---

## Patterns

- **Untested public function** — An exported or public function with no
  corresponding test case. Prioritise by risk: auth, data mutation,
  payment, external I/O functions rank highest.

- **Untested error path** — A `throw`, `raise`, or rejection inside a
  function that has no test asserting the error case. Error paths are
  the most commonly broken code under refactoring.

- **Missing docstring / JSDoc** — A public function, class, or exported
  constant with no documentation block. The minimum useful doc: what the
  function does, what each non-obvious parameter expects, and what it
  returns or throws.

- **Stale or misleading documentation** — A docstring that describes
  parameters, return values, or behavior that no longer match the
  implementation. Worse than no docs — actively misleads the reader.

- **Unexplained complex logic** — A non-trivial regex, bitwise operation,
  algorithm, or formula with no inline comment explaining the intent.
  The comment should say *why*, not *what*.

---

## Output

### Findings

For each finding:
- **Location**: `file:line` — function or class name
- **Pattern**: which category above
- **Priority**: `high` (auth/mutation/payment/IO paths) / `medium` (other
  public API) / `low` (internal helpers, utilities)

Only add tests and docs for `high` and `medium` priority items in this
pass. Flag `low` priority items in the report for future runs.

### Changes made

For each item addressed:
- **Tests added**: `file:line` — what scenario is now covered
- **Docs added**: `file:line` — what was documented

Every test added must:
1. Have a descriptive name that reads as a sentence
2. Cover at least one success case and one failure/edge case per function
3. Not duplicate an existing test
