# Hygiene Task — Dead Code

## Scope

Unused imports, unreferenced functions and variables, unreachable branches,
commented-out code blocks, and exports with no known consumers.

---

## Scan

```sh
# Unused imports — imported but never referenced in file body
grep_search(query="^import|^from\b|require(", includes=["*.ts", "*.tsx", "*.js", "*.py"], is_regex=True)

# Exported symbols — cross-reference against consumers
grep_search(query="^export function|^export const|^export class|^export type|^export interface", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

# Unreachable branches — return/throw before end of block
grep_search(query="return\b|throw\b|raise\b|panic(\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Commented-out code (not comments — actual commented code)
grep_search(query="^[[:space:]]*//.*(function|const|let|var|return|import|if\b|for\b)", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

grep_search(query="^[[:space:]]*#.*(def |import|return|if\b|for\b|class\b)", includes=["*.py"], is_regex=True)

# Variables declared but never read
grep_search(query="const |let |var ", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)
```

---

## Patterns

- **Unused import** — A module or symbol imported at the top of a file
  but never referenced in the file body. Safe to remove if no side-effect
  import is intended (note: some imports are intentional side-effects —
  check before deleting).

- **Unreferenced export** — A function, class, or constant exported from
  a module but not imported anywhere in the codebase. Flag with
  `confirmed removable` only if a codebase-wide search finds zero consumers.

- **Unreachable branch** — Code that follows an unconditional `return`,
  `throw`, `raise`, or `panic` in the same block. The runtime will never
  execute it.

- **Commented-out code block** — Lines of actual code (not explanatory
  comments) commented out. If it has been commented out and there is no
  adjacent TODO explaining why it will return, it is dead.

- **Declared but unread variable** — A variable assigned a value that is
  never read before it is reassigned or goes out of scope.

---

## Output

### Findings

For each finding:
- **Location**: `file:line`
- **Pattern**: which category above
- **Confidence**: `safe to remove` / `verify before removing` (e.g., side-effect imports, dynamic access patterns)

### Changes made

List every removal performed:
- `file:line` — what was removed — confidence level

Flag any item skipped due to uncertainty. Do not remove anything rated
`verify before removing` without noting it in Deferred Items.
