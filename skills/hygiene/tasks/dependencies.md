# Hygiene Task — Dependencies

## Scope

Outdated direct dependencies, packages with known security advisories,
deprecated packages with available replacements, and pinned versions
blocking patch or minor updates.

---

## Scan

```sh
# Node / npm
!if [ -f "package.json" ]; then
  cat package.json | grep -A200 '"dependencies"\|"devDependencies"'
fi

!if [ -f "package-lock.json" ] || [ -f "yarn.lock" ] || [ -f "pnpm-lock.yaml" ]; then
  echo "lockfile present"
fi

!npx npm-check-updates --format json 2>/dev/null | head -100

# Python
!if [ -f "requirements.txt" ]; then cat requirements.txt; fi
!if [ -f "Pipfile" ]; then cat Pipfile; fi
!if [ -f "pyproject.toml" ]; then grep -A50 "\[tool.poetry.dependencies\]\|\[project\]" pyproject.toml; fi
!pip list --outdated --format=json 2>/dev/null | head -60

# Go
!if [ -f "go.mod" ]; then cat go.mod; fi
!go list -u -m all 2>/dev/null | grep "\[" | head -30

# Rust
!if [ -f "Cargo.toml" ]; then cat Cargo.toml; fi
!cargo outdated 2>/dev/null | head -30
```

---

## Patterns

- **Outdated major version** — A dependency pinned to a major version behind
  the current release. Major bumps often contain breaking changes — flag for
  human decision rather than auto-updating.

- **Outdated minor / patch version** — A dependency behind on minor or patch
  releases. Patch updates are almost always safe. Minor updates should be
  verified against the changelog but are usually safe to apply.

- **Security advisory** — A package version with a known CVE or security
  advisory. Treat as highest priority regardless of version gap.

- **Deprecated package** — A package marked deprecated by its publisher,
  with an official or community replacement. Examples: `request` → `got` or
  `axios`; `moment` → `date-fns` or `dayjs`.

- **Phantom dependency** — A package used in code but not declared in the
  manifest (relies on transitive resolution). Fragile — declare it explicitly.

- **Unused declared dependency** — A package in the manifest with no
  `import` or `require` anywhere in the source. Safe to remove after
  confirming it is not a peer dependency or build-time tool.

---

## Output

### Findings

For each finding:
- **Package**: name and current version
- **Pattern**: which category above
- **Available**: latest version or replacement package
- **Update type**: `patch` / `minor` / `major` / `replace`
- **Risk**: `safe` (patch) / `verify changelog` (minor) / `human decision` (major / replace)

### Changes made

Apply only `safe` (patch) updates automatically. For all others, list
the recommendation in Deferred Items with the changelog URL if findable.

List every applied update:
- `package@oldVersion` → `package@newVersion`
