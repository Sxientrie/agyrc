# Antigravity Agent Tool Reference

Complete reference for every tool available to agents running on the Antigravity (Gemini CLI) platform.  
Use this as a lookup when building skills, defining subagents, or understanding what the agent can and cannot do.

---

## Table of Contents

| # | Tool | Category | Summary |
|---|------|----------|---------|
| 1 | [`view_file`](#1-view_file) | Read | View file contents (text or binary) |
| 2 | [`list_dir`](#2-list_dir) | Read | List directory contents |
| 3 | [`grep_search`](#3-grep_search) | Read | Ripgrep pattern search across files |
| 4 | [`search_web`](#4-search_web) | Read | Web search with summarized results |
| 5 | [`read_url_content`](#5-read_url_content) | Read | Fetch and convert URL to markdown |
| 6 | [`write_to_file`](#6-write_to_file) | Write | Create new files |
| 7 | [`replace_file_content`](#7-replace_file_content) | Write | Edit a single contiguous block in a file |
| 8 | [`multi_replace_file_content`](#8-multi_replace_file_content) | Write | Edit multiple non-contiguous blocks in a file |
| 9 | [`run_command`](#9-run_command) | Write | Run shell commands |
| 10 | [`ask_question`](#10-ask_question) | Interaction | Ask the user multiple-choice questions |
| 11 | [`ask_permission`](#11-ask_permission) | Interaction | Request permission for blocked operations |
| 12 | [`list_permissions`](#12-list_permissions) | Interaction | List current permission grants |
| 13 | [`generate_image`](#13-generate_image) | Media | Generate or edit images from text prompts |
| 14 | [`invoke_subagent`](#14-invoke_subagent) | Agent | Launch one or more subagents |
| 15 | [`define_subagent`](#15-define_subagent) | Agent | Define a new subagent type |
| 16 | [`send_message`](#16-send_message) | Agent | Send a message to another agent |
| 17 | [`manage_subagents`](#17-manage_subagents) | Agent | List, kill, or kill all subagents |
| 18 | [`manage_task`](#18-manage_task) | Task | Manage background tasks |
| 19 | [`schedule`](#19-schedule) | Task | Set timers or recurring cron jobs |

---

## 1. `view_file`

**Category:** Read  
**Purpose:** View the contents of a file from the local filesystem. Supports text files and binary files (image, video).

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `AbsolutePath` | string | ✅ | Absolute path to the file |
| `StartLine` | integer | ❌ | Start line (1-indexed, inclusive) |
| `EndLine` | integer | ❌ | End line (1-indexed, inclusive) |
| `ContentOffset` | integer | ❌ | Byte offset for viewing content beyond the initial byte limit when truncated |
| `IsSkillFile` | boolean | ❌ | Set `true` only when reading a file to execute its instructions |

### Constraints

- Text files: max **800 lines** per view, max **46,080 bytes** per view
- Binary files (image/video): always returns the entire file — do not use `StartLine`/`EndLine`
- Cannot edit `.ipynb` files
- Line ranges:
  - Omit both → first 800 lines (or entire file if shorter)
  - `StartLine` only → next 800 lines from that point
  - `EndLine` only → previous 800 lines up to that point
  - Both → exact range (must be ≤ 800 lines)

### Example

```json
{
  "AbsolutePath": "/home/user/project/main.py",
  "StartLine": 50,
  "EndLine": 100
}
```

---

## 2. `list_dir`

**Category:** Read  
**Purpose:** List all files and subdirectories that are direct children of a directory.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DirectoryPath` | string | ✅ | Absolute path to the directory |

### Output Format

For each child:
- Relative path to the directory
- Whether it is a directory or file
- Size in bytes (files only)
- Number of children, recursive (directories only — may be missing in large workspaces)

### Example

```json
{
  "DirectoryPath": "/home/user/project"
}
```

---

## 3. `grep_search`

**Category:** Read  
**Purpose:** Use ripgrep to find exact pattern matches within files or directories. Results capped at **50 matches**.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `SearchPath` | string | ✅ | Absolute path to a file or directory to search |
| `Query` | string | ✅ | Search term or regex pattern |
| `MatchPerLine` | boolean | ❌ | `true` → return each matching line with line numbers. `false` → return only filenames |
| `IsRegex` | boolean | ❌ | `true` → treat `Query` as regex. `false` → literal string match |
| `CaseInsensitive` | boolean | ❌ | `true` → case-insensitive search |
| `Includes` | string[] | ❌ | Glob patterns to filter files (e.g., `["*.py", "!**/vendor/*"]`). Only applies when `SearchPath` is a directory |

### Output Format (when `MatchPerLine` is true)

For each match:
- `Filename`
- `LineNumber`
- `LineContent`

### Example

```json
{
  "SearchPath": "/home/user/project",
  "Query": "def main",
  "MatchPerLine": true,
  "Includes": ["*.py"]
}
```

---

## 4. `search_web`

**Category:** Read  
**Purpose:** Perform a web search and get a summary of relevant information with URL citations.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | ✅ | The search query |
| `domain` | string | ❌ | Domain to prioritize in results |

### Example

```json
{
  "query": "python asyncio best practices 2025",
  "domain": "docs.python.org"
}
```

---

## 5. `read_url_content`

**Category:** Read  
**Purpose:** Fetch content from a URL via HTTP and convert HTML to markdown. No JavaScript execution, no authentication.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Url` | string | ✅ | URL to fetch |

### Limitations

- No JavaScript execution
- No authentication support
- Converts HTML to markdown automatically
- For pages requiring login, JS, or user visibility, use a browser-based approach instead

### Example

```json
{
  "Url": "https://docs.python.org/3/library/asyncio.html"
}
```

---

## 6. `write_to_file`

**Category:** Write  
**Purpose:** Create new files. Automatically creates parent directories if they don't exist.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TargetFile` | string | ✅ | Absolute path to the file to create |
| `CodeContent` | string | ✅ | The content to write |
| `Description` | string | ✅ | Brief explanation of the file's purpose |
| `Overwrite` | boolean | ✅ | Set `true` to overwrite an existing file. Errors if file exists and this is `false` |
| `ArtifactMetadata` | object | ❌ | Required when creating an artifact file (see below) |

### ArtifactMetadata Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `Summary` | string | ✅ | Detailed multi-line summary of the artifact |
| `UserFacing` | boolean | ✅ | `true` if the artifact should be presented to the user |
| `RequestFeedback` | boolean | ✅ | `true` to show a "Proceed" button for executable content |

### Example

```json
{
  "TargetFile": "/home/user/project/utils.py",
  "CodeContent": "def greet(name):\n    return f'Hello, {name}!'\n",
  "Description": "Utility function for greeting",
  "Overwrite": false
}
```

---

## 7. `replace_file_content`

**Category:** Write  
**Purpose:** Edit a **single contiguous block** of text in an existing file.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TargetFile` | string | ✅ | Absolute path to the file |
| `Instruction` | string | ✅ | Description of the changes being made |
| `Description` | string | ✅ | Brief user-facing explanation |
| `TargetContent` | string | ✅ | Exact string to replace (must match file content exactly, including whitespace) |
| `ReplacementContent` | string | ✅ | Content to replace it with |
| `StartLine` | integer | ✅ | Start of the search range (1-indexed) |
| `EndLine` | integer | ✅ | End of the search range (1-indexed) |
| `AllowMultiple` | boolean | ✅ | `true` → replace all occurrences in range. `false` → error if multiple found |
| `TargetLintErrorIds` | string[] | ❌ | IDs of lint errors this edit aims to fix |

### Rules

- Use **only** for single contiguous edits
- For multiple non-adjacent edits in the same file, use `multi_replace_file_content` instead
- Never make parallel calls to this tool and `multi_replace_file_content` for the same file
- `TargetContent` must be an exact character-for-character match including leading whitespace
- Cannot edit `.ipynb` files

### Example

```json
{
  "TargetFile": "/home/user/project/main.py",
  "Instruction": "Fix the off-by-one error in the loop",
  "Description": "Change range(n) to range(n+1) to include the last element",
  "TargetContent": "for i in range(n):",
  "ReplacementContent": "for i in range(n + 1):",
  "StartLine": 42,
  "EndLine": 42,
  "AllowMultiple": false
}
```

---

## 8. `multi_replace_file_content`

**Category:** Write  
**Purpose:** Edit **multiple non-contiguous blocks** of text in a single file, in one operation.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `TargetFile` | string | ✅ | Absolute path to the file |
| `Instruction` | string | ✅ | Description of all changes |
| `Description` | string | ✅ | Brief user-facing explanation |
| `ReplacementChunks` | object[] | ✅ | Array of replacement chunks (see below) |
| `ArtifactMetadata` | object | ❌ | Metadata updates if editing an artifact |
| `TargetLintErrorIds` | string[] | ❌ | IDs of lint errors this edit aims to fix |

### ReplacementChunk Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `TargetContent` | string | ✅ | Exact string to replace |
| `ReplacementContent` | string | ✅ | Replacement content |
| `StartLine` | integer | ✅ | Start of search range (1-indexed) |
| `EndLine` | integer | ✅ | End of search range (1-indexed) |
| `AllowMultiple` | boolean | ✅ | `true` → replace all occurrences in range |

### Rules

- Use **only** for multiple non-contiguous edits in the same file
- For a single contiguous edit, use `replace_file_content` instead
- Never make parallel calls for the same file
- Cannot edit `.ipynb` files

### Example

```json
{
  "TargetFile": "/home/user/project/main.py",
  "Instruction": "Update import and fix function signature",
  "Description": "Add new import and update parameter type",
  "ReplacementChunks": [
    {
      "TargetContent": "import os",
      "ReplacementContent": "import os\nimport sys",
      "StartLine": 1,
      "EndLine": 3,
      "AllowMultiple": false
    },
    {
      "TargetContent": "def process(data):",
      "ReplacementContent": "def process(data: list[str]):",
      "StartLine": 25,
      "EndLine": 25,
      "AllowMultiple": false
    }
  ]
}
```

---

## 9. `run_command`

**Category:** Write  
**Purpose:** Run shell commands on the host system. OS: Linux. Shell: bash.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `CommandLine` | string | ✅ | Exact command to execute |
| `Cwd` | string | ✅ | Working directory (absolute path). **Never use `cd` as a command** |
| `WaitMsBeforeAsync` | integer | ✅ | Milliseconds to wait before sending to background. Set high (e.g., 10000) for commands expected to finish quickly. Set low (e.g., 500) for long-running/interactive commands |
| `RunPersistent` | boolean | ❌ | `true` → run in a persistent terminal that preserves env vars between calls |
| `RequestedTerminalID` | string | ❌ | ID of a persistent terminal to reuse (from a previous persistent `run_command`) |

### Behavior

- Commands run with `PAGER=cat`
- User must approve each command before execution
- If a command doesn't return output, it was sent to background as a task — use `manage_task` to interact
- The system auto-notifies when background commands finish — no polling needed
- Persistent terminals share variables but NOT working directory, aliases, or functions

### Example

```json
{
  "CommandLine": "git log -n 5 --oneline",
  "Cwd": "/home/user/project",
  "WaitMsBeforeAsync": 5000
}
```

---

## 10. `ask_question`

**Category:** Interaction  
**Purpose:** Ask the user one or more multiple-choice questions. Renders an interactive modal with selectable options and a write-in field. Execution blocks until the user responds.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `questions` | object[] | ✅ | Array of question objects (see below) |

### Question Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `question` | string | ✅ | The question text (supports GitHub markdown links) |
| `options` | string[] | ✅ | At least 2 options. Formatted as the user's direct response. A write-in "Other" option is always added by the UI |
| `is_multi_select` | boolean | ❌ | `true` → checkboxes (multiple selections). `false` → radio buttons (single selection) |

### Guidelines

- Don't enumerate options manually — the UI does it
- Don't add an "Other" option — one is always present
- Prefix recommended options with `"(Recommended)"`
- List recommended options first

### Example

```json
{
  "questions": [
    {
      "question": "Which framework should we use?",
      "options": [
        "(Recommended) React — most ecosystem support",
        "Vue — simpler learning curve",
        "Svelte — smallest bundle size"
      ],
      "is_multi_select": false
    }
  ]
}
```

---

## 11. `ask_permission`

**Category:** Interaction  
**Purpose:** Request permission after a file/URL operation encounters a permission error. Request the narrowest scope possible.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Action` | enum | ✅ | One of: `command`, `custom`, `escalate_admin`, `execute_url`, `mcp`, `read_file`, `read_url`, `unsandboxed`, `write_file` |
| `Target` | string | ✅ | The target of the action (path, command prefix, domain, etc.) |
| `Reason` | string | ❌ | Why permission is needed |

### Action Types & Target Formats

| Action | Target Format | Matching Behavior |
|--------|---------------|-------------------|
| `command` | Command prefix or `*` | Matches commands by prefix (e.g., `git` matches `git add`) |
| `read_file` | Absolute path to file or directory | Matches the file or everything under the directory |
| `write_file` | Absolute path to file or directory | Same as `read_file`; also implicitly covers `read_file` for the same path |
| `read_url` | Domain name or `*` | Matches the domain and all subdomains |
| `execute_url` | Domain name or `*` | Matches the domain and all subdomains |
| `mcp` | `serverName/toolName`, `serverName/*`, or `*` | Matches by exact server name |
| `unsandboxed` | Command prefix or `*` | Runs outside the terminal sandbox |
| `escalate_admin` | Reason for escalation | Always prompts the user |
| `custom` | Custom action name | Matches the exact action name |

### Rules

- Never request wildcard (`*`) or root-level permissions
- Prefer a subdirectory over a whole project
- Do NOT use this for `curl`, `wget`, `pip`, `npm` — use `run_command` directly instead

### Example

```json
{
  "Action": "read_file",
  "Target": "/home/user/.config/app",
  "Reason": "Need to read app configuration to diagnose the issue"
}
```

---

## 12. `list_permissions`

**Category:** Interaction  
**Purpose:** List all current permission grants to understand what resources are accessible without prompting.

### Parameters

None (only the standard `toolSummary` and `toolAction` metadata fields).

---

## 13. `generate_image`

**Category:** Media  
**Purpose:** Generate an image or edit existing images from a text prompt. The result is saved as an artifact.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Prompt` | string | ✅ | Text prompt for generation or edit instructions |
| `ImageName` | string | ✅ | Filename for the saved image. Lowercase with underscores, max 3 words (e.g., `login_page_mockup`) |
| `AspectRatio` | string | ❌ | One of: `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `9:16`, `16:9`. Default: `1:1` |
| `ImagePaths` | string[] | ❌ | Absolute paths to existing images to use as input (edit, combine, reference). Max 3 images |

### Example

```json
{
  "Prompt": "A modern dark-mode dashboard with glassmorphism cards showing analytics data",
  "ImageName": "dashboard_mockup",
  "AspectRatio": "16:9"
}
```

---

## 14. `invoke_subagent`

**Category:** Agent  
**Purpose:** Launch one or more subagents concurrently. Each runs in the background with its own conversation context.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Subagents` | object[] | ✅ | Array of subagent specifications (see below) |

### Subagent Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `TypeName` | string | ✅ | Type name of the subagent to invoke (e.g., `research`, `self`, or a custom-defined name) |
| `Role` | string | ✅ | 2–5 word job-title-style description (e.g., `Database Debugger`) |
| `Prompt` | string | ✅ | Clear, actionable task description |
| `Workspace` | string | ❌ | `inherit` (default, same workspace), `branch` (isolated clone), or `share` (shared repo, independent branching) |

### Built-in Subagent Types

| Type | Tools | Use Case |
|------|-------|----------|
| `research` | Read-only (file, search, web) | Codebase exploration, documentation research, broad surveys |
| `self` | Full (same as parent) | Any task needing write access in a separate conversation context |

### Behavior

- Each subagent gets a unique `conversationID`
- Multiple subagents of the same type can run concurrently
- The system auto-notifies when a subagent finishes — no polling needed
- Use `send_message` to communicate with running subagents

### Example

```json
{
  "Subagents": [
    {
      "TypeName": "research",
      "Role": "API docs researcher",
      "Prompt": "Find all REST endpoints defined in the project and list them with their HTTP methods and paths."
    },
    {
      "TypeName": "self",
      "Role": "Test writer",
      "Prompt": "Write unit tests for the UserService class in src/services/user.ts",
      "Workspace": "branch"
    }
  ]
}
```

---

## 15. `define_subagent`

**Category:** Agent  
**Purpose:** Define a new reusable subagent type for the current conversation. Once defined, it can be invoked repeatedly via `invoke_subagent`.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | ✅ | Unique name for the subagent type |
| `description` | string | ✅ | Human-readable description of what it does |
| `system_prompt` | string | ✅ | Detailed system prompt for the subagent |
| `enable_write_tools` | boolean | ❌ | `true` → can create/edit files and run commands |
| `enable_mcp_tools` | boolean | ❌ | `true` → can call MCP tools |
| `enable_subagent_tools` | boolean | ❌ | `true` → can define and invoke its own subagents |

### Default Capabilities

All subagents have by default:
- Read tools (file viewing, searching, web)
- Communication tools (messaging other agents)

### Example

```json
{
  "name": "linter",
  "description": "Runs lint checks and reports issues without modifying files",
  "system_prompt": "You are a code linter. Run lint commands, parse the output, and report issues in a structured format. Never modify source files.",
  "enable_write_tools": true
}
```

---

## 16. `send_message`

**Category:** Agent  
**Purpose:** Send a message to another agent (subagent, peer agent). **Not for communicating with the user.**

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Recipient` | string | ✅ | The conversation ID of the target agent |
| `Message` | string | ✅ | The message content |

### Use Cases

- Check on subagent progress
- Send additional instructions to a running subagent
- Send new instructions to an idle subagent

### Example

```json
{
  "Recipient": "abc123-def456-ghi789",
  "Message": "Focus on the authentication module first, then move to the payment flow."
}
```

---

## 17. `manage_subagents`

**Category:** Agent  
**Purpose:** List, kill, or kill all active subagents.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Action` | enum | ✅ | `list`, `kill`, or `kill_all` |
| `ConversationIds` | string[] | ❌ | Required for `kill` — IDs of subagents to terminate |

### Behavior

- `kill` terminates the specified subagents **and all their descendants**
- `kill_all` terminates **every** subagent and their descendants
- Branched workspaces are deleted on kill, but logs and artifacts are preserved

### Example

```json
{
  "Action": "kill",
  "ConversationIds": ["abc123-def456"]
}
```

---

## 18. `manage_task`

**Category:** Task  
**Purpose:** Manage background tasks (commands sent to background, timers, cron jobs).

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Action` | enum | ✅ | `list`, `kill`, `status`, or `send_input` |
| `TaskId` | string | ❌ | Required for `kill`, `status`, `send_input` |
| `Input` | string | ❌ | Required for `send_input` — stdin input to send |

### Actions

| Action | Description |
|--------|-------------|
| `list` | List all running background tasks |
| `kill` | Cancel a task's execution |
| `status` | Check current status and log file location |
| `send_input` | Send stdin input to a running task |

### Important

Do NOT poll `status` in a loop. The system auto-notifies when a task finishes.

### Example

```json
{
  "Action": "send_input",
  "TaskId": "conv-id/task-5",
  "Input": "y\n"
}
```

---

## 19. `schedule`

**Category:** Task  
**Purpose:** Set a one-shot timer or a recurring cron job that sends a notification in the background.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Prompt` | string | ✅ | Message content for the notification when the timer fires |
| `DurationSeconds` | string | ❌ | Seconds to wait (one-shot timer). Mutually exclusive with `CronExpression` |
| `CronExpression` | string | ❌ | 5-field cron expression (recurring). Mutually exclusive with `DurationSeconds` |
| `TimerCondition` | string | ❌ | Early-cancel condition for one-shot timers. `never` (default), `any` (cancel on any message), or a specific sender ID |
| `MaxIterations` | string | ❌ | Max number of cron triggers. Only for `CronExpression`. Default: unlimited |

### TimerCondition Options

| Value | Behavior |
|-------|----------|
| `never` | Timer always fires after `DurationSeconds` unless explicitly cancelled |
| `any` | Timer cancels if ANY message is received before expiry |
| `<sender-id>` | Timer cancels only if a message from that specific sender arrives |

### Constraints

- Must specify exactly one of `DurationSeconds` or `CronExpression`
- Cannot have multiple active timers with overlapping early-cancel conditions
- Returns immediately — does not pause execution

### Examples

**One-shot timer:**
```json
{
  "DurationSeconds": "300",
  "Prompt": "Check on the build status",
  "TimerCondition": "task-123"
}
```

**Recurring cron:**
```json
{
  "CronExpression": "*/5 * * * *",
  "Prompt": "Poll deployment status",
  "MaxIterations": "12"
}
```

---

## Common Metadata Fields

Every tool call requires these two fields (not listed in each tool above for brevity):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `toolSummary` | string | ✅ | 2–5 word noun phrase (e.g., `Directory analysis`, `File edit`) |
| `toolAction` | string | ✅ | 2–5 word verb phrase (e.g., `Analyzing directory`, `Editing file`) |

These are used for logging and UI display. They don't affect tool behavior.

---

## Permission Model (ACL)

Tools are subject to a permission system that controls access:

### File Tools (`view_file`, `write_to_file`, `replace_file_content`, `multi_replace_file_content`, `list_dir`)

- Subject to file-tool ACL (auto-approved, ask-list, deny-list)
- On permission failure, use `ask_permission` to request access

### Shell Commands (`run_command`)

- Auto-approved — bypass file-tool ACL entirely
- User approves each command individually before execution

### URL Tools (`read_url_content`, `search_web`)

- Typically auto-approved for all domains
- Check `list_permissions` to verify

### Agent Tools (`invoke_subagent`, `define_subagent`, `send_message`, `manage_subagents`)

- Always available — no permission restrictions

---

## Tool Selection Guide

| Task | Tool |
|------|------|
| Read a file | `view_file` |
| See what's in a directory | `list_dir` |
| Find text across files | `grep_search` |
| Search the internet | `search_web` |
| Read a web page | `read_url_content` |
| Create a new file | `write_to_file` |
| Edit one spot in a file | `replace_file_content` |
| Edit multiple spots in a file | `multi_replace_file_content` |
| Run a shell command | `run_command` |
| Ask user to pick from options | `ask_question` |
| Generate an image | `generate_image` |
| Delegate work to another agent | `invoke_subagent` |
| Wait for something with a timeout | `schedule` |
| Check on a background command | `manage_task` |
