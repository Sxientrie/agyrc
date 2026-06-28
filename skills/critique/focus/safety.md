# Critique — Safety

## Scope

Security vulnerabilities, injection attacks, authentication and authorization
gaps, secret exposure, output encoding, and insecure patterns.

> **Concurrency safety** (race conditions, unguarded shared state, uncoordinated
> file access) is handled in depth by the companion `audit-races` skill. If the
> user's safety concern is specifically about races or threading, recommend
> running `/audit-races` after this critique — or in addition to it.

---

## Scan

```sh
# Injection — SQL, shell, template, eval
!grep -rn "f\".*{.*}\"\|\.format(\|% (\|execute(\|query(\|raw(\|cursor\.\|RawQuery\b" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

!grep -rn "subprocess\.call\|subprocess\.run\|os\.system\|os\.popen\|exec(\b\|eval(\b\|Function(" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

# Hardcoded secrets
!grep -rni \
  "password\s*=\s*['\"][^'\"]\+['\"]\|api_key\s*=\s*['\"][^'\"]\+['\"]\|secret\s*=\s*['\"][^'\"]\+['\"]\|token\s*=\s*['\"][^'\"]\+['\"]" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" \
  --exclude-dir=".git" --exclude-dir="node_modules" . 2>/dev/null

# Auth and permission guard presence
!grep -rn "is_admin\|has_permission\|authorize\|authenticate\|@login_required\|middleware\|guard\b\|role\b\|require_auth\|verifyToken" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

# XSS / unsafe output
!grep -rn "innerHTML\s*=\|dangerouslySetInnerHTML\|v-html\|render_template_string\|Markup(\|\.html(\|safe(\b" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" . 2>/dev/null

# Insecure deserialization
!grep -rn "pickle\.loads\|yaml\.load(\b\|marshal\.loads\|unserialize\b\|JSON\.parse.*req\b" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

# Path traversal
!grep -rn "os\.path\.join.*request\|open(.*request\|readFile.*req\|\.join(.*param\|\.join(.*query" \
  --include="*.py" --include="*.ts" --include="*.go" --include="*.js" . 2>/dev/null

# Dependency manifests (located only — not audited here)
!find . \( -name "package.json" -o -name "requirements.txt" -o -name "go.mod" -o -name "Pipfile" \) \
  ! -path "*/node_modules/*" | head -10
```

---

## Patterns

- **SQL / command injection** — User-controlled or externally-sourced input
  reaches a database query or shell command without parameterization or
  allow-listing. Covers string interpolation into queries, `.execute()` with
  formatted strings, and unsanitized subprocess arguments.

- **Hardcoded secrets** — Credentials, API keys, tokens, or private keys
  committed directly in source rather than read from environment variables
  or a secrets manager.

- **Missing authentication or authorization** — Endpoints, functions, or
  mutations that should require a verified identity or a specific permission
  but have no auth check, or where the check is present but can be bypassed
  (e.g. checked only on the frontend, or not applied to all HTTP methods).

- **XSS / unsafe output rendering** — User-controlled data rendered as raw
  HTML without encoding. Covers `innerHTML`, `dangerouslySetInnerHTML`,
  unescaped template variables, and `Markup()` used with untrusted input.

- **Insecure deserialization** — Untrusted data passed to `pickle.loads`,
  `yaml.load` (without `Loader=yaml.SafeLoader`), `eval`, `exec`, or
  equivalent. Can lead to arbitrary code execution.

- **Path traversal** — File paths constructed by joining user-supplied input
  without stripping `..` sequences or validating against an allowed root.

- **Dependency exposure** — Note the presence of dependency manifests.
  Flag only obviously outdated major versions or known-bad package names
  if visible. Full audit requires a dedicated tool (`pip-audit`, `npm audit`,
  `govulncheck`).

---

## Output

Produce a section titled `## Safety Findings`.

For each finding:

- **Location**: `file:line` — endpoint, function, or template name
- **Pattern**: which category above
- **Attack vector**: how an attacker could reach this path and what they
  could achieve if they did (data exfiltration, RCE, privilege escalation,
  session hijacking, etc.)
- **Bucket**:
  - `confirmed vulnerability` — the path is open today
  - `needs human review` — depends on runtime configuration or caller
    contract that can't be determined statically
  - `hardening opportunity` — currently mitigated elsewhere but fragile

Rank within the section: injection and auth gaps → secret exposure →
output encoding → insecure deserialization → path traversal → deps.
No code changes. Findings only.
