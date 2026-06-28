---
name: feature-plus
description: >
  High-value, non-generic feature addition. Activate when the user runs
  /feature-plus [optional hint]. Reads the codebase first, derives exactly
  three context-specific feature candidates, lets the user pick one or more
  via multi-select, writes a tight spec per selection, implements each as one
  atomic unit, then self-verifies against the acceptance criteria.
  Never suggests generic or template features — every candidate must be
  grounded in what already exists.
---

# /feature-plus — Context-Driven Feature Addition

Reads before it talks. Suggests before it asks. Specs before it builds.
Verifies before it closes. Each feature selected is one atomic, working,
production-ready addition — not scaffolding, not stubs.

---

## Phase 1 — Pre-flight: Workspace and codebase context

### 1A — Read AGENTS.md

Read `AGENTS.md` using the native `view_file` tool. Check in this order,
stop at the first hit:

1. `./AGENTS.md`
2. `~/.gemini/AGENTS.md`

Absorb stated architecture decisions, conventions, off-limits areas, and
any existing roadmap items. Do not re-derive what is already declared.

### 1B — Scan the codebase

Run all of the following before forming any opinion:

```sh
# Directory layout — understand the domain and structure
!find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" \
  -o -name "*.js" -o -name "*.jsx" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" \
  | sed 's|/[^/]*$||' | sort -u | head -40

# Public API surface — what already exists
grep_search(query="^export|^export default|^def |^func |^class |router\.|app\.route|@app\.", includes=["*.py", "*.ts", "*.tsx", "*.go", "*.js"], is_regex=True)

# Data models — what entities are in play
grep_search(query="^class |^interface |^type |^struct |^model |Schema\(|z\.object\(|@Entity\b", includes=["*.py", "*.ts", "*.go", "*.js"], is_regex=True)

# Test coverage — what paths are already exercised
!find . \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \) \
  ! -path "*/node_modules/*" | head -20

# Existing feature flags or TODO/roadmap markers
grep_search(query="TODO|FEATURE|ROADMAP|COMING SOON|WIP\b|PLANNED\b", includes=["*.py", "*.ts", "*.tsx", "*.go", "*.js"], is_regex=True)

# Auth / permission system — who can do what
grep_search(query="role\b|permission\b|authorize|authenticate|@login_required|guard\b|middleware\b", includes=["*.py", "*.ts", "*.go", "*.js"], is_regex=True)
```

### 1C — Resolve domain and hint

After the scan, identify:
- The **domain** (e-commerce, dev tool, SaaS dashboard, API service, etc.)
- The **primary entities** (what the product is built around)
- The **user types** visible in the code (admin, member, guest, etc.)
- Any **gaps or natural extensions** visible from what already exists

If the user ran `/feature-plus <hint>`, also note that hint — it biases
candidate generation in Phase 2 but does not override the scan findings.

---

## Phase 2 — Discovery: Generate exactly three candidates

Using everything from Phase 1, derive exactly **three** feature candidates.

### Rules for valid candidates

Every candidate must pass all four gates:

1. **Grounded** — Extends or composes something that already exists in the
   codebase. Not invented from a feature template. References actual file
   names, model names, or endpoints by name.

2. **Scoped** — Deliverable in one focused implementation session. Not a
   multi-week project. If the idea is large, scope it to one slice.

3. **Non-generic** — Would not appear on a generic feature checklist for
   this domain. "Add pagination" is generic. "Add cursor-based pagination
   to the `/orders` endpoint so the mobile client can stream results without
   re-fetching on status changes" is specific.

4. **User-facing value** — Produces an observable outcome for a real user
   or operator. Internal refactors do not qualify (those belong in `/critique`).

### Candidate format (internal — not shown to user yet)

Before presenting to the user, structure each candidate internally as:

```
Title: <short name>
Grounded in: <actual file/model/endpoint this extends>
User-facing outcome: <what a user can do or see that they cannot today>
Scope boundary: <what is explicitly out of scope>
Why high-value: <why this matters more than a generic alternative>
```

Do not present this internal structure to the user. Use it to verify
each candidate passes all four gates before proceeding.

---

## Phase 3 — Selection: Let the user pick

Invoke `ask_question` with the three candidates as options. Format each
option as: `<Title> — <user-facing outcome in one sentence>`.

```json
{
  "questions": [
    {
      "question": "I found three high-value features grounded in this codebase. Pick one or more to build:",
      "options": [
        "<Candidate 1 title> — <user-facing outcome>",
        "<Candidate 2 title> — <user-facing outcome>",
        "<Candidate 3 title> — <user-facing outcome>",
        "None of these — let me describe what I want instead"
      ],
      "is_multi_select": true
    }
  ],
  "toolSummary": "Feature selection",
  "toolAction": "Choosing which features to build"
}
```

**If "None of these — let me describe what I want instead":**
Accept the user's description as free text. Validate it against the four
candidate gates before proceeding. If it fails a gate, explain why and
ask them to narrow or reframe it. Once it passes, treat it as a single
selected candidate and continue to Phase 4.

Wait for selection. Do not begin speccing until the user has confirmed.

---

## Phase 4 — Spec: One tight spec per selected feature

For each selected feature, produce a spec block and present it to the user
for approval **before writing any code**.

Format each spec exactly like this:

```markdown
## Spec — <Feature Title>
Grounded in: <actual file / model / endpoint name(s)>

**Problem**
<One sentence: what gap or friction exists today that this removes.>

**User-facing outcome**
<One sentence: what a specific user type can do or observe after this
ships that they cannot today. Must be concrete and testable.>

**Acceptance criteria**
- [ ] <Specific, binary, testable criterion — not "works correctly">
- [ ] <Specific, binary, testable criterion>
- [ ] <Specific, binary, testable criterion>
(3–6 criteria. Each must be verifiable without running the full app.)

**Scope boundary — explicitly out**
- <What will NOT be built in this pass>
- <What will NOT be built in this pass>

**Files likely touched**
- `<file>` — <why>
- `<file>` — <why>
```

After presenting all spec blocks, invoke `ask_question`:

```json
{
  "questions": [
    {
      "question": "Review the spec(s) above. How would you like to proceed?",
      "options": [
        "Specs look good — build all of them",
        "Revise a spec before building (write in what to change)",
        "Build only some — let me pick which",
        "Cancel — I'll use the specs as a reference and build manually"
      ],
      "is_multi_select": false
    }
  ],
  "toolSummary": "Spec approval",
  "toolAction": "Approving feature specs before implementation begins"
}
```

**If "Revise a spec before building":**
Accept the revision write-in, update the relevant spec block, and
re-present only the revised spec. Re-invoke the approval payload.

**If "Build only some — let me pick which":**
Invoke `ask_question` with each approved spec as a selectable option.
`is_multi_select: true`. Continue with only the selected subset.

**If "Cancel":**
Exit cleanly. Specs remain in the conversation for manual reference.

---

## Phase 5 — Implementation: Build each feature as one atomic unit

For each approved spec, implement it completely before moving to the next.

### Rules for implementation

- **One atomic unit** — All changes for a feature land together. No partial
  implementations. If a route is added, its handler, any model changes, and
  at least one test all land in the same pass.

- **Follow existing conventions** — Match the file structure, naming style,
  error handling pattern, and import style already present in the codebase.
  Do not introduce new patterns unless the spec requires them.

- **No scaffolding, no stubs** — Every function written must work. No
  `// TODO: implement`, no `pass`, no `throw new Error("not implemented")`.

- **Tests required for acceptance criteria** — Each acceptance criterion
  must have a corresponding test or be verifiable via the existing test
  harness. If no test harness exists, note this and write at minimum one
  integration-level test.

After implementing each feature, briefly state:
- What files were created or modified
- Which acceptance criteria are covered by the implementation

Do not move to Phase 6 until all selected features are implemented.

---

## Phase 6 — Verification: Self-check against the spec

For each implemented feature, run through every acceptance criterion from
its spec and explicitly mark it:

```
## Verification — <Feature Title>

- [x] <criterion> — satisfied by <function/file:line>
- [x] <criterion> — satisfied by <function/file:line>
- [ ] <criterion> — NOT satisfied — <reason and what remains>
```

If any criterion is marked `[ ]`:
- Do not claim the feature is complete
- State what remains and why it was not addressed
- Invoke `ask_question` asking whether to address the gap now or
  document it as a known limitation

---

## Phase 7 — Delivery: Write the feature summary artifact

Write the combined output using the `write_to_file` tool.

Path: `<appDataDir>/brain/<conversation-id>/feature_plus_report.md`

```json
{
  "Summary": "Feature-plus delivery report — specs, implementation notes, and verification results.",
  "UserFacing": true,
  "RequestFeedback": false
}
```

Format the body exactly like this:

```markdown
# Feature-Plus Report — <project or directory name>
Features built: <count>
Date: <today>

---

## <Feature 1 Title>
### Spec
<paste final approved spec block>

### Implementation notes
<files created or modified, key decisions made>

### Verification
<paste verification block — all criteria marked>

---

## <Feature 2 Title>   ← omit if only one feature was built
...

---

## Known limitations
<Any criterion that could not be satisfied, with reason. Omit section
if all criteria passed.>
```

Notify the user:

```bash
termux-notification \
  --title "Feature-Plus Complete" \
  --content "<count> feature(s) built and verified." \
  --button1 "Open Report" \
  --button1-action "termux-open <appDataDir>/brain/<conversation-id>/feature_plus_report.md"



