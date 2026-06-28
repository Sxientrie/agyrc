# Critique — Maintainability

## Scope

Naming clarity, function and module size, test coverage, inline documentation,
code duplication, magic values, and TODO/FIXME debt.

---

## Scan

```sh
# File size — large files are a smell
!find . \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.go" -o -name "*.js" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" \
  | xargs wc -l 2>/dev/null | sort -rn | head -25

# Function / method declarations (to spot oversized ones)
!grep -rn "^def \|^async def \|^class " \
  --include="*.py" --include="*.go" . 2>/dev/null

!grep -rn "function \|=>\s*{\|async \b" \
  --include="*.ts" --include="*.tsx" --include="*.js" . 2>/dev/null | head -60

# Test file footprint
!find . \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \) \
  ! -path "*/node_modules/*" | head -30

!grep -rln "def test_\|unittest\|pytest\|describe(\|it(\b\|expect(\b" \
  --include="*.py" --include="*.ts" --include="*.js" . 2>/dev/null

# Deferred work
!grep -rn "TODO\|FIXME\|HACK\|XXX\|TEMP\b\|WORKAROUND\|DO NOT MERGE\|REMOVEME" \
  --include="*.py" --include="*.ts" --include="*.tsx" --include="*.go" --include="*.js" . 2>/dev/null

# Magic numbers / strings in logic
!grep -rn "[^'\"-][0-9]\{2,\}[^0-9'\"]" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null | head -40
```

---

## Patterns

- **Poor naming** — Variables, functions, parameters, or files with names
  so generic the reader cannot infer intent without reading the body:
  `data`, `temp`, `val`, `handle`, `process`, `do_stuff`, `manager`,
  `utils`. Also covers misleading names — where the name implies something
  different from what the code actually does.

- **Oversized functions or files** — Functions over ~40 lines of logic (not
  counting docstrings or blank lines) that do more than one thing. Files
  over ~300 lines that have grown into multiple responsibilities. Size is
  a proxy — flag when the body clearly contains distinct phases or concerns
  that could be named and extracted.

- **Untested critical paths** — Public functions, error paths, or branching
  logic with no corresponding test. Prioritize: paths that handle money,
  auth, data mutation, or external I/O; edge cases established in the
  Correctness scan; and any code touched by recent large diffs.

- **Missing or stale documentation** — Public APIs without a docstring or
  JSDoc block. Comments that describe what the code does rather than why.
  Comments that contradict the current implementation (stale docs are
  actively harmful).

- **Code duplication** — Two or more sites with copy-pasted or near-identical
  logic. Flag when the duplication is in load-bearing code (mutations,
  validators, formatters) where a future fix would need to be applied in
  multiple places.

- **Magic numbers and magic strings** — Unexplained numeric or string
  literals used directly in logic without a named constant. Includes
  hardcoded timeouts, limits, status codes, and string identifiers that
  appear in multiple places.

- **TODO / FIXME debt** — Deferred work items ranked by the criticality of
  the surrounding code. A TODO inside an auth function or a data migration
  ranks higher than one in a logging helper.

---

## Output

Produce a section titled `## Maintainability Findings`.

For each finding:

- **Location**: `file:line` — function, class, or block name
- **Pattern**: which category above
- **Why it matters**: what future breakage, onboarding friction, or
  regression risk this creates if left unaddressed
- **Bucket**:
  - `clear smell` — objectively hurts maintainability
  - `worth discussing` — depends on team convention or project scale

Rank within the section: test gaps on critical paths → duplication in
load-bearing code → naming → stale/missing docs → magic values → TODO debt.
No code changes. Findings only.
