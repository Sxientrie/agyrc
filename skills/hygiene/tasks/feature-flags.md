# Hygiene Task — Feature Flags

## Scope

Stale feature flags and toggles whose controlling condition is always true
or false, commented-out code blocks with no active TODO explaining their
return, and dead conditional branches gating removed or fully-shipped features.

---

## Scan

```sh
# Feature flag naming patterns
grep_search(query="FLAG_|FF_|FEATURE_|isEnabled\b|isDisabled\b|toggle\b|featureFlag\b|feature_flag\b|getFlag\b|useFlag\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Flag definition files
!find . \( -name "flags.*" -o -name "features.*" -o -name "toggles.*" \
  -o -name "feature-flags.*" -o -name "*flags.ts" -o -name "*flags.py" \) \
  ! -path "*/node_modules/*" | head -10

# Conditional blocks gating flags (if flag / unless flag)
grep_search(query="if.*FLAG_|if.*FF_|if.*isEnabled|if.*toggle\b|if.*featureFlag\b", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)

# Commented-out code blocks (multi-line)
grep_search(query="^[[:space:]]*//", includes=["*.ts", "*.tsx", "*.js"], is_regex=True)

grep_search(query="^[[:space:]]*#", includes=["*.py"], is_regex=True) (filter out matches for '^[[:space:]]*#!')

# REMOVE / DELETE / DEPRECATED markers
grep_search(query="REMOVE\b|DELETE ME|DEPRECATED\b|NO LONGER|CLEAN.UP|TECH.DEBT", includes=["*.ts", "*.tsx", "*.py", "*.go", "*.js"], is_regex=True)
```

---

## Patterns

- **Always-on flag** — A feature flag that is permanently set to `true`
  (hardcoded, always enabled in config, or the condition always evaluates
  truthy). The flag gating logic is dead — the `if (flag)` branch is always
  taken and the `else` is unreachable. Remove the flag and keep the branch body.

- **Always-off flag** — A feature flag permanently set to `false`. The
  guarded feature is effectively disabled. Both the flag check and the
  guarded block are candidates for removal — but verify the feature is
  intentionally dead and not simply untoggled before deleting.

- **Commented-out code block** — Three or more consecutive lines of
  commented-out code with no adjacent comment explaining why it is
  preserved or when it will return. If no TODO or date is attached,
  treat it as dead.

- **Orphaned flag definition** — A flag defined in a flag registry or
  constants file but never referenced in application code. Safe to remove
  from the registry.

- **Deprecated marker** — Code tagged `DEPRECATED`, `REMOVE`, or
  `DELETE ME` with no completion date or ticket reference. Surface these
  for human review rather than auto-deleting.

---

## Output

### Findings

For each finding:
- **Location**: `file:line` — flag name or block description
- **Pattern**: which category above
- **Evidence**: what makes it stale (always-true condition, no consumers,
  commented with no TODO, etc.)
- **Action**: `remove flag + inline branch` / `remove block` /
  `flag for human review`

Never auto-delete an always-off flag without noting it — the feature
may be intentionally dark-launched and not yet removed from config.

### Changes made

List every deletion or inlining performed:
- `file:line` — `flagName` — what was removed or inlined
