# Adding a New Skill

Complete guide to creating, structuring, and installing a skill for the Antigravity agent platform.

> For the full list of tools the agent can use inside skills, see [TOOL_REFERENCE.md](TOOL_REFERENCE.md).

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
9. [Install and Test](#9-install-and-test)
10. [Update the README](#10-update-the-readme)
11. [Checklist](#11-checklist)

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
  One paragraph describing what this skill does and when it activates.
  Keep it under 3 sentences. This text is what the agent uses to decide
  whether to load the skill, so be specific.
---
```

| Field | Required | Notes |
|-------|----------|-------|
| `name` | ✅ | Must exactly match the directory name |
| `description` | ✅ | **Trigger-matched** — the agent reads this to decide whether to load the skill. Vague descriptions (e.g., "helps with code") won't trigger reliably. Be specific about what it does and when it activates |

### Body (Markdown)

The body is loaded **only after** the skill triggers. Structure it like this:

```markdown
# /my-skill — Descriptive Title

## Purpose
What problem does this solve? One paragraph max.

## Activation & Trigger
How does the user trigger it?
- Slash command: `/my-skill [args]`
- Automatic: describe the conditions
- Both: specify which

### Input Matrix
| User input | Behavior |
|---|---|
| `/my-skill` (no args) | Show picker or run default |
| `/my-skill <specific>` | Run that specific thing |
| `/my-skill all` | Run everything |

## Scope Resolution
What code / files does this skill operate on?
(See Section 7 below for guidance)

## Steps
1. First thing the agent does
2. Second thing
3. ...

## Output Format
What the report / result looks like.
(See Section 6 below for guidance)

## Interactive Follow-up
What happens after the skill finishes?
(See Section 5 below for guidance)

## Hard Rules
- Non-negotiable constraints
- Things the skill must never do
- Quality bars it must meet
```

### Size Limit

Keep `SKILL.md` under **500 lines**. If you need more:
- Move detailed sub-instructions into sub-files (`focus/`, `tasks/`, `references/`)
- The agent reads sub-files on demand, so they don't waste tokens when unused

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

Use `ask_question` whenever there's a fixed set of options:

```markdown
## Activation
If the user types `/my-skill` with no arguments, show a picker:

Present an `ask_question` multi-select with these options:
1. Option A — brief description
2. Option B — brief description
3. Option C — brief description
4. Run all

If the user skips (selects nothing), abort with a one-line message.
```

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

Skills that produce substantial output (reports, analysis, findings) should write to an **artifact** — a markdown file in the agent's artifact directory.

Instruct the agent to create the artifact with `write_to_file` and set `ArtifactMetadata`:

```markdown
## Report Assembly
Produce one artifact using `write_to_file` with:
- `ArtifactMetadata.UserFacing`: true
- `ArtifactMetadata.Summary`: description of the report
- `ArtifactMetadata.RequestFeedback`: true (if the user should act on it)
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

## 9. Install and Test

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

1. Open a new Antigravity conversation
2. Type your slash command (e.g., `/my-skill`)
3. Verify the agent loads the skill and follows its instructions
4. Test edge cases:
   - No arguments → should show picker or run default
   - Specific argument → should run that specific thing
   - Invalid argument → should handle gracefully

### Dry Run

Use `./install.sh --check` to see what would be symlinked without changing anything.

---

## 10. Update the README

Add a row to the skill table in [`README.md`](../README.md):

```markdown
| **my-skill** | `/my-skill [args]` | Description of what it does. |
```

Also update the directory tree if you added new subdirectories.

---

## 11. Checklist

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
