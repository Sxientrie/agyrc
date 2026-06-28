# Critique — Observability

## Scope

Logging strategy, structured vs. unstructured output, missing error context,
silent failure paths, metrics and tracing instrumentation, and PII exposure
in log output.

---

## Scan

```sh
# Unstructured / debug logs left in production paths
!grep -rn "console\.log\|console\.warn\|console\.error\|print(\b\|fmt\.Println\|fmt\.Printf" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" --include="*.go" . 2>/dev/null

# Swallowed errors — caught but not logged or re-raised
!grep -rn "except:\|except Exception:\|catch\s*(.*)\s*{" \
  --include="*.py" --include="*.ts" --include="*.js" --include="*.go" . 2>/dev/null

!grep -rn "\.catch(\s*[)]\|\.catch(\s*err\s*=>\s*{})\|catch\s*(_)" \
  --include="*.ts" --include="*.js" . 2>/dev/null

# Error logs missing structured context fields
!grep -rn "logger\.error\|log\.Error\|log\.error\|logging\.error" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

# Potential PII written to log output
!grep -rn "log.*user\|log.*email\|log.*password\|log.*token\|log.*secret\|log.*ssn\|log.*credit" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

!grep -rn "JSON\.stringify(user\|JSON\.stringify(req\|str(request\|str(user" \
  --include="*.py" --include="*.ts" --include="*.js" . 2>/dev/null

# Tracing / metrics instrumentation presence
!grep -rn "span\|trace\|metric\|histogram\|counter\|gauge\|opentelemetry\|datadog\|newrelic\|prometheus" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null | head -40

# Critical business path entry points (auth, payment, mutation) — cross-ref with above
!grep -rn "checkout\|payment\|charge\|auth\|login\|signup\|transfer\|order\|webhook" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null | head -40
```

---

## Patterns

- **Silent swallow** — An error is caught and discarded with no log, metric,
  or re-raise. The failure disappears entirely. The caller and any monitoring
  system see a clean return; the actual cause is unrecoverable after the fact.

- **Unstructured log** — A free-form string is written where a structured
  key-value log would be queryable and aggregatable. `"Error processing user
  123"` cannot be filtered, grouped, or alerted on by a log platform;
  `{event: "process_failed", user_id: 123, error: e.message}` can.

- **Missing error context** — An error is logged but without the fields
  needed to reproduce or diagnose it: no request ID, no input shape, no
  operation name, no correlation ID. The log confirms something broke but
  not where, what, or for whom.

- **PII in log output** — User-identifiable data (email, name, token,
  password, SSN, card number) written to log output. Violates data
  minimization requirements and creates a breach surface in log storage
  and forwarding pipelines.

- **Uninstrumented critical path** — A business-critical function (auth,
  payment, checkout, data mutation, external webhook) has no timing metric,
  distributed trace span, or error counter around it. Degradation in that
  path is invisible until a user reports it or an alert fires downstream.

- **Debug log in production path** — `console.log`, `print()`, or
  `fmt.Println` used for observability in code that runs in production.
  Output is unstructured, unleveled, and often leaks internal state. Should
  be replaced with a leveled, structured logger.

---

## Output

Produce a section titled `## Observability Findings`.

For each finding:

- **Location**: `file:line` — function, handler, or catch block
- **Pattern**: which category above
- **Impact**: what a responder would be unable to determine during an
  incident because this signal is missing or corrupted
- **Bucket**:
  - `confirmed gap` — the signal is absent or harmful today
  - `needs human review` — depends on runtime log config or external
    instrumentation not visible in source
  - `hardening opportunity` — partially instrumented but fragile or incomplete

Rank within the section: silent swallows on critical paths → PII in logs →
missing error context → uninstrumented critical paths → unstructured logs →
debug logs in production.
No code changes. Findings only.
