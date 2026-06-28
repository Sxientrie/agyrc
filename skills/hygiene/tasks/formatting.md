# Hygiene Task — Formatting

## Scope

Inconsistent indentation, mixed quote styles, missing or extra semicolons,
trailing whitespace, import ordering, line length violations, and naming
convention inconsistency (camelCase vs. snake_case in the wrong context).

---

## Scan

```sh
# Detect formatter and linter config
!find . \( -name ".eslintrc*" -o -name ".prettierrc*" -o -name "eslint.config.*" \
  -o -name "biome.json" -o -name "pyproject.toml" -o -name ".flake8" \
  -o -name "setup.cfg" -o -name "golangci.yml" -o -name ".golangci.yml" \
  -o -name "rustfmt.toml" \) ! -path "*/node_modules/*" 2>/dev/null

# Mixed indentation (tabs vs spaces in same file)
grep_search(query="^\t", includes=["*.ts", "*.tsx", "*.js", "*.py"], is_regex=True)

# Trailing whitespace
grep_search(query=" $", includes=["*.ts", "*.tsx", "*.js", "*.py", "*.go"], is_regex=True)

# Mixed quote styles within files
grep_search(query=""", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

grep_search(query="'", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

# Line length violations (over 120 chars)
!awk 'length > 120 {print FILENAME ":" NR ": " length " chars"}' \
  $(find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" \
  -o -name "*.js" \) ! -path "*/node_modules/*" 2>/dev/null) 2>/dev/null | head -30

# Import ordering — unsorted imports
grep_search(query="^import\b", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

# Naming convention inconsistency (snake_case in TS, camelCase in Python)
grep_search(query="[a-z][a-z0-9]*_[a-z]", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

grep_search(query="[a-z][A-Z]", includes=["*.py"], is_regex=True)
```

---

## Patterns

- **Mixed indentation** — Tabs and spaces used interchangeably within the
  same file or codebase. Pick one; apply it consistently. If a formatter
  config exists, it defines the rule.

- **Inconsistent quote style** — Single and double quotes mixed within the
  same file without a semantic reason (e.g., avoiding escaping). If a
  Prettier or ESLint rule exists, it defines the canonical style.

- **Trailing whitespace** — Invisible characters at the end of lines.
  Creates noisy diffs and is universally considered a lint violation.

- **Line length violation** — Lines exceeding the project's configured
  maximum (default 120 if no config found). Break at logical boundaries —
  never break in the middle of a string or expression for purely cosmetic
  reasons.

- **Unsorted imports** — Import statements not ordered by the project
  convention (external → internal → relative, or alphabetical within
  groups). Disorder makes it harder to spot duplicates and missing deps.

- **Naming convention mismatch** — `snake_case` identifiers in a TypeScript
  codebase, or `camelCase` in Python. Each language has a dominant
  convention; deviations create unnecessary cognitive switching.

---

## Output

### Findings

For each finding:
- **Location**: `file:line` or `file` (for whole-file issues)
- **Pattern**: which category above
- **Rule source**: formatter/linter config that governs this, or `inferred
  from codebase majority` if no config exists

### Changes made

**Prefer invoking the formatter over manual fixes.** If a formatter is
present and configured, run it:

```sh
!npx prettier --write . 2>/dev/null
!npx eslint --fix . 2>/dev/null
!black . 2>/dev/null
!gofmt -w . 2>/dev/null
```

List what was run and what it changed. For issues the formatter cannot
fix (naming conventions, import ordering without a plugin), apply
manually and list each change:
- `file:line` — what was fixed
