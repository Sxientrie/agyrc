# Critique — Design

## Scope

Architecture, abstraction quality, separation of concerns, API surface design,
dependency direction, coupling, and — for frontend codebases — component
structure, layout patterns, and design token usage.

---

## Scan

```sh
# Module / package / directory layout
!find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" -o -name "*.js" \) \
  | sed 's|/[^/]*$||' | sort -u | head -40

# Exported / public API surface
!grep -rn "^export\|^export default\|^def \|^func \|^class \|^interface \|^type \|^pub fn\|^pub struct" \
  --include="*.py" --include="*.ts" --include="*.tsx" --include="*.go" --include="*.js" . | head -80

# Import graph — what depends on what
!grep -rn "^import\|^from\b\|require(" \
  --include="*.ts" --include="*.tsx" --include="*.py" --include="*.go" --include="*.js" . | head -100

# Separation of concerns — business/data logic inside UI components
!grep -rn "fetch(\|axios\.\|prisma\.\|db\.\|sql\|knex\." \
  --include="*.tsx" --include="*.jsx" . 2>/dev/null | head -40

# Separation of concerns — presentation logic inside data/service files
!grep -rn "className=\|style=\|<div\|<span\|console\.log\b" \
  --include="*.service.*" --include="*.repository.*" --include="*.model.*" . 2>/dev/null | head -20
```

```sh
# --- Frontend / UI codebases only ---

# Design token files
!find . \( -name "tokens.*" -o -name "*design-tokens*" -o -name "theme.*" -o -name "variables.*" \) \
  ! -path "*/node_modules/*" | head -20

# Token usage vs. hardcoded values
!grep -rn "var(--\|theme\.\|tokens\.\|colors\.\|spacing\.\|typography\." \
  --include="*.ts" --include="*.tsx" --include="*.css" --include="*.scss" . 2>/dev/null | head -40

# Hardcoded values that should be tokens
!grep -rn "#[0-9a-fA-F]\{3,6\}\b\|rgba\?\(.*\)\|[0-9]\+px\b\|[0-9]\+rem\b\|z-index\s*:\s*[0-9]" \
  --include="*.ts" --include="*.tsx" --include="*.css" --include="*.scss" . 2>/dev/null | head -60
```

---

## Patterns

**Architecture & abstraction**

- **Leaky abstraction** — Internals are exposed through the public API. Callers
  know implementation details they shouldn't need to know. Changing the
  internal representation would require callers to change too.

- **Inverted dependency** — A high-level module imports directly from a
  low-level detail rather than depending on an interface or abstraction. The
  dependency arrow points in the wrong direction.

- **God object / god file** — A class or module with too many responsibilities:
  too many exported symbols, too many imports from unrelated domains, or a
  name so generic it could mean anything (`utils.py`, `helpers.ts`, `manager.go`).

- **Premature abstraction** — A generalized interface or base class serving
  exactly one concrete caller. The abstraction adds indirection without buying
  flexibility.

- **Missing abstraction** — The same logic appears at two or more call sites
  with minor variations. Should be extracted into a shared function, hook,
  or module.

- **Tight coupling** — Two components or modules that cannot be tested or
  replaced in isolation because they reach directly into each other's state
  or call each other's internals.

- **Separation of concerns violation** — A module, component, or function
  handles two or more clearly distinct responsibilities: for example, a UI
  component that also fetches data and transforms it, a service that owns
  both business logic and presentation formatting, or a route handler that
  embeds SQL queries directly. The signal is that the file would need to
  change for two unrelated reasons.

**Frontend / UI — design tokens & layout**

- **Design token violation** — Hardcoded hex colors, pixel sizes, font sizes,
  z-indices, or border-radii that should reference a design token. Makes
  design changes a grep-and-replace exercise instead of a single token update.

- **Inconsistent component contract** — Props that diverge from the established
  pattern across sibling components (e.g., `size="lg"` in one, `size="large"`
  in another; some components accept `className`, others don't).

- **Layout anti-pattern** — Absolute positioning or magic pixel offsets where
  flex or grid should be used; non-responsive units where relative units or
  clamp() are appropriate; layout logic duplicated across components that
  should share a layout primitive.

---

## Output

Produce a section titled `## Design Findings`.

For each finding:

- **Location**: file / class / function / component name
- **Pattern**: which category above
- **Rationale**: why this is a design problem — what breaks, becomes harder,
  or becomes inconsistent when it's not addressed
- **Bucket**:
  - `clear violation` — objectively conflicts with sound design principles
  - `design smell — worth discussing` — depends on project intent or scale

Rank within the section: structural violations (inverted deps, god objects) →
coupling issues → abstraction quality → token/layout violations.
No code changes. Findings only.
