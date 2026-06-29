# Adding a New Skill

Complete guide to creating, structuring, and installing a skill for the Antigravity agent platform.

> For the full list of tools the agent can use inside skills, see [TOOL_REFERENCE.md](references/TOOL_REFERENCE.md).

---

## Table of Contents

1. [Create the Skill Directory](#1-create-the-skill-directory)
2. [Write SKILL.md](#2-write-skillmd)
3. [Organize Sub-files](#3-organize-sub-files)
4. [Tool Selection — What to Use and When](#4-tool-selection--what-to-use-and-when)
5. [User Interaction Patterns](#5-user-interaction-patterns)
6. [Output and Reporting](#6-output-and-reporting)
7. [Scope Resolution](#7-scope-resolution)
8. [Error Handling](#8-error-handling)
9. [Mobile UX & Toasts](#9-mobile-ux--toasts)
10. [Install and Test](#10-install-and-test)
11. [Update the README](#11-update-the-readme)
12. [Checklist](#12-checklist)

---

## 1. Create the Skill Directory

```bash
mkdir -p skills/<skill-name>
```

- Use **kebab-case**: `code-review`, `deploy-check`, `api-gen`
- The directory name must match the `name` field in `SKILL.md` frontmatter
- Keep it short — 1–3 words

---

## 2. Write `SKILL.md`

Every skill **must** have a `SKILL.md` file. It has two parts: frontmatter and body.

### Frontmatter (YAML)

```yaml
---
name: my-skill
description: >
  One concise paragraph describing what this skill does and when it activates.
  This text is what the agent uses to decide whether to load the skill.
  Make it specific and assertive, as vague descriptions won't trigger reliably.
---
```

| Field | Required | Notes |
|-------|----------|-------|
| `name` | ✅ | Must exactly match the directory name |
| `description` | ✅ | **Trigger-matched** — the agent reads this to decide whether to load the skill. Be specific about the domain, trigger keywords, and expected workflow |

### Body (Markdown)

The body is loaded **only after** the skill triggers. We recommend a **Phase-based execution structure**, which is the convention used by the main skills on this platform.

#### Recommended Phase-based Scaffold

Use this phase-based template for complex or multi-step workflows:

```markdown
# /my-skill — Descriptive Title

## Phase 1 — Pre-flight: Context Gathering
- Check for global rules files (e.g., `./AGENTS.md` or `~/.gemini/AGENTS.md`) using `view_file` to absorb project guidelines.
- Scan directory structure or run baseline command checks before planning work.

## Phase 2 — Routing & Focus Selection
- Map any command-line arguments to specific sub-tasks or focus areas.
- If no arguments are provided, use `ask_question` to let the user select the desired mode or tasks.

## Phase 3 — Execution: Sub-skill / Core Logic
- Read the instructions for the selected sub-task or sub-skill from its file.
- Perform the core actions (code generation, refactoring, analysis, etc.).

## Phase 4 — Verification & Safety
- Run the test suite or compile/lint checks to verify changes.
- Revert or log any failures.

## Phase 5 — Delivery & Reporting
- Generate the final markdown report and write it to the artifact location.
- Notify the user of completion.
```

#### Minimal Alternative Template

For simple, single-step utility skills, a flat structure is also acceptable:

```markdown
# /my-skill — Title

## Purpose
What problem does this solve? One paragraph max.

## Activation & Trigger
How is the skill triggered (e.g. `/my-skill` command or automatic semantic matching)?

## Scope Resolution
Define how the agent determines which files/directories to operate on.

## Steps
1. First action
2. Second action
3. Final cleanup

## Hard Rules
- Non-negotiable constraints or limits.
```

---

## 3. Organize Sub-files

For skills with multiple sub-tasks, lenses, or reference material, use subdirectories:

```
skills/my-skill/
├── SKILL.md              # Entry point (always required)
├── focus/                # Sub-lenses — parallel analysis angles
│   ├── lens-a.md         #   e.g., correctness, design, safety
│   └── lens-b.md
├── tasks/                # Sub-tasks — sequential cleanup steps
│   ├── task-a.md         #   e.g., dead-code, naming, formatting
│   └── task-b.md
├── references/           # Reference docs — read-only context
│   └── api-ref.md        #   e.g., device specs, API tables
├── scripts/              # Helper scripts — run by the agent
│   └── check.sh          #   e.g., lint wrappers, validation
└── examples/             # Example inputs/outputs
    └── sample.json       #   e.g., expected report format
```

### Existing Patterns

| Skill | Pattern | Subdirectory | Purpose |
|-------|---------|-------------|---------|
| **critique** | Lenses | `focus/` | Each file is a self-contained analysis lens (correctness, design, safety, etc.) |
| **hygiene** | Tasks | `tasks/` | Each file is a cleanup task (dead-code, naming, formatting, etc.) |
| **termux-device** | References | `references/` | Read-only docs the agent consults (system info, API tables) |

### When to Split

- **Split** when sub-parts are independently useful and the agent shouldn't load all of them every time
- **Don't split** if the skill is short enough to fit in 500 lines and all parts always run together

### How Sub-files Get Loaded

The agent reads sub-files **on demand** using `view_file`. Your `SKILL.md` tells the agent which sub-file to read for each situation. Example from critique:

```markdown
For each selected lens **in order**:
1. Read `focus/<lens>.md` to load its instructions.
2. Execute those instructions against the in-scope code.
```

---

## 4. Tool Selection — What to Use and When

Skills instruct the agent on **what to do**, but the agent decides **which tools to use**. However, good skills guide the agent toward efficient tool choices. Here's the decision framework:

### Reading Code and Files

| Situation | Best Tool | Why |
|-----------|-----------|-----|
| Read a specific file | `view_file` | Direct, shows line numbers, supports line ranges |
| Check what files exist in a directory | `list_dir` | Lists children with sizes — fast overview |
| Find a pattern across many files | `grep_search` | Ripgrep — fast, supports regex and glob filters |
| Find a specific function or class | `grep_search` with `MatchPerLine: true` | Returns exact line numbers you can reference |
| Read a sub-skill file | `view_file` with `IsSkillFile: true` | Tells the system this is an instruction file |

**Tip for skill authors:** If your skill needs to scan the codebase, instruct the agent to use `grep_search` first (fast, targeted) and `view_file` second (for the files that matched). Don't instruct it to `view_file` every file — that's slow and burns context.

Example instruction in a skill:
```markdown
## Scope Resolution
1. Use `grep_search` to find all files matching the user's focus area.
2. Use `view_file` to read only the matched files.
3. Never read more than 20 files — ask the user to narrow scope if exceeded.
```

### Modifying Code

| Situation | Best Tool | Why |
|-----------|-----------|-----|
| Create a new file | `write_to_file` | Creates parent dirs automatically |
| Edit one spot in a file | `replace_file_content` | Precise, single contiguous block |
| Edit multiple spots in one file | `multi_replace_file_content` | Multiple non-adjacent edits in one call |
| Run a build/test/lint command | `run_command` | Shell access |
| Delete or rename files | `run_command` with `rm` or `mv` | No dedicated delete/rename tool exists |

**Tip for skill authors:** When your skill applies fixes, instruct the agent to:
1. Show the proposed diff to the user first
2. Confirm before writing
3. Use `replace_file_content` for single changes (cheaper, faster)
4. Use `multi_replace_file_content` only when touching multiple separate sections of the same file

### Searching for Information

| Situation | Best Tool | Why |
|-----------|-----------|-----|
| Search the internet | `search_web` | Returns summarized results with citations |
| Read a specific web page | `read_url_content` | Fetches and converts HTML → markdown |
| Search code in the project | `grep_search` | Local ripgrep search |
| Find a file by name | `run_command` with `find` | More flexible than `list_dir` for deep searches |

**Tip for skill authors:** If your skill needs external docs (e.g., API references, framework guides), instruct the agent to use `search_web` to find the right page, then `read_url_content` to read it. Don't hardcode URLs — they go stale.

### Running Commands

| Situation | Best Tool | Why |
|-----------|-----------|-----|
| Quick command (< 10s) | `run_command` with `WaitMsBeforeAsync: 10000` | Runs synchronously, result in same turn |
| Long-running command | `run_command` with `WaitMsBeforeAsync: 500` | Sends to background automatically |
| Interactive command needing stdin | `run_command` + `manage_task` with `send_input` | Send input to a running process |
| Check on a background command | `manage_task` with `status` | Don't poll — system auto-notifies on completion |

**Tip for skill authors:** If your skill runs tests or builds, set `WaitMsBeforeAsync` high enough for the expected duration. If it might take a while, use `schedule` with `TimerCondition` set to the task ID so the agent checks back if it doesn't hear anything.

### Delegating Work

| Situation | Best Tool | Why |
|-----------|-----------|-----|
| Research task (read-only) | `invoke_subagent` with `TypeName: "research"` | Separate context, can't modify files |
| Work that needs file writes | `invoke_subagent` with `TypeName: "self"` | Full capabilities in separate context |
| Parallel independent tasks | `invoke_subagent` with multiple entries | All run concurrently |
| Custom specialist | `define_subagent` → then `invoke_subagent` | Custom system prompt + tool selection |

**Tip for skill authors:** Subagents are powerful but expensive. Use them when:
- The task has clearly independent sub-parts that benefit from parallelism
- The task would clutter the main conversation context
- You need a separate workspace (`Workspace: "branch"`) to avoid conflicts

Don't use subagents for simple sequential work — it's faster to do it inline.

---

## 5. User Interaction Patterns

Skills should be interactive, not fire-and-forget. Here's how to interact with the user effectively.

### Asking the User to Choose

Use `ask_question` whenever there's a fixed set of options. The tool requires a specific JSON payload format. Always show the agent an explicit payload example in your skill file.

#### Payload Example in Skill:
```markdown
Present an `ask_question` picker with this payload:
{
  "questions": [
    {
      "question": "What task would you like to run?",
      "options": [
        "(Recommended) Run all checks",
        "Run formatting only",
        "Skip checks"
      ],
      "is_multi_select": false
    }
  ],
  "toolSummary": "Task Selection",
  "toolAction": "Selecting check task"
}
```

#### Guidelines for the Payload:
- **`is_multi_select`**: Set `true` to render checkboxes (allowing the user to select multiple options), or `false` to render radio buttons (single selection).
- **Options style**: Prefix the recommended option with `(Recommended)` and put it first. Format options as the user's direct response (e.g., "Run all checks", not "Runs check").
- **No Manual Numbers**: Do not number the options in the array; the UI handles numbering.
- **No 'Other' Option**: Do not add an "Other" option; the UI provides one automatically.

If the user skips (selects nothing), abort with a one-line message.

**When to use `ask_question`:**
- User needs to pick from a fixed set (lenses, tasks, files, options)
- Yes/no confirmation before a destructive action
- Disambiguation when user input is ambiguous

**When NOT to use `ask_question`:**
- User needs to type a free-form value (name, path, URL) — just ask in plain text
- Only one reasonable interpretation exists — state the assumption and proceed

### Confirming Before Changes

For skills that modify code, always instruct the agent to confirm:

```markdown
## Interactive Follow-up
After presenting the report:
1. Show an `ask_question` multi-select listing every finding by ID + title
2. For each selected finding, show the proposed diff
3. Confirm each change with the user before writing
```

### Progressive Disclosure

Don't dump everything at once. Guide the user through stages:

1. **Pick what to do** → `ask_question` with options
2. **Show what was found** → artifact with report
3. **Pick what to fix** → `ask_question` with findings
4. **Confirm each fix** → show diff, then apply

### Handling "Skip" and "Abort"

Always include an escape hatch:

```markdown
Include a "Skip — just wanted the report" option in the follow-up picker.
If the user selects nothing, end gracefully with a one-line message.
```

---

## 6. Output and Reporting

### Use Artifacts for Reports

Skills that produce substantial output (reports, analysis, findings) should write to a dedicated **artifact** — a markdown file stored in the agent's conversation log directory.

#### Path Convention
Instruct the agent to write the file using the following placeholder path:
`Path: <appDataDir>/brain/<conversation-id>/your_filename.md`

#### Resolution at Runtime
The agent's runtime environment automatically resolves `<appDataDir>` and `<conversation-id>` dynamically based on the current session. The skill author must use these exact literal strings as placeholders in the instructions.

#### Example Instruction:
```markdown
## Report Assembly
Write the final report using the `write_to_file` tool.
Path: `<appDataDir>/brain/<conversation-id>/hygiene_report.md`
Payload:
{
  "Summary": "Code hygiene report — findings and verification results.",
  "UserFacing": true,
  "RequestFeedback": false
}
```

### Structured Findings

If your skill produces findings (issues, suggestions, results), define a consistent format:

```markdown
### Finding Format
Every finding MUST follow this template:

### [CATEGORY] ID: one-line title

- **Severity**: critical | high | medium | low | nit
- **File**: `path/to/file` L42–L58
- **What**: ≤ 3 sentences describing the issue
- **Why it matters**: 1 sentence on impact
- **Suggested fix**:
  ```diff
  - old code
  + new code
  ```
```

This gives findings:
- A unique **ID** for referencing in follow-up pickers
- A **severity** for prioritization
- A **file + line** link so the user can navigate directly
- A **diff** so the fix is actionable, not just described

### Summary Statistics

For skills that produce multiple findings, add a statistics table:

```markdown
## Statistics
| Category | Critical | High | Medium | Low | Nit |
|----------|----------|------|--------|-----|-----|
| ...      | ...      | ...  | ...    | ... | ... |
| **Total**| ...      | ...  | ...    | ... | ... |
```

### Executive Summary

For longer reports, lead with a short summary:

```markdown
## Executive Summary
<≤ 5 bullet points: biggest risks, overall health, recommended next step>
```

---

## 7. Scope Resolution

Every skill that operates on code must determine **what code to operate on** before doing anything else. Define this clearly in your skill:

```markdown
## Scope Resolution

| Signal | Scope |
|---|---|
| User names files / functions | Exactly those |
| Open-editor file list in metadata | Those files |
| Nothing specified, small repo (≤ 30 files) | Whole repo |
| Nothing specified, large repo | Ask user to narrow down |
```

### Efficient Scoping Instructions

Tell the agent *how* to resolve scope efficiently:

```markdown
### How to Resolve Scope
1. Check if the user named specific files or functions in their input.
2. If not, use `list_dir` on the project root to gauge size.
3. If ≤ 30 files, use `grep_search` + `view_file` to read everything relevant.
4. If > 30 files, use `ask_question` to ask the user which directories or files to focus on.
5. Never read more than 20 files without asking — context is finite.
```

### Anti-patterns

- ❌ "Read the entire codebase" — blows up on any real project
- ❌ No scope step at all — the skill guesses wrong and wastes effort
- ❌ Hardcoded file paths — breaks on any project that isn't structured identically

---

## 8. Error Handling

### Permission Errors

If your skill reads files that might be ACL-blocked, instruct the agent:

```markdown
If a file read fails with a permission error, use `ask_permission` to request
`read_file` access for the specific directory. Never request wildcard access.
```

### Empty Results

```markdown
If no issues are found, say so explicitly:
"No issues found." — one line, no padding.
Never invent issues to fill the report.
```

### User Cancellation

```markdown
If the user skips the picker or says "cancel," abort immediately with:
"Cancelled. No changes made."
```

### Tool Failures

```markdown
If a shell command fails, report the error and suggest a fix.
Don't silently retry more than once.
```

---

## 9. Mobile UX & Toasts

On Android/Termux, long-running tasks benefit from native completion alerts. Guide the agent to use Termux's toast mechanism to notify the user upon completion:

- **Toasts**: Use `termux-toast -s -g bottom "Message"` for transient toast popups.
- **Vibration & Notifications**: Do not use vibration (`termux-vibrate`) or status bar alerts (`termux-notification`) to avoid clutter and noise.

#### Example Instruction:
```markdown
## Phase 6 — Completion
Alert the user that the run is complete:
termux-toast -s -g bottom "Hygiene checks completed successfully."
```

---

## 10. Install and Test

### Install via Script

```bash
cd ~/Projects/agyrc
./install.sh
```

The installer symlinks your skill directory into `~/.gemini/config/skills/`.

### Install Manually

```bash
ln -s ~/Projects/agyrc/skills/my-skill ~/.gemini/config/skills/my-skill
```

### Test the Trigger

#### Slash Command Triggers
1. Open a new Antigravity conversation.
2. Type your slash command (e.g., `/my-skill`).
3. Verify the agent loads the skill and follows its instructions.
4. Test edge cases:
   - No arguments → should show picker or run default
   - Specific argument → should run that specific thing
   - Invalid argument → should handle gracefully

#### Semantic/Automatic Triggers (e.g., `termux-device`)
1. Ask a question or request a task that naturally relates to the skill's description (e.g., "tell me about my device's specs").
2. Check the model's loaded skills log or response to verify the skill was activated.
3. If it doesn't load, refine the YAML frontmatter description to include more explicit keyword association.

### Dry Run

Use `./install.sh --check` to see what would be symlinked without changing anything.

---

## 11. Update the README

Add a row to the skill table in [`README.md`](README.md):

```markdown
| **my-skill** | `/my-skill [args]` | Description of what it does. |
```

Also update the directory tree if you added new subdirectories.

---

## 12. Checklist

Before committing a new skill, verify:

- [ ] Directory name matches `name` in frontmatter
- [ ] `description` in frontmatter is specific enough to trigger reliably
- [ ] `SKILL.md` is under 500 lines
- [ ] Scope resolution step is defined — never operates on "everything"
- [ ] User interaction uses `ask_question` for fixed choices
- [ ] Output format is defined with consistent finding IDs (if applicable)
- [ ] Hard rules section exists with non-negotiable constraints
- [ ] Follow-up step lets the user pick which findings to act on (if applicable)
- [ ] Empty/no-results case is handled honestly
- [ ] `install.sh` picks it up correctly
- [ ] README skill table is updated
- [ ] Tested in a real conversation
