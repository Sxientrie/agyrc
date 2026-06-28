# Critique — Performance

## Scope

Algorithmic complexity, N+1 queries, unnecessary re-renders (frontend), memory
leaks, blocking calls in async contexts, expensive operations in hot paths,
and chatty APIs.

---

## Scan

```sh
# Nested loops and chained iterations — O(n²) candidates
!grep -rn "for.*for\b\|while.*while\b\|\.map(.*\.map(\|\.filter(.*\.filter(\|\.forEach(.*\.forEach(" \
  --include="*.py" --include="*.ts" --include="*.tsx" --include="*.go" --include="*.js" . 2>/dev/null

# Database / ORM queries — look for queries inside loops
!grep -rn "\.query(\|\.find(\|\.findAll(\|\.findOne(\|\.where(\|\.filter(\b\|db\.\|SELECT\b\|cursor\.\|\.fetch(" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

# Frontend re-render suspects
!grep -rn "useEffect\b\|useState\b\|useMemo\b\|useCallback\b\|React\.memo\|shouldComponentUpdate\|computed\b\|watch\b" \
  --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" --include="*.vue" . 2>/dev/null

# Memory allocation in loops
!grep -rn "\.push(\b\|\.append(\b\|\.concat(\b\|\[\.\.\.\|new \b\|malloc\b\|make(\b" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null | head -50

# Blocking calls in async contexts
!grep -rn "time\.sleep(\|readFileSync\b\|writeFileSync\b\|execSync\b\|requests\.\b\|urllib\.request\b\|fs\.readSync\b" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

# Event listeners, timers, subscriptions — leak candidates
!grep -rn "addEventListener\b\|setInterval\b\|setTimeout\b\|subscribe(\b\|\.on(\b" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" . 2>/dev/null

# Multiple sequential awaits that could be batched
!grep -rn "await\b" \
  --include="*.ts" --include="*.tsx" --include="*.js" . 2>/dev/null | head -60
```

---

## Patterns

- **Nested loops on unbounded data** — An O(n²) or worse algorithm where
  the input size is not capped. Describe the worst-case input, the implied
  complexity, and what latency or CPU spike a user would observe at scale.

- **N+1 queries** — A database query executed inside a loop: each iteration
  incurs a round-trip where a single batched or joined query would do.
  Particularly common in ORM-heavy code where `.filter()` or `.find()` is
  called per-item.

- **Unnecessary re-renders** (frontend) — A component re-renders on every
  parent render because a prop value, callback, or derived value is
  recreated on each render rather than memoized. Includes missing
  `useMemo`, `useCallback`, or `React.memo` where the inputs are stable.

- **Allocations in hot paths** — Objects, arrays, or closures created on
  every tick of a tight loop or on every render cycle when a single
  pre-allocated structure would do. Includes spread operators copying large
  arrays unnecessarily.

- **Blocking calls in async contexts** — Synchronous I/O (`readFileSync`,
  `requests.get`, `time.sleep`) called on an async thread or event loop,
  stalling all other work on that thread until the call returns.

- **Memory leaks** — Event listeners, timers (`setInterval`), subscriptions,
  or references added but never removed. Closures capturing large objects
  that prevent GC. Common in component unmount paths and long-running
  server processes.

- **Chatty APIs** — Multiple sequential network or IPC calls that could be
  replaced by one batched or multiplexed request. Includes sequential
  `await` chains where `Promise.all` would parallelize them safely.

---

## Output

Produce a section titled `## Performance Findings`.

For each finding:

- **Location**: `file:line` — function, loop, or component name
- **Pattern**: which category above
- **Impact estimate**: describe the worst-case input or usage pattern, the
  implied complexity or latency, and what a user would observe (UI freeze,
  OOM crash, slow endpoint, high CPU)
- **Bucket**:
  - `confirmed bottleneck` — will be slow or leak today at realistic scale
  - `likely bottleneck under load` — safe at current scale, will break as
    data or traffic grows
  - `minor optimization` — measurable but unlikely to matter in practice

Rank within the section: blocking/OOM risks → N+1 queries →
O(n²) in hot paths → memory leaks → unnecessary allocations →
missing memoization → chatty APIs.
No code changes. Findings only.
